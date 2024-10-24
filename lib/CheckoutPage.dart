import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'orders.dart';
import 'login.dart'; // Import the login page for logout

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String address;
  final double latitude;
  final double longitude;

  const CheckoutPage({
    required this.cartItems,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with WidgetsBindingObserver {
  String _selectedPaymentMethod = 'Cash on Delivery'; // Default payment method
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final Uuid _uuid = Uuid();
  bool _isLoading = false; // Add a loading state
  String? _txRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _txRef != null) {
      _checkPaymentStatus(_txRef!);
    }
  }

  double _calculateTotal() {
    double subtotal = 0.0;
    double serviceCharge = 39.20;
    double deliveryFee = 55.00;

    for (var item in widget.cartItems) {
      double price = (item['price'] ?? 0.0) as double;
      int quantity = (item['quantity'] ?? 1) as int;
      subtotal += price * quantity;
    }
    return subtotal + serviceCharge + deliveryFee;
  }

  Future<void> _confirmOrder() async {
    setState(() {
      _isLoading = true; // Show loading screen
    });

    try {
      String? token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      _txRef = _uuid.v4(); // Create a unique transaction reference (once)
      await _storage.write(key: 'ongoing_tx_ref', value: _txRef);

      final totalAmount = _calculateTotal(); // Grand total amount for all menu items

      // Service charge and delivery fee
      final double serviceCharge = 39.20;
      final double deliveryFee = 55.00;

      // Calculate the number of items in the cart to distribute the service charge and delivery fee
      int totalQuantity = 0;
      for (var item in widget.cartItems) {
        totalQuantity += item['quantity'] as int;
      }

      // Loop to save all items with their own calculated total price
      for (var item in widget.cartItems) {
        final double itemPrice = (item['price'] as double);
        final int itemQuantity = (item['quantity'] as int);
        final double itemTotalPrice = itemPrice * itemQuantity;
        final double itemServiceCharge = (serviceCharge / totalQuantity) * itemQuantity;
        final double itemDeliveryFee = (deliveryFee / totalQuantity) * itemQuantity;
        final double itemFinalTotal = itemTotalPrice + itemServiceCharge + itemDeliveryFee;

        final orderBody = {
          'tx_ref': _txRef,
          'menuId': item['id'],
          'restaurantId': item['restaurantId'],
          'quantity': itemQuantity,
          'address': widget.address,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'totalPrice': itemFinalTotal,
        };

        if (_selectedPaymentMethod == 'Cash on Delivery') {
          orderBody['status'] = 'waiting for delivery';
        } else {
          orderBody['status'] = 'pending';
        }

        // Send order data to the backend for each item
        final response = await http.post(
          Uri.parse('https://food-delivery-backend-uls4.onrender.com/user/createOrder'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode(orderBody),
        );

        if (response.statusCode == 401) {
          _logout(); // Token is expired or invalid, log out the user
          return;
        }

        if (response.statusCode != 201) {
          throw Exception('Order saving failed for an item');
        }
      }

      if (_selectedPaymentMethod == 'Cash on Delivery') {
        final transactionResponse = await http.post(
          Uri.parse('https://food-delivery-backend-uls4.onrender.com/api/transaction/saveCashOnDeliveryTransaction'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            'tx_ref': _txRef,
            'amount': totalAmount,
            'currency': 'ETB',
            'email': 'user@example.com',
          }),
        );

        if (transactionResponse.statusCode == 401) {
          _logout(); // Token is expired or invalid, log out the user
          return;
        }

        if (transactionResponse.statusCode == 201) {
          setState(() {
            _isLoading = false; // Hide loading screen
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order confirmed with Cash on Delivery')),
          );

          widget.cartItems.clear(); // Clear the cart items after successful order

          // Navigate to OrdersPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => OrdersPage()),
          );
        } else {
          throw Exception('Transaction saving failed');
        }
      } else {
        // Handle Mobile Payment
        final paymentResponse = await http.post(
          Uri.parse('https://food-delivery-backend-uls4.onrender.com/api/transaction/createPayment'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode({
            'tx_ref': _txRef,
            'amount': totalAmount.toString(),
            'currency': 'ETB',
            'email': 's@gmail.com',
          }),
        );

        if (paymentResponse.statusCode == 401) {
          _logout(); // Token is expired or invalid, log out the user
          return;
        }

        if (paymentResponse.statusCode == 200) {
          final responseBody = jsonDecode(paymentResponse.body);
          final paymentUrl = responseBody['data']['checkout_url'];
          if (await canLaunch(paymentUrl)) {
            await launch(paymentUrl);
            _checkPaymentStatus(_txRef!); // Start checking payment status
          } else {
            throw Exception('Could not launch payment URL');
          }
        } else {
          throw Exception('Payment initiation failed');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading screen on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _checkPaymentStatus(String txRef) async {
    try {
      while (true) {
        final response = await http.get(
          Uri.parse('https://food-delivery-backend-uls4.onrender.com/api/transaction/checkpayment?tx_ref=$txRef'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${await _storage.read(key: 'token')}",
          },
        );

        if (response.statusCode == 401) {
          _logout(); // Token is expired or invalid, log out the user
          return;
        }

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['data']['status'] == 'success') {
            setState(() {
              _isLoading = false;
              widget.cartItems.clear();
            });
            await _storage.delete(key: 'ongoing_tx_ref');
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrdersPage()));
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Waiting for payment confirmation...')),
        );

        await Future.delayed(Duration(seconds: 5));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking payment status')),
      );
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'token'); // Delete the token from secure storage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Navigate back to login
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                RadioListTile<String>(
                  title: Text('Cash on Delivery'),
                  value: 'Cash on Delivery',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text('Mobile Banking'),
                  value: 'Mobile Banking',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF652023),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text('Confirm Order'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
              child: Center(
                child: Image.asset('assets/Pizza_spinning.gif'), // Loading GIF
              ),
            ),
        ],
      ),
    );
  }
}

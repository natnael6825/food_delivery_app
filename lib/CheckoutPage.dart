import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import 'orders.dart';

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

    _txRef = _uuid.v4(); // Create a unique transaction reference
    await _storage.write(key: 'ongoing_tx_ref', value: _txRef);

    final totalAmount = _calculateTotal();

    for (var item in widget.cartItems) {
      final orderBody = {
        'tx_ref': _txRef,
        'menuId': item['id'],
        'restaurantId': item['restaurantId'],
        'quantity': item['quantity'],
        'address': widget.address, // Adding address
        'latitude': widget.latitude, // Adding latitude
        'longitude': widget.longitude, // Adding longitude
        'totalPrice': totalAmount, // Adding totalPrice to be consistent with the payment
      };

      if (_selectedPaymentMethod == 'Cash on Delivery') {
        orderBody['status'] = 'waiting for delivery';
      } else {
        orderBody['status'] = 'pending';  // Add "pending" status for other methods
      }

      // Send order data to the backend
      final response = await http.post(
        Uri.parse('https://e6e4-196-189-16-22.ngrok-free.app/orders/createOrder'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(orderBody),
      );

      if (response.statusCode != 201) {
        throw Exception('Order saving failed for an item');
      }
    }

    if (_selectedPaymentMethod == 'Cash on Delivery') {
      // Save the transaction for Cash on Delivery
      final transactionResponse = await http.post(
        Uri.parse('https://e6e4-196-189-16-22.ngrok-free.app/api/transaction/saveCashOnDeliveryTransaction'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'tx_ref': _txRef,
          'amount': totalAmount,
          'currency': 'ETB',
          'email': 'user@example.com',  // Replace with actual user email
        }),
      );

      if (transactionResponse.statusCode == 201) {
        setState(() {
          _isLoading = false; // Hide loading screen
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order confirmed with Cash on Delivery')),
        );

        // Navigate to OrdersPage after the order is confirmed
        widget.cartItems.clear();
        Navigator.of(context).pop(); // Pop CheckoutPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OrdersPage()),
        );
      } else {
        throw Exception('Transaction saving failed');
      }
    } else {
      // Handle Mobile Banking payment flow (as before)
      final paymentResponse = await http.post(
        Uri.parse('https://e6e4-196-189-16-22.ngrok-free.app/api/transaction/createPayment'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          'tx_ref': _txRef,
          'amount': totalAmount.toString(),
          'currency': 'ETB',
          'email': 'user@example.com',
        }),
      );

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
          Uri.parse(
              'https://food-delivery-backend-uls4.onrender.com/api/transaction/checkpayment?tx_ref=$txRef'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${await _storage.read(key: 'token')}",
          },
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['data']['status'] == 'success') {
            setState(() {
              _isLoading = false; // Hide loading screen
              widget.cartItems.clear(); // Clear the cart items
            });
            await _storage.delete(
                key: 'ongoing_tx_ref'); // Clear the transaction reference

            // Pop the current page (CheckoutPage)
            Navigator.of(context).pop();
            Navigator.of(context).pop();

            // Navigate to the Orders page using the widget instance
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => OrdersPage()));
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Waiting for payment confirmation...')),
        );

        await Future.delayed(
            Duration(seconds: 5)); // Wait for 5 seconds before checking again
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading screen on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking payment status')),
      );
    }
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CheckoutPage({required this.cartItems});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentMethod = 'Cash on Delivery'; // Default payment method
  final FlutterSecureStorage _storage =
      FlutterSecureStorage(); // Initialize _storage
  final Uuid _uuid = Uuid(); // Initialize UUID generator

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
    String? token = await _storage.read(key: 'token'); // Retrieve the token

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final String txRef = _uuid.v4(); // Generate a unique transaction reference
    final totalAmount = _calculateTotal();

 
    // Step 1: Loop through each cart item and send a request to save the order
    for (var item in widget.cartItems) {
         print("sss3" + item.toString());
      final response = await http.post(
        Uri.parse(
            'https://3362-196-189-19-218.ngrok-free.app/user/createOrder'), // Update with your API endpoint
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // Include the token in the headers
        },
        body: jsonEncode({
          'tx_ref': txRef, // Send the generated tx_ref
          'menuId': item['id'], // Pass the menu ID
          'restaurantId': item['restaurantId'], // Pass the restaurant ID
          'quantity': item['quantity'], // Pass the quantity
        }),
      );
      print("dsds");
      if (response.statusCode != 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order saving failed for an item')),
        );
        return;
      }
    }

    if (_selectedPaymentMethod == 'Mobile Banking') {
      // Step 2: Make a payment request with the same tx_ref
      final paymentResponse = await http.post(
        Uri.parse(
            'https://3362-196-189-19-218.ngrok-free.app/api/transaction/createPayment'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // Include the token in the headers
        },
        body: jsonEncode({
          'tx_ref': txRef, // Send the same tx_ref
          'amount': totalAmount.toString(), // Convert amount to string
          'currency': 'ETB',
          'email': 'abebe@bikila.com', // Replace with actual user email
        }),
      );

      if (paymentResponse.statusCode == 200) {
        final responseBody = jsonDecode(paymentResponse.body);
        if (responseBody['status'] == 'success') {
          final paymentUrl = responseBody['data']['checkout_url'];
          if (await canLaunch(paymentUrl)) {
            await launch(paymentUrl); // Open the payment URL in a browser
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch payment URL')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment initiation failed')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiation failed')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order confirmed with $_selectedPaymentMethod'),
        ),
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
      body: Padding(
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
    );
  }
}

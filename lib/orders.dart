import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login.dart'; // Import the login page for logout
import 'orderdetilpage.dart'; // Import the order details page

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchUserOrders();
  }

  Future<void> _fetchUserOrders() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      _logout(); // Logout if no token is found
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://food-delivery-backend-uls4.onrender.com/user/getOrdersByUser'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

     

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        setState(() {
          _orders =
              responseBody.reversed.toList(); // Reverse the order of the list
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _logout(); // Logout if the token is invalid or expired
      } else if (response.statusCode == 404) {
        setState(() {
          _orders = []; // No orders found
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders')),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  // Method to logout and redirect to the login page
  Future<void> _logout() async {
    await _storage.delete(key: 'token'); // Delete the token from secure storage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => LoginPage()), // Navigate to login page
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Orders'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text('No recent orders found'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return ListTile(
                      title: Text('Order #${order['id']}'),
                      subtitle: Text(
                          'Total: ${order['totalPrice'].toStringAsFixed(2)} ETB'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailPage(order: order),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';

class OrderDetailPage extends StatefulWidget {
  final dynamic order;

  const OrderDetailPage({required this.order});

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  String _orderStatus = '';
  bool _isLoading = true;
  bool _showTrackingButton = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
    _startAutoRefresh(); // Start the auto-refresh
  }

  Future<void> _fetchOrderStatus() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse(
          'https://d3a6-196-189-24-165.ngrok-free.app/user/getOrdersById?Id=${widget.order['id']}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseBody = jsonDecode(response.body);

      if (responseBody.isNotEmpty) {
        final orderData = responseBody[0];
        setState(() {
          _orderStatus = orderData['status'];
          _isLoading = false;
          _showTrackingButton = _orderStatus == 'delivering';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order not found')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load order status')),
      );
    }
  }

  // Auto-refresh the order status every 10 seconds
  void _startAutoRefresh() {
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        _fetchOrderStatus();
      }
    });
  }

  Widget _buildOrderStatusStep(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Column(
            children: [
              isActive
                  ? Lottie.network(
                      'https://lottie.host/35d9f6a2-e420-4cbe-916d-3bde986d169c/DfMPlvXEam.json',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey,
                    ),
              Container(
                height: 50,
                width: 2,
                color: isActive ? Colors.blue : Colors.grey,
              ),
            ],
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isActive ? Colors.blue : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Status'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fastfood,
                    size: 100,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'INVOICE : ${widget.order['tx_ref']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  _buildOrderStatusStep(
                      'Order received awaiting restaurant confirmation',
                      _orderStatus == 'waiting for delivery' ||
                          _orderStatus == 'resturant confirmed' ||
                          _orderStatus == 'delivery man received' ||
                          _orderStatus == 'delivering'),
                  _buildOrderStatusStep(
                      'Assign delivery man',
                      _orderStatus == 'resturant confirmed' ||
                          _orderStatus == 'delivery man received' ||
                          _orderStatus == 'delivering'),
                  _buildOrderStatusStep(
                      'Order received by delivery man',
                      _orderStatus == 'delivery man received' ||
                          _orderStatus == 'delivering'),
                  _buildOrderStatusStep(
                      'Delivering', _orderStatus == 'delivering'),
                  if (_showTrackingButton)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle tracking button press
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text('TRACKING'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

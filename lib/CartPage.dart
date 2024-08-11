import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    String? token = await _storage.read(key: 'token');
    setState(() {
      _token = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Cart Page'),
          SizedBox(height: 20),
          _token != null
              ? Text('Token: $_token')
              : CircularProgressIndicator(),
        ],
      ),
    );
  }
}

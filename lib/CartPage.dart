import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'CheckoutPage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartPage({required this.cartItems});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  String? _token;
  String _currentAddress = 'Fetching current location...';
  double? _latitude;
  double? _longitude;
  final double serviceCharge = 39.20;
  final double deliveryFee = 55.00;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetCurrentLocation();
    _loadToken();
  }

  Future<void> _loadToken() async {
    String? token = await _storage.read(key: 'token');
    setState(() {
      _token = token;
    });
  }

  Future<void> _checkPermissionsAndGetCurrentLocation() async {
    if (await _handleLocationPermission()) {
      _getCurrentLocation();
    }
  }

  Future<bool> _handleLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.locationWhenInUse.request();
      return result.isGranted;
    }
    return false;
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Get the address from the coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      Placemark place = placemarks[0];
      _currentAddress = "${place.locality}, ${place.subAdministrativeArea}, ${place.country}";
    });
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (var item in widget.cartItems) {
      double price = (item['price'] ?? 0.0) as double;
      int quantity = (item['quantity'] ?? 1) as int;
      subtotal += price * quantity;
    }
    return subtotal;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + serviceCharge + deliveryFee;
  }

  void _removeItem(int index) {
    setState(() {
      widget.cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        widget.cartItems[index]['quantity'] = newQuantity;
      } else {
        _removeItem(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = _calculateSubtotal();
    double total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: widget.cartItems.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      double price = (item['price'] ?? 0.0) as double;
                      int quantity = (item['quantity'] ?? 1) as int;
                      double itemTotal = price * quantity;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Image.network(
                            item['imageUrl'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(item['foodName'] ?? 'Unnamed Item'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$quantity X ${price.toStringAsFixed(2)}'),
                              SizedBox(height: 4),
                              Text('${itemTotal.toStringAsFixed(2)} Br'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  _updateQuantity(index, quantity - 1);
                                },
                              ),
                              Text(quantity.toString()),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  _updateQuantity(index, quantity + 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Promo Code',
                      border: OutlineInputBorder(),
                      suffixIcon: ElevatedButton(
                        onPressed: () {
                          // Implement promo code logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                        ),
                        child: Text('Apply'),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Deliver To',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.location_on, color: Colors.orange),
                    title: Text('Current Location'),
                    subtitle: Text(_currentAddress),
                    trailing: ElevatedButton(
                      onPressed: _checkPermissionsAndGetCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text('Refresh'),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  _buildSummaryRow('Subtotal', subtotal),
                  _buildSummaryRow('Discount', 0.0),
                  _buildSummaryRow('Extras', 0.0),
                  _buildSummaryRow('Service Charge', serviceCharge),
                  _buildSummaryRow('Delivery Fee', deliveryFee),
                  SizedBox(height: 20),
                  Divider(),
                  _buildSummaryRow('Total Amount', total, isTotal: true),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_latitude != null && _longitude != null) {
                          // Navigate to CheckoutPage with the current location data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutPage(
                                cartItems: widget.cartItems,
                                address: _currentAddress,
                                latitude: _latitude!,
                                longitude: _longitude!,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unable to fetch location. Please try again.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF652023),
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: Text('Confirm Order'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.orange : Colors.black,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} Br',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.orange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

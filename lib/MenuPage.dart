import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'CartPage.dart';
import 'MenuItemDetailPage.dart';
import 'login.dart'; // Import the login page for logout

class MenuPage extends StatefulWidget {
  final int restaurantId;
  final List<Map<String, dynamic>> cartItems;
  final String restaurantImageUrl;

  const MenuPage({
    required this.restaurantId,
    required this.cartItems,
    required this.restaurantImageUrl,
  });

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<dynamic> menuItems = [];
  Map<String, dynamic>? restaurantDetails;
  bool isLoading = true;
  bool noMenuAvailable = false;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchMenuByRestaurantId();
  }

  Future<void> fetchMenuByRestaurantId() async {
    final url = Uri.parse(
        'https://food-delivery-backend-uls4.onrender.com/restaurant/menus?restaurantId=${widget.restaurantId}');
    try {
      String? token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          menuItems = data;
          if (menuItems.isNotEmpty) {
            restaurantDetails = menuItems.first['restaurant'];
          }
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        final body = jsonDecode(response.body);
        if (body['message'] == "No menus found for this restaurant") {
          setState(() {
            noMenuAvailable = true;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load menu')),
          );
        }
      } else if (response.statusCode == 401) {
        _logout(); // If the token is expired or invalid, log out the user
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load menu')),
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
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

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: widget.cartItems, // Use the cartItems from HomePage
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF652023),
        title: Text(restaurantDetails?['name'] ?? 'Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: _openCart,
            color: Colors.white,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : noMenuAvailable
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 80),
                      SizedBox(height: 16),
                      Text(
                        'Restaurant Coming Soon',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check back later for updates!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Display the restaurant image at the top in landscape mode
                    Image.network(
                      widget.restaurantImageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/4.png', height: 200, fit: BoxFit.cover); // Fallback image
                      },
                    ),
                    if (restaurantDetails != null)
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: widget.restaurantImageUrl.startsWith('http')
                                      ? NetworkImage(widget.restaurantImageUrl)
                                      : const AssetImage('assets/4.png') as ImageProvider,
                                  radius: 30,
                                ),
                                SizedBox(width: 16.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurantDetails!['name'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      restaurantDetails!['streetName'],
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      'Open now', // Replace with actual status if available
                                      style: TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoColumn(Icons.star, 'Rating', '0.0'),
                                _buildInfoColumn(Icons.access_time, 'Working Hours', '10:00 - 22:30'),
                                _buildInfoColumn(Icons.delivery_dining, 'Delivery Time', '45 min'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Divider(height: 1, color: Colors.grey[300]),
                    Expanded(
                      child: ListView.builder(
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final menuItem = menuItems[index];
                          String imageUrl = menuItem['imagefile'];
                          double price = (menuItem['price'] as num).toDouble(); // Convert price to double

                          // Fallback if image URL is null or invalid
                          if (imageUrl == null || imageUrl == 'undefined') {
                            imageUrl = 'assets/4.png'; // Local placeholder image
                          }

                          return Card(
                            margin: EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: imageUrl.startsWith('http')
                                  ? Image.network(
                                      imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset('assets/4.png', width: 50, height: 50); // Fallback image
                                      },
                                    )
                                  : Image.asset(
                                      imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                              title: Text(menuItem['foodName']),
                              subtitle: Text(
                                '${restaurantDetails!['name']} | ${menuItem['fasting'] ? 'Fasting Food' : 'Non-Fasting Food'}',
                              ),
                              trailing: Text('\$${price.toStringAsFixed(2)}'), // Display the price
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MenuItemDetailPage(
                                      menuItem: menuItem,
                                      restaurantDetails: restaurantDetails!,
                                      cartItems: widget.cartItems,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        SizedBox(height: 4.0),
        Text(
          title,
          style: TextStyle(color: Colors.grey),
        ),
        Text(
          subtitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

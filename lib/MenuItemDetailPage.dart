import 'package:flutter/material.dart';

class MenuItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> menuItem;
  final Map<String, dynamic> restaurantDetails;
  final List<Map<String, dynamic>> cartItems;

  const MenuItemDetailPage({
    required this.menuItem,
    required this.restaurantDetails,
    required this.cartItems,
  });

  @override
  _MenuItemDetailPageState createState() => _MenuItemDetailPageState();
}

class _MenuItemDetailPageState extends State<MenuItemDetailPage> {
  int quantity = 1;

  void _incrementQuantity() {
    setState(() {
      quantity += 1;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (quantity > 1) {
        quantity -= 1;
      }
    });
  }

  void _addToCart() {
    setState(() {
      final existingItemIndex = widget.cartItems
          .indexWhere((item) => item['id'] == widget.menuItem['id']);
      if (existingItemIndex >= 0) {
        widget.cartItems[existingItemIndex]['quantity'] += quantity;
      } else {
      

        widget.cartItems.add({
          'id': widget.menuItem['id'],
          'foodName': widget.menuItem['foodName'] ?? 'Unnamed Item',
          'imageUrl': widget.menuItem['imagefile'] ?? 'assets/default-food.png',
          'quantity': quantity,
          'price': (widget.menuItem['price'] as num)
              .toDouble(), // Ensure price is passed
          'restaurantId':
              widget.menuItem['restaurantId'], // Add restaurantId here
        });
      }
    });

    Navigator.pop(context, widget.cartItems); // Pass the updated cartItems back
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        widget.menuItem['imagefile'] ?? 'assets/default-food.png';
    final String foodName = widget.menuItem['foodName'] ?? 'Unnamed Item';
    final String description =
        widget.menuItem['description'] ?? 'No description available';
    final double price = (widget.menuItem['price'] as num)
        .toDouble(); // Get the price from the menuItem

    return Scaffold(
      appBar: AppBar(
        title: Text(foodName),
        backgroundColor: const Color(0xFF652023),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image or fallback to a default image
            Image.network(imageUrl, errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/default-food.png'); // Fallback image
            }),
            SizedBox(height: 16),
            Text(
              '\$${price.toStringAsFixed(2)}', // Display the price
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF652023),
              ),
            ),
            SizedBox(height: 16),
            Text(
              description, // Display the description
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _decrementQuantity,
                  icon: Icon(Icons.remove),
                ),
                Text(quantity.toString()),
                IconButton(
                  onPressed: _incrementQuantity,
                  icon: Icon(Icons.add),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addToCart,
              child: Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}

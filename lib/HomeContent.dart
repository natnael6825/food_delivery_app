import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_screen.dart';
import 'MenuPage.dart'; // Import the MenuPage

class HomeContent extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems; // Add cartItems as a parameter

  const HomeContent({required this.cartItems});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<dynamic> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
    final url = Uri.parse('https://3362-196-189-19-218.ngrok-free.app/restaurant/restaurants'); // Replace with your API URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          restaurants = data;
          isLoading = false;
        });
      } else {
        // Handle errors
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load restaurants')),
        );
      }
    } catch (error) {
      // Handle errors
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF652023),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add_location),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: const Color(0xFF652023),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Special Orders',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Container(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: restaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = restaurants[index];
                              final imageUrl = 'https://3362-196-189-19-218.ngrok-free.app${restaurant['image']}'; // Construct full image URL
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MenuPage(
                                        restaurantId: restaurant['id'],
                                        cartItems: widget.cartItems,
                                      ),
                                    ),
                                  );
                                },
                                child: SpecialOrderCard(
                                  imagePath: imageUrl,
                                  title: restaurant['name'],
                                ),
                              );
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextButton(
                              onPressed: () {
                                // View all logic
                              },
                              child: Text(
                                'View All',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Top Restaurant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF652023),
                        ),
                      ),
                    ),
                  ),
                  GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,  // Number of columns in the grid
                      crossAxisSpacing: 10.0,  // Spacing between columns
                      mainAxisSpacing: 10.0,  // Spacing between rows
                      childAspectRatio: 1.0,  // Aspect ratio of the items (width/height)
                    ),
                    shrinkWrap: true,  // Makes the GridView only take as much space as its content needs
                    physics: NeverScrollableScrollPhysics(), // Disables the GridView's own scrolling
                    padding: const EdgeInsets.all(16.0),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      final imageUrl = 'https://3362-196-189-19-218.ngrok-free.app${restaurant['image']}'; // Construct full image URL
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuPage(
                                restaurantId: restaurant['id'],
                                cartItems: widget.cartItems,
                              ),
                            ),
                          );
                        },
                        child: TopRestaurantCard(
                          imagePath: imageUrl,
                          title: restaurant['name'],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class SpecialOrderCard extends StatelessWidget {
  final String imagePath;
  final String title;

  const SpecialOrderCard({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Image.network(
              imagePath,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/burger.png', height: 120, fit: BoxFit.cover);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF652023),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopRestaurantCard extends StatelessWidget {
  final String imagePath;
  final String title;

  const TopRestaurantCard({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF652023),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imagePath,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/burger.png', height: 100, fit: BoxFit.cover);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

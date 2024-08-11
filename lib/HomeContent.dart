import 'package:flutter/material.dart';
import 'map_screen.dart';

class HomeContent extends StatelessWidget {
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
      body: SingleChildScrollView(
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
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SpecialOrderCard(imagePath: 'assets/burger.png', title: 'Order 1'),
                        SpecialOrderCard(imagePath: 'assets/burger.png', title: 'Restaurant 2'),
                        SpecialOrderCard(imagePath: 'assets/burger.png', title: 'Restaurant 3'),
                        SpecialOrderCard(imagePath: 'assets/burger.png', title: 'Restaurant 4'),
                      ],
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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                TopRestaurantCard(imagePath: 'assets/burger.png', title: 'Name of restaurant'),
                TopRestaurantCard(imagePath: 'assets/burger.png', title: 'Name of restaurant'),
                TopRestaurantCard(imagePath: 'assets/burger.png', title: 'Name of restaurant'),
                TopRestaurantCard(imagePath: 'assets/burger.png', title: 'Name of restaurant'),
              ],
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
            Image.asset(
              imagePath,
              height: 120,
              fit: BoxFit.cover,
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
            Image.asset(
              imagePath,
              height: 100,
              fit: BoxFit.cover,
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

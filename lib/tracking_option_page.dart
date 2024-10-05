import 'package:flutter/material.dart';
import 'package:food_delivery_app/HomeContent.dart';

import 'orderdetilpage.dart';
import 'video_streaming_view_page.dart';

class TrackingOptionPage extends StatelessWidget {
  final String orderId; // The Order ID for identifying the order

  TrackingOptionPage({required this.orderId});
  
  get cartItems => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Tracking Option - Order: $orderId"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the map tracking page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeContent(cartItems: cartItems) // Assuming this is your map page
                  ),
                );
              },
              child: Text('Track on Map'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the video streaming page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoStreamingPage(orderId: orderId),
                  ),
                );
              },
              child: Text('Watch Live Video'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'delivery_tracking_page.dart'; // Import the DeliveryTrackingPage
import 'video_streaming_view_page.dart';

class TrackingOptionPage extends StatelessWidget {
  final String orderId; // The Order ID for identifying the order

  TrackingOptionPage({required this.orderId});

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
                // Navigate to the DeliveryTrackingPage to track the delivery agent's location
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryTrackingPage(orderId: orderId),
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

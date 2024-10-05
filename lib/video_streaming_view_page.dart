import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';  // Import url_launcher package

class VideoStreamingPage extends StatefulWidget {
  final String orderId; // The Order ID to identify the stream

  VideoStreamingPage({required this.orderId});

  @override
  _VideoStreamingPageState createState() => _VideoStreamingPageState();
}

class _VideoStreamingPageState extends State<VideoStreamingPage> {
  @override
  void initState() {
    super.initState();
    _launchStreamerPage();
  }

  // Function to launch the streamer page using the `url_launcher`
  Future<void> _launchStreamerPage() async {
    final String url = 'https://streamerpage.onrender.com/index.html?orderId=${widget.orderId}';
    
    // Check if the URL can be launched, and launch it
    if (await canLaunch(url)) {
      await launch(url);  // Open the URL in the default browser
    } else {
      throw 'Could not launch $url';  // Throw an error if the URL can't be launched
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Video Streaming - Order: ${widget.orderId}"),
      ),
      body: Center(
        child: Text('Opening live stream...'),  // Placeholder text while the URL opens
      ),
    );
  }
}

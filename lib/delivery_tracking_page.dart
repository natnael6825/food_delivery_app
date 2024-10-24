// Dart and Flutter imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For Google Maps
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final String orderId; // The Order ID for identifying the order

  const DeliveryTrackingPage({required this.orderId});

  @override
  _DeliveryTrackingPageState createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  Timer? _timer;
  LatLng? _deliveryAgentLocation; // Latitude and Longitude of the delivery agent
  GoogleMapController? _mapController; // Google Maps controller for managing the map view
  bool _isLoading = true;
  String? _deliveryAgentId;

  @override
  void initState() {
    super.initState();
    _getDeliveryAgentIdAndStartTracking();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when the page is closed
    super.dispose();
  }

  // Step 1: Get the delivery agent ID using the order ID
  Future<void> _getDeliveryAgentIdAndStartTracking() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      // Handle token error here, maybe log out the user
      return;
    }

    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/deliveryAgent/getDeliveryAgentByOrderId?orderId=${widget.orderId}');
    try {
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _deliveryAgentId = data['deliveryAgentId']?.toString(); // Safely convert to string
        });
        _fetchDeliveryAgentLocation(); // Start fetching the location
        _startLocationUpdates(); // Start updating location every 15 seconds
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to retrieve delivery agent ID')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // Step 2: Fetch the delivery agent's location using the deliveryAgentId
  Future<void> _fetchDeliveryAgentLocation() async {
    String? token = await _storage.read(key: 'token');
    if (_deliveryAgentId == null) {
      return;
    }

    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/deliveryAgent/fetchLocation?deliveryAgentId=${_deliveryAgentId}');
    try {
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safely extract and parse latitude and longitude as doubles
        final latitude = data['location']['latitude']?.toDouble();
        final longitude = data['location']['longitude']?.toDouble();

        // Check for null values and update the state
        if (latitude != null && longitude != null) {
          setState(() {
            _deliveryAgentLocation = LatLng(latitude, longitude);
            _isLoading = false;
          });

          // Move the camera to the new location
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(_deliveryAgentLocation!),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid location data received')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch delivery agent location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // Step 3: Start updating the location every 15 seconds
  void _startLocationUpdates() {
    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      _fetchDeliveryAgentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Delivery Agent'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _deliveryAgentLocation == null
              ? Center(child: Text('Unable to fetch delivery agent location'))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _deliveryAgentLocation!,
                    zoom: 15.0,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('deliveryAgent'),
                      position: _deliveryAgentLocation!,
                      infoWindow: InfoWindow(title: 'Delivery Agent'),
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
    );
  }
}

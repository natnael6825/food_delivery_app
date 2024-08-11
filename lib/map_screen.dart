import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home.dart'; // Ensure this import is correct

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  late GoogleMapController _mapController;
  LatLng _initialPosition = LatLng(37.7749, -122.4194); // Default to San Francisco
  Marker? _currentLocationMarker;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetCurrentLocation();
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
    LatLng currentLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _initialPosition = currentLocation;
      _selectedLocation = currentLocation; // Set current location as selected location
      _currentLocationMarker = Marker(
        markerId: MarkerId('current-location'),
        position: currentLocation,
        infoWindow: InfoWindow(title: 'Current Location'),
      );
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation, 19),
    );
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _currentLocationMarker = Marker(
        markerId: MarkerId('selected-location'),
        position: location,
        infoWindow: InfoWindow(title: 'Selected Location'),
      );
    });
    print('Selected Location: ${location.latitude}, ${location.longitude}');
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      print('Confirmed Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
    } else {
      print('No location selected');
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: Text(
              'Confirm',
              style: TextStyle(color: Color(0xFF652023)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14,),
              mapType: MapType.hybrid, // To view the satellite map
            
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _checkPermissionsAndGetCurrentLocation(); // Check permissions and get current location when map is created
            },
            onTap: _onMapTapped,
            markers: _currentLocationMarker != null
                ? {
                    _currentLocationMarker!,
                    if (_selectedLocation != null)
                      Marker(
                        markerId: MarkerId('selected-location'),
                        position: _selectedLocation!,
                        infoWindow: InfoWindow(title: 'Selected Location'),
                      ),
                  }
                : {},
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: Icon(Icons.my_location),
              backgroundColor: const Color(0xFF652023),
            ),
          ),
        ],
      ),
    );
  }
}

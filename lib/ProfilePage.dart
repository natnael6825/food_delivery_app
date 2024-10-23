import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'login.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _selectedImage;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      _logout(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String apiUrl =
        'https://food-delivery-backend-uls4.onrender.com/user/profile'; // Replace with actual API URL
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("--------------------" + response.body); // Debugging response

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        // Debugging fields
        print('Full Name: ${userData['fullName']}');
        print('Phone: ${userData['phone']}');
        print('Profile Image URL: ${userData['image']}');

        setState(() {
          _fullNameController.text = userData['fullName'] ?? 'No name provided';
          _phoneController.text = userData['phone'] ?? 'No phone provided';
          _profileImageUrl = userData['image'] ?? '';
          _isLoading = false;
        });
      } else {
        print('Failed to load profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile.')),
        );
        _logout(context);
      }
    } catch (e) {
      print('Error loading profile: $e'); // Debugging error
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile.')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  Future<void> _updateProfile() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      _logout(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String apiUrl =
        'https://food-delivery-backend-uls4.onrender.com/user/profileupdate'; // Replace with actual API URL
    var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['fullName'] = _fullNameController.text;
    request.fields['phone'] = _phoneController.text;

    if (_selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagefile', _selectedImage!.path),
      );
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _selectedImage = null; // Clear the selected image after update
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        _loadUserProfile(); // Reload user profile after update
      } else {
        print('Failed to update profile: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e'); // Debugging error
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while updating the profile.')),
      );
    }
  }

  Future<void> _selectImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              ElevatedButton(
                onPressed: _selectImage,
                child: Text('Select Profile Picture'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateProfile();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center content vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center content horizontally
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : _profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty &&
                                  Uri.tryParse(_profileImageUrl!) != null
                              ? NetworkImage(_profileImageUrl!)
                              : AssetImage('assets/4.png') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _selectImage,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  _fullNameController.text.isNotEmpty
                      ? _fullNameController.text
                      : 'No name provided',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _phoneController.text.isNotEmpty
                      ? _phoneController.text
                      : 'Phone not provided',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 30), // Spacing between the text and the button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          Size(double.infinity, 50), // Full-width button
                      backgroundColor: Color(0xFF652023),
                    ),
                    child: Text('Logout'),
                  ),
                ),
              ],
            ),
    );
  }
}

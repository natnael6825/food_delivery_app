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
  final TextEditingController _emailController = TextEditingController();

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
      _logout(context); // Logout if token is null
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String apiUrl = 'https://food-delivery-backend-uls4.onrender.com/user/profile';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send the token in the header
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        setState(() {
          _fullNameController.text = userData['fullName'] ?? 'No name provided';
          _phoneController.text = userData['phone'] ?? 'No phone provided';
          _emailController.text = userData['email'] ?? 'No email provided';
          _profileImageUrl = userData['image'] ?? '';
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _logout(context); // Logout if token is invalid or expired
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile.')),
        );
        _logout(context); // Logout on other errors as well
      }
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
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

    String apiUrl = 'https://food-delivery-backend-uls4.onrender.com/user/profileupdate';
    var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));
    request.headers['Authorization'] = 'Bearer $token'; // Send the token in the header

    print('Updating profile...');
    print('Full Name: ${_fullNameController.text}');
    print('Phone: ${_phoneController.text}');
  
    request.fields['fullName'] = _fullNameController.text;
    request.fields['phone'] = _phoneController.text;

    // Add the selected image to the request if it exists
    if (_selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagefile', _selectedImage!.path),
      );
      print('Image added to request.');
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _selectedImage = null; // Clear the selected image after update
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        _loadUserProfile(); // Reload the profile after updating
      } else if (response.statusCode == 401) {
        _logout(context); // Logout if token is invalid or expired
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while updating the profile.')),
      );
    }
  }

  Future<void> _selectImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'token'); // Delete the token from storage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to login page
      (route) => false, // Remove all previous routes
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
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
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      enabled: false, // Email should not be editable
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _selectImage,
                      child: Text('Select Profile Picture'),
                    ),
                  ],
                ),
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
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 40),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                              : AssetImage('assets/default_profile.png') as ImageProvider,
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.redAccent,
                    ),
                    child: Text('Logout'),
                  ),
                ),
              ],
            ),
    );
  }
}

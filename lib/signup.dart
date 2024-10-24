import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+251');
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  File? _selectedImage;
  bool _isVerificationStep = false;
  String? _verificationCode;
  Timer? _timer;
  int _remainingTime = 600; // 10 minutes in seconds

  // Function to pick an image from gallery
  Future<void> _selectImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Email validation using regex
  bool _isEmailValid(String email) {
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Phone number validation for +251 or 09 formats
  bool _isPhoneNumberValid(String phoneNumber) {
    final RegExp phoneRegex = RegExp(r'^(\+2519\d{8}|09\d{8})$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  // Function to initiate signup and check validations
  void _initiateSignup() {
    final String email = _emailController.text.trim();
    final String username = _usernameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (!_isEmailValid(email)) {
      _showErrorMessage('Invalid email format');
      return;
    }

    if (!_isPhoneNumberValid(phone)) {
      _showErrorMessage('Invalid phone number. Use +2519XXXXXXXX or 09XXXXXXXX format.');
      return;
    }

    if (password.length < 8) {
      _showErrorMessage('Password should be at least 8 characters long.');
      return;
    }

    if (password != confirmPassword) {
      _showErrorMessage('Passwords do not match.');
      return;
    }

    setState(() {
      _isVerificationStep = true;
    });
    _requestVerificationCode(); // Initiate verification code sending after validation
  }

  // Function to request verification code
  Future<void> _requestVerificationCode() async {
    final String email = _emailController.text.trim();
    String url = 'https://food-delivery-backend-uls4.onrender.com/user/generateVerificationCode';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _verificationCode = data['code']; // Store the verification code
        });

        // Start the countdown for 10 minutes
        _startTimer();
      } else {
        _showErrorMessage('Failed to send verification code.');
      }
    } catch (e) {
      _showErrorMessage('An error occurred while requesting verification code.');
    }
  }

  // Start a timer for 10 minutes (600 seconds)
  void _startTimer() {
    _timer?.cancel();
    _remainingTime = 600;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        _showErrorMessage('Verification time expired.');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      }
    });
  }

  // Function to handle signup after successful verification
  Future<void> _completeSignup() async {
    String enteredCode = _verificationCodeController.text.trim();

    if (enteredCode == _verificationCode) {
      _showSuccessMessage('Verification successful, signing you up...');

      String url = 'https://food-delivery-backend-uls4.onrender.com/user/signup';
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['fullName'] = _usernameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['password'] = _passwordController.text.trim();

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('imagefile', _selectedImage!.path));
      }

      try {
        var response = await request.send();
        if (response.statusCode == 201) {
          _showSuccessMessage('Signup successful.');
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        } else {
          _showErrorMessage('Signup failed.');
        }
      } catch (e) {
        _showErrorMessage('An error occurred during signup.');
      }
    } else {
      _showErrorMessage('Invalid verification code.');
    }
  }

  // Utility function to show error messages
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Utility function to show success messages
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isVerificationStep ? _buildVerificationSection() : _buildSignupSection(),
        ),
      ),
    );
  }

  // Build the sign-up form section
  Widget _buildSignupSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        GestureDetector(
          onTap: _selectImage,
          child: CircleAvatar(
            radius: 45,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : AssetImage('assets/4.png') as ImageProvider,
            child: Icon(
              Icons.camera_alt,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _initiateSignup,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF652023)),
          child: const Text('Sign up'),
        ),
      ],
    );
  }

  // Build the verification section
  Widget _buildVerificationSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Please check your email: ${_emailController.text}"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _requestVerificationCode,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF652023)),
          child: const Text('Get Verification Code'),
        ),
        const SizedBox(height: 20),
        if (_verificationCode != null) ...[
          TextField(
            controller: _verificationCodeController,
            decoration: InputDecoration(labelText: 'Enter Verification Code', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _completeSignup,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF652023)),
            child: const Text('Complete Signup'),
          ),
        ],
        const SizedBox(height: 20),
        Text('Time remaining: ${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}'),
      ],
    );
  }
}

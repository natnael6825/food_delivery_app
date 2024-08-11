import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';

class ProfilePage extends StatelessWidget {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false, // Removes all the previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            color: Color(0xFF652023),
            onPressed: () {
              // Add edit profile functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          CircleAvatar(
            radius: 45,
            backgroundImage: AssetImage('assets/4.png'), // Replace with the actual avatar image path
          ),
          SizedBox(height: 10),
          Text(
            'Yamlak',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '+251946270789',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildProfileOption(
                  icon: Icons.location_on,
                  title: 'Delivery Address',
                  onTap: () {
                    // Navigate to delivery address page
                  },
                ),
                _buildProfileOption(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: Text('English', style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    // Navigate to language settings page
                  },
                ),
                _buildProfileOption(
                  icon: Icons.card_giftcard,
                  title: 'Coupon',
                  onTap: () {
                    // Navigate to coupon page
                  },
                ),
                _buildProfileOption(
                  icon: Icons.account_balance_wallet,
                  title: 'Wallet',
                  onTap: () {
                    // Navigate to wallet page
                  },
                ),
                _buildProfileOption(
                  icon: Icons.people,
                  title: 'Referral',
                  onTap: () {
                    // Navigate to referral page
                  },
                ),
                _buildProfileOption(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    // Navigate to help & support page
                  },
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF652023),
                    ),
                    child: Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, Widget? trailing, required Function() onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

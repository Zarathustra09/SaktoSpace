import 'package:flutter/material.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // Profile Picture and Name
          Center(
            child: Column(
              children: [
                // Placeholder for profile image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'John Doe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'johndoe@example.com',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Account Options
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              // Navigate to edit profile screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Shipping Address'),
            onTap: () {
              // Navigate to shipping address screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Payment Methods'),
            onTap: () {
              // Navigate to payment methods screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Order History'),
            onTap: () {
              // Navigate to order history screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Handle logout functionality
            },
          ),
        ],
      ),
    );
  }
}

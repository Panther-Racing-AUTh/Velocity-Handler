import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              "John Doe",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              "johndoe@example.com",
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'), // Add your image
              radius: 40,
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero, // Remove default padding for a better look
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  title: "Home",
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    // Navigate to the home screen
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.change_circle,
                  title: "RPM Ranges",
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to the settings screen
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.check_circle,
                  title: "Test",
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to the settings screen
                  },
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            height: 1,
            color: Colors.grey[300],
          ),
          // Sync Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Your sync logic here
                print("Syncing...");
              },
              icon: Icon(Icons.sync, color: Colors.white),
              label: Text(
                "Sync Data",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
              ),
            ),
          ),
          // Divider
          Divider(
            thickness: 1,
            height: 1,
            color: Colors.grey[300],
          ),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: "Logout",
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                // Logout logic
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build Drawer items for better code organization
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color iconColor = Colors.black,
        Color textColor = Colors.black,
      }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Colors.grey.withOpacity(0.2),
        leading: Icon(
          icon,
          size: 28,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DesktopAppMenu(),
    );
  }
}

class DesktopAppMenu extends StatefulWidget {
  @override
  _DesktopAppMenuState createState() => _DesktopAppMenuState();
}

class _DesktopAppMenuState extends State<DesktopAppMenu> {
  bool isMenuVisible = true; // Menu visibility toggle
  String selectedMenu = "Home"; // Selected menu item

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Collapsible Side Menu
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isMenuVisible ? 250 : 70,
            color: Colors.blueGrey[900],
            child: Column(
              children: [
                // App Logo or Header
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  color: Colors.blueGrey[800],
                  child: isMenuVisible
                      ? const Text(
                          "MyApp",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
                const Divider(color: Colors.white54),
                // Menu Items
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuItem(
                          icon: Icons.home,
                          title: "Home",
                          isSelected: selectedMenu == "Home",
                          onTap: () {
                            setState(() {
                              selectedMenu = "Home";
                            });
                          }),
                      _buildMenuItem(
                          icon: Icons.settings,
                          title: "Settings",
                          isSelected: selectedMenu == "Settings",
                          onTap: () {
                            setState(() {
                              selectedMenu = "Settings";
                            });
                          }),
                      _buildMenuItem(
                          icon: Icons.info,
                          title: "About",
                          isSelected: selectedMenu == "About",
                          onTap: () {
                            setState(() {
                              selectedMenu = "About";
                            });
                          }),
                    ],
                  ),
                ),
                // Collapse/Expand Button
                IconButton(
                  icon: Icon(
                    isMenuVisible ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isMenuVisible = !isMenuVisible;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Selected Menu: $selectedMenu",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Menu Item Widget
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white54,
      ),
      title: isMenuVisible
          ? Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
              ),
            )
          : null,
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.blueGrey[700],
      hoverColor: Colors.blueGrey[800],
    );
  }


}

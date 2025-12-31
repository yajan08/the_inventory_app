import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for admin check
import 'package:the_inventory_app/pages/global_logs_page.dart';
import 'package:the_inventory_app/pages/home_page.dart';
import 'package:the_inventory_app/pages/user_ban_page.dart'; // Required to navigate to ban page
import 'package:the_inventory_app/services/auth_service.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // List of pages to display
  final List<Widget> _pages = [
    const HomePage(),
    const GlobalLogsPage(),
  ];

  final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Admin Check Logic
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user?.email == 'person1@gmail.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          "Param's Inventory", 
          style: TextStyle(color: Color(0xFFe9f5ff), fontWeight: FontWeight.bold)
        ),
        backgroundColor: const Color(0xFF124d95),
        centerTitle: true,
        // The icon for the drawer will appear automatically if drawer is not null
        iconTheme: const IconThemeData(color: Color(0xFFe9f5ff)), 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () {
                authService.signOut();
              },
              child: const Icon(
                Icons.logout_outlined,
                color: Color(0xFFe9f5ff),
              ),
            ),
          )
        ],
      ),

      // ADDED DRAWER HERE
      drawer: isAdmin ? Drawer(
        backgroundColor: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF124d95)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text(
                      "ADMIN PANEL", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text("Manage Banned Users", style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserBanPage()),
                );
              },
            ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context);
                authService.signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ) : null,

      body: _pages[_selectedIndex],

      bottomNavigationBar: CurvedNavigationBar(
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFFe9f5ff),
        color: const Color(0xFF124d95),
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.inventory, color: Color(0xFFe9f5ff)),
          Icon(Icons.assignment, color: Color(0xFFe9f5ff)),
        ],
      ),
    );
  }
}
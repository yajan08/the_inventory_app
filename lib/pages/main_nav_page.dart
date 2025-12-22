import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:the_inventory_app/pages/global_logs_page.dart';
import 'package:the_inventory_app/pages/home_page.dart';
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text("Param's Inventory", style: TextStyle(color: Color(0xFFe9f5ff))),
        backgroundColor: const Color(0xFF124d95),
        actions: [
          // ElevatedButton(onPressed: () { authService.signOut(); }, child: Icon(Icons.logout_outlined))
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () { authService.signOut(); },
              child: Icon(
                Icons.logout_outlined,
                color: Color(0xFFe9f5ff),
              ),
            ),
          )
        ],
      ),
      
      // The body shows the page based on the selected index
      body: _pages[_selectedIndex],

      bottomNavigationBar: CurvedNavigationBar(
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Color(0xFFe9f5ff),
        color: const Color(0xFF124d95), // 50% opacity
        animationDuration: Duration(milliseconds: 300),
        items: const [
          Icon(Icons.inventory, color: Color(0xFFe9f5ff)),
          Icon(Icons.assignment, color: Color(0xFFe9f5ff)),
        ],
      ),
    );
  }
}
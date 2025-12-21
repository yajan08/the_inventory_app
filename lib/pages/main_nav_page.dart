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
        title: const Text("The Inventory App", style: TextStyle(color: Color(0xFFe9f5ff))),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF124d95),
        selectedItemColor: const Color(0xFFe9f5ff),
        unselectedItemColor: const Color(0x80e9f5ff), // 50% opacity
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Logs"),
        ],
      ),
    );
  }
}
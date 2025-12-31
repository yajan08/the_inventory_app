import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_inventory_app/pages/login_page.dart';
import 'package:the_inventory_app/pages/main_nav_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showLoginPage = true;

  void switchPages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Check if user is logged in
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return LoginPage(onTap: switchPages);
        }

        final user = authSnapshot.data!;

        // 2. Real-time check against banned_users collection
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('banned_users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, banSnapshot) {
            if (banSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // 3. If banned, show the Access Denied UI
            if (banSnapshot.hasData && banSnapshot.data!.exists) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.block_flipped, size: 80, color: Colors.red),
                        const SizedBox(height: 20),
                        const Text(
                          "ACCESS DENIED",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Your inventory access has been revoked by an admin.",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text("Log Out"),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }

            // 4. Not banned, show app
            return const MainNavigationPage();
          },
        );
      },
    );
  }
}
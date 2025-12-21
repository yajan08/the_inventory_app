import 'package:flutter/material.dart';
import 'package:the_inventory_app/pages/login_page.dart';
import 'package:the_inventory_app/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {

  // initially show the login page
  bool showLoginPage = true;

  // swift between login and register pages
  void switchPages(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: switchPages,
      );
    } else {
      return RegisterPage(
        onTap: switchPages,
      );
    }
  }
}

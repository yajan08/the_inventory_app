
import 'package:flutter/material.dart';
import 'package:the_inventory_app/services/auth_service.dart';
import 'package:the_inventory_app/utilities/my_button.dart';
import 'package:the_inventory_app/utilities/my_textfield.dart';
// add my button 

// ignore: must_be_immutable
class LoginPage extends StatefulWidget {

  void Function()? onTap;

  LoginPage({
    super.key,
    required this.onTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  
  final authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // login method
  void login() async { // login
    // prepare data
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // attempt login 
    try {
      await authService.signInWithEmailPassword(email, password);
    }

    // catch errors
    catch (e) {
      if (mounted) {
        // show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid Login Credentials"),
          ),
        );
        // reset password field, let email field be as it is.
          _passwordController.text = "";
      }
    }
}

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Login Page')),
        backgroundColor: Color(0xFFe9f5ff),
      ),
      backgroundColor: Color(0xFFe9f5ff),
       body: Center(
         child: SingleChildScrollView(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 // app logo
                 Icon(
                   Icons.inventory,
                   size: 80,
                   color: Color(0xFF124d95),
                 ),
           
                 const SizedBox(height: 30),
                 // welcome or welcome back message
                 Text(
                   "Welcome Back !",
                    style: TextStyle(
                      color: Color(0xFF124d95),
                      fontSize: 20,
                    ),
                 ),
           
                 const SizedBox(height: 30),
           
                 // email text field
                 MyTextField(
                   hintText: "Email",
                   obscureText: false,
                   controller: _emailController,
                 ),
           
                 const SizedBox(height: 15),
           
                 // password text field
                 MyTextField(
                   hintText: "Password",
                   obscureText: true,
                   controller: _passwordController,
                 ),
           
                 const SizedBox(height: 15),
           
                 // login button
                 MyButton(
                   buttonText: "Login",
                   onTap: login, 
                 ),
           
                 const SizedBox(height: 15),
           
                 // register button if no account yet
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text(
                       "No account? ",
                       style: TextStyle(
                       color: Color(0xFF124d95),
                       ),
                     ),
                     GestureDetector(
                      onTap: widget.onTap,
                         child: Text(
                           "Register now! ",
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             decoration: TextDecoration.underline,
                             color: Color(0xFF124d95),
                           ),
                         ),
                     ),
                   ],
                 ),
           
               ],
             ),
           ),
       ),
    );
  }
}
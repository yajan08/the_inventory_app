
import 'package:flutter/material.dart';
import 'package:the_inventory_app/services/auth_service.dart';
import 'package:the_inventory_app/utilities/my_button.dart';
import 'package:the_inventory_app/utilities/my_textfield.dart';
import 'package:url_launcher/url_launcher.dart';
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
                 Image.asset('assets/paramLogo5.png', height: 120),
           
                 const SizedBox(height: 30),
                 // welcome or welcome back message
                 Text(
                   "Param's Inventory App",
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
                   keyboardType: TextInputType.emailAddress,
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
           
                 const SizedBox(height: 30),

          // Professional Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[400])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "Support",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[400])),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Styled Contact Section
          Column(
            children: [
              const Text(
                "Need a demo or an account?",
                style: TextStyle(
                  color: Color(0xFF3F4238), // Your dark text color
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final Uri emailUri = Uri.parse(
                    'mailto:yajanmehta@gmail.com?subject=Inventory App Request',
                  );
                  try {
                    // 1. Check if the device is capable of opening the URI
                    if (await canLaunchUrl(emailUri)) {
                      // 2. Try to launch the external mail app
                      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                    } else {
                      // If canLaunchUrl returns false (common on some Android versions/Simulators)
                      throw 'No email app found to handle this request.';
                    }
                  } catch (e) {
                    // 3. Handle errors gracefully by showing a Snackbar
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF124d95), // Matches your theme
                          content: Text(
                            "Could not open mail app. Please email: yajanmehta@gmail.com",
                            style: const TextStyle(color: Colors.white),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF124d95).withAlpha(30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, 
                        size: 18, color: Color(0xFF124d95)),
                      const SizedBox(width: 10),
                      const Text(
                        "yajanmehta@gmail.com",
                        style: TextStyle(
                          color: Color(0xFF124d95),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
               ],
             ),
           ),
       ),
    );
  }
}
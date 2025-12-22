import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_inventory_app/services/auth_service.dart';
import 'package:the_inventory_app/utilities/my_button.dart';
import 'package:the_inventory_app/utilities/my_textfield.dart';

// ignore: must_be_immutable
class RegisterPage extends StatefulWidget {

    void Function()? onTap;

    RegisterPage({
      super.key,
      required this.onTap,
    });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();

    final authService = AuthService();

    void register() async{// register code
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: Passwords do not match"),
          ),
        );
      return;
      }

    if (!email.contains('@') || email.endsWith("@")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Enter a valid email address"),
          ),
        );
      return;
    }

    if (password.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Password must be at least 6 characters long"),
            ),
          );  
        return;
      }

      // attempt sign up 
      try {
        await authService.signUpWithEmailPassword(email, password);
      }

      on FirebaseAuthException catch (e) {
        if (!mounted) return;

        String message = "Something went wrong";

        if (e.code == 'email-already-in-use') {
          message = "User already exists with this email";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );    
      }

    }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Register Page')),
        backgroundColor: Color(0xFFe9f5ff),
      ),
      backgroundColor: Color(0xFFe9f5ff),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // app logo
              Image.asset('assets/paramLogo3.png', height: 120),
        
              const SizedBox(height: 30),
              // welcome or welcome back message
              Text(
                "Welcome !",
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
                hintText: "Create Password",
                obscureText: true,
                controller: _passwordController,
              ),
        
              const SizedBox(height: 15),
        
              // confirm password text field
              MyTextField(
                hintText: "Confirm Password",
                obscureText: true,
                controller: _confirmPasswordController,
              ),
        
              const SizedBox(height: 15),
        
              // login button
              MyButton(
                buttonText: "Register",
                onTap: register,
              ),
        
              const SizedBox(height: 15),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Color(0xFF124d95),
                    ),
                  ),
                  GestureDetector(
                     onTap: widget.onTap,
                    child: Text(
                      "Login",
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

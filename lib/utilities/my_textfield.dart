
import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {

  late bool _isObscured; // local state to toggle visibility

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText; // initialize from widget
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: widget.controller,

        obscureText: _isObscured, // use local state
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.hintText,
          hintText: "Enter ${widget.hintText}...",
          hintStyle: TextStyle(
            color: Colors.blue.shade300,
          ),

          // eye icon ONLY when obscureText is true
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured; // toggle
                    });
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                BorderSide(color: Colors.blue.shade800),
          ),

          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.blue.shade300),
          ),
        ),
      ),
    );
  }
}
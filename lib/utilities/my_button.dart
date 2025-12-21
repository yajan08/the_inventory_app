import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {

  final String buttonText;
  final void Function()? onTap;

  const MyButton({
    super.key,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF124d95),
          borderRadius: BorderRadius.circular(20),
        ),
          padding: EdgeInsets.all(20.0),
          margin: EdgeInsets.symmetric(horizontal: 25.0),
          child: Center(
            child: Text(
                buttonText,
              style: TextStyle(
                color: Color(0xFFe9f5ff),
              ),
            ),
          ),
        ),
    );
  }
}

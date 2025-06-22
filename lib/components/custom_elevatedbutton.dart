import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final double minHeight;

  const CustomElevatedButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor = const Color(0xFF37474F), // blueGrey.shade700 approx
    this.foregroundColor = Colors.white,
    this.minHeight = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: Size.fromHeight(minHeight),
      ),
    );
  }
}

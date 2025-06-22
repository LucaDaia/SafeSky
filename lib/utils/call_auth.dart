import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallAuthorities {
  static BuildContext? get context => null;


  static void call() async {
  const emergencyNumber = '112'; // Replace with your custom number
  final Uri launchUri = Uri(scheme: 'tel', path: emergencyNumber);

  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Text('❌ Could not open the dialer.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}}


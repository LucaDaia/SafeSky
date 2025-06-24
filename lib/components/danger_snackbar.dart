import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

SnackBar buildDangerSnackBar({
  required BuildContext context,
  required LatLng zoneCenter,
  required VoidCallback onConfirm,
  required VoidCallback onDeny,
}) {
  return SnackBar(
    backgroundColor: Colors.red[800],
    duration: Duration(seconds: 8),
    content: Row(
      children: [
        Expanded(
          child: Text(
            '🚨 You have entered a danger zone!',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text('Confirm Danger'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
        TextButton(
          onPressed: onDeny,
          child: Text("Nothing's here"),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ],
    ),
  );
}

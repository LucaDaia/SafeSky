import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_sky/pages/map_activity.dart';
import 'package:safe_sky/pages/report_danger.dart';


//TODO: Authentication
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    routes: {
      '/' : (context) => MapActivity(),
      '/report' : (context) => ReportDanger(),
    },
  ));
}

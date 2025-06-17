import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_sky/pages/login_page.dart';
import 'package:safe_sky/pages/map_activity.dart';
import 'package:safe_sky/pages/register_page.dart';
import 'package:safe_sky/pages/report_danger.dart';


// TODO: app opening animation -> put the safesky logo
// maybe remove the pins and keep the circles
//chat activity
//change buttons colors from map activity
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/login',
    routes: {
      '/login' : (context) => LoginPage(),
      '/register' : (context) => RegisterPage(),
      '/map' : (context) => MapActivity(),
      '/report' : (context) => ReportDanger(),
    },
  ));
}
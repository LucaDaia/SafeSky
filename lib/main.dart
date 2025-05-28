import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_sky/pages/map_activity.dart';
import 'package:safe_sky/pages/report_danger.dart';

void main() => runApp(MaterialApp(
  routes: {
    '/' : (context) => MapActivity(),
    '/report' : (context) => ReportDanger(),
  },
));





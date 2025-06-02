import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_sky/utils/dark_map.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapActivity extends StatefulWidget {
  @override
  State<MapActivity> createState() => _MapActivityState();
}

class _MapActivityState extends State<MapActivity> {

  //firebase push notifications
  StreamSubscription? _reportsSubscription;

  //for zooming in on the location on activity start
  late GoogleMapController _mapController;
  LatLng? _currentPosition;

  //for markers and reports
  LatLng? _currentMarkedPosition;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool longPress = false;
  final String _pendingMarkerId = "pending_marker";

  //map costumization
  bool isDarkTheme = true;
  bool isDefault = true;
  MapType mapType = MapType.normal;

  //drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _startReportsListener();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }
  
  void _startReportsListener() {
    _reportsSubscription = FirebaseFirestore.instance
        .collection('dangerReports')
        .snapshots()
        .listen((snapshot) {
          Set<Marker> newMarkers = {};
          Set<Circle> newCircles = {};
          
          for(var doc in snapshot.docs) {
            var data = doc.data();
            var lat = data['position']['latitude'];
            var lng = data['position']['longitude'];
            var level = data['level'] ?? 'Unknown';
            var details = data['details'] ?? '';
            
            newMarkers.add(
              Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: 'Danger level: $level',
                    snippet: details,
                  ),

              ),
            );

            newCircles.add(
                Circle(
                    circleId: CircleId(doc.id),
                    radius: 50,
                    center: LatLng(lat, lng),
                    strokeColor: Colors.redAccent,
                    strokeWidth: 1,
                    fillColor: Colors.redAccent.withOpacity(0.2),
                ),
            );
          }

          setState(() {
            _markers = newMarkers;
            _circles = newCircles;
          });
    });
  }

  Future<void> _determinePosition() async {
    // Request permission
    await Permission.location.request();

    // Check permission status
    if (await Permission.location.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!, //  ! for promising its not a null value
            zoom: 16.0,
          ),
        ),
      );
    } else {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission not granted')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.setMapStyle(DarkMap.darkMapStyle);
  }
//  TODO: Complete drawer
  // TODO: Add a button click animation, at least for the report button
  // TODO: add a light theme
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleAvatar(),
            Text('SafeSky'),
            Text('Welcome to safeSky'),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 0, 80),
        child: FloatingActionButton.large(
          onPressed: () async {
            if (_currentMarkedPosition != null) {
              final result = await Navigator.pushNamed(
                context,
                '/report',
                arguments: {'reportedPosition': _currentMarkedPosition},
              );

              if (result == true) {
                setState(() {
                  _markers.removeWhere((m) => m.markerId.value == _pendingMarkerId);
                  _currentMarkedPosition = null;
                });
              }
            } else {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: "Must choose a location first!"),
              );
            }
          },
          child: Icon(Icons.report_gmailerrorred, color: Colors.white),
          backgroundColor: Colors.red[900],
          shape: CircleBorder(),
          elevation: 50,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(45.521563, -122.677433),
              zoom: 11.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapType: mapType,
            markers: _markers,
            circles: _circles,
            onLongPress: (LatLng pos) {
              Marker toReportMarker = Marker(
                markerId: MarkerId(_pendingMarkerId),
                position: pos,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Danger Zone at (${pos.latitude}, ${pos.longitude})'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              );

              setState(() {
                _markers.removeWhere((m) => m.markerId.value == _pendingMarkerId);
                _currentMarkedPosition = pos;
                _markers.add(toReportMarker);
              });

              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.info(message: 'Selected A Danger Zone!'),
              );
            },
          ),
          Positioned(
              top: 20,
              left: 20,
              child: FloatingActionButton.small(
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Icon(
                    Icons.menu,
                  ),
              ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isDarkTheme = !isDarkTheme;

                      _mapController.setMapStyle(
                        isDarkTheme ? DarkMap.darkMapStyle : null, // null resets to default
                      );
                    });
                  },
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text("Theme"),
                ),

                ElevatedButton.icon(
                  onPressed: () {

                    setState(() {
                      isDefault = !isDefault;
                      mapType = isDefault ? MapType.normal : MapType.satellite;
                    });
                  },
                  icon: Icon(Icons.map_outlined),
                  label: Text("Type"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    print("Center");
                    if (_currentPosition != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLng(_currentPosition!),
                      );
                    }
                  },
                  icon: Icon(Icons.chat_outlined),
                  label: Text("Chat"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

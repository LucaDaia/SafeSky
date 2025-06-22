import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_sky/components/custom_elevatedbutton.dart';
import 'package:safe_sky/utils/call_auth.dart';
import 'package:safe_sky/utils/dark_map.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_sky/services//auth_service.dart';

//TODO: Zoom In pe locatia raportata la revenirea in ecran

class MapActivity extends StatefulWidget {
  @override
  State<MapActivity> createState() => _MapActivityState();
}

class _MapActivityState extends State<MapActivity> {

  //firebase authentication instance
  String _displayName = 'User';
  AuthService _authService = new AuthService();

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

  //for warnings
  Circle? _lastWarnedZone;

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
    _loadUserInfo();
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

      for (var doc in snapshot.docs) {
        var data = doc.data();
        var lat = data['position']['latitude'];
        var lng = data['position']['longitude'];
        var level = data['level'] ?? 'Unknown';
        var details = data['details'] ?? '';
        var userReporting = data['user'] ?? 'Anonymous';

        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: 'Danger level: $level',
              snippet: 'Reported by $userReporting: \n $details',
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

      // 🔥 CHANGE: Check if current user location is inside any of the NEW zones
      if (_currentPosition != null) {
        for (var circle in newCircles) {
          double distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            circle.center.latitude,
            circle.center.longitude,
          );

          if (distance <= circle.radius) {
            if (_lastWarnedZone?.circleId != circle.circleId) {
              _lastWarnedZone = circle;
              _showDangerSnackbar(circle.center);
            }
            break;
          }
        }
      }
    });
  }


  Future<void> _determinePosition() async {
    await Permission.location.request();

    if (await Permission.location.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // 🔥 CHANGE: Listen for continuous location updates
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only update if moved > 10 meters
        ),
      ).listen((Position position) {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        _currentPosition = newPos; // 🔥 Save updated location
        _checkIfInsideRedZone(newPos); // 🔥 Check for proximity on move
      });

      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 16.0,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission not granted')),
      );
    }
  }

  void _loadUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _displayName =
          user?.displayName ?? user?.email ?? 'User'; // fallback if no displayName
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.setMapStyle(DarkMap.darkMapStyle);
  }

  void _checkIfInsideRedZone(LatLng userLocation) {
    for(Circle c in _circles) {
      final double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          c.center.latitude,
          c.center.longitude
      );

      if (distance <= c.radius) {
        if (_lastWarnedZone?.circleId != c.circleId) {
          _lastWarnedZone = c;
          _showDangerSnackbar(c.center);
        }
        return;
      }
    }
    _lastWarnedZone = null;
  }

  void _showDangerSnackbar(LatLng zoneCenter) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 You have entered a danger zone!'),
        backgroundColor: Colors.red[800],
        duration: Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Confirm Danger',
          textColor: Colors.white,
          onPressed: () {
            _confirmDanger(zoneCenter);
          },
        ),
      ),
    );
  }


  Future<void> _confirmDanger(LatLng location) async {
    try {
      // 🔥 Query the Firestore collection for a matching report (by location)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('dangerReports')
          .where('position.latitude', isEqualTo: location.latitude)
          .where('position.longitude', isEqualTo: location.longitude)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;

        // 🔄 Increment the upVotes field using FieldValue.increment
        await doc.reference.update({
          'upVotes': FieldValue.increment(1),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Thanks! Your confirmation was recorded.'),
            backgroundColor: Colors.green[700],
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Could not find the report to confirm.'),
            backgroundColor: Colors.orange[700],
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error while confirming danger: $e'),
          backgroundColor: Colors.red[800],
          duration: Duration(seconds: 4),
        ),
      );
    }
  }


  // TODO: Add a button click animation, at least for the report button
  // TODO: call authorities
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.blueGrey.shade900,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/SafeSkyLogo.png'),
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'SafeSky',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 30,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20,),
                    Text(
                      'Welcome, $_displayName',
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.blueGrey[400],
                thickness: 1,
              ),
              // Pushes the buttons to the bottom
              Spacer(),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    CustomElevatedButton(
                        onPressed: () {
                          setState(() {
                            isDefault = !isDefault;
                            mapType = isDefault ? MapType.normal : MapType.satellite;
                          });
                        },
                        icon: Icons.map_rounded,
                        label: 'Type'
                    ),
                    SizedBox(height: 10,),
                    CustomElevatedButton(
                        onPressed: () {
                          if(!isDefault) {
                            setState(() {
                              isDefault = !isDefault;
                              mapType = isDefault ? MapType.normal : MapType.satellite;
                            });
                          }
                          setState(() {
                            isDarkTheme = !isDarkTheme;

                            _mapController.setMapStyle(
                              isDarkTheme ? DarkMap.darkMapStyle : null, // null resets to default
                            );
                          });
                        },
                        icon: Icons.dark_mode_outlined,
                        label: 'Theme',
                    ),
                    SizedBox(height: 40,),
                    CustomElevatedButton(
                        onPressed: () {
                          _authService.signOut();
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        icon: Icons.logout,
                        label: 'Sign out'
                    ),
                    SizedBox(height: 10),
                    CustomElevatedButton(onPressed: () {},
                        icon: Icons.mail_outline,
                        label: 'Contact Us'
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
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
                arguments: {'reportedPosition': _currentMarkedPosition, 'displayName': _displayName},
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
                    CallAuthorities.call();
                  },
                  icon: Icon(Icons.call),
                  label: Text("Emergency"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                        arguments: {'currentPosition': _currentPosition}
                    );
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

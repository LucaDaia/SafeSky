import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapActivity extends StatefulWidget {
  @override
  State<MapActivity> createState() => _MapActivityState();
}

class _MapActivityState extends State<MapActivity> {

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  late GoogleMapController _mapController;

  // Center of the initial camera position
  final LatLng _center = const LatLng(45.521563, -122.677433);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'SafeSky',
            style: TextStyle(
                color: Colors.white,
                fontSize: 30.0,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        mapType: MapType.normal,
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          print("A fost raportat un pericol");
        },
        child: Icon(
          Icons.report_gmailerrorred,
          color: Colors.white,
        ),
        backgroundColor: Colors.red[900],
        shape: CircleBorder(),
        elevation: 50,
      ),
    );
  }
}

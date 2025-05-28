import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MaterialApp(
  home: MapActivity(),
));


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
        title: Text(
            'SafeSky',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30.0,
            ),
        ),
        backgroundColor: Colors.grey[800],),
      body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
          mapType: MapType.normal,
          myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            print("A fost raportat un pericol");
          }),
    );
  }
}



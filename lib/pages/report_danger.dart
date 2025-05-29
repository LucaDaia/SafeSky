import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportDanger extends StatefulWidget {
  const ReportDanger({super.key});

  @override
  State<ReportDanger> createState() => _ReportDangerState();
}

class _ReportDangerState extends State<ReportDanger> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGravity;
  String? _details;


  @override
  Widget build(BuildContext context) {

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final LatLng reportedPosition = args['reportedPosition'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report Danger',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ) ,),
        backgroundColor: Colors.black,
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey, //what is formKey
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedGravity,
                    decoration: InputDecoration(
                      labelText: "Danger Level",
                      border: OutlineInputBorder(),
                    ),
                    items: ['Low', 'Medium', 'High']
                        .map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGravity = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a danger level' : null,
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Details',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onSaved: (value) => _details = value,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter details' : null,
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: () {
                      if(_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        DateTime now = DateTime.now();

                        //TODO: Send this to Firebase
                        print('Gravity: $_selectedGravity');
                        print('Details: $_details');
                        print('Position: ${reportedPosition.latitude}, ${reportedPosition.longitude}');
                        print('Time: $now');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Report submitted!')),
                        );


                        //TODO: send back a response code true
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Submit Report'),
                  )

                ],
              ))
      ),
      backgroundColor: Colors.grey[800],
    );
  }
}




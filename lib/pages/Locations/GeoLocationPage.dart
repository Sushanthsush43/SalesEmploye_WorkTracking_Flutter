import 'package:call_logs_flutter/ApiCallPage/ApiCallPage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class GeoLocator extends StatefulWidget {
  final String loggedInUserName;

  GeoLocator({Key? key, required this.loggedInUserName}) : super(key: key);

  @override
  State<GeoLocator> createState() => _GeoLocatorState();
}

class _GeoLocatorState extends State<GeoLocator> {
  Position? _currentLocation;
  late bool servicePermission = false;
  late LocationPermission permission;
  bool _isStartLocationSet = false;
  String _currentCoordinates = "";
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      servicePermission = await Geolocator.isLocationServiceEnabled();
      if (!servicePermission) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Location service is disabled.";
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Location permission denied.";
          });
          return;
        }
      }

      _currentLocation = await Geolocator.getCurrentPosition();
      if (_currentLocation != null) {
        setState(() {
          _currentCoordinates =
              "Latitude: ${_currentLocation!.latitude}, Longitude: ${_currentLocation!.longitude}";
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to get current location.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: $e";
      });
    }
  }

  Future<void> _insertLocationData(
      int blockType, String coordinates, String column) async {
    try {
      setState(() {
        _isLoading = true;
      });

      var body = json.encode({
        'p_blockType': '9',
        'v_start_place': column == 'start_place' ? coordinates : '',
        'v_end_place': column == 'end_place' ? coordinates : '',
        'L_Name': widget.loggedInUserName,
      });
      var response = await fetch(body);
      print(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = '';
          _isStartLocationSet = column == 'start_place' ? true : false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to insert location data: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Get Employee Location',
          style: GoogleFonts.openSans(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(top: 160),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Location Coordinates",
                style: GoogleFonts.openSans(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(_currentCoordinates.isNotEmpty
                  ? _currentCoordinates
                  : "Coordinates not available"),
              SizedBox(height: 90),
              _isLoading
                  ? CircularProgressIndicator()
                  : _errorMessage.isNotEmpty
                      ? Text(
                          _errorMessage,
                          style: GoogleFonts.openSans(color: Colors.red),
                        )
                      : _isStartLocationSet
                          ? ElevatedButton(
                              onPressed: () async {
                                await _getCurrentLocation();
                                await _insertLocationData(
                                    9, _currentCoordinates, 'end_place');

                                setState(() {
                                  _isStartLocationSet = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: Colors.blueAccent, width: 2),
                                ),
                              ),
                              child: Text(
                                "End Location",
                                style: GoogleFonts.openSans(
                                    fontSize: 24, color: Colors.white),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                await _getCurrentLocation();
                                await _insertLocationData(
                                    9, _currentCoordinates, 'start_place');

                                setState(() {
                                  _isStartLocationSet = true;
                                  // _isLoading = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: Colors.blueAccent, width: 2),
                                ),
                              ),
                              child: Text(
                                "Start Location",
                                style: GoogleFonts.openSans(
                                    fontSize: 24, color: Colors.white),
                              ),
                            ),
            ],
          ),
        ),
      ),
    );
  }
}

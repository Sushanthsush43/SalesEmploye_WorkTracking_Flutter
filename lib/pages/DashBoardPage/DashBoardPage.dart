import 'dart:convert';
import 'package:call_logs_flutter/ApiCallPage/ApiCallPage.dart';
import 'package:call_logs_flutter/pages/AdminEmployePages/DisplayTodayCalls.dart';
import 'package:call_logs_flutter/pages/AdminEmployePages/LeadDetailsPage.dart';
import 'package:call_logs_flutter/pages/LoginPage/LoginPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class CallDashBoard extends StatefulWidget {
  final String loggedInUserName;
  final bool isDirectLogin;
  const CallDashBoard(
      {Key? key, required this.loggedInUserName, required this.isDirectLogin})
      : super(key: key);

  @override
  State<CallDashBoard> createState() => _CallDashBoard();
}

class _CallDashBoard extends State<CallDashBoard> {
  Map<String, int> leadStatusCounts = {};
  Map<String, List<Map<String, dynamic>>> leadDetails = {};
  Map<String, bool> isLoadingMap = {};
  bool isActionInProgress = false;
  Position? _currentLocation;
  late bool servicePermission = false;
  late LocationPermission permission;
  bool _isStartLocationSet = false;
  String _currentAddress = "";
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _locations = [];
  bool _isLoadings = false;
  String totalCallCount = '';

  @override
  void initState() {
    super.initState();
    _isLoadings = true;
    fetchDataAndUpdateCounts().then((_) {
      setState(() {
        _isLoadings = false;
      });
    });

    _loadLocationState();
    _getLocationState();
  }

//Location Part
  Future<void> _loadLocationState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isStartLocationSet = prefs.getBool('isStartLocationSet') ?? false;
      _currentAddress = prefs.getString('currentAddress') ?? '';
    });
  }

  Future<void> _setLocationState(
      bool isStartLocationSet, String currentAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isStartLocationSet) {
      await prefs.setBool('isStartLocationSet', isStartLocationSet);
      await prefs.setString('currentAddress', currentAddress);
    } else {
      await prefs.remove('isStartLocationSet');
      await prefs.remove('currentAddress');
    }
  }

  Future<void> _getLocationState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isStartLocationSet = prefs.getBool('isStartLocationSet');
    String? currentAddress = prefs.getString('currentAddress');
    setState(() {
      _isStartLocationSet = isStartLocationSet ?? false;
      _currentAddress = currentAddress ?? '';
    });
  }

//Shared Preferences
  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

//Fetching the lead status details
  Future<void> fetchDataAndUpdateCounts() async {
    var body =
        json.encode({});
    try {
      await TotalCallCount();

      var response = await fetch(body);
      print(
          '---------------------------------------------------------------------');
      print("response ${response.statusCode}");
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dataList = jsonData['Data'];
        for (var item in dataList) {
          leadStatusCounts[item['lead_status']] =
              item['number']; // Adjust the key for count
        }
        setState(() {});
      } else {
        throw Exception('Failed to load the data');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Check your internet connection"),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Rethrow the error if further handling is needed
    }
  }

//Location display in admin page part
  Future<void> _getLocationDisplay() async {
    var body =
        json.encode({});
    try {
      var response = await fetch(body);
      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        print('Response body: $responseBody');
        if (responseBody != null && responseBody is Map<String, dynamic>) {
          final data = responseBody['Data'];
          if (data is List) {
            setState(() {
              _locations = List<Map<String, dynamic>>.from(data);
            });
          } else {
            print('Unexpected response format: $responseBody');
            setState(() {});
          }
        } else {
          print('Response body is null or not in the expected format');
          setState(() {});
        }
      } else {
        print('Failed to fetch user list: ${response.statusCode}');
        setState(() {});
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Check your internet connection"),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Rethrow the error if further handling is needed
    }
  }

//Ask Location permission part
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
        await _getAddressFromCoordinates();
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

//Get the current location in latitude and longitude
  Future<void> _getAddressFromCoordinates() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      setState(() {
        _currentAddress =
            "Latitude: ${_currentLocation!.latitude}, Longitude: ${_currentLocation!.longitude}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: $e";
      });
    }
  }

//Store the Start plcae  and end place in DB
  Future<void> _insertLocationData(
      int blockType, String place, String column) async {
    try {
      setState(() {
        _isLoading = true;
      });

      var body = json.encode({      });
      var response = await fetch(body); // Update with your API call method
      print(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (column == 'start_place') {
          await prefs.setBool('isStartLocationSet', true);
          await prefs.setString('currentAddress', place);
        } else if (column == 'end_place') {
          await prefs.setBool('isStartLocationSet', false);
          await prefs.remove('currentAddress');
        }

        setState(() {
          _isLoading = false;
          _errorMessage = '';
          _isStartLocationSet = column == 'start_place';
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

//Get a lead information and display in listview
  Future<void> fetchLeadDetails(
      String status, Function(List<Map<String, dynamic>>) updateDetails) async {
    setState(() {
      isLoadingMap[status] = true;
      isActionInProgress = true;
    });

    var body = json.encode({    });
    try {
      var response = await fetch(body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dataList = jsonData['Data'];
        final details = dataList
            .map<Map<String, dynamic>>((item) => {(
                })
            .toList();
        setState(() {
          isLoadingMap[status] = false;
          isActionInProgress = false;
        });
        updateDetails(details);
      } else {
        setState(() {
          isLoadingMap[status] = false;
          isActionInProgress = false;
        });
        throw Exception('Failed to load the data');
      }
    } catch (e) {
      setState(() {
        isLoadingMap[status] = false;
        isActionInProgress = false;
      });
      print('error:$e');
    }
  }

//routes to LeadDetailsPage
  void _navigateToDetails(String status) {
    if (!isActionInProgress) {
      fetchLeadDetails(status, (details) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeadDetailsPage(
              status: status,
              details: details,
              loggedInUserName: widget.loggedInUserName,
            ),
          ),
        );
      });
    }
  }

//Duration count for Location track
  Duration _calculateDuration(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) {
      return Duration.zero;
    }
    final format = DateFormat("yyyy-MM-dd HH:mm:ss");
    final start = format.parse(startTime);
    final end = format.parse(endTime);
    return end.difference(start);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Recent call total number dislay in scaffold
  Future<void> TotalCallCount() async {
    print("textToDisplay");
    var body =
        json.encode({});
    try {
      var response = await fetch(body);
      print(json.decode((response.statusCode).toString()));
      if (response.statusCode == 200) {
        var calldata = json.decode(response.body);
        print("textToDisplay" + (calldata).toString());
        String textToDisplay = calldata["Data"][0]["calls"].toString();

        setState(() {
          totalCallCount = textToDisplay;
        });
        print(
            '---------------------------------------------------------------------------------------');
        print('response.body');
      } else {
        print('Failed to fetch data:${response.statusCode}');
      }
    } catch (e) {
      print("Exception during fetch:$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5691c8),
                  Color(0xFF457fca),
                ],
                transform: GradientRotation(3.2)),
          ),
        ),
        // centerTitle: true,
        leading: widget.isDirectLogin
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
        title: Text(
          widget.loggedInUserName,
          style: GoogleFonts.openSans(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        automaticallyImplyLeading: widget.isDirectLogin,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayTodayCalls(
                      loggedInUserName: widget.loggedInUserName),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.only(right: 25),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 10,
                minHeight: 50,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 22, bottom: 7),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromARGB(255, 79, 215, 25),
                                Color.fromARGB(255, 202, 213, 220),
                              ],
                              transform: GradientRotation(1))
                          .createShader(bounds),
                      child: const Icon(
                        Icons.call_sharp,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text(
                      totalCallCount,
                      style: GoogleFonts.openSans(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.isDirectLogin)
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: () {
                _handleLogout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoadings = true;
          });
          fetchDataAndUpdateCounts().then((_) {
            setState(() {
              _isLoadings = false;
            });
          });
        },
        child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Ensure scrolling always enabled
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Center(
                  child: _isLoadings
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Column(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _navigateToDetails('Follow Up-After Demo'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    // color: Color(0xFF68EFAD),
                                    decoration: BoxDecoration(
                                      gradient: isLoadingMap[
                                                  'Follow Up-After Demo'] ??
                                              false
                                          ? null
                                          : const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFF92FE9D),
                                                Color(0x5C00C9FF),
                                              ],
                                              stops: [0.022, 0.993],
                                              transform: GradientRotation(
                                                  3), // Gradient stops
                                            ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap[
                                                'Follow Up-After Demo'] ??
                                            false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Follow Up After Demo',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.5),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Follow Up-After Demo'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _navigateToDetails('Demo Completed'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isLoadingMap['Demo Completed'] ??
                                                  false
                                              ? null
                                              : const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFF3498db),
                                                    Color(0x5C2c3e50),
                                                  ],
                                                  stops: [
                                                    0.022,
                                                    0.993
                                                  ], // Gradient stops at 2.2% and 99.3%
                                                  transform: GradientRotation(
                                                      3), // Gradient stops
                                                ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap['Demo Completed'] ??
                                            false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Demo Completed',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.5,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Demo Completed'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _navigateToDetails(
                                    'Assigned-Action Pending'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient: isLoadingMap[
                                                  'Assigned-Action Pending'] ??
                                              false
                                          ? null
                                          : const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFF92FE9D),
                                                Color(0x5C00C9FF),
                                              ],
                                              stops: [
                                                0.022,
                                                0.993
                                              ], // Gradient stops at 2.2% and 99.3%
                                              transform: GradientRotation(
                                                  3), // Gradient stops
                                            ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap[
                                                'Assigned-Action Pending'] ??
                                            false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Action Pending',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.5,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Assigned-Action Pending'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _navigateToDetails('Not Responding'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isLoadingMap['Not Responding'] ??
                                                  false
                                              ? null
                                              : const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFF3498db),
                                                    Color(0x5C2c3e50),
                                                  ],
                                                  stops: [
                                                    0.022,
                                                    0.993
                                                  ], // Gradient stops at 2.2% and 99.3%
                                                  transform: GradientRotation(
                                                      3), // Gradient stops
                                                ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap['Not Responding'] ??
                                            false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Not Responding',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.5,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Not Responding'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _navigateToDetails('Negotiating'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isLoadingMap['Negotiating'] ?? false
                                              ? null
                                              : const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFF92FE9D),
                                                    Color(0x5C00C9FF),
                                                  ],
                                                  stops: [
                                                    0.022,
                                                    0.993
                                                  ], // Gradient stops at 2.2% and 99.3%
                                                  transform: GradientRotation(
                                                      3), // Gradient stops
                                                ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap['Negotiating'] ?? false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Negotiating',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.5),
                                                ),
                                                const SizedBox(
                                                  height: 35,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Negotiating'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _navigateToDetails('Interested'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isLoadingMap['Interested'] ?? false
                                              ? null
                                              : const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFF3498db),
                                                    Color(0x5C2c3e50),
                                                  ],
                                                  stops: [
                                                    0.022,
                                                    0.993
                                                  ], // Gradient stops at 2.2% and 99.3%
                                                  transform: GradientRotation(
                                                      3), // Gradient stops
                                                ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap['Interested'] ?? false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Interested',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.5),
                                                ),
                                                const SizedBox(
                                                  height: 35,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Interested'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _navigateToDetails('Demo Scheduled'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isLoadingMap['Demo Scheduled'] ??
                                                  false
                                              ? null
                                              : const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFF92FE9D),
                                                    Color(0x5C00C9FF),
                                                  ],
                                                  stops: [
                                                    0.022,
                                                    0.993
                                                  ], // Gradient stops at 2.2% and 99.3%
                                                  transform: GradientRotation(
                                                      3), // Gradient stops
                                                ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap['Demo Scheduled'] ??
                                            false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Demo Scheduled',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.5,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Demo Scheduled'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _navigateToDetails('Busy'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient: isLoadingMap['Busy'] ?? false
                                          ? null
                                          : const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFF3498db),
                                                Color(0x5C2c3e50),
                                              ],
                                              // Gradient stops at 2.2% and 99.3%
                                              transform: GradientRotation(
                                                  3), // Gradient stops
                                            ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap['Busy'] ?? false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Busy',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.5),
                                                ),
                                                const SizedBox(
                                                  height: 35,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Busy'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _navigateToDetails('Open'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 120,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient: isLoadingMap['Open'] ?? false
                                          ? null
                                          : const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFF92FE9D),
                                                Color(0x5C00C9FF),
                                              ],
                                              stops: [
                                                0.022,
                                                0.993
                                              ], // Gradient stops at 2.2% and 99.3%
                                              transform: GradientRotation(
                                                  3), // Gradient stops
                                            ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 33, 196, 199),
                                        width: 2,
                                      ),
                                    ),
                                    child: isLoadingMap['Open'] ?? false
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Open',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.5),
                                                ),
                                                const SizedBox(
                                                  height: 35,
                                                ),
                                                Text(
                                                  '${leadStatusCounts['Open'] ?? '0'}',
                                                  style: GoogleFonts.openSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 30),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Visibility(
                                visible: !_isStartLocationSet &&
                                    !widget.isDirectLogin,
                                child: Container(
                                  width: 380,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF5691c8),
                                          Color(0xFF457fca),
                                        ],
                                        transform: GradientRotation(3)),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255)),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      await _getCurrentLocation();
                                      await _getAddressFromCoordinates();
                                      await _insertLocationData(
                                          9, _currentAddress, 'start_place');
                                      setState(() {
                                        _isStartLocationSet = true;
                                        _isLoading = false;
                                      });
                                      await _setLocationState(
                                          true, _currentAddress);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          side: const BorderSide(
                                            color: Color.fromRGBO(
                                                255, 255, 255, 1),
                                          )),
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_isLoading)
                                          const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                        SizedBox(width: _isLoading ? 10 : 0),
                                        Text(
                                          _isLoading
                                              ? "LOCATION FETCHING..."
                                              : "START LOCATION",
                                          style: GoogleFonts.openSans(
                                            fontSize: 24,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: _isStartLocationSet &&
                                    !widget.isDirectLogin,
                                child: Container(
                                  width: 380,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(
                                              0xFF5691c8), // New color #2a5298  #ff9068
                                          Color(0xFF457fca),
                                        ],
                                        stops: [0.112, 0.78],
                                        transform: GradientRotation(3)
                                        // transform: GradientRotation(3)
                                        ),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255)),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      await _getCurrentLocation();
                                      await _getAddressFromCoordinates();
                                      await _insertLocationData(
                                          9, _currentAddress, 'end_place');
                                      setState(() {
                                        _isStartLocationSet = false;
                                        _isLoading = false;
                                      });
                                      await _setLocationState(false, '');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            width: 2),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_isLoading)
                                          const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                        SizedBox(width: _isLoading ? 10 : 0),
                                        Text(
                                          _isLoading
                                              ? "LOCATION ENDING..."
                                              : "END LOCATION",
                                          style: GoogleFonts.openSans(
                                            fontSize: 24,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Visibility(
                                visible: _isStartLocationSet &&
                                    _currentAddress.isNotEmpty &&
                                    !widget.isDirectLogin,
                                child: Column(
                                  children: [
                                    Text(
                                      "Location Address",
                                      style: GoogleFonts.openSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentAddress,
                                      style: GoogleFonts.openSans(
                                          color:
                                              Color.fromARGB(255, 8, 189, 26),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Visibility(
                            visible: widget.isDirectLogin,
                            child: Container(
                              width: 380,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF5691c8),
                                      Color(0xFF457fca),
                                    ],
                                    stops: [0.112, 0.78],
                                    transform: GradientRotation(3)
                                    // transform: GradientRotation(3)
                                    ),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255)),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  await _getLocationDisplay();
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                      return FractionallySizedBox(
                                        widthFactor: 1.0,
                                        child: SizedBox(
                                          height: 750,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Center(
                                              child: _isLoading
                                                  ? const CircularProgressIndicator()
                                                  : Column(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                            color: Colors.white,
                                                            child: ListView
                                                                .builder(
                                                              itemCount:
                                                                  _locations
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                final location =
                                                                    _locations[
                                                                        index];
                                                                final duration =
                                                                    _calculateDuration(
                                                                  location[
                                                                      'start_time'],
                                                                  location[
                                                                      'end_time'],
                                                                );
                                                                final formattedDuration =
                                                                    _formatDuration(
                                                                        duration);
                                                                return Column(
                                                                  children: [
                                                                    ListTile(
                                                                      title:
                                                                          RichText(
                                                                        text:
                                                                            TextSpan(
                                                                          children: [
                                                                            TextSpan(
                                                                              text: 'Start: ',
                                                                              style: GoogleFonts.openSans(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20),
                                                                            ),
                                                                            TextSpan(
                                                                              text: '${location['start_place'] ?? 'N/A'}\n',
                                                                              style: GoogleFonts.openSans(color: Color.fromARGB(255, 0, 0, 0), fontSize: 15),
                                                                            ),
                                                                            const TextSpan(
                                                                              text: 'End: ',
                                                                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20),
                                                                            ),
                                                                            TextSpan(
                                                                              text: location['end_place'] ?? 'N/A',
                                                                              style: GoogleFonts.openSans(color: Color.fromARGB(255, 0, 0, 0), fontSize: 15),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      subtitle:
                                                                          Text(
                                                                        '',
                                                                        style: GoogleFonts.openSans(
                                                                            color: Color.fromARGB(
                                                                          255,
                                                                          237,
                                                                          88,
                                                                          88,
                                                                        )),
                                                                      ),
                                                                    ),
                                                                    const Divider(),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                        width: 1),
                                  ),
                                  elevation: 0, // Remove elevation
                                  backgroundColor: Colors
                                      .transparent, // Set background color to transparent
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isLoading)
                                      const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    SizedBox(
                                      width: _isLoading ? 10 : 0,
                                    ),
                                    Text(
                                      _isLoading
                                          ? "LOCATION..."
                                          : "SHOW LOCATION",
                                      style: GoogleFonts.openSans(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // const SizedBox(
                          //   height: 10,
                          // ),
                          // Image.asset(
                          //   "assets/mobiezy1.png",
                          //   scale: 20,
                          // )
                        ]),
                ),
              ),
            ]),
      ),
    );
  }
}

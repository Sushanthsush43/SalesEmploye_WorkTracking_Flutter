import 'dart:convert';
import 'package:call_logs_flutter/ApiCallPage/ApiCallPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class DisplayTodayCalls extends StatefulWidget {
  final String loggedInUserName;

  const DisplayTodayCalls({Key? key, required this.loggedInUserName})
      : super(key: key);

  @override
  _DisplayTodayCallsState createState() => _DisplayTodayCallsState();
}

class _DisplayTodayCallsState extends State<DisplayTodayCalls> {
  bool isLoading = true;
  List<Map<String, dynamic>> callLogs = [];

  @override
  void initState() {
    super.initState();
    fetchCallLogs();
  }

  Future<void> fetchCallLogs() async {
    setState(() {
      isLoading = true;
    });

    var body = json.encode({,
    });
    var response = await fetch(body);
    print(response.body);
    try {
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedCallLogs =
            List<Map<String, dynamic>>.from(data['Data']);

        setState(() {
          callLogs = fetchedCallLogs;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Exception during fetch: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatTime(String dateTime) {
    final dateTimeObj = DateTime.parse(dateTime);
    final timeFormat = DateFormat('HH:mm:ss');
    return timeFormat.format(dateTimeObj);
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
              transform: GradientRotation(2.2),
            ),
          ),
        ),
        title: Text(
          'Recent call Logs',
          style: GoogleFonts.openSans(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading ? _buildSkeletonLoader() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: callLogs.length,
      itemBuilder: (context, index) {
        var callLog = callLogs[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              callLog['reciver_name'] ?? '',
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.w400,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            subtitle: Text(
              callLog['DateTime'] != null
                  ? formatTime(callLog['DateTime'])
                  : '',
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 212, 73, 82),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 15,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 25,
              ),
              title: Container(
                height: 15,
                color: Colors.grey[300],
              ),
              subtitle: Container(
                height: 12,
                color: Colors.grey[300],
              ),
            ),
          ),
        );
      },
    );
  }
}

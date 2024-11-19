import 'dart:convert';
import 'package:call_logs_flutter/ApiCallPage/ApiCallPage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class CallHistoryPage extends StatefulWidget {
  final String receiverName;
  final String callerName;

  CallHistoryPage({
    Key? key,
    required this.receiverName,
    required this.callerName,
  }) : super(key: key);

  @override
  _CallHistoryPageState createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  List<CallLogs> callLogs = [];
  bool isLoading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    var body = jsonEncode({    });
    var response = await fetch(body);
    print('---------------------------------------------------------');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final dynamic decodedResponse = json.decode(response.body);
      if (decodedResponse != null && decodedResponse['Data'] != null) {
        setState(() {
          callLogs = (decodedResponse['Data'] as List)
              .map((callLog) => CallLogs(
                    callStartDatetime: DateTime.parse(callLog['DateTime']),
                  ))
              .toList();
          isLoading = false;
        });
        print(callLogs);
      }
      print('response successful ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCallLogs = selectedDate != null
        ? callLogs
            .where((callLog) =>
                callLog.callStartDatetime?.isAtSameMomentAs(selectedDate!) ??
                false)
            .toList()
        : callLogs;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make the app bar transparent
        elevation: 0, // Remove app bar shadow
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft, // Align gradient from top left
                end: Alignment.bottomRight, // to bottom right
                colors: [
                  Color(0xFF5691c8),
                  Color(0xFF457fca),
                ],
                transform: GradientRotation(2.2)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.receiverName,
          style: GoogleFonts.openSans(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              _showDatePicker(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildSkeletonLoader()
          : ListView.builder(
              itemCount: callLogs.length,
              itemBuilder: (context, index) {
                final callLog = callLogs[index];
                String formattedDate = formatDate(callLog.callStartDatetime);
                String formattedTime = formatTime(callLog.callStartDatetime);
                return Container(
                  decoration: BoxDecoration(
                    border: const Border(
                      bottom: BorderSide(
                        color: Color.fromARGB(255, 0, 0, 0),
                        width: 1.5,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(
                      Icons.call_made_rounded,
                      color: Color.fromARGB(255, 87, 174, 15),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate,
                              style: GoogleFonts.openSans(
                                  color: const Color.fromARGB(255, 0, 0, 0)),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedTime,
                              style: GoogleFonts.openSans(
                                  color: const Color.fromARGB(255, 0, 0, 0)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
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
        );
      },
    );
  }

  void _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    // If user selects a date, update the selectedDate and fetch history
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        isLoading =
            true; // Set isLoading to true to show the loading indicator while fetching history
      });
      await fetchHistory();
    }
  }

  String formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Invalid';
    }
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  String formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    return '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}

class CallLogs {
  late DateTime? callStartDatetime;

  CallLogs({
    required this.callStartDatetime,
  });
}

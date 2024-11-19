import 'dart:convert';
import 'package:call_logs_flutter/ApiCallPage/ApiCallPage.dart';
import 'package:call_logs_flutter/pages/AdminEmployePages/HistoryViewPage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class LeadDetailsPage extends StatefulWidget {
  final String status;
  final List<Map<String, dynamic>> details;
  final String loggedInUserName;

  LeadDetailsPage({
    Key? key,
    required this.status,
    required this.details,
    required this.loggedInUserName,
  }) : super(key: key);

  @override
  State<LeadDetailsPage> createState() => _LeadDetailsPageState();
}

class _LeadDetailsPageState extends State<LeadDetailsPage> {
  List<CallLogs> callLogs = [];
  bool isLoading = true;
  Map<String, bool> callingStates = {};
  bool isCalling = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> logCall(CallDetails callDetailsList) async {
    final callStartDatetime = DateTime.now().toString();
    final callerName = callDetailsList.callerName;
    final receiverName = callDetailsList.receiverName;
    var body = jsonEncode({    });

    try {
      var response = await fetch(body);
      print("response ${response.statusCode}");
      print('Response body: ${response.body}');
      print('response successful ${response.statusCode}');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Check your internet connection"),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Rethrow the error if further handling is needed
    }
  }

  void _navigateToHistoryPage(String receiverName, String callerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallHistoryPage(
          receiverName: receiverName,
          callerName: widget.loggedInUserName,
        ),
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '${widget.status} Contacts',
          style: GoogleFonts.openSans(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LeadSearchDelegate(widget.details),
              );
            },
          ),
        ],
      ),
      body: isLoading ? _buildSkeletonLoader() : _buildListView(widget.details),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> details) {
    return ListView.builder(
      itemCount: details.length,
      itemBuilder: (context, index) {
        final detail = details[index];
        final contactName = detail['name'] ?? 'No Name';

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color.fromARGB(255, 0, 0, 0)!,
                width: 1.0,
              ),
            ),
          ),
          child: GestureDetector(
            onTap: () => _navigateToHistoryPage(
              detail['name'],
              widget.loggedInUserName,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(
                      detail['name'].isNotEmpty == true
                          ? detail['name']!
                          : '--',
                      style: GoogleFonts.openSans(
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          detail['phone']?.isNotEmpty == true
                              ? detail['phone']!
                              : '--',
                          style: GoogleFonts.openSans(
                            color: Color.fromARGB(255, 83, 205, 95),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          detail['state']?.isNotEmpty == true
                              ? detail['state']!
                              : '--',
                          style: GoogleFonts.openSans(
                            color: Color.fromARGB(255, 212, 73, 82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton(
                    onPressed: isCalling
                        ? null
                        : () async {
                            setState(() {
                              isCalling = true;
                              callingStates[contactName] = true;
                            });

                            CallDetails callDetails = CallDetails(
                              callerName: widget.loggedInUserName,
                              receiverName: contactName,
                              StartDateTime: DateTime.now(),
                            );

                            try {
                              await logCall(callDetails);
                              bool? res =
                                  await FlutterPhoneDirectCaller.callNumber(
                                detail['phone'] ?? '',
                              );
                            } catch (error) {
                              // Error handling is already done in logCall method
                            }

                            setState(() {
                              isCalling = false;
                              callingStates[contactName] = false;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 83, 205, 95),
                      padding: const EdgeInsets.all(16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(90, 50),
                    ),
                    child: callingStates[contactName] == true
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.call,
                            color: Color.fromARGB(255, 78, 73, 73),
                            size: 20,
                          ),
                  ),
                ),
              ],
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
}

class LeadSearchDelegate extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> details;

  LeadSearchDelegate(this.details);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {}); // Close search
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = details.where((detail) {
      final name = detail['name']?.toLowerCase() ?? '';
      final phone = detail['phone']?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) || phone.contains(searchQuery);
    }).toList();

    return _buildListView(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = details.where((detail) {
      final name = detail['name']?.toLowerCase() ?? '';
      final phone = detail['phone']?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) || phone.contains(searchQuery);
    }).toList();

    return _buildListView(suggestions);
  }

  Widget _buildListView(List<Map<String, dynamic>> details) {
    return ListView.builder(
      itemCount: details.length,
      itemBuilder: (context, index) {
        final detail = details[index];
        return ListTile(
          title: Text(
            detail['name'] ?? 'No Name',
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone: ${detail['phone'] ?? 'No Phone Number'}',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
              Text(
                'State: ${detail['state'] ?? 'No State'}',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CallDetails {
  final String callerName;
  final String receiverName;
  final DateTime StartDateTime;

  CallDetails({
    required this.callerName,
    required this.receiverName,
    required this.StartDateTime,
  });
}

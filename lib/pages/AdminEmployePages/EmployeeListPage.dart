import 'dart:convert';
import 'package:call_logs_flutter/pages/DashBoardPage/DashBoardPage.dart';
import 'package:call_logs_flutter/pages/LoginPage/LoginPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:call_logs_flutter/ApiCallPage/ApiCallPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OperatorList extends StatefulWidget {
  final String loggedInUserName;
  OperatorList({Key? key, required this.loggedInUserName}) : super(key: key);

  @override
  State<OperatorList> createState() => _OperatorListState();
}

class _OperatorListState extends State<OperatorList> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  Future<void> _fetchUserList() async {
    var body = json.encode({});
    try {
      var response = await fetch(body);
      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        print('Response body: $responseBody');
        if (responseBody != null && responseBody is Map<String, dynamic>) {
          final data = responseBody['Data'];
          if (data is List) {
            setState(() {
              _users = List<Map<String, dynamic>>.from(data);
              _isLoading = false;
            });
          } else {
            print('Unexpected response format: $responseBody');
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          print('Response body is null or not in the expected format');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('Failed to fetch user list: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user list: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSearch(BuildContext context) async {
    final result = await showSearch(
      context: context,
      delegate: UserSearchDelegate(users: _users),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _users = result;
      });
    }
  }

  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Color(0xFF5691c8),
                  Color(0xFF457fca),
                ],
                transform: GradientRotation(2.2)),
          ),
        ),
        title: Text(
          widget.loggedInUserName,
          style: GoogleFonts.openSans(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              _showSearch(context);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.account_circle,
                        color: Colors.black,
                        size: 40), // Profile icon on the left side
                    title: Text(
                      user['name'] ?? '--',
                      style: GoogleFonts.openSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    subtitle: Text('User ID: ${user['user_id'] ?? 'No ID'}',
                        style: GoogleFonts.openSans(
                          color: Color.fromARGB(255, 83, 205, 95),
                        )),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallDashBoard(
                            loggedInUserName: user['name'] ?? '',
                            isDirectLogin: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> users;

  UserSearchDelegate({required this.users});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filterUsers(query);
    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _filterUsers(query);
    return _buildSearchResults(suggestions);
  }

  List<Map<String, dynamic>> _filterUsers(String query) {
    return users.where((user) {
      final userName = user['name']?.toLowerCase() ?? '';
      final userId = user['user_id']?.toString() ?? '';
      final searchQuery = query.toLowerCase();

      return userName.contains(searchQuery) || userId.contains(searchQuery);
    }).toList();
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return ListTile(
          title: Text(user['name'] ?? 'No Name'),
          subtitle: Text('User ID: ${user['user_id'] ?? 'No ID'}'),
          onTap: () {
            close(context, [user]);
          },
        );
      },
    );
  }
}

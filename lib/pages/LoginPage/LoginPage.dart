import 'package:call_logs_flutter/pages/AdminEmployePages/EmployeeListPage.dart';
import 'package:call_logs_flutter/pages/DashBoardPage/DashBoardPage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:call_logs_flutter/ApiCallPage/ApiCallPage.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _loginIdController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? isLoggedIn = prefs.getString('');
    String? loggedInUserName = prefs.getString('');
    String? roleId = prefs.getString('');
    if (isLoggedIn == 'true' && loggedInUserName != null && roleId != null) {
      // Navigate to the appropriate page based on role ID
      if (roleId == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorList(
              loggedInUserName: loggedInUserName,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CallDashBoard(
              loggedInUserName: loggedInUserName,
              isDirectLogin: false,
            ),
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    String login_id = _loginIdController.text;
    String password = _passwordController.text;

    var body = json.encode({});

    try {
      var response = await fetchLogin(body);
      print("Response status: ${response.statusCode}");
      print('Response body: ${response.body}');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        if (responseBody[''] != null &&
            responseBody[''] != null) {
          // Save login details to shared preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('', 'true');
          prefs.setString('', responseBody['L_Name']);
          prefs.setString('', responseBody['p_user_role']);

          String roleId = responseBody['p_user_role'];

          // Redirect based on role ID
          if (roleId == 'Admin') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OperatorList(
                  loggedInUserName: responseBody['L_Name'],
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallDashBoard(
                  loggedInUserName: responseBody['L_Name'],
                  isDirectLogin: false,
                ),
              ),
            );
          }
        } else {
          _showErrorDialog(
              'Login Failed', 'Invalid credentials. Please try again.');
        }
      } else {
        _showErrorDialog('Error', 'An error occurred. Please try again later.');
      }
    } catch (e) {
      print('Error during login: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error', 'An error occurred. Please try again later.');
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 110),
          child: Column(
            children: [
              Image.asset(
                "assets/sales.png",
                scale: 2,
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    TextField(
                      controller: _loginIdController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Enter User ID",
                        labelStyle: GoogleFonts.openSans(
                            fontSize: 14, color: Colors.black),
                      ),
                      style: GoogleFonts.openSans(
                          color: Colors.black, fontSize: 15),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Enter Password",
                        labelStyle: GoogleFonts.openSans(
                            fontSize: 14, color: Colors.black),
                      ),
                      style: GoogleFonts.openSans(
                          color: Colors.black, fontSize: 15),
                    ),
                    const SizedBox(height: 92),
                    _isLoading
                        ? const CircularProgressIndicator() // Show loading indicator if loading
                        : Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF5691c8),
                                    Color(0xFF457fca),
                                  ],
                                  transform: GradientRotation(2.2)),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .transparent, // Make button transparent
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 100,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  side: const BorderSide(color: Colors.white),
                                ),
                              ),
                              child: Text(
                                'LOGIN',
                                style: GoogleFonts.openSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.only(top: 150, left: 105),
                      child: Center(
                        child: Row(
                          children: [
                            Text('powered by ', style: GoogleFonts.openSans()),
                            Image.asset(
                              "assets/mobiezy1.png",
                              scale: 33,
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

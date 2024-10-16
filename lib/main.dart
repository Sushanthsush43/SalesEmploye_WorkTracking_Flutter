import 'package:call_logs_flutter/pages/LoginPage/LoginPage.dart' as LoginPage;
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Log App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginPage.LoginScreen(),
    );
  }
}

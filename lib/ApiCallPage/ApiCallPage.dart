import 'package:http/http.dart' as http;
import 'dart:convert';

fetch(body) async {
  var url = Uri.parse(
      'https://zr36l28jaf.execute-api.ap-south-1.amazonaws.com/prod/call_logs_date');

  final response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body);

  return response;
}

fetchApi(body) async {
  var url = Uri.parse(
      'https://zr36l28jaf.execute-api.ap-south-1.amazonaws.com/prod/call_log_mobiezy_login');
  final response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body);
  return response;
}

fetchLogin(body) async {
  var url = Uri.parse(
      'https://ytvpnvug1k.execute-api.ap-south-1.amazonaws.com/prod/managelogin');
  final response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body);
  return response;
}

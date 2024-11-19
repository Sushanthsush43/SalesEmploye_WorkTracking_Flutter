import 'package:http/http.dart' as http;
import 'dart:convert';

fetch(body) async {
  var url = Uri.parse(
      '');

  final response = await http.post(url,
      headers: {
        '',
      },
      body: body);

  return response;
}

fetchApi(body) async {
  var url = Uri.parse(
      '');
  final response = await http.post(url,
      headers: {
        '',
      },
      body: body);
  return response;
}

fetchLogin(body) async {
  var url = Uri.parse(
      '');
  final response = await http.post(url,
      headers: {
        '',
      },
      body: body);
  return response;
}

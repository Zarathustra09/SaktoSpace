import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';

class AuthService {

Future<String> login(String email, String password) async {
    final url = '$baseUrl/login?email=$email&password=$password';

    print('Login request URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    print('Login request headers: ${{'Content-Type': 'application/json'}}');
    print('Login response status: ${response.statusCode}');
    print('Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final userId = data['user_id'];

      print('Login successful, token: $token, userId: $userId');

      // Store the token, user_id, role_id, and set isNew to false
      // Store the token, user_id, role_id, and set isNew to false
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setInt('userId', userId);
      await prefs.setBool('isNew', false); // This line sets isNew to false

      return 'Login successful';
    } else if (response.statusCode == 401) {
      print('Credentials are wrong');
      return 'Credentials are wrong';
    } else {
      print('Failed to login, response: ${response.body}');
      return 'Failed to login';
    }
  }

  Future<Map<String, String>> getHeaders() async {
    // print('Fetching headers');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      print('No token found');
      throw Exception('No token found');
    }

    // print('Token found: $token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }


  Future<void> logout() async {
    print('Logging out');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('roleId');
    print('Logout successful');
  }
}
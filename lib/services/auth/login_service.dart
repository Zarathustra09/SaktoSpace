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

  Future<String?> getAuthToken() async {
    print('Getting auth token from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token: ${token != null ? "EXISTS" : "NULL"}');
    return token;
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null;
  }

  Future<Map<String, String>> getHeaders() async {
    print('=== GETTING AUTH HEADERS ===');
    final token = await getAuthToken();
    print('Retrieved token: ${token != null ? "TOKEN_EXISTS" : "NO_TOKEN"}');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('Generated headers: $headers');
    return headers;
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
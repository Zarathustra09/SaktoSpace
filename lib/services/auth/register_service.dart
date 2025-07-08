import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';

class RegisterService {
  Future<String> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final url = '$baseUrl/register';

    print('Register request URL: $url');

    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });

    print('Register request body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('Register response status: ${response.statusCode}');
    print('Register response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Extract token and user_id from the response structure
      final token = data['token'];
      final userId = data['user']?['id'];

      if (token != null && userId != null) {
        print('Registration successful, token: $token, userId: $userId');

        // Store the token, user_id, and set isNew to true
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        await prefs.setInt('userId', userId);
        await prefs.setBool('isNew', true); // Mark as new user

        return 'Registration successful';
      }

      return 'User registered successfully';
    } else if (response.statusCode == 422) {
      // Validation errors
      final data = jsonDecode(response.body);
      final errors = data['errors'];

      if (errors != null && errors is Map) {
        // Return the first error message
        final firstErrorKey = errors.keys.first;
        final firstError = errors[firstErrorKey]?.first;
        return firstError ?? 'Validation error';
      }

      return 'Validation error';
    } else {
      print('Failed to register, response: ${response.body}');
      return 'Registration failed';
    }
  }
}
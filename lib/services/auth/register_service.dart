import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../constants.dart';
import 'login_service.dart';

class RegisterService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Helper method for consistent logging
  static void _log(String message) {
    print('[RegisterService] $message');
  }

  static void _logError(String operation, dynamic error) {
    print('[RegisterService ERROR] $operation: $error');
  }

  static Future<String> _getDeviceType() async {
    try {
      String deviceType;
      if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      } else {
        deviceType = 'web';
      }
      _log('Device type detected: $deviceType');
      return deviceType;
    } catch (e) {
      _logError('_getDeviceType', e);
      return 'unknown';
    }
  }

  Future<String> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      _log('Starting user registration');
      _log('Registration data - Name: $name, Email: $email');

      // Get FCM token before registration
      String? fcmToken = await _messaging.getToken();
      String deviceType = await _getDeviceType();
      String timestamp = DateTime.now().toIso8601String();

      final registrationData = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      if (fcmToken != null) {
        registrationData['fcm_token'] = fcmToken;
        registrationData['device_type'] = deviceType;
        registrationData['timestamp'] = timestamp;
      }

      final url = '$baseUrl/register';
      _log('Register request URL: $url');

      final body = jsonEncode(registrationData);
      _log('Register request body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      _log('Register response status: ${response.statusCode}');
      _log('Register response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Extract token and user_id from the response structure
        final token = data['token'];
        final userId = data['user']?['id'];

        if (token != null && userId != null) {
          _log('Registration successful, token: $token, userId: $userId');

          // Store the token, user_id, and set isNew to true
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          await prefs.setInt('userId', userId);
          await prefs.setBool('isNew', true); // Mark as new user

          // Save FCM token locally if available
          if (fcmToken != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('fcm_token', fcmToken);
            await prefs.setString('fcm_token_timestamp', DateTime.now().toIso8601String());
          }

          // Initialize FCM after successful registration
          await AuthService.initializeFCM();

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
        _logError('Registration failed', 'Status: ${response.statusCode}, Response: ${response.body}');
        return 'Registration failed';
      }
    } catch (e) {
      _logError('register', e);
      return 'Network error: ${e.toString()}';
    }
  }
}
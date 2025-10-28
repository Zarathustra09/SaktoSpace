import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../constants.dart';

class AuthService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Keys for local storage
  static const String _fcmTokenKey = 'fcm_token';
  static const String _tokenTimestampKey = 'fcm_token_timestamp';

  // Helper method for consistent logging
  static void _log(String message) {
    print('[AuthService] $message');
  }

  static void _logError(String operation, dynamic error) {
    print('[AuthService ERROR] $operation: $error');
  }

  // FCM Token management
  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      await prefs.setString(_tokenTimestampKey, DateTime.now().toIso8601String());
      _log('FCM token saved locally with timestamp');
    } catch (e) {
      _logError('_saveFCMToken', e);
    }
  }

  static Future<String?> _getStoredFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      _logError('_getStoredFCMToken', e);
      return null;
    }
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

  static Future<void> initializeFCM() async {
    try {
      _log('Initializing FCM');

      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _log('FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // Get and save current token
        String? currentToken = await _messaging.getToken();
        if (currentToken != null) {
          await _saveFCMToken(currentToken);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          _log('FCM token refreshed');
          await _saveFCMToken(newToken);
          if (await _isLoggedInStatic()) {
            await _updateTokenOnServer(newToken);
          }
        });

        // Set up message handling
        await _setupForegroundMessageHandling();
        await _setupMessageInteractionHandling();

      } else {
        _log('FCM permission denied');
      }
    } catch (e) {
      _logError('initializeFCM', e);
    }
  }

  static Future<void> _setupForegroundMessageHandling() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log('Got a message whilst in the foreground!');
      _log('Message data: ${message.data}');

      if (message.notification != null) {
        _log('Message also contained a notification: ${message.notification}');
        _handleNotificationReceived(message);
      }
    });
  }

  static Future<void> _setupMessageInteractionHandling() async {
    // Handle notification tap when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _log('App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log('App opened from background via notification');
      _handleNotificationTap(message);
    });
  }

  static void _handleNotificationReceived(RemoteMessage message) {
    final notificationType = message.data['type'];

    switch (notificationType) {
      case 'announcement':
        _log('Received announcement notification: ${message.data['title']}');
        break;
      default:
        _log('Received unknown notification type: $notificationType');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final notificationType = message.data['type'];

    switch (notificationType) {
      case 'announcement':
        _log('User tapped announcement notification');
        // Navigate to announcement details
        break;
      default:
        _log('User tapped unknown notification type: $notificationType');
    }
  }

  static Future<String?> _getAuthTokenStatic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  static Future<bool> _isLoggedInStatic() async {
    final token = await _getAuthTokenStatic();
    return token != null;
  }

  static Future<void> _updateTokenOnServer(String token) async {
    try {
      _log('Updating token on server: ${token.substring(0, 20)}...');

      final authToken = await _getAuthTokenStatic();
      if (authToken == null) {
        _log('No auth token found, cannot update FCM token on server');
        return;
      }

      final deviceType = await _getDeviceType();
      final timestamp = DateTime.now().toIso8601String();

      final requestBody = {
        'token': token,
        'device_type': deviceType,
        'timestamp': timestamp,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      _log('Server token update - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('Token updated on server successfully');
      } else {
        _logError('Server token update failed', response.body);
      }
    } catch (e) {
      _logError('_updateTokenOnServer', e);
    }
  }

  Future<String> login(String email, String password) async {
    try {
      _log('Starting login process');
      _log('Login attempt for email: $email');

      // Get FCM token before login
      String? fcmToken = await _messaging.getToken();
      String deviceType = await _getDeviceType();
      String timestamp = DateTime.now().toIso8601String();

      final loginData = {
        'email': email,
        'password': password,
      };

      if (fcmToken != null) {
        loginData['fcm_token'] = fcmToken;
        loginData['device_type'] = deviceType;
        loginData['timestamp'] = timestamp;
      }

      _log('Login request data: $loginData');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(loginData),
      );

      _log('Login - Status: ${response.statusCode}');
      _log('Login - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userId = data['user_id'];

        _log('Login successful, token: $token, userId: $userId');

        // Store the token, user_id, and set isNew to false
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        await prefs.setInt('userId', userId);
        await prefs.setBool('isNew', false);

        // Save FCM token locally if available
        if (fcmToken != null) {
          await _saveFCMToken(fcmToken);
        }

        // Initialize FCM after successful login
        initializeFCM();

        return 'Login successful';
      } else if (response.statusCode == 401) {
        _log('Credentials are wrong');
        return 'Credentials are wrong';
      } else {
        _log('Failed to login, response: ${response.body}');
        return 'Failed to login';
      }
    } catch (e) {
      _logError('login', e);
      return 'Network error: ${e.toString()}';
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
    try {
      _log('Starting logout process');

      final token = await getAuthToken();
      if (token == null) {
        _log('No token found for logout');
        await _clearAuthData();
        return;
      }

      // Get FCM token for removal
      String? fcmToken = await _getStoredFCMToken() ?? await _messaging.getToken();

      _log('Sending logout request to server');
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (fcmToken != null) 'fcm_token': fcmToken,
        }),
      );

      _log('Logout - Status: ${response.statusCode}');
      _log('Logout - Response: ${response.body}');

      // Always clear local data regardless of server response
      await _clearAuthData();

      if (response.statusCode == 200) {
        _log('Logout successful');
      } else {
        _log('Logout request failed, but cleared local data');
      }
    } catch (e) {
      _logError('logout', e);
      await _clearAuthData();
    }
  }

  static Future<void> _clearAuthData() async {
    try {
      _log('Clearing auth data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userId');
      await prefs.remove('roleId');
      await prefs.remove(_fcmTokenKey);
      await prefs.remove(_tokenTimestampKey);
      _log('Auth data cleared successfully');
    } catch (e) {
      _logError('_clearAuthData', e);
    }
  }
}
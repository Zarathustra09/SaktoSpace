import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'package:shop/services/auth/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function to handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[Background Handler] Handling a background message: ${message.messageId}');
  print('[Background Handler] Background message data: ${message.data}');

  // Handle different notification types
  final notificationType = message.data['type'];
  switch (notificationType) {
    case 'announcement':
      print('[Background Handler] Received announcement notification');
      break;
    default:
      print('[Background Handler] Received unknown notification type: $notificationType');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set the background messaging handler early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final String initialRoute = await _determineInitialRoute();
  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _determineInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  final isNew = prefs.getBool('isNew');

  print('ROUTE DETERMINATION:');
  print('Token exists: ${token != null}');
  print('isNew value: $isNew');

  // Initialize FCM early if user is logged in
  if (token != null) {
    try {
      await AuthService.initializeFCM();
      print('FCM initialized for logged in user');
    } catch (e) {
      print('FCM initialization error: $e');
    }
  }

  if (token != null) {
    print('Route decision: Going to entryPointScreenRoute (has token)');
    // If token exists, go to home screen
    return entryPointScreenRoute;
  } else if (isNew == false) {
    print('Route decision: Going to logInScreenRoute (not new user)');
    // If explicitly not new user but no token, go to login
    return logInScreenRoute;
  } else {
    print('Route decision: Going to onbordingScreenRoute (new user)');
    // If new user or isNew is null, show onboarding
    return onbordingScreenRoute;
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SaktoSpace',
      theme: AppTheme.lightTheme(context),
      // Dark theme is included in the Full template
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      initialRoute: initialRoute,
    );
  }
}

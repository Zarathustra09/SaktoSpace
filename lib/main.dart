import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'package:shop/services/auth/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/services/notification/notification_service.dart'; // CHANGED import
import 'package:shop/screens/notification/view/notificatios_screen.dart' show NotificationsScreen;

// Global navigator key to navigate from listeners
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[BG] Handling message: ${message.messageId}');
  try {
    await NotificationService().saveFromFCM(message);
    print('[BG] Saved to SQLite');
  } catch (e) {
    print('[BG] Save error: $e');
  }

  final notificationType = message.data['type'];
  print('[BG] Type: $notificationType');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set the background messaging handler early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground delivery
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('[FG] message: ${message.messageId}');
    try {
      await NotificationService().saveFromFCM(message);
      print('[FG] Saved to SQLite');
    } catch (e) {
      print('[FG] Save error: $e');
    }
  });

  // Tapped from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print('[OPENED] message: ${message.messageId}');
    try {
      await NotificationService().saveFromFCM(message);
      print('[OPENED] Saved to SQLite');
    } catch (e) {
      print('[OPENED] Save error: $e');
    }
    // Navigate to notifications screen
    final nav = appNavigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  });

  // Launched from terminated by tapping notification
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('[INITIAL] message: ${initialMessage.messageId}');
    try {
      await NotificationService().saveFromFCM(initialMessage);
      print('[INITIAL] Saved to SQLite');
    } catch (e) {
      print('[INITIAL] Save error: $e');
    }
    // Delay navigation until app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      }
    });
  }

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
      navigatorKey: appNavigatorKey, // added
    );
  }
}

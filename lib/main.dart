import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Sakto Space',
      theme: AppTheme.lightTheme(context),
      // Dark theme is included in the Full template
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      initialRoute: initialRoute,
    );
  }
}
import 'package:flutter/material.dart';

class EnableNotificationScreen extends StatefulWidget {
  const EnableNotificationScreen({super.key});

  @override
  State<EnableNotificationScreen> createState() =>
      _EnableNotificationScreenState();
}

class _EnableNotificationScreenState extends State<EnableNotificationScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _inAppNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildNotificationOption(
            title: 'Push Notifications',
            subtitle: 'Receive push notifications',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          _buildNotificationOption(
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          _buildNotificationOption(
            title: 'SMS Notifications',
            subtitle: 'Receive notifications via SMS',
            value: _smsNotifications,
            onChanged: (value) {
              setState(() {
                _smsNotifications = value;
              });
            },
          ),
          _buildNotificationOption(
            title: 'In-App Notifications',
            subtitle: 'Show notifications within the app',
            value: _inAppNotifications,
            onChanged: (value) {
              setState(() {
                _inAppNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

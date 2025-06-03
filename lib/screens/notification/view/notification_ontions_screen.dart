import 'package:flutter/material.dart';

class NotificationOptionsScreen extends StatefulWidget {
  const NotificationOptionsScreen({super.key});

  @override
  State<NotificationOptionsScreen> createState() =>
      _NotificationOptionsScreenState();
}

class _NotificationOptionsScreenState extends State<NotificationOptionsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _inAppNotifications = true;
  bool _promotionalNotifications = false;
  bool _orderUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        centerTitle: true,
        leading: const BackButton(),
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
          _buildNotificationOption(
            title: 'Promotional Notifications',
            subtitle: 'Receive promotions and offers',
            value: _promotionalNotifications,
            onChanged: (value) {
              setState(() {
                _promotionalNotifications = value;
              });
            },
          ),
          _buildNotificationOption(
            title: 'Order Updates',
            subtitle: 'Get updates on your orders',
            value: _orderUpdates,
            onChanged: (value) {
              setState(() {
                _orderUpdates = value;
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

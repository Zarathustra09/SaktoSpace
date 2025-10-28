import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/auth/login_service.dart';
import 'package:shop/services/profile/profile_service.dart';

import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ProfileCard(
                  name: _userProfile?['name'] ?? 'Unknown User',
                  email: _userProfile?['email'] ?? 'No email',
                  imageSrc: _userProfile?['profile_image'] != null
                      ? '$storageUrl${_userProfile!['profile_image']}'
                      : "https://i.imgur.com/IXnwbLk.png",
                  press: () async {
                    final result = await Navigator.pushNamed(context, userInfoScreenRoute);
                    if (result == true) {
                      _loadProfile(); // Refresh profile if updated
                    }
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                  child: Text(
                    "Account",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: defaultPadding / 2),
                ProfileMenuListTile(
                  text: "Orders",
                  svgSrc: "assets/icons/Order.svg",
                  press: () {
                    Navigator.pushNamed(context, ordersScreenRoute);
                  },
                ),

                // Log Out
                ListTile(
                  onTap: () async {
                    final AuthService authService = AuthService();
                    await authService.logout();

                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      logInScreenRoute,
                      (route) => false
                    );
                  },
                  minLeadingWidth: 24,
                  leading: SvgPicture.asset(
                    "assets/icons/Logout.svg",
                    height: 24,
                    width: 24,
                    colorFilter: const ColorFilter.mode(
                      errorColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  title: const Text(
                    "Log Out",
                    style: TextStyle(color: errorColor, fontSize: 14, height: 1),
                  ),
                ),
                const SizedBox(height: defaultPadding),
              ],
            ),
    );
  }
}
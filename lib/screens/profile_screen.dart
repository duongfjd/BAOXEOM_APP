import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ sơ',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            // User Profile Info
            Center(
              child: Column(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppConstants.space16),
                  Text(
                    'Người dùng mới',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'user@example.com',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space32),
            
            // Settings List
            _buildSettingsItem(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Chế độ tối',
              trailing: Switch(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (value) {},
              ),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.language_rounded,
              title: 'Ngôn ngữ',
              subtitle: 'Tiếng Việt',
              onTap: () {},
            ),
            _buildSettingsItem(
              context,
              icon: Icons.notifications_none_rounded,
              title: 'Thông báo',
              onTap: () {},
            ),
            _buildSettingsItem(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Hỗ trợ & Trợ giúp',
              onTap: () {},
            ),
            _buildSettingsItem(
              context,
              icon: Icons.info_outline_rounded,
              title: 'Về chúng tôi',
              onTap: () {},
            ),
            
            const SizedBox(height: AppConstants.space24),
            
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.space20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.space16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                    ),
                  ),
                  child: const Text('Đăng xuất'),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.space40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space24,
        vertical: AppConstants.space4,
      ),
    );
  }
}

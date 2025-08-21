import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsState.when(
        loading: () => const LoadingOverlay(
          isLoading: true,
          child: SizedBox.expand(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              title: const Text('Edit Profile'),
              leading: const Icon(Icons.person_outline),
              onTap: () => context.go('${AppRoutes.settings}/edit-profile'),
            ),
            ListTile(
              title: const Text('Change Password'),
              leading: const Icon(Icons.lock_outline),
              onTap: () => context.go('${AppRoutes.settings}/change-password'),
            ),
            const Divider(),
            Builder(
              builder: (context) {
                final themeMode = ref.watch(themeModeProvider);
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                );
              },
            ),
            SwitchListTile(
              title: const Text('Enable Biometrics'),
              secondary: const Icon(Icons.fingerprint),
              value: settings.useBiometrics,
              onChanged: (value) => ref.read(settingsProvider.notifier).toggleBiometrics(),
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              secondary: const Icon(Icons.notifications_outlined),
              value: settings.notificationsEnabled,
              onChanged: (value) => ref.read(settingsProvider.notifier).toggleNotifications(),
            ),
            const Divider(),
            ListTile(
              title: const Text('Language'),
              leading: const Icon(Icons.language),
              trailing: DropdownButton<String>(
                value: settings.locale,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'si', child: Text('සිංහල')),
                  DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateLocale(value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomButton(
                onPressed: () {
                  // Handle logout
                },
                text: 'Logout',
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

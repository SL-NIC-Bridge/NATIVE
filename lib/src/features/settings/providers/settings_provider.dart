import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsModel>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsModel>> {
  static const _settingsKey = 'user_settings';
  
  SettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        state = AsyncValue.data(SettingsModel.fromJson(settingsMap));
      } else {
        state = AsyncValue.data(SettingsModel());
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(SettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, json.encode(settings.toJson()));
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleDarkMode() async {
    state.whenData((settings) async {
      await updateSettings(settings.copyWith(darkMode: !settings.darkMode));
    });
  }

  Future<void> toggleBiometrics() async {
    state.whenData((settings) async {
      await updateSettings(settings.copyWith(useBiometrics: !settings.useBiometrics));
    });
  }

  Future<void> toggleNotifications() async {
    state.whenData((settings) async {
      await updateSettings(settings.copyWith(notificationsEnabled: !settings.notificationsEnabled));
    });
  }

  Future<void> updateLocale(String locale) async {
    state.whenData((settings) async {
      await updateSettings(settings.copyWith(locale: locale));
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  final bool useMockServices;

  const AppConfig({
    this.useMockServices = false,
  });
}

final appConfigProvider = Provider<AppConfig>((ref) {
  // Change this to false to use real API services
  return const AppConfig(useMockServices: true);
});

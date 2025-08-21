import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_api_service.dart';

class ServiceStatus {
  final bool isConnected;
  final bool isMockService;
  final String message;

  const ServiceStatus({
    required this.isConnected,
    required this.isMockService,
    this.message = '',
  });

  bool get isReady => isConnected;
}

final serviceStatusProvider = Provider<ServiceStatus>((ref) {
  try {
    final mockService = ref.read(mockServiceProvider);
    return ServiceStatus(
      isConnected: true,
      isMockService: true,
      message: 'Connected to mock service',
    );
  } catch (e) {
    return ServiceStatus(
      isConnected: false,
      isMockService: false,
      message: 'Service not available: $e',
    );
  }
});

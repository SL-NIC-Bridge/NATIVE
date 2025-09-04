import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      body: config.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load app configuration'),
              ElevatedButton(
                onPressed: () => ref.refresh(appConfigProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (_) {
          // Config loaded, now check auth state
          final authState = ref.watch(authStateProvider);
          
          Future.microtask(() {
            if (context.mounted) {
              authState.when(
                data: (state) {
                  final isAuthenticated = state.isAuthenticated;
                  context.go(isAuthenticated ? AppRoutes.dashboard : AppRoutes.login);
                },
                loading: () {
                  // Stay on splash while loading
                },
                error: (error, stack) {
                  // Go to login on auth error
                  context.go(AppRoutes.login);
                },
              );
            }
          });

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
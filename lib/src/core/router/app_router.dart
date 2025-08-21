import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/application/screens/dashboard_screen.dart';
import '../../features/application/screens/application_form_screen.dart';
import '../../features/application/screens/dynamic_form_screen.dart';
import '../../features/application/screens/application_status_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/edit_profile_screen.dart';
import '../../features/settings/screens/change_password_screen.dart';
import '../../shared/screens/splash_screen.dart';
import '../constants/app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Get auth state - this might be loading
      final authStateAsync = ref.read(authStateProvider);
      
      // Always show splash if auth is loading or has error initially
      if (authStateAsync.isLoading) {
        return AppRoutes.splash;
      }
      
      if (authStateAsync.hasError) {
        // Only redirect to login from splash, not from other routes to avoid loops
        if (state.matchedLocation == AppRoutes.splash) {
          return AppRoutes.login;
        }
        return null; // Let the route handle the error
      }
      
      final authState = authStateAsync.value;
      final isLoggedIn = authState?.isAuthenticated ?? false;
      final currentLocation = state.matchedLocation;
      
      // Route classifications
      final isAuthRoute = currentLocation == AppRoutes.login || 
                         currentLocation == AppRoutes.register;
      final isSplash = currentLocation == AppRoutes.splash;
      final isPublicRoute = isAuthRoute || isSplash;
      
      // Redirect logic
      if (!isLoggedIn && !isPublicRoute) {
        // Not logged in, trying to access protected route
        return AppRoutes.login;
      }
      
      if (isLoggedIn && isAuthRoute) {
        // Logged in, trying to access auth routes
        return AppRoutes.dashboard;
      }
      
      if (isLoggedIn && isSplash) {
        // Logged in, on splash - go to dashboard
        return AppRoutes.dashboard;
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.applicationForm,
        builder: (context, state) => const ApplicationFormScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.dynamicForm}/:formType',
        builder: (context, state) => DynamicFormScreen(
          formType: state.pathParameters['formType']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.applicationStatus,
        builder: (context, state) => const ApplicationStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
    ],
  );
});

// Alternative approach: Use a router notifier for better control
final appRouterProvider2 = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.applicationForm,
        builder: (context, state) => const ApplicationFormScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.dynamicForm}/:formType',
        builder: (context, state) => DynamicFormScreen(
          formType: state.pathParameters['formType']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.applicationStatus,
        builder: (context, state) => const ApplicationStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterNotifier(this._ref) {
    // Listen to auth changes and notify router to refresh
    _ref.listen<AsyncValue>(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
  
  String? redirect(BuildContext context, GoRouterState state) {
    final authStateAsync = _ref.read(authStateProvider);
    
    // Show splash while loading
    if (authStateAsync.isLoading) {
      return state.matchedLocation == AppRoutes.splash ? null : AppRoutes.splash;
    }
    
    // Handle errors by going to login (but only from splash to avoid loops)
    if (authStateAsync.hasError) {
      return state.matchedLocation == AppRoutes.splash ? AppRoutes.login : null;
    }
    
    final isLoggedIn = authStateAsync.value?.isAuthenticated ?? false;
    final currentLocation = state.matchedLocation;
    
    final isAuthRoute = currentLocation == AppRoutes.login || 
                       currentLocation == AppRoutes.register;
    final isSplash = currentLocation == AppRoutes.splash;
    
    if (!isLoggedIn && !isAuthRoute && !isSplash) {
      return AppRoutes.login;
    }
    
    if (isLoggedIn && (isAuthRoute || isSplash)) {
      return AppRoutes.dashboard;
    }
    
    return null;
  }
}
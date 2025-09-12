import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sl_nic_bridge/src/features/application/models/application_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/application_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/router/route_observer.dart';
import '../../../shared/widgets/custom_button.dart';
import '../widgets/application_status_card.dart';

// Use a ConsumerStatefulWidget for dashboard
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver, RouteAware {
  bool _isFirstLoad = true;
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister from lifecycle events
    WidgetsBinding.instance.removeObserver(this);
    // Unsubscribe from route observer if we were subscribed
    if (_routeObserver != null) {
      _routeObserver!.unsubscribe(this);
    }
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app is resumed from background
    if (state == AppLifecycleState.resumed) {
      _refreshApplicationStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Subscribe to route observer for navigation events
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Store the observer instance for later unsubscription
      _routeObserver = ref.read(routeObserverProvider);
      _routeObserver!.subscribe(this, route);
    }
    
    // Refresh on first load
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _refreshApplicationStatus();
    }
  }
  
  // Called when the current route has been pushed and the navigator is now displaying this route
  @override
  void didPush() {
    _refreshApplicationStatus();
  }

  // Called when this route is visible again after being covered by another route
  @override
  void didPopNext() {
    _refreshApplicationStatus();
  }
  
  void _refreshApplicationStatus() {
    // Refresh application status data
    ref.invalidate(applicationStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final applicationState = ref.watch(applicationStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshApplicationStatus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${authState.value?.user?.fullName ?? 'User'}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your NIC application process from here.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Application Status Section
              Text(
                'Application Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              applicationState.when(
                data: (application) {
                  if (application == null) {
                    // No Application
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Active Application',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your NIC application process today.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              onPressed: () => context.push(AppRoutes.applicationForm),
                              text: 'Start New Application',
                              icon: Icons.add,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Has Application
                    return ApplicationStatusCard(
                      application: application,
                      onViewStatus: () => context.push(AppRoutes.applicationStatus),
                      onStartNew: application.status == ApplicationStatus.rejected
                          ? () => context.push(AppRoutes.applicationForm)
                          : null,
                    );
                  }
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load application status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          onPressed: () => _refreshApplicationStatus(),
                          text: 'Retry',
                          type: ButtonType.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _QuickActionCard(
                    icon: Icons.person,
                    title: 'Edit Profile',
                    subtitle: 'Update your details',
                    onTap: () => context.push('${AppRoutes.settings}/edit-profile'),
                  ),
                  _QuickActionCard(
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Secure your account',
                    onTap: () => context.push('${AppRoutes.settings}/change-password'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
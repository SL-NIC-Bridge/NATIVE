import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sl_nic_bridge/src/features/application/models/application_model.dart';
import '../providers/application_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/router/route_observer.dart';
import '../../../shared/widgets/custom_button.dart';

class ApplicationStatusScreen extends ConsumerStatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  ConsumerState<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends ConsumerState<ApplicationStatusScreen> with WidgetsBindingObserver, RouteAware {
  bool _isFirstLoad = true;
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);
    // We'll refresh in didChangeDependencies instead
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

  // Use this method for initial load and subsequent dependency changes
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
    
    // On first load or when returning to this screen
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
    ref.invalidate(applicationStatusProvider);
    log('Application status refreshed');
  }
  
  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(applicationStatusProvider);
    log(applicationState.toString());


    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshApplicationStatus();
        },
        child: applicationState.when(
        data: (application) {
          if (application == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Application Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a new application to begin the process.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: CustomButton(
                      onPressed: () => context.push(AppRoutes.applicationForm),
                      text: 'Start New Application',
                      icon: Icons.add,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(
                title: 'Application ID',
                content: application.id.toUpperCase(),
                icon: Icons.tag,
              ),
              const SizedBox(height: 16),
              _StatusCard(
                title: 'Current Status',
                content: application.status.toString().split('.').last.toUpperCase(),
                icon: Icons.info_outline,
                color: _getStatusColor(application.status),
              ),
              const SizedBox(height: 16),
              _StatusCard(
                title: 'Submitted On',
                content: application.submittedAt != null 
                  ? _formatDate(application.submittedAt!) 
                  : 'Not available',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              _StatusCard(
                title: 'Last Updated',
                content: _formatDate(application.updatedAt),
                icon: Icons.update,
              ),
              if (application.comments?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                _StatusCard(
                  title: 'Comments',
                  content: application.comments!,
                  icon: Icons.comment,
                ),
              ],
              const SizedBox(height: 24),
              if (application.status == ApplicationStatus.rejected)
                CustomButton(
                  onPressed: () => context.push(AppRoutes.applicationForm),
                  text: 'Start New Application',
                  icon: Icons.add,
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          // Handle specific errors
          final appError = AppError.handle(error, stack);
          IconData errorIcon;
          String errorTitle;

          switch (appError.type) {
            case ErrorType.network:
              errorIcon = Icons.wifi_off;
              errorTitle = 'Network Error';
              break;
            case ErrorType.unauthorized:
              errorIcon = Icons.lock;
              errorTitle = 'Authentication Error';
              break;
            case ErrorType.forbidden:
              errorIcon = Icons.block;
              errorTitle = 'Access Denied';
              break;
            case ErrorType.notFound:
              errorIcon = Icons.search_off;
              errorTitle = 'Not Found';
              break;
            default:
              errorIcon = Icons.error_outline;
              errorTitle = 'Error';
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  errorIcon,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  errorTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    appError.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: () => ref.invalidate(applicationStatusProvider),
                  text: 'Retry',
                  type: ButtonType.secondary,
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format: DD MMM YYYY, hh:mm a (e.g., 13 Sep 2025, 02:30 PM)
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    final year = date.year;
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }
  
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.onHold:
        return Colors.orange;
      case ApplicationStatus.underReview:
        return Colors.blue;
      case ApplicationStatus.completed:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color? color;

  const _StatusCard({
    required this.title,
    required this.content,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
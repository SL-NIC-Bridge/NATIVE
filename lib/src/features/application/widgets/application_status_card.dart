import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../../../shared/widgets/custom_button.dart';

class ApplicationStatusCard extends StatelessWidget {
  final Application application;
  final VoidCallback onViewStatus;
  final VoidCallback? onStartNew;

  const ApplicationStatusCard({
    super.key,
    required this.application,
    required this.onViewStatus,
    this.onStartNew,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Application #${application.id}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(application.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    application.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(application.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getStatusIcon(application.status),
                  color: _getStatusColor(application.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(application.status),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Updated: ${_formatDate(application.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomButton(
              onPressed: onViewStatus,
              text: 'View Status',
              type: ButtonType.text,
              icon: Icons.visibility,
            ),
            if (onStartNew != null) ...[
              const SizedBox(height: 12),
              CustomButton(
                onPressed: onStartNew,
                text: 'Start New',
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return Colors.grey;
      case ApplicationStatus.submitted:
        return Colors.blue;
      case ApplicationStatus.underReview:
        return Colors.orange;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return Icons.edit;
      case ApplicationStatus.submitted:
        return Icons.send;
      case ApplicationStatus.underReview:
        return Icons.hourglass_empty;
      case ApplicationStatus.approved:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Draft - Complete your application';
      case ApplicationStatus.submitted:
        return 'Submitted - Under review';
      case ApplicationStatus.underReview:
        return 'Under Review - Being processed';
      case ApplicationStatus.approved:
        return 'Approved - Congratulations!';
      case ApplicationStatus.rejected:
        return 'Rejected - Please review';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
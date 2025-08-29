import 'package:sl_nic_bridge/src/core/config/field_dependency.dart';
import 'package:sl_nic_bridge/src/core/config/form_config_model.dart';

/// Evaluates the visibility and enabled state of a form field based on its dependencies.
class DependencyEvaluator {
  final Map<String, dynamic> formState;

  DependencyEvaluator(this.formState);

  /// Checks if a field should be visible.
  bool isVisible(FormField field) {
    if (field.dependencies == null || field.dependencies!.isEmpty) {
      return true;
    }

    final hideDependencies =
        field.dependencies!.where((d) => d.behavior == DependencyBehavior.hide).toList();

    if (hideDependencies.isNotEmpty) {
      // If 'hide' rules exist, the field is shown by default and only hidden if a condition is met.
      return hideDependencies.any((dep) => _isConditionMet(dep));
    }

    return true;
  }

  /// Checks if a field should be enabled.
  bool isEnabled(FormField field) {
    if (field.dependencies == null || field.dependencies!.isEmpty) {
      return true;
    }

    final disableDependencies =
        field.dependencies!.where((d) => d.behavior == DependencyBehavior.disable).toList();

    if (disableDependencies.isNotEmpty) {
      // If 'disable' rules exist, the field is disabled by default and enabled if any condition is met.
      return disableDependencies.any((dep) => _isConditionMet(dep));
    }

    return true;
  }

  /// Evaluates if a single dependency condition is met based on the current form state.
  bool _isConditionMet(FieldDependencyCondition dep) {
    final actualValue = formState[dep.field];
    final conditionValue = dep.value;

    // Handle boolean dependencies (e.g., from checkboxes/switches) where null is treated as false.
    if (conditionValue is bool) {
      final actualBool = actualValue == true;
      if (dep.condition == 'equals') return actualBool == conditionValue;
      if (dep.condition == 'notEquals') return actualBool != conditionValue;
    }

    if (actualValue == null) return false;

    switch (dep.condition) {
      case 'equals':
        return actualValue.toString() == conditionValue.toString();
      case 'notEquals':
        return actualValue.toString() != conditionValue.toString();
      case 'contains':
        if (actualValue is List) {
          // For multi-select checkboxes
          return actualValue.map((e) => e.toString()).contains(conditionValue.toString());
        }
        if (actualValue is String) {
          // For text fields
          return actualValue.contains(conditionValue.toString());
        }
        return false;
      default:
        return false;
    }
  }
}


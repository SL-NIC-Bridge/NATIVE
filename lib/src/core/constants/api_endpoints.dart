class ApiEndpoints {
  // Base paths
  static const String auth = '/auth';
  static const String applications = '/applications';
  static const String forms = '/forms';
  static const String users = '/users';
  static const String divisions = '/divisions';
  
  // Authentication endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh-token';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String changePassword = '$auth/change-password';
  static const String profile = '$auth/profile';
  static const String updateProfile = '$auth/profile';
  
  // Application endpoints
  static const String submitApplication = '$applications';
  static const String getApplications = '$applications';
  static const String getCurrentApplication = '$applications/current';
  static String getApplicationById(String id) => '$applications/$id';
  static String updateApplicationStatus(String id) => '$applications/$id/status';
  static String getApplicationsByStatus(String status) => '$applications?status=$status';
  
  // Form endpoints
  static const String getFormTypes = '$forms/types';
  static String getFormConfig(String formType) => '$forms/$formType/config';
  static const String validateFormData = '$forms/validate';
  
  // Document endpoints
  static const String uploadDocument = '/documents/upload';
  static String getDocument(String documentId) => '/documents/$documentId';
  static String deleteDocument(String documentId) => '/documents/$documentId';
  
  // Workflow endpoints
  static const String getWorkflowSteps = '/workflow/steps';
  static String updateWorkflowStep(String stepId) => '/workflow/steps/$stepId';
  
  // Admin endpoints (if needed)
  static const String adminApplications = '/admin/applications';
  static const String adminUsers = '/admin/users';
  static const String adminStats = '/admin/statistics';
}

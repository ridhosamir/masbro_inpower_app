// File: utils/constants.dart

class Constants {
  // User roles
  static const String ROLE_EMPLOYEE = 'employee';
  static const String ROLE_OFFICER = 'officer';
  static const String ROLE_TECHNICIAN = 'technician';
  static const String ROLE_ADMIN = 'admin';

  // Report statuses
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_APPROVED = 'approved';
  static const String STATUS_REJECTED = 'rejected';
  static const String STATUS_IN_PROGRESS = 'in_progress';
  static const String STATUS_COMPLETED = 'completed';

  // Task priorities
  static const String PRIORITY_LOW = 'low';
  static const String PRIORITY_MEDIUM = 'medium';
  static const String PRIORITY_HIGH = 'high';
  static const String PRIORITY_URGENT = 'urgent';

  // Collection names
  static const String COLLECTION_USERS = 'users';
  static const String COLLECTION_REPORTS = 'reports';
  static const String COLLECTION_TASKS = 'tasks';

  // Other constants
  static const int PAGINATION_LIMIT = 20;
}

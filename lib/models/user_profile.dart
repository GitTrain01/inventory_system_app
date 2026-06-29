class Profile {
  final String id;
  final String? fullName;
  final String? email;
  final String role; // 'admin' or 'staff'
  final String? branchId;
  final bool canAccessDashboard;
  final bool canAccessDelivery;
  final bool canAccessSales;
  final bool canAccessExpenses;
  final bool canAccessReports;

  const Profile({
    required this.id,
    this.fullName,
    this.email,
    required this.role,
    required this.branchId,
    this.canAccessDashboard = true,
    this.canAccessDelivery = false,
    this.canAccessSales = false,
    this.canAccessExpenses = false,
    this.canAccessReports = true,
  });

  bool get isAdmin => role == 'admin';

  /// Admin sees everything; staff gated by flag.
  bool can(String module) {
    if (isAdmin) return true;
    switch (module) {
      case 'dashboard': return canAccessDashboard;
      case 'delivery':  return canAccessDelivery;
      case 'sales':     return canAccessSales;
      case 'expenses':  return canAccessExpenses;
      case 'reports':   return canAccessReports;
      default:          return false;
    }
  }

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        fullName: j['full_name'] as String?,
        email: j['email'] as String?,
        role: (j['role'] ?? 'staff') as String,
        branchId: j['branch_id'] as String?,
        canAccessDashboard: (j['can_access_dashboard'] ?? true) as bool,
        canAccessDelivery: (j['can_access_delivery'] ?? false) as bool,
        canAccessSales: (j['can_access_sales'] ?? false) as bool,
        canAccessExpenses: (j['can_access_expenses'] ?? false) as bool,
        canAccessReports: (j['can_access_reports'] ?? true) as bool,
      );
}
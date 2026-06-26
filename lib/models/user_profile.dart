class Profile {
  final String id;
  final String role;          // 'admin' or 'staff'
  final String? branchId;
  final bool canAccessSales;
  final bool canAccessDelivery;
  final bool canAccessExpenses;
  final bool canAccessProducts;
  final bool canAccessReports;

  const Profile({
    required this.id,
    required this.role,
    required this.branchId,
    this.canAccessSales = false,
    this.canAccessDelivery = false,
    this.canAccessExpenses = false,
    this.canAccessProducts = false,
    this.canAccessReports = false,
  });

  bool get isAdmin => role == 'admin';

  // ⚠️ These keys must match your user_profiles COLUMN names exactly.
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        role: (json['role'] ?? 'staff') as String,
        branchId: json['branch_id'] as String?,
        canAccessSales: (json['can_access_sales'] ?? false) as bool,
        canAccessDelivery: (json['can_access_delivery'] ?? false) as bool,
        canAccessExpenses: (json['can_access_expenses'] ?? false) as bool,
        canAccessProducts: (json['can_access_products'] ?? false) as bool,
        canAccessReports: (json['can_access_reports'] ?? false) as bool,
      );
}
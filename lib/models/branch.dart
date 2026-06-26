class Branch {
  final String id;
  final String name;
  final String? address;
  final bool isActive;
  final bool nightShiftEnabled;

  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.isActive = true,
    this.nightShiftEnabled = false,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        isActive: (json['is_active'] ?? true) as bool,
        nightShiftEnabled: (json['night_shift_enabled'] ?? false) as bool,
      );
}
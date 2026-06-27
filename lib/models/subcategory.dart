class Subcategory {
  final String id;
  final String branchId;
  final String name;
  final int sortOrder;

  const Subcategory({
    required this.id,
    required this.branchId,
    required this.name,
    this.sortOrder = 0,
  });

  factory Subcategory.fromJson(Map<String, dynamic> j) => Subcategory(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        name: j['name'] as String,
        sortOrder: (j['sort_order'] ?? 0) as int,
      );
}
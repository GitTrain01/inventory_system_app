import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A shimmering placeholder list shown while real data loads.
/// Render this in place of a spinner; it mimics ListTile rows.
class SkeletonList extends StatelessWidget {
  final int rows;
  final bool hasTrailing;
  const SkeletonList({super.key, this.rows = 8, this.hasTrailing = true});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        itemCount: rows,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, __) => ListTile(
          title: const Text('Product placeholder name'),
          subtitle: const Text('Some secondary detail line here'),
          trailing: hasTrailing
              ? const Text('₱000.00', style: TextStyle(fontWeight: FontWeight.w600))
              : null,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      'Checked In' => (const Color(0xFF147D53), const Color(0xFFE3F7EE)),
      'Checked Out' => (const Color(0xFF5C6472), const Color(0xFFECEFF3)),
      _ => (const Color(0xFF9A6500), const Color(0xFFFFF3D6)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          status,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

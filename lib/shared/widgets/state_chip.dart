import 'package:flutter/material.dart';

class PickingStateChip extends StatelessWidget {
  const PickingStateChip({super.key, required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor(state);
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  (String, Color) _labelAndColor(String state) {
    return switch (state) {
      'draft' => ('Borrador', Colors.grey),
      'waiting' => ('En espera', Colors.orange),
      'confirmed' => ('Confirmado', Colors.blue),
      'assigned' => ('Listo', Colors.indigo),
      'done' => ('Hecho', Colors.green),
      'cancel' => ('Cancelado', Colors.red),
      _ => (state, Colors.blueGrey),
    };
  }
}

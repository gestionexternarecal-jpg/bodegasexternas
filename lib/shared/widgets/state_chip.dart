import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';

class PickingStateChip extends StatelessWidget {
  const PickingStateChip({super.key, required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final (label, color) = _labelAndColor(state, semantic);
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  (String, Color) _labelAndColor(String state, AppSemanticColors semantic) {
    return switch (state) {
      'draft' => ('Borrador', semantic.neutral),
      'waiting' => ('En espera', semantic.pending),
      'confirmed' => ('Confirmado', semantic.active),
      'assigned' => ('Listo', semantic.info),
      'done' => ('Hecho', semantic.success),
      'cancel' => ('Cancelado', semantic.danger),
      _ => (state, semantic.neutral),
    };
  }
}

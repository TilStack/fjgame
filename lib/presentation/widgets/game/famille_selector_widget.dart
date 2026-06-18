// Sélecteur de famille : chips horizontaux scrollables.

import 'package:flutter/material.dart';
import '../../../domain/models/famille.dart';

class FamilleSelectorWidget extends StatelessWidget {
  final List<Famille> familles;
  final Famille? familleSelectee;
  final void Function(Famille) onSelect;

  const FamilleSelectorWidget({
    super.key,
    required this.familles,
    required this.familleSelectee,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: familles.map((f) {
          final selected = familleSelectee?.id == f.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.nom),
              selected: selected,
              onSelected: (_) => onSelect(f),
              selectedColor: primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : primary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(color: primary),
              backgroundColor: Colors.transparent,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

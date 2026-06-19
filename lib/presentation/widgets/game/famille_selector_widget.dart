// Sélecteur de famille : chips horizontaux scrollables avec animation de scale à la sélection.

import 'package:flutter/material.dart';

import '../../../domain/models/famille.dart';

class FamilleSelectorWidget extends StatefulWidget {
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
  State<FamilleSelectorWidget> createState() => _FamilleSelectorWidgetState();
}

class _FamilleSelectorWidgetState extends State<FamilleSelectorWidget> {
  String? _animatingId;

  void _handleSelect(Famille f) {
    widget.onSelect(f);
    setState(() => _animatingId = f.id);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _animatingId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.familles.map((f) {
          final selected = widget.familleSelectee?.id == f.id;
          final isAnimating = _animatingId == f.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 1.0, end: isAnimating ? 1.04 : 1.0),
              curve: Curves.easeInOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: FilterChip(
                label: Text(f.nom),
                selected: selected,
                onSelected: (_) => _handleSelect(f),
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
            ),
          );
        }).toList(),
      ),
    );
  }
}

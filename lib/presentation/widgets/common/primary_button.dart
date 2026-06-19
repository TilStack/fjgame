// Bouton principal réutilisable avec deux variantes : filled et outlined.
// Supporte l'état de chargement (animation 3 points) et l'état désactivé (opacité 0.5).

import 'dart:math';

import 'package:flutter/material.dart';

enum PrimaryButtonVariant { filled, outlined }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = PrimaryButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final PrimaryButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDisabled = onPressed == null || isLoading;

    final child = isLoading ? const _DotsLoading() : Text(label);

    final button = switch (variant) {
      PrimaryButtonVariant.filled => FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: child,
        ),
      PrimaryButtonVariant.outlined => OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: child,
        ),
    };

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: button,
    );
  }
}

class _DotsLoading extends StatefulWidget {
  const _DotsLoading();

  @override
  State<_DotsLoading> createState() => _DotsLoadingState();
}

class _DotsLoadingState extends State<_DotsLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i / 3.0) % 1.0;
            final bump = max(0.0, sin(phase * pi));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              transform: Matrix4.translationValues(0, -6 * bump, 0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4 + 0.6 * bump),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

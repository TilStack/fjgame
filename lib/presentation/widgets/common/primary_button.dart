// Bouton principal réutilisable avec deux variantes : filled et outlined.
// Supporte l'état de chargement (spinner blanc) et l'état désactivé (opacité 0.5).

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

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Text(label);

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

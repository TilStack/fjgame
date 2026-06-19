// Grille 2 colonnes de mini cartes (main du joueur actif).
// Tap sur une carte ouvre CardPeekOverlay.

import 'package:flutter/material.dart';
import '../../../domain/models/famille.dart';
import 'card_peek_overlay.dart';
import 'carte_mini_widget.dart';

class PlayerHandGridWidget extends StatefulWidget {
  const PlayerHandGridWidget({
    super.key,
    required this.personnages,
    required this.familles,
    this.onDescripteurSelected,
  });

  final List<Personnage> personnages;
  final List<Famille> familles;
  final void Function(Descripteur)? onDescripteurSelected;

  @override
  State<PlayerHandGridWidget> createState() => _PlayerHandGridWidgetState();
}

class _PlayerHandGridWidgetState extends State<PlayerHandGridWidget> {
  Personnage? _selected;
  final Map<int, GlobalKey> _keys = {};

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.personnages.length,
      itemBuilder: (context, i) {
        final p = widget.personnages[i];
        final famille = widget.familles.firstWhere((f) => f.id == p.familleId);
        _keys[i] ??= GlobalKey();

        return CarteMiniWidget(
          key: _keys[i],
          personnage: p,
          famille: famille,
          isSelected: _selected?.id == p.id,
          onTap: () => _openPeek(context, i, p, famille),
        );
      },
    );
  }

  void _openPeek(BuildContext ctx, int i, Personnage p, Famille famille) {
    final renderBox =
        _keys[i]!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final sourceRect = position & renderBox.size;

    setState(() => _selected = p);

    CardPeekOverlay.show(
      context: ctx,
      sourceRect: sourceRect,
      personnage: p,
      famille: famille,
      onDescripteurSelected: (d) {
        if (mounted) setState(() => _selected = null);
        widget.onDescripteurSelected?.call(d);
      },
      onClose: () {
        if (mounted) setState(() => _selected = null);
      },
    );
  }
}

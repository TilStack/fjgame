// Écran de configuration de la partie locale : saisie des noms de joueurs (3–6).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

class LobbyLocalScreen extends ConsumerStatefulWidget {
  const LobbyLocalScreen({super.key});

  @override
  ConsumerState<LobbyLocalScreen> createState() => _LobbyLocalScreenState();
}

class _LobbyLocalScreenState extends ConsumerState<LobbyLocalScreen> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_controllers.length >= 6) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removePlayer(int index) {
    if (_controllers.length <= 3) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  Future<void> _startGame(AppLocalizations l10n) async {
    final noms = _controllers.map((c) => c.text.trim()).toList();

    if (noms.any((n) => n.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.minPlayers)),
      );
      return;
    }

    await ref.read(gameNotifierProvider.notifier).demarrerPartieLocale(noms);

    if (!mounted) return;
    final state = ref.read(gameNotifierProvider);
    if (state.erreur != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.erreur!)),
      );
    } else {
      context.go('/game/transition');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final isLoading = ref.watch(gameNotifierProvider).isLoading;
    final canAdd = _controllers.length < 6;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playLocal),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.players,
              style: AppTextStyles.cinzel(fontSize: 22, color: primary),
            ),
            const SizedBox(height: 20),
            ...List.generate(_controllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _controllers[i],
                        labelText: l10n.playerName(i + 1),
                        hintText: l10n.playerName(i + 1),
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                    if (i >= 3) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _removePlayer(i),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: Text(l10n.removePlayer),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            PrimaryButton(
              label: l10n.addPlayer,
              variant: PrimaryButtonVariant.outlined,
              onPressed: canAdd ? _addPlayer : null,
            ),
            if (!canAdd)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.maxPlayers,
                  style: AppTextStyles.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: l10n.startGame,
              isLoading: isLoading,
              onPressed: isLoading ? null : () => _startGame(l10n),
            ),
          ],
        ),
      ),
    );
  }
}

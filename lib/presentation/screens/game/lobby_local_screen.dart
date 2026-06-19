// Écran de configuration de la partie locale : saisie des noms de joueurs (3–6).
// Champs animés avec flutter_animate. Avatar coloré en préfixe.
// Suppression par icône close avec slideX+fadeOut 200ms.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/game/distribution_animation_widget.dart';

class LobbyLocalScreen extends ConsumerStatefulWidget {
  const LobbyLocalScreen({super.key});

  @override
  ConsumerState<LobbyLocalScreen> createState() => _LobbyLocalScreenState();
}

class _LobbyLocalScreenState extends ConsumerState<LobbyLocalScreen> {
  final List<TextEditingController> _controllers = [];

  static const _avatarColors = [
    Color(0xFFFF1744), Color(0xFF1E88E5), Color(0xFF43A047),
    Color(0xFFFB8C00), Color(0xFF8E24AA), Color(0xFF00ACC1),
  ];

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
        SnackBar(content: Text(l10n.minPlayers)));
      return;
    }
    await ref.read(gameNotifierProvider.notifier).demarrerPartieLocale(noms);
    if (!mounted) return;
    final state = ref.read(gameNotifierProvider);
    if (state.erreur != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.erreur!)));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dCtx) => DistributionAnimationWidget(
        nombreJoueurs: noms.length,
        nombreCartesTotal: 52,
        onAnimationComplete: () => Navigator.of(dCtx).pop(),
      ),
    );
    if (!mounted) return;
    context.go('/game/transition');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isLoading = ref.watch(gameNotifierProvider).isLoading;
    final canAdd = _controllers.length < 6;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: isDark
            ? AppTheme.gameAppBarThemeDark
            : AppTheme.gameAppBarThemeLight,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.playLocal),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 48, color: primary)
                  .animate()
                  .fadeIn(duration: reduceMotion ? Duration.zero : 300.ms),
              const SizedBox(height: 16),
              Text(
                l10n.players,
                style: AppTextStyles.cinzel(fontSize: 22, color: primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '3 – 6',
                style: AppTextStyles.inter(fontSize: 12, color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Champs joueurs animés
              ...List.generate(_controllers.length, (i) {
                final avatarColor = _avatarColors[i % _avatarColors.length];
                final letter = String.fromCharCode(65 + i); // A, B, C...
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          decoration: InputDecoration(
                            labelText: l10n.playerName(i + 1),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: avatarColor,
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            suffixIcon: i >= 3
                                ? IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 18, color: AppColors.error),
                                    onPressed: () => _removePlayer(i),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(
                          duration: reduceMotion ? Duration.zero : 250.ms,
                          delay: reduceMotion ? Duration.zero : Duration(milliseconds: 100 * i))
                      .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: reduceMotion ? Duration.zero : 250.ms,
                          delay: reduceMotion ? Duration.zero : Duration(milliseconds: 100 * i)),
                );
              }),

              const SizedBox(height: 16),

              // Bouton ajouter (visible si < 6)
              if (canAdd)
                GestureDetector(
                  onTap: _addPlayer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 20, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.addPlayer,
                        style:
                            AppTextStyles.inter(fontSize: 13, color: primary),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: reduceMotion ? Duration.zero : 200.ms),

              const SizedBox(height: 24),
              PrimaryButton(
                label: l10n.startGame,
                isLoading: isLoading,
                onPressed: isLoading ? null : () => _startGame(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

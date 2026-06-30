// Écran de lobby en ligne : créer une salle ou rejoindre via un code à 6 caractères.
// Deux sections côte à côte (Wrap adaptif) : Créer avec SegmentedButton 3-6 joueurs,
// Rejoindre avec champ code MAJUSCULES. Gestion isLoading + SnackBar erreur.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/online_game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  int _maxPlayers = 4;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _localizeError(AppLocalizations l10n, String key) => switch (key) {
        'roomNotFound' => l10n.roomNotFound,
        'roomFull' => l10n.roomFull,
        'gameAlreadyStarted' => l10n.gameAlreadyStarted,
        _ => key,
      };

  Future<void> _createRoom() async {
    final notifier = ref.read(onlineGameNotifierProvider.notifier);
    await notifier.createRoom(_maxPlayers);
    if (!mounted) return;
    final state = ref.read(onlineGameNotifierProvider);
    if (state.roomId != null) {
      context.go('/room/${state.roomId}');
    }
  }

  Future<void> _joinRoom(AppLocalizations l10n) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final notifier = ref.read(onlineGameNotifierProvider.notifier);
    await notifier.joinRoom(code);
    if (!mounted) return;
    final state = ref.read(onlineGameNotifierProvider);
    if (state.roomId != null) {
      context.go('/room/${state.roomId}');
    }
  }

  void _showErrorIfNeeded(AppLocalizations l10n, String? erreur) {
    if (erreur == null) return;
    final msg = _localizeError(l10n, erreur);
    ref.read(onlineGameNotifierProvider.notifier).clearErreur();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final state = ref.watch(onlineGameNotifierProvider);

    // Show SnackBar on error (post-frame to avoid build-time setState)
    if (state.erreur != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showErrorIfNeeded(l10n, state.erreur);
      });
    }

    final isLoading = state.isLoading;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: isDark
            ? AppTheme.gameAppBarThemeDark
            : AppTheme.gameAppBarThemeLight,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.playOnline,
            style: AppTextStyles.cinzel(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Icône + titre + sous-titre ──────────────────────────
                    reduceMotion
                        ? Icon(Icons.wifi, size: 48, color: primary)
                        : Icon(Icons.wifi, size: 48, color: primary)
                            .animate()
                            .fadeIn(duration: 400.ms),
                    const SizedBox(height: 14),
                    reduceMotion
                        ? Text(
                            l10n.playOnline,
                            style:
                                AppTextStyles.cinzel(fontSize: 22, color: primary),
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            l10n.playOnline,
                            style:
                                AppTextStyles.cinzel(fontSize: 22, color: primary),
                            textAlign: TextAlign.center,
                          )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms),
                    const SizedBox(height: 6),
                    Text(
                      l10n.onlineSubtitle,
                      style:
                          AppTextStyles.inter(fontSize: 12, color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Deux sections : Créer | Rejoindre ──────────────────
                    Wrap(
                      spacing: 16,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        // ── Section Créer ──────────────────────────────────
                        _SectionCard(
                          color: surfaceColor,
                          borderColor: borderColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.createRoom,
                                style: AppTextStyles.cinzel(
                                  fontSize: 15,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.createRoomHint,
                                style: AppTextStyles.inter(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.players,
                                style: AppTextStyles.inter(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(value: 3, label: Text('3')),
                                  ButtonSegment(value: 4, label: Text('4')),
                                  ButtonSegment(value: 5, label: Text('5')),
                                  ButtonSegment(value: 6, label: Text('6')),
                                ],
                                selected: {_maxPlayers},
                                onSelectionChanged: (val) =>
                                    setState(() => _maxPlayers = val.first),
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(height: 20),
                              PrimaryButton(
                                label: l10n.createRoom,
                                onPressed: isLoading ? null : _createRoom,
                              ),
                            ],
                          ),
                        ),

                        // ── Section Rejoindre ──────────────────────────────
                        _SectionCard(
                          color: surfaceColor,
                          borderColor: borderColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.joinRoom,
                                style: AppTextStyles.cinzel(
                                  fontSize: 15,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.joinRoomHint,
                                style: AppTextStyles.inter(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(6),
                                  UpperCaseTextFormatter(),
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.roomCode,
                                ),
                              ),
                              const SizedBox(height: 20),
                              PrimaryButton(
                                label: l10n.joinRoom,
                                variant: PrimaryButtonVariant.outlined,
                                onPressed: isLoading
                                    ? null
                                    : () => _joinRoom(l10n),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Carte de section avec bordure arrondie.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

/// Formateur qui convertit toute saisie en majuscules.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

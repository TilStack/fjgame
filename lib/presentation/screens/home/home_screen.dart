// Écran d'accueil redesigné : animation éventail, statut utilisateur, boutons d'action.
// SettingsBottomSheet accessible via icône engrenage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/auth_provider.dart';
import '../../../application/providers/locale_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/settings_bottom_sheet.dart';
import '../../widgets/home/home_animation_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Zone haute : actions AppBar transparente
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    color: textSecondary,
                    onPressed: () =>
                        ref.read(themeNotifierProvider.notifier).setTheme(
                              themeMode == ThemeMode.dark
                                  ? ThemeMode.light
                                  : ThemeMode.dark,
                            ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: textSecondary,
                    onPressed: () => SettingsBottomSheet.show(context),
                  ),
                ],
              ),
            ),

            // Zone centrale
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HomeAnimationWidget(),
                  const SizedBox(height: 32),

                  // Statut utilisateur
                  if (user != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AvatarWidget(
                            pseudo: user.pseudo,
                            avatarColor: user.avatarColor,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.pseudo,
                                style: AppTextStyles.inter(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!user.isAnonymous)
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.onlineStatus,
                                      style: AppTextStyles.inter(
                                        fontSize: 11,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                GestureDetector(
                                  onTap: () => context.go('/register'),
                                  child: Text(
                                    l10n.signUp,
                                    style: AppTextStyles.inter(
                                      fontSize: 11,
                                      color: primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Boutons d'action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: l10n.playLocal,
                          onPressed: () => context.go('/lobby-local'),
                        ),
                        const SizedBox(height: 16),
                        // Jouer en ligne — Coming soon
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Opacity(
                              opacity: 0.6,
                              child: PrimaryButton(
                                label: l10n.playOnline,
                                variant: PrimaryButtonVariant.outlined,
                                onPressed: null,
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  l10n.comingSoon,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Zone basse : version
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: Text(
                  l10n.appVersion,
                  style: AppTextStyles.inter(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.pseudo, required this.avatarColor});
  final String pseudo;
  final String avatarColor;

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFF1744);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(avatarColor);
    final letter = pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

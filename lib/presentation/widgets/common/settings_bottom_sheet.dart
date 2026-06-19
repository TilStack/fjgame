// BottomSheet de paramètres : thème, langue, sons. Accessible depuis HomeScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/locale_provider.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/sound_service.dart';
import '../../../l10n/app_localizations.dart';

class SettingsBottomSheet {
  const SettingsBottomSheet._();

  static void show(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => UncontrolledProviderScope(
        container: container,
        child: const _SettingsContent(),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent();

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  bool _soundEnabled = SoundService.instance.enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settings,
              style: AppTextStyles.cinzel(fontSize: 20, color: primary),
            ),
            const SizedBox(height: 20),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeNotifierProvider.notifier).setTheme(s.first),
            ),
            const SizedBox(height: 20),
            SegmentedButton<Locale>(
              segments: [
                ButtonSegment(
                  value: const Locale('fr'),
                  label: Text(l10n.languageFr),
                ),
                ButtonSegment(
                  value: const Locale('en'),
                  label: Text(l10n.languageEn),
                ),
              ],
              selected: {locale},
              onSelectionChanged: (s) =>
                  ref.read(localeNotifierProvider.notifier).setLocale(s.first),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _soundEnabled ? l10n.soundOn : l10n.soundOff,
                style: AppTextStyles.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              value: _soundEnabled,
              activeThumbColor: primary,
              onChanged: (v) {
                setState(() => _soundEnabled = v);
                SoundService.instance.setEnabled(v);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.appVersion,
                style: AppTextStyles.inter(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

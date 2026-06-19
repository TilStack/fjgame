// Écran de réinitialisation de mot de passe via Firebase Auth.
// Envoie un email de reset et redirige vers /login après succès.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/firebase_error_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset(AppLocalizations l10n) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.resetPasswordSent),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mapFirebaseAuthError(e.code)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.lock_reset, size: 64, color: primary),
            const SizedBox(height: 24),
            Text(
              l10n.forgotPassword,
              textAlign: TextAlign.center,
              style: AppTextStyles.cinzel(fontSize: 22, color: primary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.forgotPasswordExplain,
              textAlign: TextAlign.center,
              style: AppTextStyles.inter(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _emailCtrl,
              labelText: l10n.email,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.sendResetLink,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () => _sendReset(l10n),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/extensions/build_context_extension.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';
import 'package:shmuki_talk/features/auth/presentation/widgets/google_sign_in_button.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<dynamic>>(signInNotifierProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) => context.showSnack(error.toString(), isError: true),
      );
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
              AppColors.gradientAccent,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildLogo().animate().fadeIn(duration: 600.ms).slideY(
                      begin: -0.3,
                      end: 0,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 32),
                _buildTitle(context)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms),
                const SizedBox(height: 12),
                _buildSubtitle(context)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms),
                const Spacer(flex: 3),
                _buildFeatures(context)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),
                const Spacer(flex: 2),
                GoogleSignInButton(
                  onPressed: () => ref.read(signInNotifierProvider.notifier).signIn(),
                  isLoading: ref.watch(signInNotifierProvider).isLoading,
                ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideY(
                      begin: 0.3,
                      end: 0,
                    ),
                const SizedBox(height: 16),
                _buildPrivacyNote(context)
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 600.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.radio,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return const Text(
      AppStrings.appName,
      style: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      AppStrings.appTagline,
      style: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white.withOpacity(0.8),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      ('🎤', 'שדר בלחיצת כפתור'),
      ('👨‍👩‍👧‍👦', 'חדרים פרטיים לכל קבוצה'),
      ('⚡', 'תקשורת מיידית ואמינה'),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(f.$1, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                f.$2,
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return Text(
      'הקול שלך לעולם לא מוקלט או מאוחסן',
      style: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 12,
        color: Colors.white.withOpacity(0.5),
      ),
      textAlign: TextAlign.center,
    );
  }
}

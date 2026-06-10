import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shmuki_talk/core/extensions/build_context_extension.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/router/app_router.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';

class JoinRoomPage extends ConsumerStatefulWidget {
  final String? prefillCode;

  const JoinRoomPage({super.key, this.prefillCode});

  @override
  ConsumerState<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends ConsumerState<JoinRoomPage> {
  late final TextEditingController _codeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.prefillCode ?? '');
    if (widget.prefillCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _join());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;

    final room = await ref.read(joinRoomProvider.notifier).joinByCode(
          _codeController.text.trim().toUpperCase(),
        );

    if (!mounted) return;

    if (room != null) {
      context.go(AppRoutes.roomPath(room.id));
    } else {
      final error = ref.read(joinRoomProvider).error;
      context.showSnack(error?.toString() ?? AppStrings.errorOccurred, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(joinRoomProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.joinRoomTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.login,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.joinRoomTitle,
                style: context.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.enterInviteCode,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeController,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: 'FAMILY7',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    letterSpacing: 4,
                    color: AppColors.textHint.withOpacity(0.5),
                  ),
                  counterText: '',
                ),
                maxLength: 10,
                onChanged: (value) {
                  _codeController.value = _codeController.value.copyWith(
                    text: value.toUpperCase(),
                    selection: TextSelection.collapsed(offset: value.length),
                  );
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.enterInviteCode;
                  }
                  if (value.trim().length < 4) {
                    return AppStrings.invalidCode;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _join,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(AppStrings.join),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

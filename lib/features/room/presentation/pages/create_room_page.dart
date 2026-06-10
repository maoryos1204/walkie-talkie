import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shmuki_talk/core/constants/app_constants.dart';
import 'package:shmuki_talk/core/extensions/build_context_extension.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/router/app_router.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';

class CreateRoomPage extends ConsumerStatefulWidget {
  const CreateRoomPage({super.key});

  @override
  ConsumerState<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends ConsumerState<CreateRoomPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedEmoji = '👥';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    final room = await ref.read(createRoomProvider.notifier).createRoom(
          name: _nameController.text.trim(),
          emoji: _selectedEmoji,
        );

    if (!mounted) return;

    if (room != null) {
      context.go(AppRoutes.roomPath(room.id));
    } else {
      final error = ref.read(createRoomProvider).error;
      context.showSnack(error?.toString() ?? AppStrings.errorOccurred, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createRoomProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createRoomTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmojiSection(context),
              const SizedBox(height: 24),
              _buildNameField(context),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _create,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(AppStrings.create),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.roomEmoji,
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _showEmojiPicker,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _showEmojiPicker,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('שנה אמוג\'י'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: AppConstants.defaultRoomEmojis.map((emoji) {
            final isSelected = emoji == _selectedEmoji;
            return GestureDetector(
              onTap: () => setState(() => _selectedEmoji = emoji),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.roomName,
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: AppStrings.roomNameHint,
            prefixIcon: Icon(Icons.group),
          ),
          maxLength: AppConstants.maxRoomNameLength,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'הכנס שם לחדר';
            }
            if (value.trim().length < AppConstants.minRoomNameLength) {
              return 'שם החדר חייב להכיל לפחות ${AppConstants.minRoomNameLength} תווים';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'בחר אמוג\'י',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: AppConstants.defaultRoomEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmoji = emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

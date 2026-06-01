import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/utils/sheet_utils.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';

class AddTorrentButton extends ConsumerWidget {
  const AddTorrentButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.add_rounded, color: AppColors.qbittorrent),
      onPressed: () => _showAddTorrentSheet(context, ref),
      tooltip: 'Add Torrent',
    );
  }

  void _showAddTorrentSheet(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    final categoryController = TextEditingController();
    final savePathController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    SheetUtils.showSeekarrModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Torrent',
                    style: Theme.of(ctx2).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Magnet / URL',
                      hintText: 'magnet:?xt=urn:btih:...',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: savePathController,
                    decoration: const InputDecoration(
                      labelText: 'Save Path (optional)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.qbittorrent,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        final service = ref.read(qbittorrentServiceProvider);
                        await service.addTorrentUrl(
                          urlController.text.trim(),
                          category: categoryController.text.trim().isEmpty
                              ? null
                              : categoryController.text.trim(),
                          savePath: savePathController.text.trim().isEmpty
                              ? null
                              : savePathController.text.trim(),
                        );
                        ref.invalidate(torrentsProvider);
                        Navigator.of(ctx2).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Torrent added successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(ctx2).showSnackBar(
                          SnackBar(content: Text('Failed to add torrent: $e')),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add Torrent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

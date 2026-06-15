import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';
import 'package:seekarr/features/qbittorrent/presentation/widgets/torrent_delete_dialog.dart';

class TorrentSelectionBar extends ConsumerWidget {
  final VoidCallback onConfirmDelete;

  const TorrentSelectionBar({super.key, required this.onConfirmDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedHashes = ref.watch(selectedTorrentHashesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedHashes.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      color: colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(selectedTorrentHashesProvider.notifier).state = {};
                },
                child: const Text('Cancel'),
              ),
              const Spacer(),
              Text(
                '${selectedHashes.length} selected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final hashes = selectedHashes.toList();
                  final service = ref.read(qbittorrentServiceProvider);
                  try {
                    await service.resumeTorrents(hashes);
                    ref.invalidate(torrentsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Resumed')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to resume: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Resume'),
              ),
              IconButton(
                icon: Icon(
                  Icons.flash_on_rounded,
                  color: AppColors.qbittorrent,
                ),
                tooltip: 'Force Resume',
                onPressed: () async {
                  final hashes = selectedHashes.toList();
                  final service = ref.read(qbittorrentServiceProvider);
                  try {
                    await service.setForceStart(hashes, true);
                    ref.invalidate(torrentsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Force started')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.pause_rounded, color: AppColors.warning),
                tooltip: 'Pause',
                onPressed: () async {
                  final hashes = selectedHashes.toList();
                  final service = ref.read(qbittorrentServiceProvider);
                  try {
                    await service.pauseTorrents(hashes);
                    ref.invalidate(torrentsProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to pause: $e')),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                tooltip: 'Delete',
                onPressed: onConfirmDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDeleteTorrents(
  BuildContext context,
  WidgetRef ref,
  Set<String> hashes,
) async {
  final count = hashes.length;
  final result = await showTorrentDeleteDialog(
    context: context,
    title: 'Delete torrents',
    message:
        'Delete $count torrent${count > 1 ? 's' : ''}? This action cannot be undone.',
    multi: count > 1,
  );
  if (!result.confirmed) return false;
  if (!context.mounted) return false;

  final service = ref.read(qbittorrentServiceProvider);
  try {
    await service.deleteTorrents(
      hashes.toList(),
      deleteFiles: result.deleteFiles,
    );
    ref.invalidate(torrentsProvider);
    ref.read(selectedTorrentHashesProvider.notifier).state = {};
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.deleteFiles
                ? 'Deleted $count torrent${count > 1 ? 's' : ''} and files'
                : 'Deleted $count torrent${count > 1 ? 's' : ''}',
          ),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
    return false;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';
import 'package:seekarr/features/qbittorrent/presentation/widgets/add_torrent_button.dart';

class QbittorrentActionsBar extends ConsumerWidget {
  const QbittorrentActionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [AddTorrentButton(), QbittorrentOverflowMenu()],
    );
  }
}

class QbittorrentOverflowMenu extends ConsumerWidget {
  const QbittorrentOverflowMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_QbOverflowAction>(
      icon: Icon(Icons.more_vert_rounded, color: AppColors.qbittorrent),
      tooltip: 'More',
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: _QbOverflowAction.pauseAll,
          child: ListTile(
            leading: Icon(Icons.pause_rounded),
            title: Text('Pause all'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _QbOverflowAction.resumeAll,
          child: ListTile(
            leading: Icon(Icons.play_arrow_rounded),
            title: Text('Resume all'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _QbOverflowAction.toggleAltSpeed,
          child: ListTile(
            leading: Icon(Icons.shield_moon_outlined),
            title: Text('Toggle alternative speeds'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _QbOverflowAction action,
  ) async {
    final service = ref.read(qbittorrentServiceProvider);
    try {
      switch (action) {
        case _QbOverflowAction.pauseAll:
          await service.pauseTorrents(const ['all']);
          ref.invalidate(torrentsProvider);
          ref.invalidate(allTorrentsProvider);
          _showSnack(context, 'All torrents paused');
          break;
        case _QbOverflowAction.resumeAll:
          await service.resumeTorrents(const ['all']);
          ref.invalidate(torrentsProvider);
          ref.invalidate(allTorrentsProvider);
          _showSnack(context, 'All torrents resumed');
          break;
        case _QbOverflowAction.toggleAltSpeed:
          await service.toggleAlternativeSpeedLimits();
          ref.invalidate(transferInfoProvider);
          _showSnack(context, 'Alternative speed limits toggled');
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _QbOverflowAction { pauseAll, resumeAll, toggleAltSpeed }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/utils/route_utils.dart';
import 'package:seekarr/core/widgets/async_value_widget.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_file.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_tracker.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';
import 'package:seekarr/features/qbittorrent/presentation/widgets/torrent_delete_dialog.dart';
import 'package:seekarr/features/qbittorrent/presentation/widgets/torrent_edit_dialogs.dart';

class TorrentDetailScreen extends ConsumerStatefulWidget {
  final String hash;
  final String? heroTag;

  const TorrentDetailScreen({super.key, required this.hash, this.heroTag});

  @override
  ConsumerState<TorrentDetailScreen> createState() =>
      _TorrentDetailScreenState();
}

class _TorrentDetailScreenState extends ConsumerState<TorrentDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(torrentDetailPollingProvider(widget.hash));
    final torrentAsync = ref.watch(qbittorrentTorrentsProvider(widget.hash));

    return AsyncValueWidget<List<Torrent>>(
      value: torrentAsync,
      serviceName: 'qBittorrent',
      data: (matches) {
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Torrent')),
            body: const Center(child: Text('Torrent not found')),
          );
        }
        return _buildContent(matches.first);
      },
    );
  }

  Widget _buildContent(Torrent torrent) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = AppColors.qbittorrent;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => RouteUtils.popOrGo(context, '/services'),
            ),
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    torrent.name,
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Files'),
                Tab(text: 'Trackers'),
                Tab(text: 'Actions'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _InfoTab(torrent: torrent),
            _FilesTab(hash: widget.hash),
            _TrackersTab(hash: widget.hash),
            _ActionsTab(torrent: torrent),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends ConsumerWidget {
  final Torrent torrent;

  const _InfoTab({required this.torrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _InfoRow(label: 'Name', value: torrent.name),
        _InfoRow(label: 'Size', value: torrent.sizeFormatted),
        _InfoRow(label: 'Progress', value: torrent.progressFormatted),
        _InfoRow(label: 'State', value: torrent.state),
        _InfoRow(label: 'Download Speed', value: torrent.dlSpeedFormatted),
        _InfoRow(label: 'Upload Speed', value: torrent.upSpeedFormatted),
        _InfoRow(label: 'ETA', value: torrent.etaFormatted),
        _EditableInfoRow(
          label: 'Category',
          value: torrent.category,
          onTap: () => _editCategory(context, ref, torrent),
        ),
        _EditableInfoRow(
          label: 'Tags',
          value: torrent.tags.join(', '),
          onTap: () => _editTags(context, ref, torrent),
        ),
        _InfoRow(label: 'Ratio', value: torrent.ratio.toStringAsFixed(2)),
        _InfoRow(label: 'Seeders', value: '${torrent.seeders}'),
        _InfoRow(label: 'Leechers', value: '${torrent.leechers}'),
      ],
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    Torrent torrent,
  ) async {
    final result = await showEditCategoryDialog(
      context,
      currentCategory: torrent.category,
    );
    if (result == null) return;
    if (result == torrent.category) return;
    if (!context.mounted) return;
    final service = ref.read(qbittorrentServiceProvider);
    try {
      await service.setCategory([torrent.hash], result);
      ref.invalidate(torrentsProvider);
      ref.invalidate(allTorrentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category set to "${result.trim()}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to set category: $e')));
      }
    }
  }

  Future<void> _editTags(
    BuildContext context,
    WidgetRef ref,
    Torrent torrent,
  ) async {
    final result = await showEditTagsDialog(context, currentTags: torrent.tags);
    if (result == null) return;
    final newSet = result.toSet();
    final oldSet = torrent.tags.toSet();
    if (newSet.length == oldSet.length && newSet.containsAll(oldSet)) return;
    if (!context.mounted) return;
    final service = ref.read(qbittorrentServiceProvider);
    try {
      final toAdd = newSet.difference(oldSet).toList();
      final toRemove = oldSet.difference(newSet).toList();
      if (toAdd.isNotEmpty) {
        await service.addTags([torrent.hash], toAdd);
      }
      if (toRemove.isNotEmpty) {
        await service.removeTags([torrent.hash], toRemove);
      }
      ref.invalidate(torrentsProvider);
      ref.invalidate(allTorrentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tags updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update tags: $e')));
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _EditableInfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilesTab extends ConsumerWidget {
  final String hash;

  const _FilesTab({required this.hash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(torrentFilesProvider(hash));

    return AsyncValueWidget<List<TorrentFile>>(
      value: filesAsync,
      serviceName: 'qBittorrent',
      data: (files) {
        if (files.isEmpty) {
          return const Center(child: Text('No files'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: files.length,
          itemBuilder: (context, index) =>
              _FileRow(file: files[index], index: index, hash: hash),
        );
      },
    );
  }
}

class _FileRow extends ConsumerWidget {
  final TorrentFile file;
  final int index;
  final String hash;

  const _FileRow({required this.file, required this.index, required this.hash});

  static const _priorityLabels = <int, String>{
    0: 'Do not download',
    1: 'Normal',
    2: 'High',
    6: 'Maximum',
    7: 'Mixed',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      onTap: () => _showPriorityMenu(context, ref),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 4,
          height: 32,
          child: LinearProgressIndicator(
            value: file.progress,
            backgroundColor: colorScheme.outline,
            color: AppColors.qbittorrent,
          ),
        ),
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      subtitle: Text(
        file.priorityLabel,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Text(
        '${file.sizeFormatted} • ${file.progressFormatted}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Future<void> _showPriorityMenu(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _priorityLabels.entries
              .map(
                (e) => ListTile(
                  dense: true,
                  title: Text(e.value),
                  trailing: file.priority == e.key
                      ? Icon(
                          Icons.check_rounded,
                          color: AppColors.qbittorrent,
                          size: 18,
                        )
                      : null,
                  onTap: () => Navigator.of(ctx).pop(e.key),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (picked == null) return;
    if (picked == file.priority) return;
    if (!context.mounted) return;

    final service = ref.read(qbittorrentServiceProvider);
    try {
      await service.filePrio(
        hash: hash,
        fileIndexes: [index],
        priority: picked,
      );
      ref.invalidate(torrentFilesProvider(hash));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priority set to ${_priorityLabels[picked]}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to set priority: $e')));
      }
    }
  }
}

class _TrackersTab extends ConsumerWidget {
  final String hash;

  const _TrackersTab({required this.hash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(torrentTrackersProvider(hash));

    return AsyncValueWidget<List<TorrentTracker>>(
      value: trackersAsync,
      serviceName: 'qBittorrent',
      data: (trackers) {
        if (trackers.isEmpty) {
          return const Center(child: Text('No trackers'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: trackers.length,
          itemBuilder: (context, index) =>
              _TrackerRow(tracker: trackers[index]),
        );
      },
    );
  }
}

class _TrackerRow extends StatelessWidget {
  final TorrentTracker tracker;

  const _TrackerRow({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      title: Text(
        tracker.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      subtitle: Row(
        children: [
          _StatusDot(status: tracker.status),
          const SizedBox(width: 6),
          Text(
            tracker.statusLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Text(
        'Peers: ${tracker.numPeers}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final int status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      2 => AppColors.success,
      3 => AppColors.warning,
      4 => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ActionsTab extends ConsumerWidget {
  final Torrent torrent;

  const _ActionsTab({required this.torrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        FilledButton.icon(
          onPressed: () async {
            final service = ref.read(qbittorrentServiceProvider);
            try {
              await service.resumeTorrents([torrent.hash]);
              ref.invalidate(torrentsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Resumed')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed to resume: $e')));
              }
            }
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Resume'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.qbittorrent,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final service = ref.read(qbittorrentServiceProvider);
            try {
              await service.setForceStart([torrent.hash], true);
              ref.invalidate(torrentsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Force started')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            }
          },
          icon: const Icon(Icons.flash_on_rounded, size: 18),
          label: const Text('Force Resume'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.black,
          ),
          onPressed: () async {
            final service = ref.read(qbittorrentServiceProvider);
            try {
              await service.pauseTorrents([torrent.hash]);
              ref.invalidate(torrentsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Paused')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed to pause: $e')));
              }
            }
          },
          icon: const Icon(Icons.pause_rounded, size: 18),
          label: const Text('Pause'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _confirmDeleteSingle(context, ref, torrent),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Delete'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: torrent.hash));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hash copied to clipboard')),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy hash'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: torrent.name));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name copied to clipboard')),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy name'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        _SectionLabel('Speed limits (this torrent)'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _setLimit(context, ref, torrent, isDownload: true),
          icon: const Icon(Icons.south_rounded, size: 16),
          label: const Text('Download limit'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _setLimit(context, ref, torrent, isDownload: false),
          icon: const Icon(Icons.north_rounded, size: 16),
          label: const Text('Upload limit'),
        ),
        const SizedBox(height: 24),
        _SectionLabel('Global'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _toggleAltSpeed(context, ref),
          icon: const Icon(Icons.shield_moon_outlined, size: 16),
          label: const Text('Toggle alternative speed limits'),
        ),
        const SizedBox(height: 24),
        _SectionLabel('Maintenance'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _recheck(context, ref, torrent),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Force recheck'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _reannounce(context, ref, torrent),
          icon: const Icon(Icons.campaign_rounded, size: 16),
          label: const Text('Reannounce to trackers'),
        ),
      ],
    );
  }

  Future<void> _recheck(
    BuildContext context,
    WidgetRef ref,
    Torrent torrent,
  ) async {
    final service = ref.read(qbittorrentServiceProvider);
    try {
      await service.recheck(torrent.hash);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recheck started')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to recheck: $e')));
      }
    }
  }

  Future<void> _reannounce(
    BuildContext context,
    WidgetRef ref,
    Torrent torrent,
  ) async {
    final service = ref.read(qbittorrentServiceProvider);
    try {
      await service.reannounce([torrent.hash]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reannounced to trackers')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reannounce: $e')));
      }
    }
  }

  Future<void> _setLimit(
    BuildContext context,
    WidgetRef ref,
    Torrent torrent, {
    required bool isDownload,
  }) async {
    // qB doesn't expose per-torrent current limits directly; we use 0 as a
    // best-effort starting point (the user can re-type the actual value).
    final result = await showSpeedLimitDialog(
      context,
      title: isDownload ? 'Download limit' : 'Upload limit',
      currentLimitBytes: 0,
    );
    if (result == null) return;
    if (!context.mounted) return;
    final service = ref.read(qbittorrentServiceProvider);
    try {
      if (isDownload) {
        await service.setDownloadLimit([torrent.hash], result.bytesPerSecond!);
      } else {
        await service.setUploadLimit([torrent.hash], result.bytesPerSecond!);
      }
      ref.invalidate(torrentsProvider);
      if (context.mounted) {
        final bytes = result.bytesPerSecond!;
        final label = bytes == 0
            ? 'cleared'
            : '${(bytes / 1024).toStringAsFixed(0)} KB/s';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDownload
                  ? 'Download limit set to $label'
                  : 'Upload limit set to $label',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to set limit: $e')));
      }
    }
  }

  Future<void> _toggleAltSpeed(BuildContext context, WidgetRef ref) async {
    final service = ref.read(qbittorrentServiceProvider);
    try {
      await service.toggleAlternativeSpeedLimits();
      ref.invalidate(transferInfoProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alternative speed limits toggled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to toggle: $e')));
      }
    }
  }

  void _confirmDeleteSingle(
    BuildContext context,
    WidgetRef ref,
    Torrent torrent,
  ) {
    showTorrentDeleteDialog(
      context: context,
      title: 'Delete torrent',
      message: 'Delete "${torrent.name}"? This action cannot be undone.',
    ).then((result) async {
      if (!result.confirmed) return;
      if (!context.mounted) return;
      final service = ref.read(qbittorrentServiceProvider);
      try {
        await service.deleteTorrents([
          torrent.hash,
        ], deleteFiles: result.deleteFiles);
        ref.invalidate(torrentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.deleteFiles
                    ? 'Deleted torrent and files'
                    : 'Deleted torrent',
              ),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    });
  }
}

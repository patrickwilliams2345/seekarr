import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/core/utils/route_utils.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_file.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_tracker.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';

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

    return torrentAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Torrent')),
            body: const Center(child: Text('Torrent not found')),
          );
        }
        return _buildContent(matches.first);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Torrent')),
        body: Center(child: Text('Error: $error')),
      ),
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

class _InfoTab extends StatelessWidget {
  final Torrent torrent;

  const _InfoTab({required this.torrent});

  @override
  Widget build(BuildContext context) {
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
        _InfoRow(label: 'Category', value: torrent.category),
        _InfoRow(label: 'Tags', value: torrent.tags.join(', ')),
        _InfoRow(label: 'Ratio', value: torrent.ratio.toStringAsFixed(2)),
        _InfoRow(label: 'Seeders', value: '${torrent.seeders}'),
        _InfoRow(label: 'Leechers', value: '${torrent.leechers}'),
      ],
    );
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

class _FilesTab extends ConsumerWidget {
  final String hash;

  const _FilesTab({required this.hash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(torrentFilesProvider(hash));

    return filesAsync.when(
      data: (files) {
        if (files.isEmpty) {
          return const Center(child: Text('No files'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: files.length,
          itemBuilder: (context, index) => _FileRow(file: files[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _FileRow extends StatelessWidget {
  final TorrentFile file;

  const _FileRow({required this.file});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
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
      trailing: Text(
        '${file.sizeFormatted} • ${file.progressFormatted}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _TrackersTab extends ConsumerWidget {
  final String hash;

  const _TrackersTab({required this.hash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(torrentTrackersProvider(hash));

    return trackersAsync.when(
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resumed')),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Force started')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paused')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to pause: $e')),
                );
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
      ],
    );
  }

  void _confirmDeleteSingle(
    BuildContext context,
    WidgetRef ref,
    Torrent torrent,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete torrent'),
        content: Text('Delete "${torrent.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final service = ref.read(qbittorrentServiceProvider);
              try {
                await service.deleteTorrents([torrent.hash], deleteFiles: false);
                ref.invalidate(torrentsProvider);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final service = ref.read(qbittorrentServiceProvider);
              try {
                await service.deleteTorrents([torrent.hash], deleteFiles: true);
                ref.invalidate(torrentsProvider);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete + files'),
          ),
        ],
      ),
    );
  }
}

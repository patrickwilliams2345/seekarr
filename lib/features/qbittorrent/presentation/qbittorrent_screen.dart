import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent.dart';
import 'package:seekarr/features/qbittorrent/domain/models/transfer_info.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';
import 'package:seekarr/features/qbittorrent/presentation/widgets/speed_stats_bar.dart';
import 'package:seekarr/features/qbittorrent/presentation/widgets/torrent_tile.dart';

class QbittorrentScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final double topPadding;
  final VoidCallback? onAddTorrent;

  const QbittorrentScreen({
    super.key,
    this.showAppBar = true,
    this.topPadding = 0,
    this.onAddTorrent,
  });

  @override
  ConsumerState<QbittorrentScreen> createState() => _QbittorrentScreenState();
}

class _QbittorrentScreenState extends ConsumerState<QbittorrentScreen> {
  final _filters = const [
    TorrentFilter.all,
    TorrentFilter.downloading,
    TorrentFilter.seeding,
    TorrentFilter.paused,
    TorrentFilter.queued,
  ];

  String _filterLabel(TorrentFilter filter) {
    return switch (filter) {
      TorrentFilter.all => 'All',
      TorrentFilter.downloading => 'Downloading',
      TorrentFilter.seeding => 'Seeding',
      TorrentFilter.paused => 'Paused',
      TorrentFilter.queued => 'Queued',
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(torrentPollingProvider);
    final selectedFilter = ref.watch(torrentFilterProvider);
    final currentSort = ref.watch(torrentSortProvider);
    final sortReverse = ref.watch(torrentSortReverseProvider);
    final torrentsAsync = ref.watch(torrentsProvider);
    final selectedHashes = ref.watch(selectedTorrentHashesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final accent = AppColors.qbittorrent;

    return Scaffold(
      body: Column(
        children: [
          if (widget.topPadding > 0) SizedBox(height: widget.topPadding),
          _buildStatsBar(ref),
          _buildFilterChips(selectedFilter, colorScheme, accent),
          _buildFilterRow(colorScheme, accent),
          const SizedBox(height: 4),
          _buildSortRow(currentSort, sortReverse, colorScheme),
          Expanded(
            child: _buildTorrentList(
              torrentsAsync,
              selectedHashes,
              ref,
              colorScheme,
            ),
          ),
          if (selectedHashes.isNotEmpty)
            _buildSelectionBar(selectedHashes, ref, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatsBar(WidgetRef ref) {
    final transferAsync = ref.watch(transferInfoProvider);
    final torrentsAsync = ref.watch(torrentsProvider);

    TransferInfo? info;
    transferAsync.whenOrNull(data: (d) => info = d);

    int total = 0;
    int active = 0;
    torrentsAsync.whenOrNull(
      data: (list) {
        total = list.length;
        active = list.where((t) => t.parsedState.isActive).length;
      },
    );

    return SpeedStatsBar(info: info, torrentCount: total, activeCount: active);
  }

  Widget _buildFilterChips(
    TorrentFilter selectedFilter,
    ColorScheme colorScheme,
    Color accent,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final filter in _filters) ...[
            if (filter != _filters.first) const SizedBox(width: 6),
            _FilterChip(
              label: _filterLabel(filter),
              active: filter == selectedFilter,
              accent: accent,
              colorScheme: colorScheme,
              onTap: () {
                ref.read(torrentFilterProvider.notifier).state = filter;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterRow(ColorScheme colorScheme, Color accent) {
    final categories = ref.watch(availableCategoriesProvider);
    final tags = ref.watch(availableTagsProvider);
    final trackers = ref.watch(availableTrackersProvider);
    final selectedCategory = ref.watch(torrentCategoryFilterProvider);
    final selectedTag = ref.watch(torrentTagFilterProvider);
    final selectedTracker = ref.watch(torrentTrackerFilterProvider);

    final hasAnyOptions =
        categories.isNotEmpty || tags.isNotEmpty || trackers.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: hasAnyOptions
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                          label: 'Categories',
                          selectedLabel: selectedCategory,
                          options: categories,
                          accent: accent,
                          colorScheme: colorScheme,
                          onSelected: (value) {
                            ref
                                .read(torrentCategoryFilterProvider.notifier)
                                .state = value;
                          },
                        ),
                        const SizedBox(width: 4),
                        _FilterPill(
                          label: 'Tags',
                          selectedLabel: selectedTag,
                          options: tags,
                          accent: accent,
                          colorScheme: colorScheme,
                          onSelected: (value) {
                            ref
                                .read(torrentTagFilterProvider.notifier)
                                .state = value;
                          },
                        ),
                        const SizedBox(width: 4),
                        _FilterPill(
                          label: 'Trackers',
                          selectedLabel: selectedTracker,
                          options: trackers,
                          accent: accent,
                          colorScheme: colorScheme,
                          onSelected: (value) {
                            ref
                                .read(torrentTrackerFilterProvider.notifier)
                                .state = value;
                          },
                        ),
                      ],
                    ),
                  )
                : Text(
                    '—',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow(
    TorrentSort currentSort,
    bool reverse,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'Sort:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final sort in TorrentSort.values) ...[
                    if (sort != TorrentSort.values.first)
                      const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        if (sort == currentSort) {
                          ref.read(torrentSortReverseProvider.notifier).state =
                              !reverse;
                        } else {
                          ref.read(torrentSortProvider.notifier).state = sort;
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: sort == currentSort
                              ? AppColors.qbittorrent.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sort.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: sort == currentSort
                                        ? AppColors.qbittorrent
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: sort == currentSort
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                            if (sort == currentSort) ...[
                              const SizedBox(width: 2),
                              Icon(
                                reverse
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 10,
                                color: AppColors.qbittorrent,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTorrentList(
    AsyncValue<List<Torrent>> torrentsAsync,
    Set<String> selectedHashes,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    return torrentsAsync.when(
      data: (torrents) {
        if (torrents.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No torrents',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allTorrentsProvider);
            ref.invalidate(torrentsProvider);
            ref.invalidate(transferInfoProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 4, bottom: 80),
            itemCount: torrents.length,
            itemBuilder: (context, index) {
              final torrent = torrents[index];
              return TorrentTile(
                torrent: torrent,
                selected: selectedHashes.contains(torrent.hash),
                onTap: () {
                  if (selectedHashes.isNotEmpty) {
                    _toggleSelection(ref, torrent.hash);
                  } else {
                    context.push('/services/qbittorrent/torrent/${torrent.hash}');
                  }
                },
                onLongPress: () {
                  _toggleSelection(ref, torrent.hash);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(
    Set<String> selectedHashes,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
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
              IconButton(
                icon: Icon(Icons.flash_on_rounded, color: AppColors.qbittorrent),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.pause_rounded, color: AppColors.warning),
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
                onPressed: () => _confirmDelete(context, ref, selectedHashes),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(WidgetRef ref, String hash) {
    final notifier = ref.read(selectedTorrentHashesProvider.notifier);
    final current = Set<String>.from(notifier.state);
    if (current.contains(hash)) {
      current.remove(hash);
    } else {
      current.add(hash);
    }
    notifier.state = current;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Set<String> hashes) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete torrents'),
        content: Text(
          'Delete ${hashes.length} torrent${hashes.length > 1 ? 's' : ''}?',
        ),
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
                await service.deleteTorrents(hashes.toList(), deleteFiles: false);
                ref.invalidate(torrentsProvider);
                ref.read(selectedTorrentHashesProvider.notifier).state = {};
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
                await service.deleteTorrents(hashes.toList(), deleteFiles: true);
                ref.invalidate(torrentsProvider);
                ref.read(selectedTorrentHashesProvider.notifier).state = {};
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.accent,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.22) : Colors.transparent,
          border: Border.all(color: active ? accent : colorScheme.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? accent : colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final String? selectedLabel;
  final List<String> options;
  final Color accent;
  final ColorScheme colorScheme;
  final ValueChanged<String?> onSelected;

  const _FilterPill({
    required this.label,
    required this.selectedLabel,
    required this.options,
    required this.accent,
    required this.colorScheme,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedLabel != null;
    final displayLabel = selectedLabel ?? label;

    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return PopupMenuButton<String?>(
      offset: const Offset(0, 36),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Text(
            'All',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: selectedLabel == null
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
        ...options.map(
          (o) => PopupMenuItem<String?>(
            value: o,
            child: Text(
              o,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: o == selectedLabel
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.qbittorrent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: active
                    ? AppColors.qbittorrent
                    : colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 10,
              color: active
                  ? AppColors.qbittorrent
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

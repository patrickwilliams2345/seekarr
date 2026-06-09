import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';

const List<TorrentFilter> kTorrentStatusFilters = [
  TorrentFilter.all,
  TorrentFilter.downloading,
  TorrentFilter.seeding,
  TorrentFilter.completed,
  TorrentFilter.paused,
  TorrentFilter.queued,
];

String torrentFilterLabel(TorrentFilter filter) {
  switch (filter) {
    case TorrentFilter.all:
      return 'All';
    case TorrentFilter.downloading:
      return 'Downloading';
    case TorrentFilter.seeding:
      return 'Seeding';
    case TorrentFilter.completed:
      return 'Completed';
    case TorrentFilter.paused:
      return 'Paused';
    case TorrentFilter.queued:
      return 'Queued';
  }
}

class TorrentFilterChipsRow extends ConsumerWidget {
  const TorrentFilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(torrentFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final accent = AppColors.qbittorrent;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final filter in kTorrentStatusFilters) ...[
            if (filter != kTorrentStatusFilters.first) const SizedBox(width: 6),
            _FilterChip(
              label: torrentFilterLabel(filter),
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
}

class TorrentFilterPillsRow extends ConsumerWidget {
  const TorrentFilterPillsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(availableCategoriesProvider);
    final tags = ref.watch(availableTagsProvider);
    final trackers = ref.watch(availableTrackersProvider);
    final selectedCategory = ref.watch(torrentCategoryFilterProvider);
    final selectedTag = ref.watch(torrentTagFilterProvider);
    final selectedTracker = ref.watch(torrentTrackerFilterProvider);

    final hasAnyOptions =
        categories.isNotEmpty || tags.isNotEmpty || trackers.isNotEmpty;

    final colorScheme = Theme.of(context).colorScheme;
    final accent = AppColors.qbittorrent;

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
                            ref.read(torrentTagFilterProvider.notifier).state =
                                value;
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
}

class TorrentSortRow extends ConsumerWidget {
  const TorrentSortRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(torrentSortProvider);
    final reverse = ref.watch(torrentSortReverseProvider);
    final colorScheme = Theme.of(context).colorScheme;

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

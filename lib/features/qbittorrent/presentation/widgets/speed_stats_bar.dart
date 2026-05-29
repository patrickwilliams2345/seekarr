import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/theme.dart';
import 'package:seekarr/features/qbittorrent/domain/models/transfer_info.dart';

class SpeedStatsBar extends StatelessWidget {
  final TransferInfo? info;
  final int torrentCount;
  final int activeCount;

  const SpeedStatsBar({
    super.key,
    this.info,
    required this.torrentCount,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.qbittorrent;

    final widgets = <Widget>[
      _StatChip(label: '$torrentCount', subtitle: 'Torrents', color: accent),
      _StatChip(label: '$activeCount', subtitle: 'Active', color: accent),
    ];

    if (info != null) {
      widgets.addAll([
        _StatChip(
          label: info!.dlSpeedFormatted,
          subtitle: 'DL Speed',
          color: accent,
        ),
        _StatChip(
          label: info!.upSpeedFormatted,
          subtitle: 'UL Speed',
          color: AppColors.success,
        ),
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < widgets.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            widgets[i],
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;

  const _StatChip({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.borderRadiusSm,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/core/app_spacing.dart';
import 'package:seekarr/core/providers/navigation_refresh_provider.dart';
import 'package:seekarr/core/widgets/floating_bottom_nav_bar.dart';
import 'package:seekarr/features/services/presentation/services_dashboard_sections.dart';
import 'package:seekarr/features/services/presentation/services_provider.dart';
import 'package:seekarr/features/services/presentation/services_status_overview.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = FloatingNavBarMetrics.getScrollViewBottomPadding(
      context,
    );

    ref.listen<int>(navigationRefreshProvider(NavigationSection.services), (
      previous,
      next,
    ) {
      _invalidateServicesDashboard(ref);
    });

    final settings = ref.watch(currentSettingsProvider);
    final allUnconfigured = ServiceKey.values.every(
      (s) => !settings.isServiceConfigured(s),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: ServicesOnlineSummary(),
          ),
        ],
      ),
      body: allUnconfigured
          ? _ServicesEmptyState(
              onSetUpServices: () => context.go('/settings/services'),
            )
          : RefreshIndicator(
              onRefresh: () async => _invalidateServicesDashboard(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomPadding),
                children: const [
                  ServiceStatusGrid(),
                  ServicesTrendingSection(),
                  ServicesRecentRequestsSection(),
                  ServicesRecentlyAddedMoviesSection(),
                  ServicesRecentlyAddedSeriesSection(),
                  ServicesDownloadingSection(),
                ],
              ),
            ),
    );
  }
}

class _ServicesEmptyState extends StatelessWidget {
  const _ServicesEmptyState({required this.onSetUpServices});
  final VoidCallback onSetUpServices;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHigh,
              ),
              child: Icon(
                Icons.dns_outlined,
                size: 34,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No services configured',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Connect your self-hosted services to start managing them from one place.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onSetUpServices,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Set up services'),
            ),
          ],
        ),
      ),
    );
  }
}

void _invalidateServicesDashboard(WidgetRef ref) {
  for (final service in ServiceKey.values) {
    ref.invalidate(serviceSummaryProvider(service));
  }
  ref.invalidate(servicesTrendingProvider);
  ref.invalidate(servicesRequestsProvider);
  ref.invalidate(servicesMoviesProvider);
  ref.invalidate(servicesSeriesProvider);
  ref.invalidate(servicesMusicProvider);
  ref.invalidate(servicesQueueProvider);
}

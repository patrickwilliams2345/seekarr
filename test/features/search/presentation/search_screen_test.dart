import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seekarr/core/widgets/content_card.dart';

import 'package:seekarr/features/discover/data/seerr_service.dart';
import 'package:seekarr/features/movies/data/radarr_service.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
import 'package:seekarr/features/search/presentation/global_search_provider.dart';
import 'package:seekarr/features/search/presentation/search_screen.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

import '../../../test_helpers/fake_services.dart';
import '../../../test_helpers/model_builders.dart';

void main() {
  testWidgets('renders grouped global search result cards', (tester) async {
    await _pumpSearch(tester);

    expect(find.text('Radarr'), findsWidgets);
    expect(find.text('1 result'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Movie'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
    expect(_posterSizedContentCard(tester), findsOneWidget);
    expect(_solidActionIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('filters search results by selected service', (tester) async {
    await _pumpSearch(tester);

    await tester.tap(find.text('Seerr').first);
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsNothing);
    expect(find.text('No Seerr results'), findsOneWidget);

    await tester.tap(find.text('Radarr').first);
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('No Seerr results'), findsNothing);
  });

  testWidgets('tapping a result navigates with the result as route extra', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/services/radarr/movie/:id',
          builder: (context, state) {
            final movie = state.extra as RadarrMovie?;
            return Scaffold(
              body: Text(
                'Movie detail ${state.pathParameters['id']} ${movie?.title}',
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dune'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/services/radarr/movie/10');
    expect(find.text('Movie detail 10 Dune'), findsOneWidget);
  });
}

Finder _solidActionIcon(IconData icon) {
  return find.descendant(
    of: find.byWidgetPredicate((widget) => widget is DecoratedBox),
    matching: find.byIcon(icon),
  );
}

Finder _posterSizedContentCard(WidgetTester tester) {
  for (final element in find.byType(ContentCard).evaluate()) {
    final box = element.renderObject as RenderBox?;
    if (box?.size == const Size(50, 75)) {
      return find.byWidget(element.widget);
    }
  }
  return find.byKey(const ValueKey('missing-poster-sized-content-card'));
}

Future<void> _pumpSearch(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

_overrides() {
  return [
    currentSettingsProvider.overrideWith(
      (ref) => const SettingsModel(
        radarrUrl: 'http://radarr.local:7878',
        radarrApiKey: 'key',
      ),
    ),
    globalSearchQueryProvider.overrideWith((ref) => 'dune'),
    seerrServiceProvider.overrideWith((ref) => FakeSeerrService()),
    radarrServiceProvider.overrideWith(
      (ref) => _SearchRadarrService(
        results: [buildMovie(id: 10, title: 'Dune', year: 2024)],
      ),
    ),
  ];
}

class _SearchRadarrService extends FakeRadarrService {
  final List<RadarrMovie> results;

  _SearchRadarrService({required this.results});

  @override
  Future<List<RadarrMovie>> lookupMovies(String term) async => results;
}

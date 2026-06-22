import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/import/data/manual_import_service.dart';
import 'package:seekarr/features/import/domain/manual_import_models.dart';
import 'package:seekarr/features/import/presentation/manual_import_provider.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

import '../../../test_helpers/fake_api_client.dart';

/// Test-only `ManualImportService` that uses a `FakeApiClient`.
class _FakeManualImportService extends ManualImportService {
  _FakeManualImportService(FakeApiClient client, ServiceKey service)
    : super(client: client, service: service);
}

ProviderContainer _container({
  required FakeApiClient client,
  ServiceKey service = ServiceKey.radarr,
  List<dynamic> extra = const [],
}) {
  return ProviderContainer(
    overrides: [
      manualImportServiceProvider(
        service,
      ).overrideWith((ref) => _FakeManualImportService(client, service)),
      ...extra,
    ],
  );
}

ManualImportItem _radarrItem({
  int movieId = 0,
  String path = '/downloads/x.mkv',
}) {
  return ManualImportItem.fromJson({
    'path': path,
    'name': path.split('/').last,
    'movie': movieId > 0 ? {'id': movieId, 'title': 'Some Movie'} : null,
  });
}

ManualImportFixAssignment _radarrAssignment({int movieId = 0}) {
  return ManualImportFixAssignment(
    match: ManualImportLookupResult(
      id: movieId,
      title: 'Some Movie',
      raw: movieId > 0
          ? {'id': movieId, 'title': 'Some Movie'}
          : const <String, dynamic>{},
    ),
  );
}

ManualImportFixAssignment _sonarrAssignment({
  int seriesId = 0,
  List<int> episodeIds = const [],
}) {
  return ManualImportFixAssignment(
    match: ManualImportLookupResult(
      id: seriesId,
      title: 'Some Series',
      raw: seriesId > 0
          ? {'id': seriesId, 'title': 'Some Series'}
          : const <String, dynamic>{},
    ),
    episodes: episodeIds
        .map(
          (id) => ManualImportEpisode(
            id: id,
            seasonNumber: 1,
            episodeNumber: id,
            title: 'E$id',
            raw: {
              'id': id,
              'seasonNumber': 1,
              'episodeNumber': id,
              'title': 'E$id',
            },
          ),
        )
        .toList(growable: false),
  );
}

ManualImportFixAssignment _lidarrAssignment({
  int artistId = 0,
  int? albumId,
  List<int> trackIds = const [],
}) {
  return ManualImportFixAssignment(
    match: ManualImportLookupResult(
      id: artistId,
      title: 'Some Artist',
      raw: artistId > 0
          ? {'id': artistId, 'title': 'Some Artist'}
          : const <String, dynamic>{},
    ),
    album: albumId == null
        ? null
        : ManualImportAlbum(
            id: albumId,
            title: 'Some Album',
            raw: {'id': albumId, 'title': 'Some Album'},
          ),
    tracks: trackIds
        .map(
          (id) => ManualImportTrack(
            id: id,
            title: 'T$id',
            raw: {'id': id, 'title': 'T$id'},
          ),
        )
        .toList(growable: false),
  );
}

void main() {
  group('mapImportError', () {
    test('returns "Couldn\'t reach Radarr" for connectionError', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      expect(
        mapImportError(err, ServiceKey.radarr),
        startsWith("Couldn't reach Radarr"),
      );
    });

    test('returns "Couldn\'t reach Sonarr" for connectionTimeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        mapImportError(err, ServiceKey.sonarr),
        startsWith("Couldn't reach Sonarr"),
      );
    });

    test('returns the 500 hint message for statusCode 500 (radarr)', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/v3/command'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v3/command'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
      final msg = mapImportError(err, ServiceKey.radarr);
      expect(msg, contains('returned 500'));
      expect(
        msg,
        contains('Try moving the file into a folder named after the movie'),
      );
      expect(msg, contains('Check Radarr → System → Logs'));
    });

    test('returns the 500 hint message for sonarr (series/episode naming)', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/v3/command'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v3/command'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
      final msg = mapImportError(err, ServiceKey.sonarr);
      expect(msg, contains('returned 500'));
      expect(msg, contains("doesn't match a known series/episode pattern"));
      expect(msg, contains('Series Title/S01E01.ext'));
      expect(msg, isNot(contains('movie')));
    });

    test(
      'returns the 500 hint message for lidarr (artist/album/track naming)',
      () {
        final err = DioException(
          requestOptions: RequestOptions(path: '/api/v1/command'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/v1/command'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );
        final msg = mapImportError(err, ServiceKey.lidarr);
        expect(msg, contains('returned 500'));
        expect(
          msg,
          contains("doesn't match a known artist/album/track pattern"),
        );
        expect(msg, contains('Artist/Album/Track.ext'));
        expect(msg, isNot(contains('movie')));
      },
    );

    test('returns "Radarr returned 404: Not Found" for 404 with message', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 404,
          data: {'message': 'Not Found'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(
        mapImportError(err, ServiceKey.radarr),
        'Radarr returned 404: Not Found',
      );
    });

    test('returns "Radarr returned 401." for 401 with no message', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(mapImportError(err, ServiceKey.radarr), 'Radarr returned 401.');
    });

    test('returns error.toString() for non-DioException throwables', () {
      expect(mapImportError(Exception('boom'), ServiceKey.radarr), 'boom');
    });

    test(
      'returns "Lidarr request failed..." for DioException with no response and unknown type',
      () {
        final err = DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.unknown,
        );
        expect(
          mapImportError(err, ServiceKey.lidarr),
          contains('Lidarr request failed'),
        );
      },
    );
  });

  group('libraryGuardError', () {
    test('returns null for a valid radarr assignment', () {
      expect(
        libraryGuardError(ServiceKey.radarr, _radarrAssignment(movieId: 123)),
        isNull,
      );
    });

    test(
      'returns non-null containing "library" for radarr with match.id == 0',
      () {
        final msg = libraryGuardError(
          ServiceKey.radarr,
          _radarrAssignment(movieId: 0),
        );
        expect(msg, isNotNull);
        expect(msg, contains('library'));
      },
    );

    test('returns non-null for sonarr with no episodes', () {
      final msg = libraryGuardError(
        ServiceKey.sonarr,
        _sonarrAssignment(seriesId: 10),
      );
      expect(msg, isNotNull);
      expect(msg, contains('library'));
    });

    test('returns non-null for lidarr with no tracks', () {
      final msg = libraryGuardError(
        ServiceKey.lidarr,
        _lidarrAssignment(artistId: 1, albumId: 2),
      );
      expect(msg, isNotNull);
      expect(msg, contains('library'));
    });

    test('returns non-null for lidarr with no album', () {
      final msg = libraryGuardError(
        ServiceKey.lidarr,
        _lidarrAssignment(artistId: 1, trackIds: [4]),
      );
      expect(msg, isNotNull);
      expect(msg, contains('library'));
    });

    test('returns null for a valid sonarr assignment with episodes', () {
      expect(
        libraryGuardError(
          ServiceKey.sonarr,
          _sonarrAssignment(seriesId: 10, episodeIds: [50]),
        ),
        isNull,
      );
    });

    test('returns null for a valid lidarr assignment with album + tracks', () {
      expect(
        libraryGuardError(
          ServiceKey.lidarr,
          _lidarrAssignment(artistId: 1, albumId: 2, trackIds: [4]),
        ),
        isNull,
      );
    });
  });

  group('ManualImportFlowNotifier.applyFixAssignment', () {
    test(
      'guard fails fast for radarr with match.id == 0: no API call, error set',
      () async {
        final client = FakeApiClient();
        final container = _container(
          client: client,
          service: ServiceKey.radarr,
        );
        addTearDown(container.dispose);

        // Seed the flow with a radarr service and one item.
        final notifier = container.read(manualImportFlowProvider.notifier);
        await notifier.start(ServiceKey.radarr, force: true);
        // Reset error from the start() call.
        container.read(manualImportFlowProvider.notifier).state = container
            .read(manualImportFlowProvider)
            .copyWith(error: null);
        client.postCallCount = 0; // ignore any start() side effects

        final item = _radarrItem(movieId: 0, path: '/downloads/Barbie.avi');
        final assignment = _radarrAssignment(movieId: 0);

        final result = await notifier.applyFixAssignment(item, assignment);

        expect(result, isNull);
        expect(client.postCallCount, 0);
        final state = container.read(manualImportFlowProvider);
        expect(state.error, isNotNull);
        expect(state.error, contains('library'));
      },
    );

    test(
      'valid radarr assignment: no API call, item replaced, auto-selected',
      () async {
        final client = FakeApiClient();
        final container = _container(
          client: client,
          service: ServiceKey.radarr,
        );
        addTearDown(container.dispose);

        final notifier = container.read(manualImportFlowProvider.notifier);
        final item = _radarrItem(
          movieId: 123,
          path: '/downloads/Inception.avi',
        );
        final assignment = _radarrAssignment(movieId: 123);

        // Inject the item into state manually (skip folder scan).
        container.read(manualImportFlowProvider.notifier).state = container
            .read(manualImportFlowProvider)
            .copyWith(service: ServiceKey.radarr, items: [item]);

        final result = await notifier.applyFixAssignment(item, assignment);

        expect(result, isNotNull);
        // The fix flow MUST NOT call the import endpoint — the actual import
        // is triggered by confirmImport when the user clicks "Confirm import".
        expect(client.postCallCount, 0);

        final state = container.read(manualImportFlowProvider);
        // Item at the same path should have been replaced with the resolved one.
        expect(state.items.length, 1);
        expect(state.items.first.path, '/downloads/Inception.avi');
        expect(state.items.first.hasMatchFor(ServiceKey.radarr), isTrue);
        // The resolved item should be auto-selected so "Confirm import" picks it.
        expect(state.selectedPaths, contains('/downloads/Inception.avi'));
        expect(state.error, isNull);
      },
    );
  });

  group('ManualImportFlowNotifier.confirmImport', () {
    test('sets state.error to the mapped message on DioException 500', () async {
      final client = FakeApiClient();
      client.postException = DioException(
        requestOptions: RequestOptions(path: '/api/v3/command'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v3/command'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
      final container = _container(client: client, service: ServiceKey.radarr);
      addTearDown(container.dispose);

      final notifier = container.read(manualImportFlowProvider.notifier);
      final item = _radarrItem(movieId: 123, path: '/downloads/Inception.avi');

      // Pre-populate state with a ready, selected item (the post-fix-flow state).
      container.read(manualImportFlowProvider.notifier).state = container
          .read(manualImportFlowProvider)
          .copyWith(
            service: ServiceKey.radarr,
            items: [item],
            selectedPaths: {'/downloads/Inception.avi'},
          );

      final command = await notifier.confirmImport();

      expect(command, isNull);
      final state = container.read(manualImportFlowProvider);
      expect(state.error, isNotNull);
      expect(state.error, contains('returned 500'));
      expect(
        state.error,
        contains('Try moving the file into a folder named after the movie'),
      );
    });
  });
}

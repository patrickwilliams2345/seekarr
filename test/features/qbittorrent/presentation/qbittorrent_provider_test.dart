import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/qbittorrent/data/qbittorrent_client.dart';
import 'package:seekarr/features/qbittorrent/data/qbittorrent_service.dart';
import 'package:seekarr/features/qbittorrent/presentation/qbittorrent_provider.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';
import 'package:seekarr/features/settings/domain/settings_model.dart';

class _StubAdapter implements HttpClientAdapter {
  final Map<String, List<dynamic>> responses = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = responses[options.path] ?? <dynamic>[];
    return ResponseBody.fromBytes(
      Uint8List.fromList(utf8.encode(jsonEncode(body))),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

Map<String, dynamic> _torrentJson({
  String hash = 'aaa',
  String state = 'downloading',
  String category = '',
  String tracker = '',
  List<String> tags = const [],
}) => {
  'hash': hash,
  'name': 'A',
  'size': 100,
  'progress': 0.5,
  'state': state,
  'dlspeed': 0,
  'upspeed': 0,
  'eta': 60,
  'category': category,
  'tracker': tracker,
  'tags': tags,
  'ratio': 1.0,
  'added_on': 0,
  'completed': 0,
  'num_leechs': 0,
  'num_seeds': 0,
};

ProviderContainer _container({
  SettingsModel? settings,
  Map<String, List<dynamic>>? responses,
}) {
  final container = ProviderContainer(
    overrides: [
      currentSettingsProvider.overrideWith(
        (ref) => settings ?? const SettingsModel(),
      ),
      qbittorrentServiceProvider.overrideWith((ref) {
        final s = ref.watch(currentSettingsProvider);
        if (s.qbittorrentUrl.isEmpty) {
          throw Exception('qBittorrent not configured');
        }
        final dio = Dio(BaseOptions(baseUrl: s.qbittorrentUrl));
        final adapter = _StubAdapter();
        if (responses != null) adapter.responses.addAll(responses);
        dio.httpClientAdapter = adapter;
        final client = QbittorrentClient(
          url: s.qbittorrentUrl,
          username: s.qbittorrentUsername.isEmpty
              ? null
              : s.qbittorrentUsername,
          password: s.qbittorrentPassword.isEmpty
              ? null
              : s.qbittorrentPassword,
          dio: dio,
        );
        return QbittorrentService(client);
      }),
    ],
  );
  return container;
}

void main() {
  group('qbittorrentServiceProvider', () {
    test('throws when URL is empty', () {
      final container = _container();
      expect(() => container.read(qbittorrentServiceProvider), throwsException);
    });

    test('creates service when URL configured', () {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost:8080'),
      );
      final service = container.read(qbittorrentServiceProvider);
      expect(service, isA<QbittorrentService>());
    });
  });

  group('available* providers', () {
    test('availableCategories derives from allTorrentsProvider', () async {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
        responses: {
          '/api/v2/torrents/info': [
            _torrentJson(category: 'linux'),
            _torrentJson(category: 'movies'),
            _torrentJson(category: 'linux'), // duplicate
            _torrentJson(category: ''), // ignored
          ],
        },
      );

      // Touch allTorrentsProvider so it builds.
      await container.read(allTorrentsProvider.future);
      final cats = container.read(availableCategoriesProvider);

      expect(cats, ['linux', 'movies']);
    });

    test('availableTags aggregates all torrent tags', () async {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
        responses: {
          '/api/v2/torrents/info': [
            _torrentJson(tags: ['a', 'b']),
            _torrentJson(tags: ['b', 'c']),
          ],
        },
      );

      await container.read(allTorrentsProvider.future);
      final tags = container.read(availableTagsProvider);

      expect(tags, ['a', 'b', 'c']);
    });

    test('availableTrackers extracts domains', () async {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
        responses: {
          '/api/v2/torrents/info': [
            _torrentJson(tracker: 'https://tracker.example/announce'),
            _torrentJson(tracker: 'https://other.example/announce'),
            _torrentJson(tracker: 'https://www.tracker.example/announce'),
            _torrentJson(tracker: ''),
          ],
        },
      );

      await container.read(allTorrentsProvider.future);
      final trackers = container.read(availableTrackersProvider);

      expect(trackers, ['other.example', 'tracker.example']);
    });

    test('available* return empty when allTorrentsProvider has no data', () {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
      );
      expect(container.read(availableCategoriesProvider), isEmpty);
      expect(container.read(availableTagsProvider), isEmpty);
      expect(container.read(availableTrackersProvider), isEmpty);
    });
  });

  group('torrentsProvider filters', () {
    test(
      'queued filter applies client-side even though api filter is all',
      () async {
        final container = _container(
          settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
          responses: {
            '/api/v2/torrents/info': [
              _torrentJson(hash: 'a', state: 'downloading'),
              _torrentJson(hash: 'b', state: 'queuedDL'),
              _torrentJson(hash: 'c', state: 'queuedUP'),
            ],
          },
        );

        container.read(torrentFilterProvider.notifier).state =
            TorrentFilter.queued;
        final torrents = await container.read(torrentsProvider.future);

        expect(torrents.map((t) => t.hash), containsAll(['b', 'c']));
        expect(torrents.map((t) => t.hash), isNot(contains('a')));
      },
    );

    test('category filter is applied on top of API filter', () async {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
        responses: {
          '/api/v2/torrents/info': [
            _torrentJson(hash: 'a', category: 'linux'),
            _torrentJson(hash: 'b', category: 'movies'),
          ],
        },
      );

      container
        ..read(torrentFilterProvider.notifier).state = TorrentFilter.all
        ..read(torrentCategoryFilterProvider.notifier).state = 'linux';
      final torrents = await container.read(torrentsProvider.future);

      expect(torrents.map((t) => t.hash), ['a']);
    });

    test('tag filter narrows by tag membership', () async {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
        responses: {
          '/api/v2/torrents/info': [
            _torrentJson(hash: 'a', tags: ['4k', 'remux']),
            _torrentJson(hash: 'b', tags: ['1080p']),
          ],
        },
      );

      container
        ..read(torrentFilterProvider.notifier).state = TorrentFilter.all
        ..read(torrentTagFilterProvider.notifier).state = '4k';
      final torrents = await container.read(torrentsProvider.future);

      expect(torrents.map((t) => t.hash), ['a']);
    });

    test('tracker filter narrows by domain', () async {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
        responses: {
          '/api/v2/torrents/info': [
            _torrentJson(hash: 'a', tracker: 'https://alpha.example/announce'),
            _torrentJson(hash: 'b', tracker: 'https://beta.example/announce'),
          ],
        },
      );

      container
        ..read(torrentFilterProvider.notifier).state = TorrentFilter.all
        ..read(torrentTrackerFilterProvider.notifier).state = 'alpha.example';
      final torrents = await container.read(torrentsProvider.future);

      expect(torrents.map((t) => t.hash), ['a']);
    });
  });

  group('qbittorrentTorrentsProvider', () {
    test('forwards hashes query to service', () async {
      final container = _container(
        settings: const SettingsModel(qbittorrentUrl: 'http://localhost'),
        responses: {
          '/api/v2/torrents/info': [_torrentJson(hash: 'a')],
        },
      );

      final torrents = await container.read(
        qbittorrentTorrentsProvider('a').future,
      );
      expect(torrents, hasLength(1));
      expect(torrents.first.hash, 'a');
    });
  });
}

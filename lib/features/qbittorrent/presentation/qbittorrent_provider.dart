import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: implementation_imports
import 'package:flutter_riverpod/legacy.dart';

import 'package:seekarr/features/qbittorrent/data/qbittorrent_client.dart';
import 'package:seekarr/features/qbittorrent/data/qbittorrent_service.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_file.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_tracker.dart';
import 'package:seekarr/features/qbittorrent/domain/models/transfer_info.dart';
import 'package:seekarr/features/settings/data/settings_provider.dart';

final qbittorrentServiceProvider = Provider<QbittorrentService>((ref) {
  final settings = ref.watch(currentSettingsProvider);
  if (settings.qbittorrentUrl.isEmpty) {
    throw Exception('qBittorrent not configured');
  }
  final client = QbittorrentClient(
    url: settings.qbittorrentUrl,
    username: settings.qbittorrentUsername.isNotEmpty
        ? settings.qbittorrentUsername
        : null,
    password: settings.qbittorrentPassword.isNotEmpty
        ? settings.qbittorrentPassword
        : null,
  );
  return QbittorrentService(client);
});

enum TorrentFilter { all, downloading, seeding, paused, queued }

final torrentFilterProvider = StateProvider<TorrentFilter>(
  (ref) => TorrentFilter.all,
);

final torrentsProvider = FutureProvider<List<Torrent>>((ref) async {
  final service = ref.watch(qbittorrentServiceProvider);
  final filter = ref.watch(torrentFilterProvider);

  String? apiFilter;
  switch (filter) {
    case TorrentFilter.downloading:
      apiFilter = 'downloading';
    case TorrentFilter.seeding:
      apiFilter = 'seeding';
    case TorrentFilter.paused:
      apiFilter = 'paused';
    case TorrentFilter.queued:
      apiFilter = 'all';
    case TorrentFilter.all:
      apiFilter = 'all';
  }

  return service.getTorrents(filter: apiFilter);
});

final qbittorrentTorrentsProvider =
    FutureProvider.family<List<Torrent>, String>((ref, hash) async {
      final service = ref.watch(qbittorrentServiceProvider);
      return service.getTorrents(hashes: hash);
    });

final torrentFilesProvider = FutureProvider.family<List<TorrentFile>, String>((
  ref,
  hash,
) async {
  final service = ref.watch(qbittorrentServiceProvider);
  return service.getTorrentFiles(hash);
});

final torrentTrackersProvider =
    FutureProvider.family<List<TorrentTracker>, String>((ref, hash) async {
      final service = ref.watch(qbittorrentServiceProvider);
      return service.getTorrentTrackers(hash);
    });

final transferInfoProvider = FutureProvider<TransferInfo>((ref) async {
  final service = ref.watch(qbittorrentServiceProvider);
  return service.getTransferInfo();
});

final selectedTorrentHashesProvider = StateProvider<Set<String>>((ref) => {});

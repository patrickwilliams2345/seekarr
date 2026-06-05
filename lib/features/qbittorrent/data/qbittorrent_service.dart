import 'package:flutter/foundation.dart';

import 'package:seekarr/features/qbittorrent/data/qbittorrent_client.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_file.dart';
import 'package:seekarr/features/qbittorrent/domain/models/torrent_tracker.dart';
import 'package:seekarr/features/qbittorrent/domain/models/transfer_info.dart';

List<Torrent> _parseTorrentList(List<dynamic> json) {
  return json
      .cast<Map<String, dynamic>>()
      .map(Torrent.fromJson)
      .toList(growable: false);
}

class QbittorrentService {
  final QbittorrentClient _client;

  QbittorrentService(this._client);

  String? get baseUrl => _client.baseUrl.isNotEmpty ? _client.baseUrl : null;

  Future<bool> authenticate() => _client.authenticate();

  Future<String> getVersion() => _client.getVersion();

  Future<List<Torrent>> getTorrents({
    String? filter,
    String? category,
    String? sort,
    bool? reverse,
    String? hashes,
  }) async {
    final params = <String, dynamic>{};
    if (filter != null) params['filter'] = filter;
    if (category != null) params['category'] = category;
    if (sort != null) params['sort'] = sort;
    if (reverse == true) params['reverse'] = true;
    if (hashes != null) params['hashes'] = hashes;

    final response = await _client.get(
      '/api/v2/torrents/info',
      queryParameters: params.isNotEmpty ? params : null,
    );

    final List<dynamic> raw = response.data is List
        ? response.data as List<dynamic>
        : [];
    if (raw.length > 200) {
      return compute(_parseTorrentList, raw);
    }
    return raw
        .map((e) => Torrent.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<TorrentFile>> getTorrentFiles(String hash) async {
    final response = await _client.get(
      '/api/v2/torrents/files',
      queryParameters: {'hash': hash},
    );

    final List<dynamic> raw = response.data is List
        ? response.data as List<dynamic>
        : [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(TorrentFile.fromJson)
        .toList(growable: false);
  }

  Future<List<TorrentTracker>> getTorrentTrackers(String hash) async {
    final response = await _client.get(
      '/api/v2/torrents/trackers',
      queryParameters: {'hash': hash},
    );

    final List<dynamic> raw = response.data is List
        ? response.data as List<dynamic>
        : [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(TorrentTracker.fromJson)
        .toList(growable: false);
  }

  Future<TransferInfo> getTransferInfo() async {
    final response = await _client.get('/api/v2/transfer/info');
    return TransferInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> pauseTorrents(List<String> hashes) async {
    await _client.post(
      '/api/v2/torrents/stop',
      data: {'hashes': hashes.join('|')},
    );
  }

  Future<void> resumeTorrents(List<String> hashes) async {
    await _client.post(
      '/api/v2/torrents/start',
      data: {'hashes': hashes.join('|')},
    );
  }

  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    await _client.post(
      '/api/v2/torrents/delete',
      data: {
        'hashes': hashes.join('|'),
        'deleteFiles': deleteFiles.toString(),
      },
    );
  }

  Future<void> addTorrentUrl(
    String url, {
    String? category,
    String? savePath,
  }) async {
    final data = <String, dynamic>{'urls': url};
    if (category != null) data['category'] = category;
    if (savePath != null) data['savepath'] = savePath;

    await _client.post('/api/v2/torrents/add', data: data);
  }

  Future<void> setCategory(List<String> hashes, String category) async {
    await _client.post(
      '/api/v2/torrents/setCategory',
      data: {'hashes': hashes.join('|'), 'category': category},
    );
  }

  Future<void> addTags(List<String> hashes, List<String> tags) async {
    await _client.post(
      '/api/v2/torrents/addTags',
      data: {'hashes': hashes.join('|'), 'tags': tags.join(',')},
    );
  }

  Future<void> removeTags(List<String> hashes, List<String> tags) async {
    await _client.post(
      '/api/v2/torrents/removeTags',
      data: {'hashes': hashes.join('|'), 'tags': tags.join(',')},
    );
  }

  Future<void> setDownloadLimit(
    List<String> hashes,
    int limitBytesPerSecond,
  ) async {
    await _client.post(
      '/api/v2/torrents/setDownloadLimit',
      data: {
        'hashes': hashes.join('|'),
        'limit': limitBytesPerSecond,
      },
    );
  }

  Future<void> setUploadLimit(
    List<String> hashes,
    int limitBytesPerSecond,
  ) async {
    await _client.post(
      '/api/v2/torrents/setUploadLimit',
      data: {
        'hashes': hashes.join('|'),
        'limit': limitBytesPerSecond,
      },
    );
  }

  Future<void> setForceStart(List<String> hashes, bool value) async {
    await _client.post(
      '/api/v2/torrents/setForceStart',
      data: {'hashes': hashes.join('|'), 'value': value.toString()},
    );
  }

  Future<void> toggleAlternativeSpeedLimits() async {
    await _client.post('/api/v2/transfer/toggleSpeedLimitsMode');
  }
}

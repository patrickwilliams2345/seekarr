import 'parse_utils.dart';

enum TorrentState {
  downloading,
  metaDownloading,
  seeding,
  stalled,
  checking,
  paused,
  queuedUp,
  queuedDl,
  error,
  unknown;

  String get label {
    switch (this) {
      case TorrentState.downloading:
        return 'DL';
      case TorrentState.metaDownloading:
        return 'META';
      case TorrentState.seeding:
        return 'SEED';
      case TorrentState.stalled:
        return 'STALLED';
      case TorrentState.checking:
        return 'CHECK';
      case TorrentState.paused:
        return 'PAUSE';
      case TorrentState.queuedUp:
      case TorrentState.queuedDl:
        return 'QUEUE';
      case TorrentState.error:
        return 'ERR';
      case TorrentState.unknown:
        return '—';
    }
  }

  bool get isActive =>
      this == TorrentState.downloading ||
      this == TorrentState.metaDownloading ||
      this == TorrentState.seeding;

  bool get isPaused => this == TorrentState.paused;

  bool get isQueued =>
      this == TorrentState.queuedUp || this == TorrentState.queuedDl;

  static TorrentState fromString(String? state) {
    return switch (state) {
      'downloading' || 'forcedDL' => TorrentState.downloading,
      'metaDL' => TorrentState.metaDownloading,
      'uploading' || 'forcedUP' => TorrentState.seeding,
      'stalledUP' => TorrentState.seeding,
      'stalledDL' => TorrentState.stalled,
      'checkingUP' || 'checkingDL' => TorrentState.checking,
      'pausedUP' || 'pausedDL' => TorrentState.paused,
      'stoppedUP' || 'stoppedDL' || 'stopped' => TorrentState.paused,
      'queuedUP' => TorrentState.queuedUp,
      'queuedDL' => TorrentState.queuedDl,
      'moving' || 'allocating' => TorrentState.downloading,
      'error' || 'missingFiles' => TorrentState.error,
      _ => TorrentState.unknown,
    };
  }
}

class Torrent {
  final String hash;
  final String name;
  final int size;
  final double progress;
  final String state;
  final TorrentState parsedState;
  final int dlSpeed;
  final int upSpeed;
  final int eta;
  final String category;
  final String tracker;
  final List<String> tags;
  final double ratio;
  final int addedOn;
  final int completed;
  final int leechers;
  final int seeders;

  const Torrent({
    required this.hash,
    required this.name,
    required this.size,
    required this.progress,
    required this.state,
    required this.parsedState,
    required this.dlSpeed,
    required this.upSpeed,
    required this.eta,
    required this.category,
    required this.tracker,
    required this.tags,
    required this.ratio,
    required this.addedOn,
    required this.completed,
    required this.leechers,
    required this.seeders,
  });

  factory Torrent.fromJson(Map<String, dynamic> json) {
    return Torrent(
      hash: json['hash'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: parseInt(json['size']),
      progress: parseDouble(json['progress']),
      state: json['state'] as String? ?? '',
      parsedState: TorrentState.fromString(json['state'] as String?),
      dlSpeed: parseInt(json['dlspeed']),
      upSpeed: parseInt(json['upspeed']),
      eta: parseInt(json['eta']),
      category: json['category'] as String? ?? '',
      tracker: json['tracker'] as String? ?? '',
      tags: _parseTags(json['tags']),
      ratio: parseDouble(json['ratio']),
      addedOn: parseInt(json['added_on']),
      completed: parseInt(json['completed']),
      leechers: parseInt(json['num_leechs']),
      seeders: parseInt(json['num_seeds']),
    );
  }

  static List<String> _parseTags(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    final str = value?.toString() ?? '';
    if (str.isEmpty) return [];
    return str
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  String get sizeFormatted => formatSize(size);

  String get dlSpeedFormatted {
    if (dlSpeed <= 0) return '0';
    return formatSpeed(dlSpeed);
  }

  String get upSpeedFormatted {
    if (upSpeed <= 0) return '0';
    return formatSpeed(upSpeed);
  }

  String get etaFormatted {
    if (eta < 0 ||
        state == 'pausedDL' ||
        state == 'pausedUP' ||
        state == 'stoppedDL' ||
        state == 'stoppedUP' ||
        state == 'stopped') {
      return '';
    }
    if (eta >= 8640000) return '∞';
    final d = eta ~/ 86400;
    final h = (eta % 86400) ~/ 3600;
    final m = (eta % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get progressFormatted => '${(progress * 100).toStringAsFixed(1)}%';

  String get trackerDomain {
    if (tracker.isEmpty) return '';
    try {
      final uri = Uri.parse(tracker);
      final host = uri.host;
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return '';
    }
  }
}

import 'parse_utils.dart';

class TorrentTracker {
  final String url;
  final int status;
  final int tier;
  final int numPeers;
  final int numSeeds;
  final int numLeeches;
  final int numDownloaded;
  final String msg;

  const TorrentTracker({
    required this.url,
    required this.status,
    required this.tier,
    required this.numPeers,
    required this.numSeeds,
    required this.numLeeches,
    required this.numDownloaded,
    required this.msg,
  });

  factory TorrentTracker.fromJson(Map<String, dynamic> json) {
    return TorrentTracker(
      url: json['url'] as String? ?? '',
      status: parseInt(json['status']),
      tier: parseInt(json['tier']),
      numPeers: parseInt(json['num_peers']),
      numSeeds: parseInt(json['num_seeds']),
      numLeeches: parseInt(json['num_leeches']),
      numDownloaded: parseInt(json['num_downloaded']),
      msg: json['msg']?.toString() ?? '',
    );
  }

  String get statusLabel {
    switch (status) {
      case 0:
        return 'Disabled';
      case 1:
        return 'Not contacted';
      case 2:
        return 'Working';
      case 3:
        return 'Updating';
      case 4:
        return 'Not working';
      default:
        return 'Unknown';
    }
  }
}

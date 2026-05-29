import 'parse_utils.dart';

class TorrentTracker {
  final String url;
  final String status;
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
      status: json['status'] as String? ?? '',
      tier: parseInt(json['tier']),
      numPeers: parseInt(json['num_peers']),
      numSeeds: parseInt(json['num_seeds']),
      numLeeches: parseInt(json['num_leeches']),
      numDownloaded: parseInt(json['num_downloaded']),
      msg: json['msg'] as String? ?? '',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'Working':
        return 'Working';
      case 'Updating':
        return 'Updating';
      case 'Not working':
        return 'Not working';
      case 'Not contacted yet':
        return 'Not contacted yet';
      default:
        return status;
    }
  }
}

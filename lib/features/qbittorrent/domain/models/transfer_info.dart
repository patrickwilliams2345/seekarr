import 'parse_utils.dart';

class TransferInfo {
  final int dlSpeed;
  final int upSpeed;
  final int dlInfoData;
  final int upInfoData;
  final int dlRateLimit;
  final int upRateLimit;
  final bool altSpeedEnabled;

  const TransferInfo({
    required this.dlSpeed,
    required this.upSpeed,
    required this.dlInfoData,
    required this.upInfoData,
    required this.dlRateLimit,
    required this.upRateLimit,
    required this.altSpeedEnabled,
  });

  factory TransferInfo.fromJson(Map<String, dynamic> json) {
    return TransferInfo(
      dlSpeed: parseInt(json['dl_info_speed']),
      upSpeed: parseInt(json['up_info_speed']),
      dlInfoData: parseInt(json['dl_info_data']),
      upInfoData: parseInt(json['up_info_data']),
      dlRateLimit: parseInt(json['dl_rate_limit']),
      upRateLimit: parseInt(json['up_rate_limit']),
      altSpeedEnabled: json['use_alt_speed_limits'] == true,
    );
  }

  String get dlSpeedFormatted {
    if (dlSpeed <= 0) return '0 B/s';
    return formatSpeed(dlSpeed);
  }

  String get upSpeedFormatted {
    if (upSpeed <= 0) return '0 B/s';
    return formatSpeed(upSpeed);
  }
}

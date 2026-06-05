import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/qbittorrent/domain/models/parse_utils.dart';

void main() {
  group('parseInt', () {
    test('returns int as-is', () {
      expect(parseInt(42), 42);
    });

    test('truncates double to int', () {
      expect(parseInt(3.9), 3);
      expect(parseInt(-1.5), -1);
    });

    test('parses numeric string', () {
      expect(parseInt('123'), 123);
    });

    test('returns 0 for invalid or null', () {
      expect(parseInt(null), 0);
      expect(parseInt('not a number'), 0);
      expect(parseInt({}), 0);
    });
  });

  group('parseDouble', () {
    test('returns double as-is', () {
      expect(parseDouble(3.14), 3.14);
    });

    test('promotes int to double', () {
      expect(parseDouble(7), 7.0);
    });

    test('parses numeric string', () {
      expect(parseDouble('2.5'), 2.5);
    });

    test('returns 0 for invalid or null', () {
      expect(parseDouble(null), 0);
      expect(parseDouble('not a number'), 0);
    });
  });

  group('formatSize', () {
    test('returns em-dash for non-positive values', () {
      expect(formatSize(0), '—');
      expect(formatSize(-10), '—');
    });

    test('formats bytes', () {
      expect(formatSize(512), '512.0 B');
    });

    test('formats kilobytes', () {
      expect(formatSize(2048), '2.0 KB');
    });

    test('formats megabytes', () {
      expect(formatSize(5 * 1024 * 1024), '5.0 MB');
    });

    test('formats gigabytes', () {
      expect(formatSize(2 * 1024 * 1024 * 1024), '2.0 GB');
    });

    test('formats terabytes', () {
      expect(formatSize(1024 * 1024 * 1024 * 1024), '1.0 TB');
    });
  });

  group('formatSpeed', () {
    test('returns 0 B/s for non-positive values', () {
      expect(formatSpeed(0), '0 B/s');
      expect(formatSpeed(-1), '0 B/s');
    });

    test('formats KB/s', () {
      expect(formatSpeed(2048), '2.0 KB/s');
    });

    test('formats MB/s', () {
      expect(formatSpeed(52 * 1024 * 1024), '52.0 MB/s');
    });

    test('formats GB/s', () {
      expect(formatSpeed(3 * 1024 * 1024 * 1024), '3.0 GB/s');
    });
  });
}

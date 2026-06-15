import 'package:flutter/material.dart';

Future<String?> showEditCategoryDialog(
  BuildContext context, {
  required String currentCategory,
}) {
  final controller = TextEditingController(text: currentCategory);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Set category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category',
            hintText: 'Leave empty to clear',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<List<String>?> showEditTagsDialog(
  BuildContext context, {
  required List<String> currentTags,
}) {
  final controller = TextEditingController(text: currentTags.join(', '));
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Set tags'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tags (comma-separated)',
            hintText: 'e.g. 4k, italian, dubbed',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitTags(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submitTags(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

List<String> _submitTags(BuildContext ctx, String raw) {
  final tags = raw
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
  Navigator.of(ctx).pop(tags);
  return tags;
}

class SpeedLimitResult {
  final int? bytesPerSecond;
  const SpeedLimitResult._(this.bytesPerSecond);
  static const noChange = SpeedLimitResult._(null);
  factory SpeedLimitResult.kbps(int kbps) => SpeedLimitResult._(kbps * 1024);
}

Future<SpeedLimitResult?> showSpeedLimitDialog(
  BuildContext context, {
  required String title,
  required int currentLimitBytes,
}) {
  final controller = TextEditingController(
    text: currentLimitBytes > 0
        ? (currentLimitBytes / 1024).toStringAsFixed(0)
        : '',
  );
  return showDialog<SpeedLimitResult>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Limit (KB/s)',
            hintText: '0 = no limit',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitSpeedLimit(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submitSpeedLimit(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

SpeedLimitResult _submitSpeedLimit(BuildContext ctx, String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    Navigator.of(ctx).pop(const SpeedLimitResult._(0));
    return const SpeedLimitResult._(0);
  }
  final kbps = double.tryParse(trimmed.replaceAll(',', '.'));
  if (kbps == null || kbps < 0) {
    Navigator.of(ctx).pop(SpeedLimitResult.noChange);
    return SpeedLimitResult.noChange;
  }
  final result = kbps == 0
      ? const SpeedLimitResult._(0)
      : SpeedLimitResult._((kbps * 1024).round());
  Navigator.of(ctx).pop(result);
  return result;
}

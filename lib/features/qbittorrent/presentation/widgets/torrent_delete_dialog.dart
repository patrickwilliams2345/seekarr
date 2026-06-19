import 'package:flutter/material.dart';

import 'package:seekarr/core/app_radius.dart';
import 'package:seekarr/core/app_spacing.dart';

/// Result returned by [showTorrentDeleteDialog].
class TorrentDeleteResult {
  final bool confirmed;
  final bool deleteFiles;

  const TorrentDeleteResult({
    required this.confirmed,
    required this.deleteFiles,
  });

  static const cancelled = TorrentDeleteResult(
    confirmed: false,
    deleteFiles: false,
  );
}

/// Shows a confirmation dialog for deleting one or more torrents with a
/// warning banner when "Delete files" is selected. Returns
/// [TorrentDeleteResult.cancelled] when the user dismisses the dialog.
Future<TorrentDeleteResult> showTorrentDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  bool multi = false,
}) async {
  bool deleteFiles = false;

  final result = await showDialog<TorrentDeleteResult>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      final errorColor = colorScheme.error;

      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: errorColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                CheckboxListTile(
                  value: deleteFiles,
                  onChanged: (value) =>
                      setState(() => deleteFiles = value ?? false),
                  title: Text(
                    'Delete files',
                    style: TextStyle(
                      color: deleteFiles ? errorColor : null,
                      fontWeight: deleteFiles ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(
                    'Permanently delete downloaded files from disk',
                    style: Theme.of(dialogContext).textTheme.bodySmall
                        ?.copyWith(color: deleteFiles ? errorColor : null),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (deleteFiles) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.10),
                      borderRadius: AppRadius.borderRadiusSm,
                      border: Border.all(
                        color: errorColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            multi
                                ? 'This cannot be undone! All selected torrents and their files will be permanently removed.'
                                : 'This cannot be undone! Files will be permanently removed from disk.',
                            style: TextStyle(
                              color: errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(
                  dialogContext,
                ).pop(TorrentDeleteResult.cancelled),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(
                  TorrentDeleteResult(
                    confirmed: true,
                    deleteFiles: deleteFiles,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: colorScheme.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    },
  );

  return result ?? TorrentDeleteResult.cancelled;
}

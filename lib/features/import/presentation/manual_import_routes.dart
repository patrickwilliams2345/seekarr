import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:seekarr/features/settings/domain/service_key.dart';

const manualImportPathPrefix = '/import';
const manualImportBrowsePath = '$manualImportPathPrefix/browse';
const manualImportFolderPath = '$manualImportPathPrefix/folder';
const manualImportMatchPath = '$manualImportPathPrefix/match';
const manualImportProgressPath = '$manualImportPathPrefix/progress';

ServiceKey? manualImportServiceFromRoute(String? value) {
  final normalized = value?.trim().toLowerCase();
  for (final service in ServiceKey.values) {
    if (service.supportsManualImport && service.routeParam == normalized) {
      return service;
    }
  }
  return null;
}

String manualImportLocation(String path, ServiceKey service, {int? targetId}) {
  return Uri(
    path: path,
    queryParameters: {
      'service': service.routeParam,
      if (targetId != null && targetId > 0) 'targetId': '$targetId',
    },
  ).toString();
}

VoidCallback? openManualImportCallback(
  BuildContext context,
  ServiceKey service,
  int targetId,
) {
  if (targetId <= 0) return null;
  return () => context.push(
    manualImportLocation(manualImportBrowsePath, service, targetId: targetId),
  );
}

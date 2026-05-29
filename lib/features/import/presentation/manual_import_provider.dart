import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/features/import/data/manual_import_service.dart';
import 'package:seekarr/features/import/domain/manual_import_models.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

const Object _noValue = Object();

final manualImportFlowProvider =
    NotifierProvider<ManualImportFlowNotifier, ManualImportFlowState>(
      ManualImportFlowNotifier.new,
    );

class ManualImportFlowState {
  final ServiceKey? service;
  final int? targetId;
  final List<ManualImportRootFolder> rootFolders;
  final ManualImportFileSystemResult? fileSystem;
  final String? currentPath;
  final String? selectedFolder;
  final List<ManualImportItem> items;
  final Set<String> selectedPaths;
  final Set<String> bulkFixPaths;
  final List<ManualImportItem> submittedItems;
  final List<ManualImportQualityOption> qualityOptions;
  final List<ManualImportLanguageOption> languageOptions;
  final ManualImportCommandStatus? command;
  final bool isLoadingBrowse;
  final bool isLoadingItems;
  final bool isReprocessing;
  final bool isSubmitting;
  final ManualImportMode importMode;
  final String? error;

  const ManualImportFlowState({
    this.service,
    this.targetId,
    this.rootFolders = const [],
    this.fileSystem,
    this.currentPath,
    this.selectedFolder,
    this.items = const [],
    this.selectedPaths = const {},
    this.bulkFixPaths = const {},
    this.submittedItems = const [],
    this.qualityOptions = const [],
    this.languageOptions = const [],
    this.command,
    this.isLoadingBrowse = false,
    this.isLoadingItems = false,
    this.isReprocessing = false,
    this.isSubmitting = false,
    this.importMode = ManualImportMode.auto,
    this.error,
  });

  List<ManualImportItem> get selectedItems => items
      .where((item) => selectedPaths.contains(item.path))
      .toList(growable: false);

  List<ManualImportItem> get bulkFixItems => items
      .where((item) => bulkFixPaths.contains(item.path))
      .toList(growable: false);

  List<ManualImportItem> get selectableItems =>
      items.where((item) => item.isSelectable).toList(growable: false);

  bool get hasSelectedItems => selectedPaths.isNotEmpty;

  bool get allSelectableSelected =>
      selectableItems.isNotEmpty &&
      selectableItems.every((item) => selectedPaths.contains(item.path));

  bool get canImportSelected =>
      service != null &&
      selectedItems.isNotEmpty &&
      selectedItems.every((item) => item.isReadyForImportFor(service!)) &&
      !isSubmitting;

  ManualImportFlowState copyWith({
    Object? service = _noValue,
    Object? targetId = _noValue,
    List<ManualImportRootFolder>? rootFolders,
    Object? fileSystem = _noValue,
    Object? currentPath = _noValue,
    Object? selectedFolder = _noValue,
    List<ManualImportItem>? items,
    Set<String>? selectedPaths,
    Set<String>? bulkFixPaths,
    List<ManualImportItem>? submittedItems,
    List<ManualImportQualityOption>? qualityOptions,
    List<ManualImportLanguageOption>? languageOptions,
    Object? command = _noValue,
    bool? isLoadingBrowse,
    bool? isLoadingItems,
    bool? isReprocessing,
    bool? isSubmitting,
    ManualImportMode? importMode,
    Object? error = _noValue,
  }) {
    return ManualImportFlowState(
      service: identical(service, _noValue)
          ? this.service
          : service as ServiceKey?,
      targetId: identical(targetId, _noValue)
          ? this.targetId
          : targetId as int?,
      rootFolders: rootFolders ?? this.rootFolders,
      fileSystem: identical(fileSystem, _noValue)
          ? this.fileSystem
          : fileSystem as ManualImportFileSystemResult?,
      currentPath: identical(currentPath, _noValue)
          ? this.currentPath
          : currentPath as String?,
      selectedFolder: identical(selectedFolder, _noValue)
          ? this.selectedFolder
          : selectedFolder as String?,
      items: items ?? this.items,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      bulkFixPaths: bulkFixPaths ?? this.bulkFixPaths,
      submittedItems: submittedItems ?? this.submittedItems,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      languageOptions: languageOptions ?? this.languageOptions,
      command: identical(command, _noValue)
          ? this.command
          : command as ManualImportCommandStatus?,
      isLoadingBrowse: isLoadingBrowse ?? this.isLoadingBrowse,
      isLoadingItems: isLoadingItems ?? this.isLoadingItems,
      isReprocessing: isReprocessing ?? this.isReprocessing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      importMode: importMode ?? this.importMode,
      error: identical(error, _noValue) ? this.error : error as String?,
    );
  }
}

class ManualImportFlowNotifier extends Notifier<ManualImportFlowState> {
  @override
  ManualImportFlowState build() => const ManualImportFlowState();

  Future<void> start(
    ServiceKey service, {
    int? targetId,
    bool force = false,
  }) async {
    if (!force &&
        state.service == service &&
        state.targetId == targetId &&
        state.rootFolders.isNotEmpty) {
      return;
    }

    state = ManualImportFlowState(
      service: service,
      targetId: targetId,
      isLoadingBrowse: true,
    );

    try {
      final api = ref.read(manualImportServiceProvider(service));
      final rootFolders = await api.getRootFolders();
      const defaultPath = '/';
      state = state.copyWith(
        rootFolders: rootFolders,
        isLoadingBrowse: false,
        currentPath: defaultPath,
        selectedFolder: defaultPath,
        error: null,
      );
      await selectFolder(defaultPath);
    } catch (error) {
      state = state.copyWith(isLoadingBrowse: false, error: error.toString());
    }
  }

  Future<void> selectFolder(String path) async {
    final service = state.service;
    if (service == null || path.isEmpty) return;

    state = state.copyWith(
      currentPath: path,
      selectedFolder: path,
      fileSystem: null,
      isLoadingBrowse: true,
      error: null,
    );

    try {
      final api = ref.read(manualImportServiceProvider(service));
      final fileSystem = await api.getFileSystem(path);
      state = state.copyWith(fileSystem: fileSystem, isLoadingBrowse: false);
    } catch (error) {
      state = state.copyWith(isLoadingBrowse: false, error: error.toString());
    }
  }

  Future<void> loadSelectedFolderItems() async {
    await _refreshSelectedFolderItems(clearItems: true);
  }

  Future<List<ManualImportItem>> _refreshSelectedFolderItems({
    bool preserveSelection = false,
    bool clearItems = false,
  }) async {
    final service = state.service;
    final folder = state.selectedFolder;
    if (service == null || folder == null || folder.isEmpty) return const [];

    final previousSelected = state.selectedPaths;
    final previousBulk = state.bulkFixPaths;

    state = state.copyWith(
      isLoadingItems: true,
      items: clearItems ? const [] : null,
      selectedPaths: preserveSelection ? null : const {},
      bulkFixPaths: preserveSelection ? null : const {},
      command: null,
      error: null,
    );

    try {
      final api = ref.read(manualImportServiceProvider(service));
      final items = await api.getManualImportItems(folder: folder);
      final selectablePaths = items
          .where((item) => item.isSelectable)
          .map((item) => item.path)
          .toSet();
      final selectedPaths = preserveSelection
          ? previousSelected.intersection(selectablePaths)
          : selectablePaths;
      final bulkFixPaths = preserveSelection
          ? previousBulk.intersection(selectedPaths)
          : const <String>{};
      state = state.copyWith(
        items: items,
        selectedPaths: selectedPaths,
        bulkFixPaths: bulkFixPaths,
        isLoadingItems: false,
      );
      return items;
    } catch (error) {
      state = state.copyWith(isLoadingItems: false, error: error.toString());
      return const [];
    }
  }

  void toggleItem(ManualImportItem item, bool selected) {
    if (!item.isSelectable) return;
    final next = {...state.selectedPaths};
    final nextBulk = {...state.bulkFixPaths};
    if (selected) {
      next.add(item.path);
    } else {
      next.remove(item.path);
      nextBulk.remove(item.path);
    }
    state = state.copyWith(selectedPaths: next, bulkFixPaths: nextBulk);
  }

  void toggleAllSelectable() {
    if (state.allSelectableSelected) {
      state = state.copyWith(selectedPaths: const {}, bulkFixPaths: const {});
      return;
    }

    state = state.copyWith(
      selectedPaths: state.selectableItems.map((item) => item.path).toSet(),
    );
  }

  void toggleBulkFixItem(ManualImportItem item, bool selected) {
    if (!state.selectedPaths.contains(item.path)) return;
    final next = {...state.bulkFixPaths};
    if (selected) {
      next.add(item.path);
    } else {
      next.remove(item.path);
    }
    state = state.copyWith(bulkFixPaths: next);
  }

  void clearBulkFixSelection() {
    state = state.copyWith(bulkFixPaths: const {});
  }

  Future<List<ManualImportLookupResult>> lookup(String term) async {
    final service = state.service;
    if (service == null) return const [];
    return ref.read(manualImportServiceProvider(service)).lookup(term);
  }

  Future<List<ManualImportLookupResult>> getLibraryMatches() async {
    final service = state.service;
    if (service == null) return const [];
    return ref.read(manualImportServiceProvider(service)).getLibraryMatches();
  }

  Future<List<ManualImportQualityOption>> getQualityOptions() async {
    final service = state.service;
    if (service == null) return const [];
    if (state.qualityOptions.isNotEmpty) return state.qualityOptions;

    try {
      final options = await ref
          .read(manualImportServiceProvider(service))
          .getQualityOptions();
      state = state.copyWith(qualityOptions: options);
      return options;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return const [];
    }
  }

  Future<List<ManualImportLanguageOption>> getLanguageOptions() async {
    final service = state.service;
    if (service == null) return const [];
    if (state.languageOptions.isNotEmpty) return state.languageOptions;

    try {
      final options = await ref
          .read(manualImportServiceProvider(service))
          .getLanguageOptions();
      state = state.copyWith(languageOptions: options);
      return options;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return const [];
    }
  }

  void setImportMode(ManualImportMode importMode) {
    state = state.copyWith(importMode: importMode);
  }

  Future<ManualImportItem?> reprocessItem(
    ManualImportItem item,
    ManualImportFixAssignment assignment,
  ) async {
    final service = state.service;
    if (service == null) return null;

    state = state.copyWith(isReprocessing: true, error: null);
    try {
      final api = ref.read(manualImportServiceProvider(service));
      final reprocessed = await api.reprocessItem(
        item: item,
        assignment: assignment,
      );
      final merged = item.mergedWithReprocessed(reprocessed);
      final updated = merged.resolvedWithAssignment(service, assignment);
      state = state.copyWith(
        items: [
          for (final existing in state.items)
            if (existing.path == item.path || existing.id == item.id)
              updated
            else
              existing,
        ],
        isReprocessing: false,
      );
      return updated;
    } catch (error) {
      state = state.copyWith(isReprocessing: false, error: error.toString());
      return null;
    }
  }

  Future<ManualImportItem?> updateItemMetadata(
    ManualImportItem item, {
    ManualImportQualityOption? quality,
    List<ManualImportLanguageOption>? languages,
  }) async {
    final service = state.service;
    if (service == null) return null;
    if (!item.hasMatchFor(service)) return item;

    final qualityOverride = quality?.toQualityModel(
      currentQuality: item.quality,
    );
    final languageOverride = languages
        ?.map((item) => item.toLanguageResource())
        .toList(growable: false);
    final draft = item.withMetadataOverrides(
      quality: qualityOverride,
      languages: languageOverride,
    );

    final assignment = _assignmentForItem(service, draft);

    return reprocessItem(draft, assignment);
  }

  Future<List<ManualImportItem>> reprocessItems(
    Map<ManualImportItem, ManualImportFixAssignment> assignments,
  ) async {
    final service = state.service;
    if (service == null || assignments.isEmpty) return const [];

    state = state.copyWith(isReprocessing: true, error: null);
    try {
      final api = ref.read(manualImportServiceProvider(service));
      final updatedByPath = <String, ManualImportItem>{};
      for (final entry in assignments.entries) {
        final reprocessed = await api.reprocessItem(
          item: entry.key,
          assignment: entry.value,
        );
        updatedByPath[entry.key.path] = entry.key
            .mergedWithReprocessed(reprocessed)
            .resolvedWithAssignment(service, entry.value);
      }
      state = state.copyWith(
        items: [
          for (final existing in state.items)
            updatedByPath[existing.path] ?? existing,
        ],
        bulkFixPaths: const {},
        isReprocessing: false,
      );
      final refreshed = state.items
          .where((item) => updatedByPath.containsKey(item.path))
          .toList(growable: false);
      return refreshed;
    } catch (error) {
      state = state.copyWith(isReprocessing: false, error: error.toString());
      return const [];
    }
  }

  Future<List<ManualImportEpisode>> getEpisodes({
    required int seriesId,
    int? seasonNumber,
  }) async {
    final service = state.service;
    if (service != ServiceKey.sonarr) return const [];
    return ref
        .read(manualImportServiceProvider(service!))
        .getEpisodes(seriesId: seriesId, seasonNumber: seasonNumber);
  }

  Future<List<ManualImportAlbum>> getAlbums(int artistId) async {
    final service = state.service;
    if (service != ServiceKey.lidarr) return const [];
    return ref.read(manualImportServiceProvider(service!)).getAlbums(artistId);
  }

  Future<List<ManualImportTrack>> getTracks(int albumId) async {
    final service = state.service;
    if (service != ServiceKey.lidarr) return const [];
    return ref
        .read(manualImportServiceProvider(service!))
        .getTracks(albumId: albumId);
  }

  Future<ManualImportCommandStatus?> confirmImport() async {
    final service = state.service;
    if (service == null || !state.canImportSelected) return null;

    final files = state.selectedItems;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final api = ref.read(manualImportServiceProvider(service));
      final command = await api.startManualImport(
        files,
        importMode: state.importMode,
      );
      state = state.copyWith(
        command: command,
        submittedItems: files,
        isSubmitting: false,
      );
      return command;
    } catch (error) {
      state = state.copyWith(isSubmitting: false, error: error.toString());
      return null;
    }
  }

  Future<void> pollCommand() async {
    final service = state.service;
    final command = state.command;
    if (service == null || command == null || !command.isActive) return;

    try {
      final api = ref.read(manualImportServiceProvider(service));
      final next = await api.getCommand(command.id);
      state = state.copyWith(command: next);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }
}

ManualImportFixAssignment _assignmentForItem(
  ServiceKey service,
  ManualImportItem item,
) {
  final matchPayload = switch (service) {
    ServiceKey.radarr => item.movie ?? const <String, dynamic>{},
    ServiceKey.sonarr => item.series ?? const <String, dynamic>{},
    ServiceKey.lidarr => item.artist ?? const <String, dynamic>{},
    _ => const <String, dynamic>{},
  };
  final episodes = service == ServiceKey.sonarr
      ? item.episodes
            .map(ManualImportEpisode.fromJson)
            .where((item) => item.id > 0)
            .toList(growable: false)
      : const <ManualImportEpisode>[];
  final episode = service == ServiceKey.sonarr && item.episodes.isNotEmpty
      ? ManualImportEpisode.fromJson(item.episodes.first)
      : null;
  final tracks = service == ServiceKey.lidarr
      ? item.tracks
            .map(ManualImportTrack.fromJson)
            .where((item) => item.id > 0)
            .toList(growable: false)
      : const <ManualImportTrack>[];
  final track = service == ServiceKey.lidarr && item.tracks.isNotEmpty
      ? ManualImportTrack.fromJson(item.tracks.first)
      : null;

  return ManualImportFixAssignment(
    match: ManualImportLookupResult.fromJson(service, matchPayload),
    episode: episode,
    episodes: episodes,
    album: service == ServiceKey.lidarr && item.album != null
        ? ManualImportAlbum.fromJson(item.album!)
        : null,
    track: track,
    tracks: tracks,
  );
}

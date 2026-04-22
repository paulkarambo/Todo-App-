import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/planner_item.dart';
import '../models/project.dart';
import '../models/subtask.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

const _uuid = Uuid();

class PlannerProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  Map<String, List<PlannerItem>> _itemsByDate = {};
  List<Project> _projects = [Project.arbeit, Project.privat];
  DateTime _selectedDate = DateTime.now();
  bool _showTexts = true;
  bool _showSubtasks = true;
  bool _groupByProject = false;
  SortMode _sortMode = SortMode.manual;
  SortDirection _sortDir = SortDirection.desc;
  String? _filterProjectId;
  String? _defaultProjectId;
  Priority _defaultPriority = Priority.low;
  bool _needsStartupModal = false;
  bool _isLoaded = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get needsStartupModal => _needsStartupModal;
  bool get isLoaded => _isLoaded;
  List<Project> get projects => List.unmodifiable(_projects);
  DateTime get selectedDate => _selectedDate;
  bool get showTexts => _showTexts;
  bool get showSubtasks => _showSubtasks;
  bool get groupByProject => _groupByProject;
  SortMode get sortMode => _sortMode;
  SortDirection get sortDir => _sortDir;
  String? get filterProjectId => _filterProjectId;
  String? get defaultProjectId => _defaultProjectId;
  Priority get defaultPriority => _defaultPriority;

  bool hasItemsOnDate(String dateKey) =>
      (_itemsByDate[dateKey]?.isNotEmpty) ?? false;

  List<PlannerItem> get currentItems {
    var list = List<PlannerItem>.from(
        _itemsByDate[PlannerDateUtils.toDateKey(_selectedDate)] ?? []);

    if (_filterProjectId != null) {
      list = list.where((i) => i.projectId == _filterProjectId).toList();
    }

    if (_sortMode == SortMode.manual) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } else if (_sortMode == SortMode.priority) {
      final m = _sortDir == SortDirection.asc ? 1 : -1;
      list.sort((a, b) {
        if (a.isNote || b.isNote) return 0;
        return (a.priority.order - b.priority.order) * m;
      });
    } else if (_sortMode == SortMode.project) {
      final m = _sortDir == SortDirection.asc ? 1 : -1;
      list.sort((a, b) {
        if (a.isNote || b.isNote) return 0;
        final pA = _projects
            .firstWhere((p) => p.id == a.projectId,
                orElse: () => const Project(id: '', name: '', colorValue: 0))
            .name;
        final pB = _projects
            .firstWhere((p) => p.id == b.projectId,
                orElse: () => const Project(id: '', name: '', colorValue: 0))
            .name;
        return pA.compareTo(pB) * m;
      });
    }

    return list;
  }

  List<Map<String, dynamic>> get groupedItems {
    final all = currentItems;
    final result = <Map<String, dynamic>>[];

    for (final project in _projects) {
      final items = all.where((i) => i.projectId == project.id).toList();
      if (items.isNotEmpty) {
        result.add({'project': project, 'items': items});
      }
    }

    final noProject = all.where((i) => i.projectId == null).toList();
    if (noProject.isNotEmpty) {
      result.add({
        'project': const Project(
            id: 'none', name: 'Ohne Projekt', colorValue: 0xFF475569),
        'items': noProject,
      });
    }

    return result;
  }

  /// All task items across all dates, sorted: today+future ascending, then past ascending.
  List<MapEntry<String, List<PlannerItem>>> get allTasksByDate {
    final today = PlannerDateUtils.toDateKey(DateTime.now());
    final entries = _itemsByDate.entries
        .where((e) => e.value.any((i) => i.isTask))
        .toList();
    final future = entries.where((e) => e.key.compareTo(today) >= 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final past = entries.where((e) => e.key.compareTo(today) < 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [...future, ...past];
  }

  Project? projectById(String? id) {
    if (id == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> loadFromSupabase() async {
    final started = await SupabaseService.isStarted();

    if (!started) {
      _needsStartupModal = true;
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final projects = await SupabaseService.fetchProjects();
      if (projects.isNotEmpty) _projects = projects;
    } catch (_) {}

    try {
      final items = await SupabaseService.fetchAllItems();
      _itemsByDate = {};
      for (final item in items) {
        _itemsByDate.putIfAbsent(item.dateKey, () => []).add(item);
      }
    } catch (_) {}

    try {
      final s = await SupabaseService.fetchSettings();
      if (s != null) {
        _showTexts = s['showTexts'] as bool? ?? true;
        _showSubtasks = s['showSubtasks'] as bool? ?? true;
        _groupByProject = s['groupByProject'] as bool? ?? false;
        _sortMode = SortMode.values.firstWhere(
          (e) => e.name == (s['sortMode'] as String?),
          orElse: () => SortMode.manual,
        );
        _sortDir = SortDirection.values.firstWhere(
          (e) => e.name == (s['sortDir'] as String?),
          orElse: () => SortDirection.desc,
        );
        _defaultProjectId = s['defaultProjectId'] as String?;
        _defaultPriority = PriorityExt.fromString(s['defaultPriority'] as String?);
      }
    } catch (_) {}

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveToSupabase() async {
    final allItems = _itemsByDate.values.expand((l) => l).toList();
    await Future.wait([
      SupabaseService.upsertItems(allItems),
      SupabaseService.upsertProjects(_projects),
      SupabaseService.saveSettings({
        'showTexts': _showTexts,
        'showSubtasks': _showSubtasks,
        'groupByProject': _groupByProject,
        'sortMode': _sortMode.name,
        'sortDir': _sortDir.name,
        'defaultProjectId': _defaultProjectId,
        'defaultPriority': _defaultPriority.name,
      }),
    ]);
  }

  // ── Startup ────────────────────────────────────────────────────────────────
  Future<void> seedTestData() async {
    final today = PlannerDateUtils.toDateKey(DateTime.now());
    final yesterday = PlannerDateUtils.toDateKey(
        DateTime.now().subtract(const Duration(days: 1)));

    _projects = [Project.arbeit, Project.privat];
    _itemsByDate = {
      today: [
        PlannerItem(
          id: _uuid.v4(),
          type: ItemType.task,
          text: 'Willkommen! — Hier klicken für Details',
          priority: Priority.high,
          projectId: DefaultProjects.arbeitId,
          notes:
              '**Markdown** in Notizen wird unterstützt.\n- Unteraufgaben hinzufügen\n- Drag & Drop im manuellen Modus',
          subtasks: [
            Subtask(id: _uuid.v4(), text: 'Unteraufgabe ausprobieren'),
            Subtask(id: _uuid.v4(), text: 'Priorität einstellen'),
          ],
          sortOrder: 0,
          dateKey: today,
        ),
        PlannerItem(
          id: _uuid.v4(),
          type: ItemType.task,
          text: 'Sport — 30 Minuten laufen',
          priority: Priority.medium,
          projectId: DefaultProjects.privatId,
          sortOrder: 1,
          dateKey: today,
        ),
        PlannerItem(
          id: _uuid.v4(),
          type: ItemType.task,
          text: 'E-Mails checken',
          priority: Priority.low,
          projectId: DefaultProjects.arbeitId,
          completed: true,
          sortOrder: 2,
          dateKey: today,
        ),
        PlannerItem(
          id: _uuid.v4(),
          type: ItemType.note,
          content:
              '### Tagesnotiz\n- Erledigtes wird grau\n- **Drag & Drop** im manuellen Modus möglich',
          sortOrder: 3,
          dateKey: today,
        ),
      ],
      yesterday: [
        PlannerItem(
          id: _uuid.v4(),
          type: ItemType.task,
          text: 'Projektplanung Q2',
          priority: Priority.high,
          projectId: DefaultProjects.arbeitId,
          completed: true,
          sortOrder: 0,
          dateKey: yesterday,
        ),
        PlannerItem(
          id: _uuid.v4(),
          type: ItemType.task,
          text: 'Einkaufen',
          priority: Priority.low,
          projectId: DefaultProjects.privatId,
          sortOrder: 1,
          dateKey: yesterday,
        ),
      ],
    };

    _needsStartupModal = false;
    await SupabaseService.setStarted();
    await _saveToSupabase();
    notifyListeners();
  }

  Future<void> startEmpty() async {
    _projects = [Project.arbeit, Project.privat];
    _itemsByDate = {};
    _needsStartupModal = false;
    await SupabaseService.setStarted();
    await _saveToSupabase();
    notifyListeners();
  }

  // ── Date Navigation ────────────────────────────────────────────────────────
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void goToPreviousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  void goToNextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  // ── Items ──────────────────────────────────────────────────────────────────
  void addItem(PlannerItem item) {
    final key = item.dateKey;
    final existing = _itemsByDate[key] ?? [];
    final shifted = existing
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key + 1))
        .toList();
    _itemsByDate[key] = [item.copyWith(sortOrder: 0), ...shifted];
    _saveToSupabase();
    notifyListeners();
  }

  void updateItem(PlannerItem updated) {
    final key = updated.dateKey;
    final list = _itemsByDate[key];
    if (list == null) return;
    _itemsByDate[key] =
        list.map((i) => i.id == updated.id ? updated : i).toList();
    _saveToSupabase();
    notifyListeners();
  }

  void deleteItem(String id, String dateKey) {
    final list = _itemsByDate[dateKey];
    if (list == null) return;
    _itemsByDate[dateKey] = list.where((i) => i.id != id).toList();
    SupabaseService.deleteItem(id);
    _saveToSupabase();
    notifyListeners();
  }

  void moveItem(String id, String fromDateKey, String toDateKey) {
    if (fromDateKey == toDateKey) return;
    final fromList = _itemsByDate[fromDateKey];
    if (fromList == null) return;
    final item = fromList.where((i) => i.id == id).firstOrNull;
    if (item == null) return;

    _itemsByDate[fromDateKey] = fromList.where((i) => i.id != id).toList();

    final toList = List<PlannerItem>.from(_itemsByDate[toDateKey] ?? []);
    toList.insert(0, item.copyWith(dateKey: toDateKey, sortOrder: 0));
    _itemsByDate[toDateKey] = toList
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key))
        .toList();

    _saveToSupabase();
    notifyListeners();
  }

  void toggleCompleted(String id, String dateKey) {
    final list = _itemsByDate[dateKey];
    if (list == null) return;
    _itemsByDate[dateKey] = list
        .map((i) => i.id == id ? i.copyWith(completed: !i.completed) : i)
        .toList();
    _saveToSupabase();
    notifyListeners();
  }

  void reorderItems(int oldIndex, int newIndex) {
    final key = PlannerDateUtils.toDateKey(_selectedDate);
    var list = List<PlannerItem>.from(_itemsByDate[key] ?? []);
    if (_filterProjectId != null) return;
    if (oldIndex < newIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    list = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key))
        .toList();
    _itemsByDate[key] = list;
    _saveToSupabase();
    notifyListeners();
  }

  // ── Subtasks ───────────────────────────────────────────────────────────────
  void _updateItemInDate(
      String itemId, String dateKey, PlannerItem Function(PlannerItem) updater) {
    final list = _itemsByDate[dateKey];
    if (list == null) return;
    _itemsByDate[dateKey] =
        list.map((i) => i.id == itemId ? updater(i) : i).toList();
    _saveToSupabase();
    notifyListeners();
  }

  void addSubtask(String itemId, String dateKey, Subtask subtask) {
    _updateItemInDate(itemId, dateKey, (item) {
      return item.copyWith(subtasks: [...item.subtasks, subtask]);
    });
  }

  void updateSubtask(String itemId, String dateKey, Subtask updated) {
    _updateItemInDate(itemId, dateKey, (item) {
      return item.copyWith(
        subtasks: item.subtasks
            .map((s) => s.id == updated.id ? updated : s)
            .toList(),
      );
    });
  }

  void deleteSubtask(String itemId, String dateKey, String subtaskId) {
    _updateItemInDate(itemId, dateKey, (item) {
      return item.copyWith(
        subtasks: item.subtasks.where((s) => s.id != subtaskId).toList(),
      );
    });
  }

  void toggleSubtask(String itemId, String dateKey, String subtaskId) {
    _updateItemInDate(itemId, dateKey, (item) {
      return item.copyWith(
        subtasks: item.subtasks
            .map((s) =>
                s.id == subtaskId ? s.copyWith(completed: !s.completed) : s)
            .toList(),
      );
    });
  }

  // ── Projects ───────────────────────────────────────────────────────────────
  void addProject(Project project) {
    _projects = [..._projects, project];
    _saveToSupabase();
    notifyListeners();
  }

  void updateProject(Project updated) {
    _projects =
        _projects.map((p) => p.id == updated.id ? updated : p).toList();
    _saveToSupabase();
    notifyListeners();
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  void setShowTexts(bool v) {
    _showTexts = v;
    _saveToSupabase();
    notifyListeners();
  }

  void setShowSubtasks(bool v) {
    _showSubtasks = v;
    _saveToSupabase();
    notifyListeners();
  }

  void setGroupByProject(bool v) {
    _groupByProject = v;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  void toggleSortDirection() {
    _sortDir =
        _sortDir == SortDirection.asc ? SortDirection.desc : SortDirection.asc;
    notifyListeners();
  }

  void setFilterProject(String? projectId) {
    _filterProjectId = projectId;
    notifyListeners();
  }

  void setDefaultProject(String? projectId) {
    _defaultProjectId = projectId;
    _saveToSupabase();
    notifyListeners();
  }

  void setDefaultPriority(Priority priority) {
    _defaultPriority = priority;
    _saveToSupabase();
    notifyListeners();
  }
}

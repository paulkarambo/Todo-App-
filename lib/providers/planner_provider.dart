import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/planner_item.dart';
import '../models/project.dart';
import '../models/subtask.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

const _keyStarted = 'planner_started';
const _keyItems = 'planner_items';
const _keyProjects = 'planner_projects';
const _keySettings = 'planner_settings';

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

  bool hasItemsOnDate(String dateKey) =>
      (_itemsByDate[dateKey]?.isNotEmpty) ?? false;

  List<PlannerItem> get currentItems {
    var list = List<PlannerItem>.from(_itemsByDate[PlannerDateUtils.toDateKey(_selectedDate)] ?? []);

    // Filter by project
    if (_filterProjectId != null) {
      list = list.where((i) => i.projectId == _filterProjectId).toList();
    }

    // Sort
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
        final pA = _projects.firstWhere((p) => p.id == a.projectId,
            orElse: () => const Project(id: '', name: '', colorValue: 0)).name;
        final pB = _projects.firstWhere((p) => p.id == b.projectId,
            orElse: () => const Project(id: '', name: '', colorValue: 0)).name;
        return pA.compareTo(pB) * m;
      });
    }

    return list;
  }

  /// Returns items grouped by project. Each entry: {project, items}.
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

  Project? projectById(String? id) {
    if (id == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final started = prefs.getBool(_keyStarted) ?? false;

    if (!started) {
      _needsStartupModal = true;
      _isLoaded = true;
      notifyListeners();
      return;
    }

    // Projects
    final projJson = prefs.getString(_keyProjects);
    if (projJson != null) {
      try {
        final list = jsonDecode(projJson) as List<dynamic>;
        _projects = list
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Items
    final itemsJson = prefs.getString(_keyItems);
    if (itemsJson != null) {
      try {
        final list = jsonDecode(itemsJson) as List<dynamic>;
        final items = list
            .map((e) => PlannerItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _itemsByDate = {};
        for (final item in items) {
          _itemsByDate.putIfAbsent(item.dateKey, () => []).add(item);
        }
      } catch (_) {}
    }

    // Settings
    final settingsJson = prefs.getString(_keySettings);
    if (settingsJson != null) {
      try {
        final s = jsonDecode(settingsJson) as Map<String, dynamic>;
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
      } catch (_) {}
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final allItems = _itemsByDate.values.expand((l) => l).toList();
    await Future.wait([
      prefs.setString(_keyItems, jsonEncode(allItems.map((i) => i.toJson()).toList())),
      prefs.setString(_keyProjects, jsonEncode(_projects.map((p) => p.toJson()).toList())),
      prefs.setString(
          _keySettings,
          jsonEncode({
            'showTexts': _showTexts,
            'showSubtasks': _showSubtasks,
            'groupByProject': _groupByProject,
            'sortMode': _sortMode.name,
            'sortDir': _sortDir.name,
          })),
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
          notes: '**Markdown** in Notizen wird unterstützt.\n- Unteraufgaben hinzufügen\n- Drag & Drop im manuellen Modus',
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
          content: '### Tagesnotiz\n- Erledigtes wird grau\n- **Drag & Drop** im manuellen Modus möglich',
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStarted, true);
    await _save();
    notifyListeners();
  }

  Future<void> startEmpty() async {
    _projects = [Project.arbeit, Project.privat];
    _itemsByDate = {};
    _needsStartupModal = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStarted, true);
    await _save();
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
    // Prepend new item; shift all existing sortOrders up by 1
    final shifted = existing
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key + 1))
        .toList();
    _itemsByDate[key] = [item.copyWith(sortOrder: 0), ...shifted];
    _save();
    notifyListeners();
  }

  void updateItem(PlannerItem updated) {
    final key = updated.dateKey;
    final list = _itemsByDate[key];
    if (list == null) return;
    _itemsByDate[key] = list.map((i) => i.id == updated.id ? updated : i).toList();
    _save();
    notifyListeners();
  }

  void deleteItem(String id, String dateKey) {
    final list = _itemsByDate[dateKey];
    if (list == null) return;
    _itemsByDate[dateKey] = list.where((i) => i.id != id).toList();
    _save();
    notifyListeners();
  }

  void toggleCompleted(String id, String dateKey) {
    final list = _itemsByDate[dateKey];
    if (list == null) return;
    _itemsByDate[dateKey] =
        list.map((i) => i.id == id ? i.copyWith(completed: !i.completed) : i).toList();
    _save();
    notifyListeners();
  }

  void reorderItems(int oldIndex, int newIndex) {
    final key = PlannerDateUtils.toDateKey(_selectedDate);
    var list = List<PlannerItem>.from(_itemsByDate[key] ?? []);
    if (_filterProjectId != null) return; // reorder disabled when filtered
    if (oldIndex < newIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    // Reassign sortOrder
    list = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key))
        .toList();
    _itemsByDate[key] = list;
    _save();
    notifyListeners();
  }

  // ── Subtasks ───────────────────────────────────────────────────────────────
  void _updateItemInDate(String itemId, String dateKey, PlannerItem Function(PlannerItem) updater) {
    final list = _itemsByDate[dateKey];
    if (list == null) return;
    _itemsByDate[dateKey] = list.map((i) => i.id == itemId ? updater(i) : i).toList();
    _save();
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
        subtasks: item.subtasks.map((s) => s.id == updated.id ? updated : s).toList(),
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
            .map((s) => s.id == subtaskId ? s.copyWith(completed: !s.completed) : s)
            .toList(),
      );
    });
  }

  // ── Projects ───────────────────────────────────────────────────────────────
  void addProject(Project project) {
    _projects = [..._projects, project];
    _save();
    notifyListeners();
  }

  void updateProject(Project updated) {
    _projects = _projects.map((p) => p.id == updated.id ? updated : p).toList();
    _save();
    notifyListeners();
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  void setShowTexts(bool v) {
    _showTexts = v;
    _save();
    notifyListeners();
  }

  void setShowSubtasks(bool v) {
    _showSubtasks = v;
    _save();
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
    _sortDir = _sortDir == SortDirection.asc ? SortDirection.desc : SortDirection.asc;
    notifyListeners();
  }

  void setFilterProject(String? projectId) {
    _filterProjectId = projectId;
    notifyListeners();
  }
}

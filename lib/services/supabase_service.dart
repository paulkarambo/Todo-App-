import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/planner_item.dart';
import '../models/project.dart';
import '../models/subtask.dart';

class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ── Bootstrap ────────────────────────────────────────────────────────────────

  static Future<bool> isStarted() async {
    final row = await _db
        .from('user_settings')
        .select('value')
        .eq('key', 'planner_started')
        .maybeSingle();
    if (row == null) return false;
    final val = row['value'];
    if (val is bool) return val;
    if (val is String) return val == 'true';
    return false;
  }

  static Future<void> setStarted() async {
    await _db.from('user_settings').upsert({
      'key': 'planner_started',
      'value': true,
    });
  }

  // ── Items ─────────────────────────────────────────────────────────────────────

  static Future<List<PlannerItem>> fetchAllItems() async {
    final rows = await _db.from('planner_items').select();
    return (rows as List<dynamic>)
        .map((r) => _itemFromRow(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> upsertItems(List<PlannerItem> items) async {
    if (items.isEmpty) return;
    await _db.from('planner_items').upsert(
      items.map(_itemToRow).toList(),
      onConflict: 'id',
    );
  }

  static Future<void> deleteItem(String id) async {
    await _db.from('planner_items').delete().eq('id', id);
  }

  // ── Projects ──────────────────────────────────────────────────────────────────

  static Future<List<Project>> fetchProjects() async {
    final rows = await _db.from('projects').select();
    return (rows as List<dynamic>)
        .map((r) => Project.fromJson({
              'id': r['id'],
              'name': r['name'],
              'colorValue': r['color_value'],
            }))
        .toList();
  }

  static Future<void> upsertProjects(List<Project> projects) async {
    if (projects.isEmpty) return;
    await _db.from('projects').upsert(
      projects
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'color_value': p.colorValue,
              })
          .toList(),
      onConflict: 'id',
    );
  }

  // ── Settings ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchSettings() async {
    final row = await _db
        .from('user_settings')
        .select('value')
        .eq('key', 'planner_settings')
        .maybeSingle();
    if (row == null) return null;
    final val = row['value'];
    if (val is String) return jsonDecode(val) as Map<String, dynamic>;
    if (val is Map) return val.cast<String, dynamic>();
    return null;
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _db.from('user_settings').upsert({
      'key': 'planner_settings',
      'value': settings,
    });
  }

  // ── Converters ────────────────────────────────────────────────────────────────

  static PlannerItem _itemFromRow(Map<String, dynamic> r) {
    final subtasksRaw = r['subtasks'];
    List<dynamic> subtasksList;
    if (subtasksRaw is String) {
      subtasksList = jsonDecode(subtasksRaw) as List<dynamic>;
    } else {
      subtasksList = (subtasksRaw as List<dynamic>?) ?? [];
    }

    return PlannerItem(
      id: r['id'] as String,
      type: r['type'] == 'note' ? ItemType.note : ItemType.task,
      text: r['text'] as String? ?? '',
      content: r['content'] as String? ?? '',
      completed: r['completed'] as bool? ?? false,
      priority: PriorityExt.fromString(r['priority'] as String?),
      projectId: r['project_id'] as String?,
      notes: r['notes'] as String? ?? '',
      subtasks: subtasksList
          .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList(),
      sortOrder: r['sort_order'] as int? ?? 0,
      dateKey: r['date_key'] as String,
    );
  }

  static Map<String, dynamic> _itemToRow(PlannerItem item) => {
        'id': item.id,
        'type': item.type == ItemType.task ? 'task' : 'note',
        'text': item.text,
        'content': item.content,
        'completed': item.completed,
        'priority': item.priority.name,
        'project_id': item.projectId,
        'notes': item.notes,
        'subtasks': item.subtasks.map((s) => s.toJson()).toList(),
        'sort_order': item.sortOrder,
        'date_key': item.dateKey,
      };
}

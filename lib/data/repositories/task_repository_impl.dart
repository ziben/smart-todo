import 'package:drift/drift.dart';
import '../../domain/models/task_model.dart' as domain;
import '../../domain/repositories/task_repository.dart';
import '../local/database.dart';

/// 任务仓储实现
class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _database;

  TaskRepositoryImpl(this._database);

  @override
  Future<List<domain.Task>> getAllTasks() async {
    final tasks = await _database.getAllTasks();
    return tasks.map(_mapToDomain).toList();
  }

  @override
  Stream<List<domain.Task>> watchAllTasks() {
    return _database.watchTodoTasks().map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Future<domain.Task?> getTaskById(String id) async {
    final task = await _database.getTaskById(id);
    return task != null ? _mapToDomain(task) : null;
  }

  @override
  Stream<List<domain.Task>> watchTodayTasks() {
    return _database.watchTodayTasks().map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Stream<List<domain.Task>> watchTodoTasks() {
    return _database.watchTodoTasks().map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Stream<List<domain.Task>> watchTasksByProject(String projectId) {
    return _database.watchTasksByProject(projectId).map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Future<List<domain.Task>> getOverdueTasks() async {
    final now = DateTime.now();
    final allTasks = await getAllTasks();
    return allTasks.where((t) =>
      t.dueDate != null &&
      t.dueDate!.isBefore(now) &&
      t.status != domain.TaskStatus.done &&
      t.status != domain.TaskStatus.archived &&
      t.status != domain.TaskStatus.deleted
    ).toList();
  }

  @override
  Future<List<domain.Task>> searchTasks(String query) async {
    final tasks = await _database.searchTasks(query);
    return tasks.map(_mapToDomain).toList();
  }

  @override
  Future<domain.Task> createTask(domain.Task task) async {
    final companion = _mapToCompanion(task);
    await _database.insertTask(companion);
    return task;
  }

  @override
  Future<domain.Task> updateTask(domain.Task task) async {
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now(),
      isDirty: true,
      version: task.version + 1,
    );
    final companion = _mapToCompanion(updatedTask);
    await _database.updateTask(companion);
    return updatedTask;
  }

  @override
  Future<void> deleteTask(String id) async {
    await _database.softDeleteTask(id);
  }

  @override
  Future<void> deleteTaskPermanently(String id) async {
    await _database.deleteTaskPermanently(id);
  }

  @override
  Future<domain.Task> completeTask(String id) async {
    final task = await getTaskById(id);
    if (task == null) {
      throw Exception('Task not found');
    }
    
    final completedTask = task.copyWith(
      status: domain.TaskStatus.done,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: true,
    );
    
    return updateTask(completedTask);
  }

  @override
  Future<List<domain.Task>> batchUpdateTasks(List<domain.Task> tasks) async {
    final results = <domain.Task>[];
    for (final task in tasks) {
      final updated = await updateTask(task);
      results.add(updated);
    }
    return results;
  }

  @override
  Future<List<domain.Task>> getTasksToSync() async {
    final tasks = await _database.getTasksToSync();
    return tasks.map(_mapToDomain).toList();
  }

  @override
  Future<void> markTaskSynced(String id) async {
    await _database.markTaskSynced(id);
  }

  // ============ 映射方法 ============

  domain.Task _mapToDomain(Task task) {
    return domain.Task(
      id: task.id,
      title: task.title,
      description: task.description,
      status: domain.TaskStatus.values[task.status],
      priority: domain.TaskPriority.values[task.priority],
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      estimatedDuration: task.estimatedDuration,
      actualDuration: task.actualDuration,
      parentId: task.parentId,
      subtaskIds: _parseJsonList(task.subtaskIds),
      projectId: task.projectId,
      tags: _parseJsonList(task.tags),
      attachments: _parseJsonList(task.attachments),
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      completedAt: task.completedAt,
      deletedAt: task.deletedAt,
      createdBy: task.createdBy,
      assignedTo: task.assignedTo,
      collaborators: _parseJsonList(task.collaborators),
      repeatRule: domain.RepeatRule.values[task.repeatRule],
      repeatUntil: task.repeatUntil,
      syncStatus: domain.SyncStatus.values[task.syncStatus],
      isDirty: task.isDirty,
      version: task.version,
    );
  }

  TasksCompanion _mapToCompanion(domain.Task task) {
    return TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      status: Value(task.status.index),
      priority: Value(task.priority.index),
      dueDate: Value(task.dueDate),
      dueTime: Value(task.dueTime),
      estimatedDuration: Value(task.estimatedDuration),
      actualDuration: Value(task.actualDuration),
      parentId: Value(task.parentId),
      subtaskIds: Value(_encodeJsonList(task.subtaskIds)),
      projectId: Value(task.projectId),
      tags: Value(_encodeJsonList(task.tags)),
      attachments: Value(_encodeJsonList(task.attachments)),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
      completedAt: Value(task.completedAt),
      deletedAt: Value(task.deletedAt),
      createdBy: Value(task.createdBy),
      assignedTo: Value(task.assignedTo),
      collaborators: Value(_encodeJsonList(task.collaborators)),
      repeatRule: Value(task.repeatRule.index),
      repeatUntil: Value(task.repeatUntil),
      syncStatus: Value(task.syncStatus.index),
      isDirty: Value(task.isDirty),
      version: Value(task.version),
    );
  }

  List<String> _parseJsonList(String json) {
    if (json.isEmpty || json == '[]') return [];
    try {
      final list = json.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
      if (list.isEmpty) return [];
      return list.split(',').map((e) => e.trim()).toList();
    } catch (_) {
      return [];
    }
  }

  String _encodeJsonList(List<String> list) {
    if (list.isEmpty) return '[]';
    return '[${list.map((e) => '"$e"').join(',')}]';
  }
}
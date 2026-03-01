import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/task_model.dart';
import '../../domain/repositories/task_repository.dart';
import '../local/database.dart';
import '../remote/firebase_datasource.dart';

/// 混合同步仓储实现
/// 结合本地数据库和 Firebase 远程数据源
class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _database;
  final FirebaseRemoteDataSource? _remoteDataSource;

  TaskRepositoryImpl(this._database, this._remoteDataSource);

  @override
  Future<List<Task>> getAllTasks() async {
    final tasks = await _database.getAllTasks();
    return tasks.map(_mapToDomain).toList();
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    return _database.watchTodoTasks().map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final task = await _database.getTaskById(id);
    return task != null ? _mapToDomain(task) : null;
  }

  @override
  Stream<List<Task>> watchTodayTasks() {
    return _database.watchTodayTasks().map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Stream<List<Task>> watchTodoTasks() {
    return _database.watchTodoTasks().map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Stream<List<Task>> watchTasksByProject(String projectId) {
    return _database.watchTasksByProject(projectId).map(
      (tasks) => tasks.map(_mapToDomain).toList(),
    );
  }

  @override
  Future<List<Task>> getOverdueTasks() async {
    final now = DateTime.now();
    final allTasks = await getAllTasks();
    return allTasks.where((t) =>
      t.dueDate != null &&
      t.dueDate!.isBefore(now) &&
      t.status != TaskStatus.done &&
      t.status != TaskStatus.archived &&
      t.status != TaskStatus.deleted
    ).toList();
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    final tasks = await _database.searchTasks(query);
    return tasks.map(_mapToDomain).toList();
  }

  @override
  Future<Task> createTask(Task task) async {
    final companion = _mapToCompanion(task);
    await _database.insertTask(companion);
    
    // 尝试同步到远程
    try {
      await _remoteDataSource?.uploadTask(task);
    } catch (_) {
      // 离线时忽略同步错误
    }
    
    return task;
  }

  @override
  Future<Task> updateTask(Task task) async {
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now(),
      isDirty: true,
      version: task.version + 1,
    );
    final companion = _mapToCompanion(updatedTask);
    await _database.updateTask(companion);
    
    // 尝试同步到远程
    try {
      await _remoteDataSource?.updateTask(updatedTask);
    } catch (_) {
      // 离线时忽略同步错误
    }
    
    return updatedTask;
  }

  @override
  Future<void> deleteTask(String id) async {
    await _database.softDeleteTask(id);
    
    // 尝试同步删除到远程
    try {
      await _remoteDataSource?.deleteTask(id);
    } catch (_) {
      // 离线时忽略同步错误
    }
  }

  @override
  Future<void> deleteTaskPermanently(String id) async {
    await _database.deleteTaskPermanently(id);
    
    try {
      await _remoteDataSource?.deleteTask(id);
    } catch (_) {}
  }

  @override
  Future<Task> completeTask(String id) async {
    final task = await getTaskById(id);
    if (task == null) {
      throw Exception('Task not found');
    }
    
    final completedTask = task.copyWith(
      status: TaskStatus.done,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: true,
    );
    
    return updateTask(completedTask);
  }

  @override
  Future<List<Task>> batchUpdateTasks(List<Task> tasks) async {
    final results = <Task>[];
    for (final task in tasks) {
      final updated = await updateTask(task);
      results.add(updated);
    }
    return results;
  }

  @override
  Future<List<Task>> getTasksToSync() async {
    final tasks = await _database.getTasksToSync();
    return tasks.map(_mapToDomain).toList();
  }

  @override
  Future<void> markTaskSynced(String id) async {
    await _database.markTaskSynced(id);
  }

  // ============ 远程同步方法 ============

  /// 从远程拉取最新数据并合并
  Future<void> pullFromRemote() async {
    if (_remoteDataSource == null) return;
    
    try {
      final remoteTasks = await _remoteDataSource!.fetchTasks();
      
      for (final remoteData in remoteTasks) {
        final localTask = await _database.getTaskById(remoteData['id']);
        
        if (localTask == null) {
          // 本地不存在，直接创建
          final task = _mapRemoteToDomain(remoteData);
          await _database.insertTask(_mapToCompanion(task));
        } else {
          // 比较版本号，保留较新的
          final localVersion = localTask.version;
          final remoteVersion = remoteData['version'] ?? 0;
          
          if (remoteVersion > localVersion) {
            final task = _mapRemoteToDomain(remoteData);
            await _database.updateTask(_mapToCompanion(task));
          }
        }
      }
    } catch (e) {
      // 离线时忽略
    }
  }

  /// 强制全量同步
  Future<void> forceFullSync() async {
    if (_remoteDataSource == null) return;
    
    try {
      // 获取所有本地任务
      final localTasks = await _database.getAllTasks();
      
      // 批量上传到远程
      final tasks = localTasks.map(_mapToDomain).toList();
      await _remoteDataSource!.batchUploadTasks(tasks);
      
      // 标记所有为已同步
      for (final task in localTasks) {
        await _database.markTaskSynced(task.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============ 映射方法 ============

  Task _mapToDomain(Task task) {
    return Task(
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      estimatedDuration: task.estimatedDuration,
      actualDuration: task.actualDuration,
      parentId: task.parentId,
      subtaskIds: task.subtaskIds,
      projectId: task.projectId,
      tags: task.tags,
      attachments: task.attachments,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      completedAt: task.completedAt,
      deletedAt: task.deletedAt,
      createdBy: task.createdBy,
      assignedTo: task.assignedTo,
      collaborators: task.collaborators,
      repeatRule: task.repeatRule,
      repeatUntil: task.repeatUntil,
      syncStatus: task.syncStatus,
      isDirty: task.isDirty,
      version: task.version,
    );
  }

  TasksCompanion _mapToCompanion(Task task) {
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

  Task _mapRemoteToDomain(Map<String, dynamic> data) {
    return Task(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      status: TaskStatus.values[data['status'] ?? 1],
      priority: TaskPriority.values[data['priority'] ?? 0],
      dueDate: data['dueDate'] != null 
          ? DateTime.parse(data['dueDate']) 
          : null,
      dueTime: data['dueTime'] != null 
          ? DateTime.parse(data['dueTime']) 
          : null,
      estimatedDuration: data['estimatedDuration'],
      actualDuration: data['actualDuration'],
      parentId: data['parentId'],
      subtaskIds: List<String>.from(data['subtaskIds'] ?? []),
      projectId: data['projectId'],
      tags: List<String>.from(data['tags'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt']) 
          : DateTime.now(),
      completedAt: data['completedAt'] != null 
          ? DateTime.parse(data['completedAt']) 
          : null,
      deletedAt: data['deletedAt'] != null 
          ? DateTime.parse(data['deletedAt']) 
          : null,
      createdBy: data['createdBy'],
      assignedTo: data['assignedTo'],
      collaborators: List<String>.from(data['collaborators'] ?? []),
      repeatRule: RepeatRule.values[data['repeatRule'] ?? 0],
      repeatUntil: data['repeatUntil'] != null 
          ? DateTime.parse(data['repeatUntil']) 
          : null,
      syncStatus: SyncStatus.synced,
      isDirty: false,
      version: data['version'] ?? 1,
    );
  }

  String _encodeJsonList(List<String> list) {
    if (list.isEmpty) return '[]';
    return '[${list.map((e) => '"$e"').join(',')}]';
  }
}
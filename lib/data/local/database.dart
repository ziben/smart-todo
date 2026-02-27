import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ============ 任务表 ============

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(1))(); // TaskStatus.todo
  IntColumn get priority => integer().withDefault(const Constant(0))(); // TaskPriority.none
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get dueTime => dateTime().nullable()();
  IntColumn get estimatedDuration => integer().nullable(); // 分钟
  IntColumn get actualDuration => integer().nullable();
  TextColumn get parentId => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get attachments => text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable();
  TextColumn get createdBy => text().nullable()();
  TextColumn get assignedTo => text().nullable()();
  TextColumn get collaborators => text().withDefault(const Constant('[]'))(); // JSON array
  IntColumn get repeatRule => integer().withDefault(const Constant(0))(); // RepeatRule.none
  DateTimeColumn get repeatUntil => dateTime().nullable()();
  TextColumn get locationReminder => text().nullable(); // JSON
  IntColumn get syncStatus => integer().withDefault(const Constant(1))(); // SyncStatus.pending
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  String get tableName => 'tasks';
}

// ============ 项目/清单表 ============

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#2196F3'))();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get sharedWith => text().withDefault(const Constant('[]'))();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  String get tableName => 'projects';
}

// ============ 标签表 ============

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#757575'))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  String get tableName => 'tags';
}

// ============ 任务活动日志表 ============

class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get userId => text().nullable()();
  IntColumn get actionType => integer()(); // create, update, complete, delete, etc.
  TextColumn get fieldName => text().nullable()(); // 修改的字段
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get deviceInfo => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  String get tableName => 'activity_logs';
}

// ============ 同步队列表 ============

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // task, project, tag
  TextColumn get entityId => text()();
  IntColumn get operation => integer()(); // create, update, delete
  TextColumn get payload => text()(); // JSON data
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRetryAt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  String get tableName => 'sync_queue';
}

// ============ 数据库类 ============

@DriftDatabase(tables: [
  Tasks,
  Projects,
  Tags,
  ActivityLogs,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 处理数据库升级
    },
  );

  // ============ 任务查询方法 ============
  
  // 获取所有任务
  Future<List<Task>> getAllTasks() => select(tasks).get();
  
  // 获取单个任务
  Future<Task?> getTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  // 获取今日任务
  Stream<List<Task>> watchTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (select(tasks)
      ..where((t) => t.dueDate.isNotNull())
      ..where((t) => t.dueDate.isBetweenValues(startOfDay, endOfDay))
      ..where((t) => t.status.isNotInValues([3, 4, 5])) // 排除已完成、归档、删除
      ..orderBy([
        (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.dueTime),
      ]))
        .watch();
  }
  
  // 获取待办任务（按优先级和时间排序）
  Stream<List<Task>> watchTodoTasks() {
    return (select(tasks)
      ..where((t) => t.status.equals(1)) // todo
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.dueDate),
      ]))
        .watch();
  }
  
  // 获取项目下的任务
  Stream<List<Task>> watchTasksByProject(String projectId) {
    return (select(tasks)
      ..where((t) => t.projectId.equals(projectId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.status.isNotInValues([4, 5])) // 排除归档和删除
      ..orderBy([
        (t) => OrderingTerm(expression: t.status),
        (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
      ]))
        .watch();
  }
  
  // 搜索任务
  Future<List<Task>> searchTasks(String query) {
    return (select(tasks)
      ..where((t) => t.title.contains(query) | t.description.contains(query))
      ..where((t) => t.deletedAt.isNull()))
        .get();
  }
  
  // 插入任务
  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);
  
  // 更新任务
  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);
  
  // 软删除任务
  Future<int> softDeleteTask(String id) {
    return (update(tasks)
      ..where((t) => t.id.equals(id)))
        .write(TasksCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          isDirty: const Value(true),
        ));
  }
  
  // 永久删除任务
  Future<int> deleteTaskPermanently(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
  
  // 获取需要同步的任务
  Future<List<Task>> getTasksToSync() =>
      (select(tasks)..where((t) => t.isDirty.equals(true))).get();
  
  // 标记任务已同步
  Future<int> markTaskSynced(String id) {
    return (update(tasks)
      ..where((t) => t.id.equals(id)))
        .write(TasksCompanion(
          isDirty: const Value(false),
          syncStatus: const Value(0), // synced
          updatedAt: Value(DateTime.now()),
        ));
  }

  // ============ 项目相关方法 ============
  
  Future<List<Project>> getAllProjects() => select(projects).get();
  
  Stream<List<Project>> watchAllProjects() => select(projects).watch();
  
  Future<int> insertProject(ProjectsCompanion project) => 
      into(projects).insert(project);
  
  Future<bool> updateProject(ProjectsCompanion project) => 
      update(projects).replace(project);
  
  Future<int> deleteProject(String id) => 
      (delete(projects)..where((p) => p.id.equals(id))).go();

  // ============ 标签相关方法 ============
  
  Future<List<Tag>> getAllTags() => select(tags).get();
  
  Future<int> insertTag(TagsCompanion tag) => into(tags).insert(tag);
  
  Future<int> incrementTagUsage(String tagId) {
    return customStatement('''
      UPDATE tags 
      SET usage_count = usage_count + 1, updated_at = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), tagId]);
  }

  // ============ 统计查询 ============
  
  // 获取今日统计
  Future<Map<String, dynamic>> getTodayStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    // 今日任务总数
    final totalToday = await customSelect('''
      SELECT COUNT(*) as count FROM tasks
      WHERE DATE(due_date) = DATE(?)
      AND deleted_at IS NULL
    ''', [startOfDay.toIso8601String()]).getSingleOrNull();
    
    // 已完成
    final completedToday = await customSelect('''
      SELECT COUNT(*) as count FROM tasks
      WHERE DATE(completed_at) = DATE(?)
      AND status = 3
    ''', [startOfDay.toIso8601String()]).getSingleOrNull();
    
    // 逾期任务
    final overdue = await customSelect('''
      SELECT COUNT(*) as count FROM tasks
      WHERE due_date < ?
      AND status NOT IN (3, 4, 5)
      AND deleted_at IS NULL
    ''', [now.toIso8601String()]).getSingleOrNull();
    
    return {
      'totalToday': totalToday?.read<int>('count') ?? 0,
      'completedToday': completedToday?.read<int>('count') ?? 0,
      'overdue': overdue?.read<int>('count') ?? 0,
    };
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'smart_todo');
}
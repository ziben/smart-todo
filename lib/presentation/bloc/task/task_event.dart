part of 'task_bloc.dart';

@freezed
class TaskEvent with _$TaskEvent {
  // 初始化/加载事件
  const factory TaskEvent.loadTasks({
    TaskStatus? status,
    String? projectId,
    String? tag,
    DateTime? fromDate,
    DateTime? toDate,
  }) = _LoadTasks;

  const factory TaskEvent.watchTasks({
    TaskStatus? status,
    String? projectId,
  }) = _WatchTasks;

  const factory TaskEvent.loadTask({
    required String id,
  }) = _LoadTask;

  // CRUD 操作
  const factory TaskEvent.createTask({
    required String title,
    String? description,
    TaskPriority priority,
    DateTime? dueDate,
    DateTime? dueTime,
    String? projectId,
    List<String> tags,
    String? parentId,
    int? estimatedDuration,
  }) = _CreateTask;

  const factory TaskEvent.updateTask({
    required String id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? dueTime,
    String? projectId,
    List<String>? tags,
    int? estimatedDuration,
  }) = _UpdateTask;

  const factory TaskEvent.deleteTask({
    required String id,
    bool permanently,
  }) = _DeleteTask;

  const factory TaskEvent.completeTask({
    required String id,
  }) = _CompleteTask;

  // 搜索和过滤
  const factory TaskEvent.searchTasks({
    required String query,
  }) = _SearchTasks;

  const factory TaskEvent.filterTasks({
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    String? tag,
    DateTime? fromDate,
    DateTime? toDate,
  }) = _FilterTasks;

  const factory TaskEvent.clearFilters() = _ClearFilters;

  // 排序和重新排序
  const factory TaskEvent.reorderTasks({
    required int oldIndex,
    required int newIndex,
  }) = _ReorderTasks;

  const factory TaskEvent.sortTasks({
    required TaskSortOption sortBy,
    bool ascending,
  }) = _SortTasks;

  // 批量操作
  const factory TaskEvent.batchComplete({
    required List<String> ids,
  }) = _BatchComplete;

  const factory TaskEvent.batchDelete({
    required List<String> ids,
  }) = _BatchDelete;

  const factory TaskEvent.batchMoveToProject({
    required List<String> ids,
    required String projectId,
  }) = _BatchMoveToProject;

  const factory TaskEvent.batchAddTags({
    required List<String> ids,
    required List<String> tags,
  }) = _BatchAddTags;

  // 子任务操作
  const factory TaskEvent.addSubtask({
    required String parentId,
    required String title,
  }) = _AddSubtask;

  const factory TaskEvent.reorderSubtasks({
    required String parentId,
    required List<String> subtaskIds,
  }) = _ReorderSubtasks;

  // 其他
  const factory TaskEvent.clearError() = _ClearError;
}

// 排序选项
enum TaskSortOption {
  manual,        // 手动排序
  dueDate,       // 截止日期
  priority,      // 优先级
  createdAt,     // 创建时间
  updatedAt,     // 更新时间
  title,         // 标题
  estimatedTime, // 预计时间
}

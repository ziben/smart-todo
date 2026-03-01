import '../models/task_model.dart';

/// 任务仓储接口
abstract class TaskRepository {
  /// 获取所有任务
  Future<List<Task>> getAllTasks();
  
  /// 监听所有任务
  Stream<List<Task>> watchAllTasks();
  
  /// 按 ID 获取任务
  Future<Task?> getTaskById(String id);
  
  /// 获取今日任务
  Stream<List<Task>> watchTodayTasks();
  
  /// 获取待办任务
  Stream<List<Task>> watchTodoTasks();
  
  /// 按项目获取任务
  Stream<List<Task>> watchTasksByProject(String projectId);
  
  /// 获取逾期任务
  Future<List<Task>> getOverdueTasks();
  
  /// 搜索任务
  Future<List<Task>> searchTasks(String query);
  
  /// 创建任务
  Future<Task> createTask(Task task);
  
  /// 更新任务
  Future<Task> updateTask(Task task);
  
  /// 删除任务（软删除）
  Future<void> deleteTask(String id);
  
  /// 永久删除任务
  Future<void> deleteTaskPermanently(String id);
  
  /// 完成任务
  Future<Task> completeTask(String id);
  
  /// 批量更新任务
  Future<List<Task>> batchUpdateTasks(List<Task> tasks);
  
  /// 获取需要同步的任务
  Future<List<Task>> getTasksToSync();
  
  /// 标记任务已同步
  Future<void> markTaskSynced(String id);
}
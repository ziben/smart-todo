part of 'task_bloc.dart';

@freezed
class TaskState with _$TaskState {
  const factory TaskState.initial() = _Initial;
  
  const factory TaskState.loading() = _Loading;
  
  const factory TaskState.loaded({
    required List<Task> tasks,
    required List<Task> filteredTasks,
    @Default([]) List<Task> selectedTasks,
    Task? selectedTask,
    Task? lastCreatedTask,
    @Default(false) bool isSelecting,
    @Default(false) bool isSearching,
    @Default('') String searchQuery,
    @Default(TaskSortOption.manual) TaskSortOption sortBy,
    @Default(true) bool sortAscending,
    @Default({}) Map<String, dynamic> activeFilters,
    String? errorMessage,
  }) = _Loaded;
  
  const factory TaskState.error(String message) = _Error;
}

// 扩展方法
extension TaskStateX on TaskState {
  bool get isLoading => this is _Loading;
  bool get isLoaded => this is _Loaded;
  bool get isError => this is _Error;
  bool get isInitial => this is _Initial;
  
  List<Task> get tasksOrEmpty => maybeWhen(
    loaded: (tasks, _, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________, ____________, _____________) => tasks,
    orElse: () => [],
  );
  
  List<Task> get filteredTasksOrEmpty => maybeWhen(
    loaded: (_, filtered, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________, ____________, _____________) => filtered,
    orElse: () => [],
  );
  
  Task? get selectedTaskOrNull => maybeWhen(
    loaded: (_, __, ___, selected, ____, _____, ______, _______, ________, _________, __________, ___________, ____________, _____________) => selected,
    orElse: () => null,
  );
  
  String? get errorMessageOrNull => maybeWhen(
    error: (message) => message,
    loaded: (_, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________, ____________, _____________, error) => error,
    orElse: () => null,
  );
  
  // 获取今日任务数
  int get todayTaskCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return filteredTasksOrEmpty.where((t) {
      if (t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isAtSameMomentAs(today);
    }).length;
  }
  
  // 获取逾期任务数
  int get overdueTaskCount {
    final now = DateTime.now();
    return filteredTasksOrEmpty.where((t) {
      if (t.dueDate == null) return false;
      if (t.status == TaskStatus.done || t.status == TaskStatus.archived) return false;
      return t.dueDate!.isBefore(now);
    }).length;
  }
  
  // 获取高优先级任务数
  int get highPriorityTaskCount {
    return filteredTasksOrEmpty.where((t) => 
      t.priority == TaskPriority.high || t.priority == TaskPriority.urgent
    ).length;
  }
  
  // 获取已完成任务数
  int get completedTaskCount {
    return filteredTasksOrEmpty.where((t) => t.status == TaskStatus.done).length;
  }
  
  // 完成率
  double get completionRate {
    final total = filteredTasksOrEmpty.length;
    if (total == 0) return 0.0;
    return completedTaskCount / total;
  }
}
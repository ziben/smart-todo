import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../domain/models/task_model.dart';
import '../../../../domain/usecases/task_usecases.dart';

part 'task_bloc.freezed.dart';
part 'task_event.dart';
part 'task_state.dart';

@injectable
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase _getTasksUseCase;
  final GetTaskByIdUseCase _getTaskByIdUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final CompleteTaskUseCase _completeTaskUseCase;
  final SearchTasksUseCase _searchTasksUseCase;
  final GetTodayTasksUseCase _getTodayTasksUseCase;
  final GetOverdueTasksUseCase _getOverdueTasksUseCase;

  StreamSubscription<List<Task>>? _tasksSubscription;

  TaskBloc({
    required GetTasksUseCase getTasksUseCase,
    required GetTaskByIdUseCase getTaskByIdUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required CompleteTaskUseCase completeTaskUseCase,
    required SearchTasksUseCase searchTasksUseCase,
    required GetTodayTasksUseCase getTodayTasksUseCase,
    required GetOverdueTasksUseCase getOverdueTasksUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _getTaskByIdUseCase = getTaskByIdUseCase,
        _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _completeTaskUseCase = completeTaskUseCase,
        _searchTasksUseCase = searchTasksUseCase,
        _getTodayTasksUseCase = getTodayTasksUseCase,
        _getOverdueTasksUseCase = getOverdueTasksUseCase,
        super(const TaskState.initial()) {
    on<TaskEvent>((event, emit) async {
      await event.map(
        loadTasks: (e) => _onLoadTasks(e, emit),
        watchTasks: (e) => _onWatchTasks(e, emit),
        loadTask: (e) => _onLoadTask(e, emit),
        createTask: (e) => _onCreateTask(e, emit),
        updateTask: (e) => _onUpdateTask(e, emit),
        deleteTask: (e) => _onDeleteTask(e, emit),
        completeTask: (e) => _onCompleteTask(e, emit),
        searchTasks: (e) => _onSearchTasks(e, emit),
        filterTasks: (e) => _onFilterTasks(e, emit),
        reorderTasks: (e) => _onReorderTasks(e, emit),
        clearError: (e) => _onClearError(e, emit),
      );
    });
  }

  Future<void> _onLoadTasks(_LoadTasks event, Emitter<TaskState> emit) async {
    emit(const TaskState.loading());
    
    final result = await _getTasksUseCase(
      GetTasksParams(
        status: event.status,
        projectId: event.projectId,
        tag: event.tag,
        fromDate: event.fromDate,
        toDate: event.toDate,
      ),
    );
    
    result.fold(
      (failure) => emit(TaskState.error(failure.message)),
      (tasks) => emit(TaskState.loaded(
        tasks: tasks,
        filteredTasks: tasks,
      )),
    );
  }

  Future<void> _onWatchTasks(_WatchTasks event, Emitter<TaskState> emit) async {
    emit(const TaskState.loading());
    
    await _tasksSubscription?.cancel();
    
    _tasksSubscription = _getTasksUseCase.watch(
      GetTasksParams(
        status: event.status,
        projectId: event.projectId,
      ),
    ).listen(
      (tasks) => emit(TaskState.loaded(
        tasks: tasks,
        filteredTasks: tasks,
      )),
      onError: (error) => emit(TaskState.error(error.toString())),
    );
  }

  Future<void> _onLoadTask(_LoadTask event, Emitter<TaskState> emit) async {
    final result = await _getTaskByIdUseCase(GetTaskByIdParams(id: event.id));
    
    result.fold(
      (failure) => emit(TaskState.error(failure.message)),
      (task) {
        final currentState = state;
        if (currentState is _Loaded) {
          emit(currentState.copyWith(selectedTask: task));
        } else {
          emit(TaskState.loaded(tasks: const [], selectedTask: task));
        }
      },
    );
  }

  Future<void> _onCreateTask(_CreateTask event, Emitter<TaskState> emit) async {
    final result = await _createTaskUseCase(
      CreateTaskParams(
        title: event.title,
        description: event.description,
        priority: event.priority,
        dueDate: event.dueDate,
        dueTime: event.dueTime,
        projectId: event.projectId,
        tags: event.tags,
        parentId: event.parentId,
        estimatedDuration: event.estimatedDuration,
      ),
    );
    
    result.fold(
      (failure) => emit(TaskState.error(failure.message)),
      (task) {
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedTasks = [...currentState.tasks, task];
          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: updatedTasks,
            lastCreatedTask: task,
          ));
        }
      },
    );
  }

  Future<void> _onUpdateTask(_UpdateTask event, Emitter<TaskState> emit) async {
    final result = await _updateTaskUseCase(
      UpdateTaskParams(
        id: event.id,
        title: event.title,
        description: event.description,
        status: event.status,
        priority: event.priority,
        dueDate: event.dueDate,
        dueTime: event.dueTime,
        projectId: event.projectId,
        tags: event.tags,
        estimatedDuration: event.estimatedDuration,
      ),
    );
    
    result.fold(
      (failure) => emit(TaskState.error(failure.message)),
      (task) {
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedTasks = currentState.tasks.map((t) =>
            t.id == task.id ? task : t
          ).toList();
          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: updatedTasks,
            selectedTask: currentState.selectedTask?.id == task.id ? task : currentState.selectedTask,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteTask(_DeleteTask event, Emitter<TaskState> emit) async {
    final result = await _deleteTaskUseCase(DeleteTaskParams(id: event.id));
    
    result.fold(
      (failure) => emit(TaskState.error(failure.message)),
      (_) {
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedTasks = currentState.tasks.where((t) => t.id != event.id).toList();
          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: updatedTasks,
            selectedTask: currentState.selectedTask?.id == event.id ? null : currentState.selectedTask,
          ));
        }
      },
    );
  }

  Future<void> _onCompleteTask(_CompleteTask event, Emitter<TaskState> emit) async {
    final result = await _completeTaskUseCase(CompleteTaskParams(id: event.id));
    
    result.fold(
      (failure) => emit(TaskState.error(failure.message)),
      (task) {
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedTasks = currentState.tasks.map((t) =>
            t.id == task.id ? task : t
          ).toList();
          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: updatedTasks,
            selectedTask: currentState.selectedTask?.id == task.id ? task : currentState.selectedTask,
          ));
        }
      },
    );
  }

  Future<void> _onSearchTasks(_SearchTasks event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    if (event.query.isEmpty) {
      emit(currentState.copyWith(filteredTasks: currentState.tasks));
      return;
    }

    final result = await _searchTasksUseCase(SearchTasksParams(query: event.query));
    
    result.fold(
      (failure) => emit(TaskState.error(failure.message)),
      (tasks) => emit(currentState.copyWith(filteredTasks: tasks)),
    );
  }

  Future<void> _onFilterTasks(_FilterTasks event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    var filtered = currentState.tasks;

    // 按状态过滤
    if (event.status != null) {
      filtered = filtered.where((t) => t.status == event.status).toList();
    }

    // 按优先级过滤
    if (event.priority != null) {
      filtered = filtered.where((t) => t.priority == event.priority).toList();
    }

    // 按项目过滤
    if (event.projectId != null) {
      filtered = filtered.where((t) => t.projectId == event.projectId).toList();
    }

    // 按标签过滤
    if (event.tag != null) {
      filtered = filtered.where((t) => t.tags.contains(event.tag)).toList();
    }

    // 按日期范围过滤
    if (event.fromDate != null) {
      filtered = filtered.where((t) =>
        t.dueDate != null && t.dueDate!.isAfter(event.fromDate!)
      ).toList();
    }
    if (event.toDate != null) {
      filtered = filtered.where((t) =>
        t.dueDate != null && t.dueDate!.isBefore(event.toDate!)
      ).toList();
    }

    emit(currentState.copyWith(filteredTasks: filtered));
  }

  Future<void> _onReorderTasks(_ReorderTasks event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    final reordered = [...currentState.filteredTasks];
    final item = reordered.removeAt(event.oldIndex);
    reordered.insert(event.newIndex, item);

    emit(currentState.copyWith(filteredTasks: reordered));
  }

  Future<void> _onClearError(_ClearError event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is _Error) {
      emit(const TaskState.initial());
    } else if (currentState is _Loaded) {
      emit(currentState.copyWith(errorMessage: null));
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
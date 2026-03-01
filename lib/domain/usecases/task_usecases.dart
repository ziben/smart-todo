import 'package:injectable/injectable.dart';
import '../entities/failures.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import 'package:dartz/dartz.dart';

/// 获取任务列表参数
class GetTasksParams {
  final TaskStatus? status;
  final String? projectId;
  final String? tag;
  final DateTime? fromDate;
  final DateTime? toDate;

  const GetTasksParams({
    this.status,
    this.projectId,
    this.tag,
    this.fromDate,
    this.toDate,
  });
}

/// 按 ID 获取任务参数
class GetTaskByIdParams {
  final String id;
  const GetTaskByIdParams(this.id);
}

/// 创建任务参数
class CreateTaskParams {
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final String? projectId;
  final List<String> tags;
  final String? parentId;
  final int? estimatedDuration;

  const CreateTaskParams({
    required this.title,
    this.description,
    this.priority = TaskPriority.none,
    this.dueDate,
    this.dueTime,
    this.projectId,
    this.tags = const [],
    this.parentId,
    this.estimatedDuration,
  });
}

/// 更新任务参数
class UpdateTaskParams {
  final String id;
  final String? title;
  final String? description;
  final TaskStatus? status;
  final TaskPriority? priority;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final String? projectId;
  final List<String>? tags;
  final int? estimatedDuration;

  const UpdateTaskParams({
    required this.id,
    this.title,
    this.description,
    this.status,
    this.priority,
    this.dueDate,
    this.dueTime,
    this.projectId,
    this.tags,
    this.estimatedDuration,
  });
}

/// 删除任务参数
class DeleteTaskParams {
  final String id;
  final bool permanent;

  const DeleteTaskParams({required this.id, this.permanent = false});
}

/// 完成任务参数
class CompleteTaskParams {
  final String id;
  const CompleteTaskParams(this.id);
}

/// 搜索任务参数
class SearchTasksParams {
  final String query;
  const SearchTasksParams(this.query);
}

/// ============ Use Cases ============

/// 获取所有任务 UseCase
@injectable
class GetTasksUseCase {
  final TaskRepository _repository;

  GetTasksUseCase(this._repository);

  Future<Either<Failure, List<Task>>> call(GetTasksParams params) async {
    try {
      final tasks = await _repository.getAllTasks();
      
      var filtered = tasks;
      
      if (params.status != null) {
        filtered = filtered.where((t) => t.status == params.status).toList();
      }
      if (params.projectId != null) {
        filtered = filtered.where((t) => t.projectId == params.projectId).toList();
      }
      if (params.tag != null) {
        filtered = filtered.where((t) => t.tags.contains(params.tag)).toList();
      }
      if (params.fromDate != null) {
        filtered = filtered.where((t) => t.dueDate != null && t.dueDate!.isAfter(params.fromDate!)).toList();
      }
      if (params.toDate != null) {
        filtered = filtered.where((t) => t.dueDate != null && t.dueDate!.isBefore(params.toDate!)).toList();
      }
      
      return Right(filtered);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Stream<List<Task>> watch(GetTasksParams params) {
    return _repository.watchAllTasks();
  }
}

/// 按 ID 获取任务 UseCase
@injectable
class GetTaskByIdUseCase {
  final TaskRepository _repository;

  GetTaskByIdUseCase(this._repository);

  Future<Either<Failure, Task>> call(GetTaskByIdParams params) async {
    try {
      final task = await _repository.getTaskById(params.id);
      if (task == null) {
        return const Left(TaskNotFoundFailure());
      }
      return Right(task);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

/// 创建任务 UseCase
@injectable
class CreateTaskUseCase {
  final TaskRepository _repository;

  CreateTaskUseCase(this._repository);

  Future<Either<Failure, Task>> call(CreateTaskParams params) async {
    try {
      if (params.title.trim().isEmpty) {
        return const Left(ValidationFailure('Task title cannot be empty'));
      }

      final task = Task.create(
        title: params.title,
        description: params.description,
        priority: params.priority,
        dueDate: params.dueDate,
        dueTime: params.dueTime,
        projectId: params.projectId,
        tags: params.tags,
        parentId: params.parentId,
        estimatedDuration: params.estimatedDuration,
      );

      final created = await _repository.createTask(task);
      return Right(created);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

/// 更新任务 UseCase
@injectable
class UpdateTaskUseCase {
  final TaskRepository _repository;

  UpdateTaskUseCase(this._repository);

  Future<Either<Failure, Task>> call(UpdateTaskParams params) async {
    try {
      final existing = await _repository.getTaskById(params.id);
      if (existing == null) {
        return const Left(TaskNotFoundFailure());
      }

      final updated = existing.copyWith(
        title: params.title ?? existing.title,
        description: params.description ?? existing.description,
        status: params.status ?? existing.status,
        priority: params.priority ?? existing.priority,
        dueDate: params.dueDate ?? existing.dueDate,
        dueTime: params.dueTime ?? existing.dueTime,
        projectId: params.projectId ?? existing.projectId,
        tags: params.tags ?? existing.tags,
        estimatedDuration: params.estimatedDuration ?? existing.estimatedDuration,
      );

      final result = await _repository.updateTask(updated);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

/// 删除任务 UseCase
@injectable
class DeleteTaskUseCase {
  final TaskRepository _repository;

  DeleteTaskUseCase(this._repository);

  Future<Either<Failure, void>> call(DeleteTaskParams params) async {
    try {
      final existing = await _repository.getTaskById(params.id);
      if (existing == null) {
        return const Left(TaskNotFoundFailure());
      }

      if (params.permanent) {
        await _repository.deleteTaskPermanently(params.id);
      } else {
        await _repository.deleteTask(params.id);
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

/// 完成任务 UseCase
@injectable
class CompleteTaskUseCase {
  final TaskRepository _repository;

  CompleteTaskUseCase(this._repository);

  Future<Either<Failure, Task>> call(CompleteTaskParams params) async {
    try {
      final task = await _repository.completeTask(params.id);
      return Right(task);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

/// 搜索任务 UseCase
@injectable
class SearchTasksUseCase {
  final TaskRepository _repository;

  SearchTasksUseCase(this._repository);

  Future<Either<Failure, List<Task>>> call(SearchTasksParams params) async {
    try {
      if (params.query.trim().isEmpty) {
        return const Right([]);
      }
      final tasks = await _repository.searchTasks(params.query);
      return Right(tasks);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

/// 获取今日任务 UseCase
@injectable
class GetTodayTasksUseCase {
  final TaskRepository _repository;

  GetTodayTasksUseCase(this._repository);

  Stream<List<Task>> call() {
    return _repository.watchTodayTasks();
  }
}

/// 获取逾期任务 UseCase
@injectable
class GetOverdueTasksUseCase {
  final TaskRepository _repository;

  GetOverdueTasksUseCase(this._repository);

  Future<Either<Failure, List<Task>>> call() async {
    try {
      final tasks = await _repository.getOverdueTasks();
      return Right(tasks);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
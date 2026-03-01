/// 基础失败类型
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// 数据库操作失败
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// 网络失败
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// 缓存失败
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// 验证失败
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// 任务不存在
class TaskNotFoundFailure extends Failure {
  const TaskNotFoundFailure() : super('Task not found');
}

/// 项目不存在
class ProjectNotFoundFailure extends Failure {
  const ProjectNotFoundFailure() : super('Project not found');
}

/// 标签不存在
class TagNotFoundFailure extends Failure {
  const TagNotFoundFailure() : super('Tag not found');
}

/// 同步失败
class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

/// 权限失败
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
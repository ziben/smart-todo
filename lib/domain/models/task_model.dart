import 'package:drift/drift.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

/// 任务优先级枚举
enum TaskPriority {
  @JsonValue(0)
  none,      // 无优先级
  @JsonValue(1)
  low,       // 低优先级
  @JsonValue(2)
  medium,    // 中优先级
  @JsonValue(3)
  high,      // 高优先级
  @JsonValue(4)
  urgent,    // 紧急
}

/// 任务状态枚举
enum TaskStatus {
  @JsonValue(0)
  inbox,     // 收件箱（未分类）
  @JsonValue(1)
  todo,      // 待办
  @JsonValue(2)
  inProgress,// 进行中
  @JsonValue(3)
  done,      // 已完成
  @JsonValue(4)
  archived,  // 已归档
  @JsonValue(5)
  deleted,   // 已删除
}

/// 重复规则枚举
enum RepeatRule {
  @JsonValue(0)
  none,         // 不重复
  @JsonValue(1)
  daily,        // 每天
  @JsonValue(2)
  weekdays,     // 工作日
  @JsonValue(3)
  weekly,       // 每周
  @JsonValue(4)
  biweekly,     // 每两周
  @JsonValue(5)
  monthly,      // 每月
  @JsonValue(6)
  quarterly,    // 每季度
  @JsonValue(7)
  yearly,       // 每年
}

/// 任务数据模型
@freezed
class Task with _$Task {
  const factory Task({
    /// 唯一标识
    required String id,
    
    /// 任务标题
    required String title,
    
    /// 任务描述/备注
    String? description,
    
    /// 任务状态
    @Default(TaskStatus.todo) TaskStatus status,
    
    /// 优先级
    @Default(TaskPriority.none) TaskPriority priority,
    
    /// 截止日期
    DateTime? dueDate,
    
    /// 截止时间
    DateTime? dueTime,
    
    /// 预计时长（分钟）
    int? estimatedDuration,
    
    /// 实际时长（分钟）
    int? actualDuration,
    
    /// 父任务ID（支持子任务）
    String? parentId,
    
    /// 子任务列表
    @Default([]) List<String> subtaskIds,
    
    /// 项目/清单ID
    String? projectId,
    
    /// 标签列表
    @Default([]) List<String> tags,
    
    /// 附件列表
    @Default([]) List<String> attachments,
    
    /// 创建时间
    required DateTime createdAt,
    
    /// 更新时间
    required DateTime updatedAt,
    
    /// 完成时间
    DateTime? completedAt,
    
    /// 删除时间（软删除）
    DateTime? deletedAt,
    
    /// 创建者ID
    String? createdBy,
    
    /// 分配给
    String? assignedTo,
    
    /// 协作者列表
    @Default([]) List<String> collaborators,
    
    /// 重复规则
    @Default(RepeatRule.none) RepeatRule repeatRule,
    
    /// 重复结束日期
    DateTime? repeatUntil,
    
    /// 地理位置提醒
    LocationReminder? locationReminder,
    
    /// 同步状态
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    
    /// 本地修改标记
    @Default(false) bool isDirty,
    
    /// 版本号（乐观锁）
    @Default(1) int version,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) =>
      _$TaskFromJson(json);

  /// 创建新任务工厂方法
  factory Task.create({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.none,
    DateTime? dueDate,
    DateTime? dueTime,
    String? projectId,
    List<String> tags = const [],
    String? parentId,
    int? estimatedDuration,
  }) {
    final now = DateTime.now();
    return Task(
      id: _generateId(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      dueTime: dueTime,
      projectId: projectId,
      tags: tags,
      parentId: parentId,
      estimatedDuration: estimatedDuration,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
  }

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    for (var i = 0; i < length; i++) {
      result += chars[(now + i) % chars.length];
    }
    return result;
  }
}

/// 地理位置提醒
@freezed
class LocationReminder with _$LocationReminder {
  const factory LocationReminder({
    required double latitude,
    required double longitude,
    required double radius, // 米
    required String address,
    required LocationTrigger trigger, // 到达或离开
    String? name,
  }) = _LocationReminder;

  factory LocationReminder.fromJson(Map<String, dynamic> json) =>
      _$LocationReminderFromJson(json);
}

enum LocationTrigger {
  @JsonValue('arrive')
  arrive,    // 到达
  @JsonValue('leave')
  leave,     // 离开
}

/// 同步状态
enum SyncStatus {
  @JsonValue('synced')
  synced,      // 已同步
  @JsonValue('pending')
  pending,     // 待同步
  @JsonValue('syncing')
  syncing,     // 同步中
  @JsonValue('error')
  error,       // 同步失败
  @JsonValue('conflict')
  conflict,    // 冲突
}
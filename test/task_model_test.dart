import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/domain/models/task_model.dart';

void main() {
  group('Task 模型测试', () {
    test('创建基础任务', () {
      final task = Task.create(title: '测试任务');
      
      expect(task.title, '测试任务');
      expect(task.status, TaskStatus.todo);
      expect(task.priority, TaskPriority.none);
      expect(task.id, isNotEmpty);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
    });

    test('创建带所有属性的任务', () {
      final now = DateTime.now();
      final task = Task.create(
        title: '完整任务',
        description: '这是一个测试任务',
        priority: TaskPriority.high,
        dueDate: now,
        dueTime: now,
        projectId: 'project-1',
        tags: ['tag1', 'tag2'],
        estimatedDuration: 60,
      );
      
      expect(task.title, '完整任务');
      expect(task.description, '这是一个测试任务');
      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, isNotNull);
      expect(task.projectId, 'project-1');
      expect(task.tags, ['tag1', 'tag2']);
      expect(task.estimatedDuration, 60);
    });

    test('Task.copyWith 复制任务', () {
      final task = Task.create(title: '原任务');
      final copied = task.copyWith(
        title: '新任务',
        priority: TaskPriority.urgent,
      );
      
      expect(copied.title, '新任务');
      expect(copied.priority, TaskPriority.urgent);
      expect(copied.id, task.id); // ID 不变
    });

    test('Task JSON 序列化', () {
      final task = Task.create(title: 'JSON测试');
      final json = task.toJson();
      final restored = Task.fromJson(json);
      
      expect(restored.title, task.title);
      expect(restored.id, task.id);
    });

    test('Task 优先级比较', () {
      expect(TaskPriority.urgent.index > TaskPriority.high.index, isTrue);
      expect(TaskPriority.high.index > TaskPriority.medium.index, isTrue);
      expect(TaskPriority.medium.index > TaskPriority.low.index, isTrue);
      expect(TaskPriority.low.index > TaskPriority.none.index, isTrue);
    });

    test('Task 状态流转', () {
      var task = Task.create(title: '状态测试');
      
      // 创建时是 todo
      expect(task.status, TaskStatus.todo);
      
      // 标记为进行中
      task = task.copyWith(status: TaskStatus.inProgress);
      expect(task.status, TaskStatus.inProgress);
      
      // 标记完成
      task = task.copyWith(
        status: TaskStatus.done,
        completedAt: DateTime.now(),
      );
      expect(task.status, TaskStatus.done);
      expect(task.completedAt, isNotNull);
    });

    test('子任务支持', () {
      final parent = Task.create(title: '父任务');
      final child = Task.create(
        title: '子任务',
        parentId: parent.id,
      );
      
      expect(parent.parentId, isNull);
      expect(child.parentId, parent.id);
    });

    test('重复任务', () {
      final task = Task.create(
        title: '重复任务',
        dueDate: DateTime.now(),
      ).copyWith(
        repeatRule: RepeatRule.daily,
        repeatUntil: DateTime.now().add(const Duration(days: 30)),
      );
      
      expect(task.repeatRule, RepeatRule.daily);
      expect(task.repeatUntil, isNotNull);
    });

    test('软删除', () {
      var task = Task.create(title: '待删除');
      task = task.copyWith(
        status: TaskStatus.deleted,
        deletedAt: DateTime.now(),
      );
      
      expect(task.status, TaskStatus.deleted);
      expect(task.deletedAt, isNotNull);
    });
  });

  group('LocationReminder 模型测试', () {
    test('创建地理位置提醒', () {
      final reminder = LocationReminder(
        latitude: 39.9042,
        longitude: 116.4074,
        radius: 100,
        address: '北京市',
        trigger: LocationTrigger.arrive,
        name: '公司',
      );
      
      expect(reminder.latitude, 39.9042);
      expect(reminder.longitude, 116.4074);
      expect(reminder.radius, 100);
      expect(reminder.address, '北京市');
      expect(reminder.trigger, LocationTrigger.arrive);
      expect(reminder.name, '公司');
    });

    test('LocationReminder JSON 序列化', () {
      final reminder = LocationReminder(
        latitude: 39.9042,
        longitude: 116.4074,
        radius: 100,
        address: '北京市',
        trigger: LocationTrigger.leave,
      );
      
      final json = reminder.toJson();
      final restored = LocationReminder.fromJson(json);
      
      expect(restored.latitude, reminder.latitude);
      expect(restored.trigger, LocationTrigger.leave);
    });
  });

  group('TaskPriority 枚举测试', () {
    test('所有优先级值正确', () {
      expect(TaskPriority.none.index, 0);
      expect(TaskPriority.low.index, 1);
      expect(TaskPriority.medium.index, 2);
      expect(TaskPriority.high.index, 3);
      expect(TaskPriority.urgent.index, 4);
    });

    test('JSON 序列化/反序列化', () {
      expect(TaskPriority.urgent.toJson(), 4);
    });
  });

  group('RepeatRule 枚举测试', () {
    test('所有重复规则', () {
      expect(RepeatRule.none.index, 0);
      expect(RepeatRule.daily.index, 1);
      expect(RepeatRule.weekdays.index, 2);
      expect(RepeatRule.weekly.index, 3);
      expect(RepeatRule.biweekly.index, 4);
      expect(RepeatRule.monthly.index, 5);
      expect(RepeatRule.quarterly.index, 6);
      expect(RepeatRule.yearly.index, 7);
    });
  });

  group('SyncStatus 枚举测试', () {
    test('同步状态', () {
      expect(SyncStatus.synced.toJson(), 'synced');
      expect(SyncStatus.pending.toJson(), 'pending');
      expect(SyncStatus.syncing.toJson(), 'syncing');
      expect(SyncStatus.error.toJson(), 'error');
      expect(SyncStatus.conflict.toJson(), 'conflict');
    });
  });
}
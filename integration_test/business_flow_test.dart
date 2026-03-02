import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_todo/domain/models/task_model.dart';
import 'package:smart_todo/domain/models/project_model.dart';
import 'package:smart_todo/services/nlp_service.dart';
import 'package:smart_todo/services/pomodoro_service.dart';

void main() {
  // 业务流程集成测试（不需要 Flutter 界面）

  group('任务完整生命周期', () {
    test('从创建到完成的完整流程', () {
      // 1. NLP 解析输入
      final nlpService = NlpServiceImpl();
      final parseResult = nlpService.parse('P1 明天上午10点 完成项目提案 #工作 #重要 2小时');

      // 验证解析
      expect(parseResult.title, '完成项目提案');
      expect(parseResult.priority, TaskPriority.high);
      expect(parseResult.dueDate, isNotNull);
      expect(parseResult.tags, containsAll(['工作', '重要']));
      expect(parseResult.estimatedDuration, 120);

      // 2. 创建任务
      final task = Task.create(
        title: parseResult.title,
        priority: parseResult.priority,
        dueDate: parseResult.dueDate,
        dueTime: parseResult.dueTime,
        tags: parseResult.tags,
        estimatedDuration: parseResult.estimatedDuration,
      );

      expect(task.status, TaskStatus.todo);
      expect(task.isDirty, isFalse);

      // 3. 开始执行 - 状态变为进行中
      var updatedTask = task.copyWith(status: TaskStatus.inProgress);
      expect(updatedTask.status, TaskStatus.inProgress);
      expect(updatedTask.isDirty, isTrue);

      // 4. 标记为完成
      updatedTask = updatedTask.copyWith(
        status: TaskStatus.done,
        completedAt: DateTime.now(),
      );
      expect(updatedTask.status, TaskStatus.done);
      expect(updatedTask.completedAt, isNotNull);

      // 5. JSON 持久化模拟
      final json = updatedTask.toJson();
      expect(json['title'], '完成项目提案');
      expect(json['priority'], TaskPriority.high.index);

      // 6. 从 JSON 恢复
      final restored = Task.fromJson(json);
      expect(restored.title, updatedTask.title);
      expect(restored.status, TaskStatus.done);
    });

    test('任务软删除流程', () {
      final task = Task.create(title: '待删除任务');

      // 软删除
      var deletedTask = task.copyWith(
        status: TaskStatus.deleted,
        deletedAt: DateTime.now(),
      );

      expect(deletedTask.status, TaskStatus.deleted);
      expect(deletedTask.deletedAt, isNotNull);

      // 恢复任务
      var restoredTask = deletedTask.copyWith(
        status: TaskStatus.todo,
        deletedAt: null,
      );
      expect(restoredTask.status, TaskStatus.todo);
      expect(restoredTask.deletedAt, isNull);

      // 永久删除
      // (在实际应用中会从数据库删除)
    });

    test('子任务流程', () {
      // 创建父任务
      final parent = Task.create(title: '完成项目');

      // 创建子任务
      final subtask1 = Task.create(
        title: '需求分析',
        parentId: parent.id,
      );
      final subtask2 = Task.create(
        title: '系统设计',
        parentId: parent.id,
      );
      final subtask3 = Task.create(
        title: '编码实现',
        parentId: parent.id,
      );

      // 验证父子关系
      expect(subtask1.parentId, parent.id);
      expect(subtask2.parentId, parent.id);
      expect(subtask3.parentId, parent.id);

      // 更新父任务的子任务列表
      final updatedParent = parent.copyWith(
        subtaskIds: [subtask1.id, subtask2.id, subtask3.id],
      );

      expect(updatedParent.subtaskIds.length, 3);
    });

    test('重复任务流程', () {
      final now = DateTime.now();

      // 创建每日重复任务
      final dailyTask = Task.create(
        title: '每日站会',
        dueDate: now,
      ).copyWith(
        repeatRule: RepeatRule.daily,
        repeatUntil: now.add(const Duration(days: 30)),
      );

      expect(dailyTask.repeatRule, RepeatRule.daily);
      expect(dailyTask.repeatUntil, isNotNull);

      // 创建每周重复任务
      final weeklyTask = Task.create(
        title: '周报',
        dueDate: now,
      ).copyWith(
        repeatRule: RepeatRule.weekly,
      );

      expect(weeklyTask.repeatRule, RepeatRule.weekly);

      // 工作日重复
      final weekdayTask = Task.create(
        title: '晨会',
        dueDate: now,
      ).copyWith(
        repeatRule: RepeatRule.weekdays,
      );

      expect(weekdayTask.repeatRule, RepeatRule.weekdays);
    });
  });

  group('番茄钟 + 任务联动', () {
    test('番茄钟与任务关联流程', () {
      final pomodoroService = PomodoroServiceImpl();
      const config = PomodoroConfig(
        workDuration: 25,
        shortBreakDuration: 5,
        longBreakDuration: 15,
        sessionsBeforeLongBreak: 4,
      );
      pomodoroService.setConfig(config);

      // 创建任务
      final task = Task.create(title: '专注任务');

      // 启动番茄钟
      pomodoroService.start(task.id);
      expect(pomodoroService.currentTaskId, task.id);
      expect(pomodoroService.state, PomodoroState.working);
      expect(pomodoroService.completedSessions, 0);

      // 完成4个工作周期
      for (int i = 0; i < 4; i++) {
        pomodoroService.skip(); // 跳过工作 -> 休息
        pomodoroService.skip(); // 跳过休息 -> 工作
      }

      // 验证进入长休息
      expect(pomodoroService.currentSession, PomodoroSession.longBreak);
      expect(pomodoroService.completedSessions, 4);

      // 停止番茄钟
      pomodoroService.stop();
      expect(pomodoroService.state, PomodoroState.idle);

      pomodoroService.dispose();
    });

    test('番茄钟自定义配置流程', () {
      final pomodoroService = PomodoroServiceImpl();

      // 使用更长的专注时间
      const longConfig = PomodoroConfig(
        workDuration: 50,
        shortBreakDuration: 10,
        longBreakDuration: 30,
      );
      pomodoroService.setConfig(longConfig);

      pomodoroService.start('task-1');
      expect(pomodoroService.remainingSeconds, 50 * 60);

      pomodoroService.stop();

      // 切换到短时间配置
      const shortConfig = PomodoroConfig(
        workDuration: 15,
        shortBreakDuration: 3,
        longBreakDuration: 10,
      );
      pomodoroService.setConfig(shortConfig);

      pomodoroService.start('task-2');
      expect(pomodoroService.remainingSeconds, 15 * 60);

      pomodoroService.stop();
      pomodoroService.dispose();
    });
  });

  group('项目 + 任务管理流程', () {
    test('项目创建与任务关联', () {
      // 创建项目
      final project = Project.create(
        name: 'Flutter 开发',
        color: ProjectColor.blue,
        icon: ProjectIcon.code,
      );

      expect(project.name, 'Flutter 开发');
      expect(project.color, ProjectColor.blue);
      expect(project.icon, ProjectIcon.code);

      // 创建属于该项目的任务
      final task1 = Task.create(
        title: '学习 Widget',
        projectId: project.id,
        tags: ['学习', 'Flutter'],
      );
      final task2 = Task.create(
        title: '状态管理',
        projectId: project.id,
        tags: ['学习', 'Flutter'],
      );

      expect(task1.projectId, project.id);
      expect(task2.projectId, project.id);

      // 更新项目统计
      final updatedProject = project.copyWith(
        totalTasks: 2,
        completedTasks: 0,
      );

      expect(updatedProject.totalTasks, 2);
      expect(updatedProject.completionRate, 0.0);

      // 完成任务
      var task1Done = task1.copyWith(
        status: TaskStatus.done,
        completedAt: DateTime.now(),
      );

      // 更新项目统计
      final finalProject = updatedProject.copyWith(
        completedTasks: 1,
      );

      expect(finalProject.completedTasks, 1);
      expect(finalProject.completionRate, 0.5);
    });

    test('项目归档流程', () {
      final project = Project.create(name: '已完成项目');

      // 归档项目
      final archived = project.copyWith(
        isArchived: true,
      );

      expect(archived.isArchived, isTrue);

      // 恢复项目
      final restored = archived.copyWith(
        isArchived: false,
      );

      expect(restored.isArchived, isFalse);
    });

    test('嵌套项目流程', () {
      // 创建父项目
      final parent = Project.create(name: '学习');

      // 创建子项目
      final child1 = Project.create(
        name: 'Flutter',
        parentId: parent.id,
        color: ProjectColor.blue,
      );
      final child2 = Project.create(
        name: 'React',
        parentId: parent.id,
        color: ProjectColor.green,
      );

      expect(parent.parentId, isNull);
      expect(child1.parentId, parent.id);
      expect(child2.parentId, parent.id);

      // 更新父项目
      final updatedParent = parent.copyWith(
        totalTasks: 10,
        completedTasks: 5,
      );

      expect(updatedParent.totalTasks, 10);
      expect(updatedParent.completionRate, 0.5);
    });
  });

  group('复杂 NLP 场景', () {
    test('各种时间格式解析', () {
      final nlpService = NlpServiceImpl();

      // 今天
      var result = nlpService.parse('今天 任务');
      expect(result.dueDate?.day, DateTime.now().day);

      // 明天
      result = nlpService.parse('明天 任务');
      expect(result.dueDate?.day, DateTime.now().add(const Duration(days: 1)).day);

      // 具体日期
      result = nlpService.parse('3月15日 任务');
      expect(result.dueDate?.month, 3);
      expect(result.dueDate?.day, 15);

      // 时间
      result = nlpService.parse('下午3点半 任务');
      expect(result.dueTime?.hour, 15);
      expect(result.dueTime?.minute, 30);

      // 组合
      result = nlpService.parse('明天早上9点 会议');
      expect(result.dueDate?.day, DateTime.now().add(const Duration(days: 1)).day);
      expect(result.dueTime?.hour, 9);
    });

    test('优先级解析', () {
      final nlpService = NlpServiceImpl();

      expect(nlpService.parse('P0 任务').priority, TaskPriority.urgent);
      expect(nlpService.parse('P1 任务').priority, TaskPriority.high);
      expect(nlpService.parse('P2 任务').priority, TaskPriority.medium);
      expect(nlpService.parse('P3 任务').priority, TaskPriority.low);

      expect(nlpService.parse('紧急任务').priority, TaskPriority.urgent);
      expect(nlpService.parse('重要任务').priority, TaskPriority.high);
      expect(nlpService.parse('普通任务').priority, TaskPriority.medium);
    });

    test('时长解析', () {
      final nlpService = NlpServiceImpl();

      expect(nlpService.parse('任务 30分钟').estimatedDuration, 30);
      expect(nlpService.parse('任务 1小时').estimatedDuration, 60);
      expect(nlpService.parse('任务 2小时30分钟').estimatedDuration, 150);
    });

    test('标签解析', () {
      final nlpService = NlpServiceImpl();

      var result = nlpService.parse('任务 #工作 #紧急');
      expect(result.tags, containsAll(['工作', '紧急']));

      result = nlpService.parse('任务 标签:工作');
      expect(result.tags, contains('工作'));
    });
  });

  group('数据一致性', () {
    test('任务 ID 唯一性', () {
      final tasks = List.generate(100, (_) => Task.create(title: '任务'));
      final ids = tasks.map((t) => t.id).toSet();

      // 100个任务应该有100个不同的ID
      expect(ids.length, 100);
    });

    test('JSON 序列化完整性', () {
      final now = DateTime.now();
      final task = Task(
        id: 'test-123',
        title: '完整任务',
        description: '描述',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueDate: now,
        dueTime: now,
        estimatedDuration: 60,
        projectId: 'proj-1',
        tags: ['tag1', 'tag2'],
        attachments: ['file1.pdf'],
        createdAt: now,
        updatedAt: now,
        repeatRule: RepeatRule.daily,
      );

      // 完整序列化
      final json = task.toJson();

      // 验证所有字段
      expect(json['id'], 'test-123');
      expect(json['title'], '完整任务');
      expect(json['description'], '描述');
      expect(json['status'], TaskStatus.inProgress.index);
      expect(json['priority'], TaskPriority.high.index);
      expect(json['tags'], ['tag1', 'tag2']);
      expect(json['attachments'], ['file1.pdf']);
      expect(json['repeatRule'], RepeatRule.daily.index);

      // 完整反序列化
      final restored = Task.fromJson(json);

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.status, task.status);
      expect(restored.priority, task.priority);
      expect(restored.tags, task.tags);
      expect(restored.attachments, task.attachments);
      expect(restored.repeatRule, task.repeatRule);
    });

    test('Freezed 模型不可变性', () {
      final task = Task.create(title: '原始任务');

      // copyWith 创建新实例
      final updated = task.copyWith(title: '新任务');

      // 原始对象不变
      expect(task.title, '原始任务');
      expect(updated.title, '新任务');
      expect(task.id, updated.id); // ID 相同
    });
  });

  group('边界情况', () {
    test('空任务列表', () {
      final tasks = <Task>[];
      expect(tasks.isEmpty, isTrue);
    });

    test('任务过滤 - 无结果', () {
      final tasks = [
        Task.create(title: 'Flutter'),
        Task.create(title: 'React'),
      ];

      final result = tasks.where((t) => t.title.contains('Python')).toList();
      expect(result, isEmpty);
    });

    test('日期边界 - 跨月', () {
      final nlpService = NlpServiceImpl();
      final result = nlpService.parse('下月1日 任务');

      // 应该解析到下个月
      expect(result.dueDate, isNotNull);
    });

    test('超长任务标题', () {
      final longTitle = 'A' * 1000;
      final task = Task.create(title: longTitle);

      expect(task.title.length, 1000);
    });
  });
}
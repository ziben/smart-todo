import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_todo/main.dart' as app;
import 'package:smart_todo/domain/models/task_model.dart';
import 'package:smart_todo/domain/usecases/task_usecases.dart';
import 'package:smart_todo/services/nlp_service.dart';
import 'package:smart_todo/services/pomodoro_service.dart';
import 'package:smart_todo/domain/models/project_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('任务管理集成测试', () {
    testWidgets('创建任务的完整流程', (WidgetTester tester) async {
      // 启动应用
      await app.main();
      await tester.pumpAndSettle();

      // 点击添加任务按钮
      final addButton = find.byTooltip('添加任务');
      if (addButton.evaluateSafely().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 输入任务标题
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, '集成测试任务');
        await tester.pumpAndSettle();

        // 点击保存
        final saveButton = find.text('保存');
        if (saveButton.evaluateSafely().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }

      // 验证任务已创建（检查列表中是否有该任务）
      expect(find.text('集成测试任务'), findsAny);
    });

    testWidgets('NLP 解析完整流程', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // 模拟 NLP 解析完整流程
      final nlpService = NlpServiceImpl();

      // 输入自然语言任务
      const input = 'P1 明天上午9点 完成项目汇报 #工作 1小时';
      final result = nlpService.parse(input);

      // 验证解析结果
      expect(result.title, '完成项目汇报');
      expect(result.priority, TaskPriority.high);
      expect(result.dueDate, isNotNull);
      expect(result.tags, contains('工作'));
      expect(result.estimatedDuration, 60);

      // 验证时间
      expect(result.dueTime?.hour, 9);
    });

    testWidgets('任务状态流转', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // 创建任务
      final task = Task.create(
        title: '状态测试任务',
        priority: TaskPriority.medium,
      );

      // 验证初始状态
      expect(task.status, TaskStatus.todo);
      expect(task.priority, TaskPriority.medium);

      // 模拟进行中
      var updatedTask = task.copyWith(status: TaskStatus.inProgress);
      expect(updatedTask.status, TaskStatus.inProgress);

      // 模拟完成
      updatedTask = updatedTask.copyWith(
        status: TaskStatus.done,
        completedAt: DateTime.now(),
      );
      expect(updatedTask.status, TaskStatus.done);
      expect(updatedTask.completedAt, isNotNull);
    });
  });

  group('番茄钟集成测试', () {
    testWidgets('番茄钟完整工作流', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final pomodoroService = PomodoroServiceImpl();
      const config = PomodoroConfig(
        workDuration: 25,
        shortBreakDuration: 5,
        longBreakDuration: 15,
      );
      pomodoroService.setConfig(config);

      // 启动番茄钟
      pomodoroService.start('task-1');
      expect(pomodoroService.state, PomodoroState.working);
      expect(pomodoroService.currentSession, PomodoroSession.work);
      expect(pomodoroService.remainingSeconds, 25 * 60);

      // 暂停
      pomodoroService.pause();
      expect(pomodoroService.state, PomodoroState.paused);

      // 恢复
      pomodoroService.resume();
      expect(pomodoroService.state, PomodoroState.working);

      // 跳过到休息
      pomodoroService.skip();
      expect(
        pomodoroService.currentSession == PomodoroSession.shortBreak ||
        pomodoroService.currentSession == PomodoroSession.longBreak,
        isTrue,
      );

      // 停止
      pomodoroService.stop();
      expect(pomodoroService.state, PomodoroState.idle);

      pomodoroService.dispose();
    });

    testWidgets('番茄钟配置变更', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final pomodoroService = PomodoroServiceImpl();

      // 默认配置
      expect(pomodoroService.config.workDuration, 25);

      // 修改配置
      const newConfig = PomodoroConfig(
        workDuration: 45,
        shortBreakDuration: 10,
        longBreakDuration: 30,
      );
      pomodoroService.setConfig(newConfig);

      // 启动并验证新配置生效
      pomodoroService.start('task-1');
      expect(pomodoroService.remainingSeconds, 45 * 60);

      pomodoroService.stop();
      pomodoroService.dispose();
    });
  });

  group('项目/清单集成测试', () {
    testWidgets('创建项目的完整流程', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // 创建项目
      final project = Project.create(
        name: '工作项目',
        color: ProjectColor.red,
        icon: ProjectIcon.work,
      );

      // 验证
      expect(project.name, '工作项目');
      expect(project.color, ProjectColor.red);
      expect(project.icon, ProjectIcon.work);
      expect(project.id, isNotEmpty);
      expect(project.createdAt, isNotNull);
    });

    testWidgets('项目嵌套', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // 创建父项目
      final parent = Project.create(name: '父项目');
      expect(parent.parentId, isNull);

      // 创建子项目
      final child = Project.create(
        name: '子项目',
        parentId: parent.id,
      );
      expect(child.parentId, parent.id);

      // JSON 序列化
      final json = parent.toJson();
      final restored = Project.fromJson(json);
      expect(restored.name, parent.name);
      expect(restored.id, parent.id);
    });

    testWidgets('项目统计更新', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      var project = Project.create(name: '测试项目');

      // 初始无统计
      expect(project.totalTasks, 0);
      expect(project.completedTasks, 0);
      expect(project.completionRate, 0.0);

      // 更新统计
      project = project.copyWith(
        totalTasks: 10,
        completedTasks: 7,
        overdueTasks: 1,
      );

      expect(project.totalTasks, 10);
      expect(project.completedTasks, 7);
      expect(project.overdueTasks, 1);
      expect(project.completionRate, 0.7);
    });
  });

  group('NLP + 任务创建流程', () {
    testWidgets('NLP 解析后创建任务', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // NLP 解析
      final nlpService = NlpServiceImpl();
      final parseResult = nlpService.parse('紧急 明天晚上8点 完成PPT #工作 2小时');

      // 基于解析结果创建任务
      final task = Task.create(
        title: parseResult.title,
        priority: parseResult.priority,
        dueDate: parseResult.dueDate,
        dueTime: parseResult.dueTime,
        tags: parseResult.tags,
        estimatedDuration: parseResult.estimatedDuration,
      );

      // 验证
      expect(task.title, '完成PPT');
      expect(task.priority, TaskPriority.urgent);
      expect(task.tags, contains('工作'));
      expect(task.estimatedDuration, 120);
    });

    testWidgets('批量 NLP 解析', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final nlpService = NlpServiceImpl();
      final inputs = [
        '任务1 #标签1',
        '任务2 #标签2',
        'P1 任务3 #标签3',
      ];

      final results = nlpService.parseBatch(inputs);

      expect(results.length, 3);
      expect(results[0].title, '任务1');
      expect(results[1].title, '任务2');
      expect(results[2].priority, TaskPriority.high);
      expect(results[2].tags, contains('标签3'));
    });
  });

  group('任务搜索集成测试', () {
    testWidgets('搜索任务流程', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // 创建多个任务
      final tasks = [
        Task.create(title: 'Flutter 开发'),
        Task.create(title: 'React 开发'),
        Task.create(title: 'Python 脚本'),
        Task.create(title: 'Flutter UI 设计'),
      ];

      // 模拟搜索
      final keyword = 'Flutter';
      final filtered = tasks.where((t) => 
        t.title.toLowerCase().contains(keyword.toLowerCase())
      ).toList();

      expect(filtered.length, 2);
      expect(filtered.every((t) => t.title.contains('Flutter')), isTrue);
    });

    testWidgets('按标签搜索', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final tasks = [
        Task.create(title: '任务A', tags: ['工作', '紧急']),
        Task.create(title: '任务B', tags: ['生活']),
        Task.create(title: '任务C', tags: ['工作']),
      ];

      // 按标签搜索
      final workTasks = tasks.where((t) => t.tags.contains('工作')).toList();

      expect(workTasks.length, 2);
      expect(workTasks.any((t) => t.title == '任务A'), isTrue);
      expect(workTasks.any((t) => t.title == '任务C'), isTrue);
    });
  });

  group('数据验证集成测试', () {
    testWidgets('任务数据完整性', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final task = Task(
        id: 'test-id',
        title: '完整任务',
        description: '描述',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        dueDate: now,
        dueTime: now,
        projectId: 'proj-1',
        tags: ['tag1', 'tag2'],
        estimatedDuration: 60,
        createdAt: now,
        updatedAt: now,
      );

      // JSON 往返
      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.status, task.status);
      expect(restored.priority, task.priority);
      expect(restored.tags, task.tags);
      expect(restored.estimatedDuration, task.estimatedDuration);
    });

    testWidgets('空输入验证', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      final nlpService = NlpServiceImpl();

      // 空字符串
      final emptyResult = nlpService.parse('');
      expect(emptyResult.title, isEmpty);

      // 只含空格
      final spaceResult = nlpService.parse('   ');
      expect(spaceResult.title, isEmpty);

      // 验证
      expect(nlpService.validate(emptyResult), isFalse);
      expect(nlpService.validate(spaceResult), isFalse);
    });
  });
}
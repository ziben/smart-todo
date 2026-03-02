import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_todo/domain/entities/failures.dart';
import 'package:smart_todo/domain/models/task_model.dart';
import 'package:smart_todo/domain/repositories/task_repository.dart';
import 'package:smart_todo/domain/usecases/task_usecases.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late GetTasksUseCase getTasksUseCase;
  late GetTaskByIdUseCase getTaskByIdUseCase;
  late CreateTaskUseCase createTaskUseCase;
  late UpdateTaskUseCase updateTaskUseCase;
  late DeleteTaskUseCase deleteTaskUseCase;
  late CompleteTaskUseCase completeTaskUseCase;
  late SearchTasksUseCase searchTasksUseCase;
  late GetOverdueTasksUseCase getOverdueTasksUseCase;

  final testTask = Task.create(
    title: '测试任务',
    description: '测试描述',
    priority: TaskPriority.high,
    projectId: 'project-1',
    tags: ['tag1'],
  );

  setUp(() {
    mockRepository = MockTaskRepository();

    getTasksUseCase = GetTasksUseCase(mockRepository);
    getTaskByIdUseCase = GetTaskByIdUseCase(mockRepository);
    createTaskUseCase = CreateTaskUseCase(mockRepository);
    updateTaskUseCase = UpdateTaskUseCase(mockRepository);
    deleteTaskUseCase = DeleteTaskUseCase(mockRepository);
    completeTaskUseCase = CompleteTaskUseCase(mockRepository);
    searchTasksUseCase = SearchTasksUseCase(mockRepository);
    getOverdueTasksUseCase = GetOverdueTasksUseCase(mockRepository);

    // 注册 fallback 值
    registerFallbackValue(testTask);
    registerFallbackValue(const GetTasksParams());
  });

  group('GetTasksUseCase', () {
    test('获取所有任务成功', () async {
      when(() => mockRepository.getAllTasks())
          .thenAnswer((_) async => [testTask]);

      final result = await getTasksUseCase(const GetTasksParams());

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('should not be left'),
        (tasks) => expect(tasks.length, 1),
      );
      verify(() => mockRepository.getAllTasks()).called(1);
    });

    test('获取所有任务失败', () async {
      when(() => mockRepository.getAllTasks())
          .thenThrow(Exception('Database error'));

      final result = await getTasksUseCase(const GetTasksParams());

      expect(result.isLeft(), isTrue);
    });

    test('按状态过滤任务', () async {
      when(() => mockRepository.getAllTasks())
          .thenAnswer((_) async => [testTask]);

      final result = await getTasksUseCase(
        const GetTasksParams(status: TaskStatus.todo),
      );

      result.fold(
        (l) => fail('should not be left'),
        (tasks) => expect(tasks.first.status, TaskStatus.todo),
      );
    });

    test('按项目ID过滤任务', () async {
      when(() => mockRepository.getAllTasks())
          .thenAnswer((_) async => [testTask]);

      final result = await getTasksUseCase(
        const GetTasksParams(projectId: 'project-1'),
      );

      result.fold(
        (l) => fail('should not be left'),
        (tasks) => expect(tasks.first.projectId, 'project-1'),
      );
    });

    test('按标签过滤任务', () async {
      when(() => mockRepository.getAllTasks())
          .thenAnswer((_) async => [testTask]);

      final result = await getTasksUseCase(
        const GetTasksParams(tag: 'tag1'),
      );

      result.fold(
        (l) => fail('should not be left'),
        (tasks) => expect(tasks.first.tags.contains('tag1'), isTrue),
      );
    });
  });

  group('GetTaskByIdUseCase', () {
    test('按ID获取任务成功', () async {
      when(() => mockRepository.getTaskById('task-1'))
          .thenAnswer((_) async => testTask);

      final result = await getTaskByIdUseCase(
        const GetTaskByIdParams('task-1'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('should not be left'),
        (task) => expect(task.id, testTask.id),
      );
    });

    test('按ID获取任务 - 任务不存在', () async {
      when(() => mockRepository.getTaskById('non-existent'))
          .thenAnswer((_) async => null);

      final result = await getTaskByIdUseCase(
        const GetTaskByIdParams('non-existent'),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<TaskNotFoundFailure>()),
        (task) => fail('should not be right'),
      );
    });
  });

  group('CreateTaskUseCase', () {
    test('创建任务成功', () async {
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => testTask);

      final result = await createTaskUseCase(
        const CreateTaskParams(title: '测试任务'),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.createTask(any())).called(1);
    });

    test('创建任务 - 空标题失败', () async {
      final result = await createTaskUseCase(
        const CreateTaskParams(title: ''),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (task) => fail('should not be right'),
      );
    });

    test('创建任务 - 只含空格失败', () async {
      final result = await createTaskUseCase(
        const CreateTaskParams(title: '   '),
      );

      expect(result.isLeft(), isTrue);
    });

    test('创建任务传递所有参数', () async {
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => testTask);

      await createTaskUseCase(
        CreateTaskParams(
          title: '测试任务',
          description: '测试描述',
          priority: TaskPriority.high,
          projectId: 'project-1',
          tags: ['tag1', 'tag2'],
          estimatedDuration: 60,
        ),
      );

      verify(() => mockRepository.createTask(any())).called(1);
    });
  });

  group('UpdateTaskUseCase', () {
    test('更新任务成功', () async {
      when(() => mockRepository.getTaskById('task-1'))
          .thenAnswer((_) async => testTask);
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => testTask.copyWith(title: '新标题'));

      final result = await updateTaskUseCase(
        const UpdateTaskParams(id: 'task-1', title: '新标题'),
      );

      expect(result.isRight(), isTrue);
    });

    test('更新不存在的任务失败', () async {
      when(() => mockRepository.getTaskById('non-existent'))
          .thenAnswer((_) async => null);

      final result = await updateTaskUseCase(
        const UpdateTaskParams(id: 'non-existent', title: '新标题'),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<TaskNotFoundFailure>()),
        (task) => fail('should not be right'),
      );
    });
  });

  group('DeleteTaskUseCase', () {
    test('软删除任务成功', () async {
      when(() => mockRepository.getTaskById('task-1'))
          .thenAnswer((_) async => testTask);
      when(() => mockRepository.deleteTask('task-1'))
          .thenAnswer((_) async => {});

      final result = await deleteTaskUseCase(
        const DeleteTaskParams(id: 'task-1', permanent: false),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.deleteTask('task-1')).called(1);
    });

    test('永久删除任务成功', () async {
      when(() => mockRepository.getTaskById('task-1'))
          .thenAnswer((_) async => testTask);
      when(() => mockRepository.deleteTaskPermanently('task-1'))
          .thenAnswer((_) async => {});

      final result = await deleteTaskUseCase(
        const DeleteTaskParams(id: 'task-1', permanent: true),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.deleteTaskPermanently('task-1')).called(1);
    });

    test('删除不存在的任务失败', () async {
      when(() => mockRepository.getTaskById('non-existent'))
          .thenAnswer((_) async => null);

      final result = await deleteTaskUseCase(
        const DeleteTaskParams(id: 'non-existent'),
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('CompleteTaskUseCase', () {
    test('完成任务成功', () async {
      when(() => mockRepository.completeTask('task-1'))
          .thenAnswer((_) async => testTask.copyWith(
                status: TaskStatus.done,
                completedAt: DateTime.now(),
              ));

      final result = await completeTaskUseCase(
        const CompleteTaskParams('task-1'),
      );

      expect(result.isRight(), isTrue);
    });
  });

  group('SearchTasksUseCase', () {
    test('搜索任务成功', () async {
      when(() => mockRepository.searchTasks('测试'))
          .thenAnswer((_) async => [testTask]);

      final result = await searchTasksUseCase(
        const SearchTasksParams('测试'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('should not be left'),
        (tasks) => expect(tasks.length, 1),
      );
    });

    test('空搜索词返回空列表', () async {
      final result = await searchTasksUseCase(
        const SearchTasksParams(''),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('should not be left'),
        (tasks) => expect(tasks, isEmpty),
      );
    });

    test('只含空格的搜索词返回空列表', () async {
      final result = await searchTasksUseCase(
        const SearchTasksParams('   '),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('should not be left'),
        (tasks) => expect(tasks, isEmpty),
      );
    });
  });

  group('GetOverdueTasksUseCase', () {
    test('获取逾期任务成功', () async {
      when(() => mockRepository.getOverdueTasks())
          .thenAnswer((_) async => [testTask]);

      final result = await getOverdueTasksUseCase();

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.getOverdueTasks()).called(1);
    });

    test('获取逾期任务失败', () async {
      when(() => mockRepository.getOverdueTasks())
          .thenThrow(Exception('Database error'));

      final result = await getOverdueTasksUseCase();

      expect(result.isLeft(), isTrue);
    });
  });
}
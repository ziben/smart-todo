// 独立 Dart 测试 - 不需要 Flutter 依赖
// 用于验证核心业务逻辑

/// 简单的任务模型
class Task {
  final String id;
  final String title;
  final String? description;
  final int status; // 0=todo, 1=inProgress, 2=done
  final int priority; // 0=none, 1=low, 2=medium, 3=high, 4=urgent
  final DateTime? dueDate;
  final DateTime? dueTime;
  final int? estimatedDuration;
  final String? projectId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status = 0,
    this.priority = 0,
    this.dueDate,
    this.dueTime,
    this.estimatedDuration,
    this.projectId,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? status,
    int? priority,
    DateTime? dueDate,
    DateTime? dueTime,
    int? estimatedDuration,
    String? projectId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      projectId: projectId ?? this.projectId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// NLP 解析结果
class NlpParseResult {
  final String title;
  final int priority;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final List<String> tags;
  final int? estimatedDuration;

  NlpParseResult({
    required this.title,
    this.priority = 0,
    this.dueDate,
    this.dueTime,
    this.tags = const [],
    this.estimatedDuration,
  });
}

/// NLP 服务
class NlpService {
  NlpParseResult parse(String input) {
    if (input.trim().isEmpty) {
      return NlpParseResult(title: '');
    }

    String text = input.trim();
    int priority = 0;
    DateTime? dueDate;
    DateTime? dueTime;
    List<String> tags = [];
    int? estimatedDuration;

    // 解析优先级
    final lowerText = text.toLowerCase();
    if (lowerText.contains('p0') || lowerText.contains('紧急') || lowerText.contains('urgent')) {
      priority = 4;
    } else if (lowerText.contains('p1') || lowerText.contains('重要') || lowerText.contains('high')) {
      priority = 3;
    } else if (lowerText.contains('p2') || lowerText.contains('普通') || lowerText.contains('medium')) {
      priority = 2;
    } else if (lowerText.contains('p3') || lowerText.contains('低') || lowerText.contains('low')) {
      priority = 1;
    }

    // 解析日期
    final now = DateTime.now();
    if (text.contains('今天')) {
      dueDate = DateTime(now.year, now.month, now.day);
      text = text.replaceAll('今天', '');
    } else if (text.contains('明天')) {
      final tomorrow = now.add(const Duration(days: 1));
      dueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      text = text.replaceAll('明天', '');
    } else if (text.contains('后天')) {
      final dayAfter = now.add(const Duration(days: 2));
      dueDate = DateTime(dayAfter.year, dayAfter.month, dayAfter.day);
      text = text.replaceAll('后天', '');
    }

    // 解析时间
    final timeMatch = RegExp(r'(\d{1,2})[:点](\d{0,2})?').firstMatch(text);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2)?.isNotEmpty == true
          ? int.parse(timeMatch.group(2)!)
          : 0;
      if (text.contains('下午') || text.contains('晚上')) {
        if (hour < 12) hour += 12;
      }
      dueTime = DateTime(now.year, now.month, now.day, hour, minute);
    }

    // 解析标签 - 使用原始输入解析（因为 text 已经被清理过了）
    // 修复：\w 不匹配中文，需要用 Unicode 匹配
    final tagMatches = RegExp(r'#([^\s#]+)').allMatches(input);
    for (final match in tagMatches) {
      tags.add(match.group(1)!);
    }

    // 解析时长 - 使用原始输入解析
    final hourMatch = RegExp(r'(\d+)\s*[个]?小时?').firstMatch(input);
    final minMatch = RegExp(r'(\d+)\s*分钟?').firstMatch(input);
    if (hourMatch != null) {
      estimatedDuration = int.parse(hourMatch.group(1)!) * 60;
    }
    if (minMatch != null) {
      estimatedDuration = (estimatedDuration ?? 0) + int.parse(minMatch.group(1)!);
    }

    // 清理标题
    String title = text
        .replaceAll(RegExp(r'p\d'), '')
        .replaceAll(RegExp(r'#[^\s#]+'), '')
        .replaceAll(RegExp(r'\d+[时分]'), '')
        .replaceAll(RegExp(r'(紧急|重要|普通|低)'), '')
        .replaceAll(RegExp(r'(今天|明天|后天|早上|下午|晚上)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return NlpParseResult(
      title: title.isEmpty ? input : title,
      priority: priority,
      dueDate: dueDate,
      dueTime: dueTime,
      tags: tags,
      estimatedDuration: estimatedDuration,
    );
  }
}

/// 番茄钟服务
class PomodoroService {
  int _state = 0; // 0=idle, 1=working, 2=shortBreak, 3=longBreak, 4=paused
  int _remainingSeconds = 0;
  String? _currentTaskId;
  int _completedSessions = 0;
  int _workDuration = 25;

  int get state => _state;
  int get remainingSeconds => _remainingSeconds;
  String? get currentTaskId => _currentTaskId;
  int get completedSessions => _completedSessions;

  void start(String taskId) {
    _currentTaskId = taskId;
    _state = 1; // working
    _remainingSeconds = _workDuration * 60;
  }

  void pause() {
    if (_state == 1 || _state == 2 || _state == 3) {
      _state = 4; // paused
    }
  }

  void resume() {
    if (_state == 4) {
      _state = 1; // back to working
    }
  }

  void stop() {
    _state = 0;
    _currentTaskId = null;
    _remainingSeconds = 0;
  }

  void skip() {
    // 跳过到下一个会话
    if (_state == 1) {
      _state = 2; // short break
      _remainingSeconds = 5 * 60;
      _completedSessions++;
    } else if (_state == 2) {
      _state = 1; // back to working
      _remainingSeconds = _workDuration * 60;
    }
  }
}

// ============ 测试 ============

int passed = 0;
int failed = 0;

void expect(dynamic actual, dynamic matcher, {String? reason}) {
  bool match = false;
  
  if (matcher is bool) {
    match = actual == matcher;
  } else if (matcher is int) {
    match = actual == matcher;
  } else if (matcher is String) {
    match = actual == matcher;
  } else if (matcher is Set) {
    match = matcher.contains(actual);
  } else if (matcher == isNull) {
    match = actual == null;
  } else if (matcher == isNotNull) {
    match = actual != null;
  } else if (matcher is TypeMatcher) {
    match = actual.runtimeType == matcher.type;
  }
  
  if (match) {
    passed++;
    print('  ✓');
  } else {
    failed++;
    print('  ✗ Expected: $matcher, got: $actual${reason != null ? " ($reason)" : ""}');
  }
}

// 简化 matcher
final isNull = TypeMatcher<Object?>(null);
final isNotNull = TypeMatcher<Object>(Object());

class TypeMatcher<T> {
  final dynamic type;
  TypeMatcher(this.type);
}

void test(String name, void Function() fn) {
  print('Testing: $name');
  try {
    fn();
  } catch (e) {
    failed++;
    print('  ✗ Error: $e');
  }
}

void group(String name, void Function() fn) {
  print('\n=== $name ===');
  fn();
  print('Passed: $passed, Failed: $failed');
}

void main() {
  final nlpService = NlpService();
  
  group('NLP Service Tests', () {
    test('Parse simple task', () {
      final result = nlpService.parse('完成代码评审');
      expect(result.title, '完成代码评审');
      expect(result.priority, 0);
    });

    test('Parse priority P0', () {
      final result = nlpService.parse('P0 紧急修复bug');
      expect(result.priority, 4);
    });

    test('Parse priority P1', () {
      final result = nlpService.parse('P1 重要任务');
      expect(result.priority, 3);
    });

    test('Parse today', () {
      final result = nlpService.parse('今天 提交代码');
      expect(result.dueDate, isNotNull);
    });

    test('Parse tomorrow', () {
      final result = nlpService.parse('明天 开会');
      expect(result.dueDate, isNotNull);
    });

    test('Parse tags', () {
      final result = nlpService.parse('任务 #工作 #紧急');
      expect(result.tags.contains('工作'), true);
      expect(result.tags.contains('紧急'), true);
    });

    test('Parse duration', () {
      final result = nlpService.parse('写代码 2小时');
      expect(result.estimatedDuration, 60);
    });

    test('Parse time', () {
      final result = nlpService.parse('下午3点 开会');
      expect(result.dueTime?.hour, 15);
    });
  });

  group('Task Model Tests', () {
    test('Create task', () {
      final task = Task(
        id: '1',
        title: '测试任务',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(task.title, '测试任务');
    });

    test('Copy with', () {
      final task = Task(
        id: '1',
        title: '原任务',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final updated = task.copyWith(title: '新任务');
      expect(updated.title, '新任务');
      expect(updated.id, '1'); // ID 不变
    });
  });

  group('Pomodoro Service Tests', () {
    test('Initial state', () {
      final service = PomodoroService();
      expect(service.state, 0);
      expect(service.currentTaskId, isNull);
    });

    test('Start pomodoro', () {
      final service = PomodoroService();
      service.start('task-1');
      expect(service.state, 1);
      expect(service.currentTaskId, 'task-1');
    });

    test('Pause and resume', () {
      final service = PomodoroService();
      service.start('task-1');
      service.pause();
      expect(service.state, 4);
      service.resume();
      expect(service.state, 1);
    });

    test('Stop pomodoro', () {
      final service = PomodoroService();
      service.start('task-1');
      service.stop();
      expect(service.state, 0);
      expect(service.currentTaskId, isNull);
    });

    test('Skip session', () {
      final service = PomodoroService();
      service.start('task-1');
      service.skip();
      expect(service.state, 2); // short break
      expect(service.completedSessions, 1);
    });
  });

  print('\n================');
  print('Total: Passed=$passed, Failed=$failed');
  print('================');
}
import 'dart:async';
import 'package:injectable/injectable.dart';

/// 番茄钟状态
enum PomodoroState {
  idle,       // 空闲
  working,    // 工作中（专注）
  shortBreak, // 短休息
  longBreak,  // 长休息
  paused,     // 暂停
}

/// 番茄钟会话类型
enum PomodoroSession {
  work,       // 工作会话
  shortBreak, // 短休息
  longBreak,  // 长休息
}

/// 番茄钟配置
class PomodoroConfig {
  final int workDuration;        // 工作时长（分钟），默认25
  final int shortBreakDuration;  // 短休息时长（分钟），默认5
  final int longBreakDuration;   // 长休息时长（分钟），默认15
  final int sessionsBeforeLongBreak; // 长休息前的会话数，默认4

  const PomodoroConfig({
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.sessionsBeforeLongBreak = 4,
  });

  PomodoroConfig copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroConfig(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }
}

/// 番茄钟会话结果
class PomodoroSessionResult {
  final String taskId;
  final PomodoroSession sessionType;
  final int duration; // 实际时长（秒）
  final bool completed;
  final DateTime startTime;
  final DateTime endTime;

  const PomodoroSessionResult({
    required this.taskId,
    required this.sessionType,
    required this.duration,
    required this.completed,
    required this.startTime,
    required this.endTime,
  });
}

/// 番茄钟服务接口
abstract class PomodoroService {
  /// 启动番茄钟
  void start(String taskId, {PomodoroSession? sessionType});

  /// 暂停番茄钟
  void pause();

  /// 恢复番茄钟
  void resume();

  /// 停止番茄钟
  void stop();

  /// 跳过当前阶段
  void skip();

  /// 获取当前剩余时间（秒）
  int get remainingSeconds;

  /// 获取当前状态
  PomodoroState get state;

  /// 获取当前会话类型
  PomodoroSession? get currentSession;

  /// 获取当前任务ID
  String? get currentTaskId;

  /// 获取已完成的会话数
  int get completedSessions;

  /// 获取配置
  PomodoroConfig get config;

  /// 设置配置
  void setConfig(PomodoroConfig config);

  /// 重置会话计数
  void resetSessionCount();

  /// 计时器流
  Stream<int> get tickStream;

  /// 状态变更流
  Stream<PomodoroState> get stateStream;

  /// 会话完成流
  Stream<PomodoroSessionResult> get sessionCompleteStream;
}

/// 番茄钟服务实现
@Injectable(as: PomodoroService)
class PomodoroServiceImpl implements PomodoroService {
  Timer? _timer;
  PomodoroConfig _config = const PomodoroConfig();
  
  PomodoroState _state = PomodoroState.idle;
  PomodoroSession? _currentSession;
  String? _currentTaskId;
  int _remainingSeconds = 0;
  int _completedSessions = 0;
  
  final _tickController = StreamController<int>.broadcast();
  final _stateController = StreamController<PomodoroState>.broadcast();
  final _sessionCompleteController = StreamController<PomodoroSessionResult>.broadcast();
  
  DateTime? _sessionStartTime;

  @override
  int get remainingSeconds => _remainingSeconds;

  @override
  PomodoroState get state => _state;

  @override
  PomodoroSession? get currentSession => _currentSession;

  @override
  String? get currentTaskId => _currentTaskId;

  @override
  int get completedSessions => _completedSessions;

  @override
  PomodoroConfig get config => _config;

  @override
  Stream<int> get tickStream => _tickController.stream;

  @override
  Stream<PomodoroState> get stateStream => _stateController.stream;

  @override
  Stream<PomodoroSessionResult> get sessionCompleteStream =>
      _sessionCompleteController.stream;

  @override
  void start(String taskId, {PomodoroSession? sessionType}) {
    _currentTaskId = taskId;
    _currentSession = sessionType ?? PomodoroSession.work;
    _sessionStartTime = DateTime.now();
    
    // 根据会话类型设置时长
    switch (_currentSession!) {
      case PomodoroSession.work:
        _remainingSeconds = _config.workDuration * 60;
        _state = PomodoroState.working;
        break;
      case PomodoroSession.shortBreak:
        _remainingSeconds = _config.shortBreakDuration * 60;
        _state = PomodoroState.shortBreak;
        break;
      case PomodoroSession.longBreak:
        _remainingSeconds = _config.longBreakDuration * 60;
        _state = PomodoroState.longBreak;
        break;
    }
    
    _stateController.add(_state);
    _startTimer();
  }

  @override
  void pause() {
    if (_state == PomodoroState.working || 
        _state == PomodoroState.shortBreak ||
        _state == PomodoroState.longBreak) {
      _timer?.cancel();
      _state = PomodoroState.paused;
      _stateController.add(_state);
    }
  }

  @override
  void resume() {
    if (_state == PomodoroState.paused) {
      if (_currentSession == PomodoroSession.work) {
        _state = PomodoroState.working;
      } else if (_currentSession == PomodoroSession.shortBreak) {
        _state = PomodoroState.shortBreak;
      } else {
        _state = PomodoroState.longBreak;
      }
      _stateController.add(_state);
      _startTimer();
    }
  }

  @override
  void stop() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    _currentSession = null;
    _currentTaskId = null;
    _remainingSeconds = 0;
    _sessionStartTime = null;
    _stateController.add(_state);
  }

  @override
  void skip() {
    _timer?.cancel();
    _completeSession(completed: false);
    _startNextSession();
  }

  @override
  void setConfig(PomodoroConfig config) {
    _config = config;
  }

  @override
  void resetSessionCount() {
    _completedSessions = 0;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _tickController.add(_remainingSeconds);
      } else {
        _timer?.cancel();
        _completeSession(completed: true);
        _startNextSession();
      }
    });
  }

  void _completeSession({required bool completed}) {
    if (_currentTaskId != null && _currentSession != null && _sessionStartTime != null) {
      final result = PomodoroSessionResult(
        taskId: _currentTaskId!,
        sessionType: _currentSession!,
        duration: _getSessionDuration(_currentSession!) * 60,
        completed: completed,
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
      );
      _sessionCompleteController.add(result);
      
      // 只有完成工作会话才增加计数
      if (_currentSession == PomodoroSession.work && completed) {
        _completedSessions++;
      }
    }
  }

  void _startNextSession() {
    if (_currentSession == PomodoroSession.work) {
      // 工作会话结束，检查是否需要长休息
      if (_completedSessions > 0 && 
          _completedSessions % _config.sessionsBeforeLongBreak == 0) {
        start(_currentTaskId!, sessionType: PomodoroSession.longBreak);
      } else {
        start(_currentTaskId!, sessionType: PomodoroSession.shortBreak);
      }
    } else {
      // 休息结束，开始新的工作会话
      start(_currentTaskId!, sessionType: PomodoroSession.work);
    }
  }

  int _getSessionDuration(PomodoroSession session) {
    switch (session) {
      case PomodoroSession.work:
        return _config.workDuration;
      case PomodoroSession.shortBreak:
        return _config.shortBreakDuration;
      case PomodoroSession.longBreak:
        return _config.longBreakDuration;
    }
  }

  void dispose() {
    _timer?.cancel();
    _tickController.close();
    _stateController.close();
    _sessionCompleteController.close();
  }
}
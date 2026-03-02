import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/services/pomodoro_service.dart';

void main() {
  late PomodoroServiceImpl pomodoroService;

  setUp(() {
    pomodoroService = PomodoroServiceImpl();
  });

  tearDown(() {
    pomodoroService.dispose();
  });

  group('PomodoroService 基本功能测试', () {
    test('初始状态为空闲', () {
      expect(pomodoroService.state, PomodoroState.idle);
      expect(pomodoroService.currentTaskId, isNull);
      expect(pomodoroService.currentSession, isNull);
      expect(pomodoroService.remainingSeconds, 0);
    });

    test('启动工作会话', () {
      pomodoroService.start('task-1');
      
      expect(pomodoroService.state, PomodoroState.working);
      expect(pomodoroService.currentTaskId, 'task-1');
      expect(pomodoroService.currentSession, PomodoroSession.work);
      expect(pomodoroService.remainingSeconds, 25 * 60);
    });

    test('暂停和恢复', () async {
      pomodoroService.start('task-1');
      expect(pomodoroService.state, PomodoroState.working);
      
      pomodoroService.pause();
      expect(pomodoroService.state, PomodoroState.paused);
      
      pomodoroService.resume();
      expect(pomodoroService.state, PomodoroState.working);
    });

    test('停止番茄钟', () {
      pomodoroService.start('task-1');
      pomodoroService.stop();
      
      expect(pomodoroService.state, PomodoroState.idle);
      expect(pomodoroService.currentTaskId, isNull);
      expect(pomodoroService.currentSession, isNull);
    });

    test('跳过当前阶段', () {
      pomodoroService.start('task-1');
      pomodoroService.skip();
      
      // 跳过后应该开始休息
      expect(
        pomodoroService.currentSession == PomodoroSession.shortBreak ||
        pomodoroService.currentSession == PomodoroSession.longBreak,
        isTrue,
      );
    });
  });

  group('PomodoroService 配置测试', () {
    test('自定义工作时长', () {
      const config = PomodoroConfig(
        workDuration: 30,
        shortBreakDuration: 5,
        longBreakDuration: 15,
      );
      pomodoroService.setConfig(config);
      
      pomodoroService.start('task-1');
      
      expect(pomodoroService.remainingSeconds, 30 * 60);
    });

    test('使用短休息会话类型', () {
      pomodoroService.start('task-1', sessionType: PomodoroSession.shortBreak);
      
      expect(pomodoroService.currentSession, PomodoroSession.shortBreak);
      expect(pomodoroService.state, PomodoroState.shortBreak);
    });

    test('使用长休息会话类型', () {
      pomodoroService.start('task-1', sessionType: PomodoroSession.longBreak);
      
      expect(pomodoroService.currentSession, PomodoroSession.longBreak);
      expect(pomodoroService.state, PomodoroState.longBreak);
    });
  });

  group('PomodoroService 会话计数', () {
    test('完成工作会话增加计数', () async {
      // 设置一个很短的工作时长用于测试
      const config = PomodoroConfig(workDuration: 1);
      pomodoroService.setConfig(config);
      
      pomodoroService.start('task-1');
      
      // 等待会话完成（1分钟）
      await Future.delayed(const Duration(minutes: 1, seconds: 5));
      
      expect(pomodoroService.completedSessions, 1);
    });

    test('重置会话计数', () async {
      const config = PomodoroConfig(workDuration: 1);
      pomodoroService.setConfig(config);
      
      pomodoroService.start('task-1');
      await Future.delayed(const Duration(minutes: 1, seconds: 5));
      
      pomodoroService.resetSessionCount();
      expect(pomodoroService.completedSessions, 0);
    });

    test('长休息前的工作会话数', () {
      const config = PomodoroConfig(sessionsBeforeLongBreak: 2);
      pomodoroService.setConfig(config);
      
      // 每次 skip 会跳到下一个会话
      pomodoroService.start('task-1', sessionType: PomodoroSession.work);
      pomodoroService.skip(); // 到短休息
      pomodoroService.skip(); // 到工作
      pomodoroService.skip(); // 到短休息
      pomodoroService.skip(); // 到工作 -> 应该是长休息
      
      expect(pomodoroService.currentSession, PomodoroSession.longBreak);
    });
  });

  group('PomodoroService 流测试', () {
    test('tickStream 发送倒计时', () async {
      // 设置短时长用于测试
      const config = PomodoroConfig(workDuration: 1);
      pomodoroService.setConfig(config);
      
      final ticks = <int>[];
      final subscription = pomodoroService.tickStream.listen((seconds) {
        ticks.add(seconds);
      });
      
      pomodoroService.start('task-1');
      
      // 等待一些 tick
      await Future.delayed(const Duration(seconds: 3));
      
      expect(ticks.isNotEmpty, isTrue);
      expect(ticks.first, 60); // 第一个 tick 应该是 60 秒
      
      subscription.cancel();
    });

    test('stateStream 发送状态变更', () async {
      final states = <PomodoroState>[];
      final subscription = pomodoroService.stateStream.listen((state) {
        states.add(state);
      });
      
      pomodoroService.start('task-1');
      await Future.delayed(const Duration(milliseconds: 100));
      pomodoroService.pause();
      await Future.delayed(const Duration(milliseconds: 100));
      pomodoroService.resume();
      await Future.delayed(const Duration(milliseconds: 100));
      pomodoroService.stop();
      
      expect(states, contains(PomodoroState.working));
      expect(states, contains(PomodoroState.paused));
      expect(states, contains(PomodoroState.idle));
      
      subscription.cancel();
    });
  });

  group('PomodoroConfig 测试', () {
    test('默认配置', () {
      const config = PomodoroConfig();
      
      expect(config.workDuration, 25);
      expect(config.shortBreakDuration, 5);
      expect(config.longBreakDuration, 15);
      expect(config.sessionsBeforeLongBreak, 4);
    });

    test('配置 copyWith', () {
      const config = PomodoroConfig();
      final newConfig = config.copyWith(workDuration: 30);
      
      expect(newConfig.workDuration, 30);
      expect(newConfig.shortBreakDuration, 5); // 未修改的保持不变
    });
  });
}
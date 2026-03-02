import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/pomodoro_service.dart';

part 'pomodoro_bloc.freezed.dart';
part 'pomodoro_event.dart';
part 'pomodoro_state.dart';

@injectable
class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroBlocState> {
  final PomodoroService _pomodoroService;

  PomodoroBloc(this._pomodoroService) : super(PomodoroBlocState.initial()) {
    on<PomodoroStarted>(_onStarted);
    on<PomodoroPaused>(_onPaused);
    on<PomodoroResumed>(_onResumed);
    on<PomodoroStopped>(_onStopped);
    on<PomodoroSkipped>(_onSkipped);
    on<PomodoroTicked>(_onTicked);
    on<PomodoroStateChanged>(_onStateChanged);
    on<PomodoroSessionCompleted>(_onSessionCompleted);
    on<PomodoroConfigUpdated>(_onConfigUpdated);

    // 监听服务状态变更
    _pomodoroService.stateStream.listen((state) {
      add(PomodoroStateChanged(state));
    });

    // 监听计时器
    _pomodoroService.tickStream.listen((seconds) {
      add(PomodoroTicked(seconds));
    });

    // 监听会话完成
    _pomodoroService.sessionCompleteStream.listen((result) {
      add(PomodoroSessionCompleted(result));
    });
  }

  void _onStarted(PomodoroStarted event, Emitter<PomodoroBlocState> emit) {
    _pomodoroService.start(event.taskId, sessionType: event.sessionType);
    emit(state.copyWith(
      taskId: event.taskId,
      sessionType: event.sessionType ?? PomodoroSession.work,
      state: PomodoroState.working,
      remainingSeconds: _pomodoroService.remainingSeconds,
    ));
  }

  void _onPaused(PomodoroPaused event, Emitter<PomodoroBlocState> emit) {
    _pomodoroService.pause();
    emit(state.copyWith(state: PomodoroState.paused));
  }

  void _onResumed(PomodoroResumed event, Emitter<PomodoroBlocState> emit) {
    _pomodoroService.resume();
    // 状态会通过 stream 更新
  }

  void _onStopped(PomodoroStopped event, Emitter<PomodoroBlocState> emit) {
    _pomodoroService.stop();
    emit(PomodoroBlocState.initial());
  }

  void _onSkipped(PomodoroSkipped event, Emitter<PomodoroBlocState> emit) {
    _pomodoroService.skip();
  }

  void _onTicked(PomodoroTicked event, Emitter<PomodoroBlocState> emit) {
    emit(state.copyWith(remainingSeconds: event.seconds));
  }

  void _onStateChanged(PomodoroStateChanged event, Emitter<PomodoroBlocState> emit) {
    emit(state.copyWith(
      state: event.state,
      sessionType: _pomodoroService.currentSession ?? state.sessionType,
    ));
  }

  void _onSessionCompleted(PomodoroSessionCompleted event, Emitter<PomodoroBlocState> emit) {
    emit(state.copyWith(
      completedSessions: _pomodoroService.completedSessions,
      lastSessionResult: event.result,
    ));
  }

  void _onConfigUpdated(PomodoroConfigUpdated event, Emitter<PomodoroBlocState> emit) {
    _pomodoroService.setConfig(event.config);
    emit(state.copyWith(config: event.config));
  }
}
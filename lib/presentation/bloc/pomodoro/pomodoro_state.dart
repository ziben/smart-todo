part of 'pomodoro_bloc.dart';

@freezed
class PomodoroBlocState with _$PomodoroBlocState {
  const factory PomodoroBlocState({
    @Default('') String taskId,
    @Default(PomodoroSession.work) PomodoroSession sessionType,
    @Default(PomodoroState.idle) PomodoroState state,
    @Default(25 * 60) int remainingSeconds,
    @Default(0) int completedSessions,
    @Default(PomodoroConfig()) PomodoroConfig config,
    PomodoroSessionResult? lastSessionResult,
  }) = _PomodoroBlocState;

  factory PomodoroBlocState.initial() => const PomodoroBlocState();
}
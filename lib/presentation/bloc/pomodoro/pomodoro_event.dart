part of 'pomodoro_bloc.dart';

abstract class PomodoroEvent {}

class PomodoroStarted extends PomodoroEvent {
  final String taskId;
  final PomodoroSession? sessionType;

  PomodoroStarted(this.taskId, {this.sessionType});
}

class PomodoroPaused extends PomodoroEvent {}

class PomodoroResumed extends PomodoroEvent {}

class PomodoroStopped extends PomodoroEvent {}

class PomodoroSkipped extends PomodoroEvent {}

class PomodoroTicked extends PomodoroEvent {
  final int seconds;
  PomodoroTicked(this.seconds);
}

class PomodoroStateChanged extends PomodoroEvent {
  final PomodoroState state;
  PomodoroStateChanged(this.state);
}

class PomodoroSessionCompleted extends PomodoroEvent {
  final PomodoroSessionResult result;
  PomodoroSessionCompleted(this.result);
}

class PomodoroConfigUpdated extends PomodoroEvent {
  final PomodoroConfig config;
  PomodoroConfigUpdated(this.config);
}
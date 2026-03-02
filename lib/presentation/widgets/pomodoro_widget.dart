import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pomodoro/pomodoro_bloc.dart';
import '../../services/pomodoro_service.dart';

/// 番茄钟 Widget
class PomodoroWidget extends StatelessWidget {
  final String taskId;
  final bool compact;

  const PomodoroWidget({
    super.key,
    required this.taskId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroBlocState>(
      builder: (context, state) {
        final isCurrentTask = state.taskId == taskId;
        
        if (!isCurrentTask) {
          // 显示开始按钮
          return _buildStartButton(context);
        }
        
        // 显示番茄钟界面
        return compact 
            ? _buildCompactView(context, state)
            : _buildFullView(context, state);
      },
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<PomodoroBloc>().add(PomodoroStarted(taskId));
      },
      icon: const Icon(Icons.timer),
      label: const Text('开始专注'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCompactView(BuildContext context, PomodoroBlocState state) {
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    final isWorking = state.state == PomodoroState.working;
    final color = isWorking ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isWorking ? Icons.local_fire_department : Icons.coffee, 
               color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          // 控制按钮
          if (state.state == PomodoroState.paused)
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 20),
              onPressed: () {
                context.read<PomodoroBloc>().add(PomodoroResumed());
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            IconButton(
              icon: const Icon(Icons.pause, size: 20),
              onPressed: () {
                context.read<PomodoroBloc>().add(PomodoroPaused());
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          IconButton(
            icon: const Icon(Icons.stop, size: 20),
            onPressed: () {
              context.read<PomodoroBloc>().add(PomodoroStopped());
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context, PomodoroBlocState state) {
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final isWorking = state.state == PomodoroState.working;
    final color = isWorking ? Colors.red : Colors.green;
    
    final sessionLabel = switch (state.sessionType) {
      PomodoroSession.work => '专注时间',
      PomodoroSession.shortBreak => '短休息',
      PomodoroSession.longBreak => '长休息',
      null => '',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sessionLabel,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // 进度环
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _getProgress(state),
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (state.completedSessions > 0)
                      Text(
                        '已完成 ${state.completedSessions} 个番茄',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.state == PomodoroState.paused)
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<PomodoroBloc>().add(PomodoroResumed());
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('继续'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<PomodoroBloc>().add(PomodoroPaused());
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<PomodoroBloc>().add(PomodoroStopped());
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getProgress(PomodoroBlocState state) {
    final totalSeconds = switch (state.sessionType) {
      PomodoroSession.work => state.config.workDuration * 60,
      PomodoroSession.shortBreak => state.config.shortBreakDuration * 60,
      PomodoroSession.longBreak => state.config.longBreakDuration * 60,
      null => 25 * 60,
    };
    return 1 - (state.remainingSeconds / totalSeconds);
  }
}

/// 番茄钟设置对话框
class PomodoroSettingsDialog extends StatefulWidget {
  const PomodoroSettingsDialog({super.key});

  @override
  State<PomodoroSettingsDialog> createState() => _PomodoroSettingsDialogState();
}

class _PomodoroSettingsDialogState extends State<PomodoroSettingsDialog> {
  late int _workDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;
  late int _sessionsBeforeLongBreak;

  @override
  void initState() {
    super.initState();
    final state = context.read<PomodoroBloc>().state;
    _workDuration = state.config.workDuration;
    _shortBreakDuration = state.config.shortBreakDuration;
    _longBreakDuration = state.config.longBreakDuration;
    _sessionsBeforeLongBreak = state.config.sessionsBeforeLongBreak;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('番茄钟设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSlider('工作时长', _workDuration, 5, 60, (v) {
            setState(() => _workDuration = v);
          }),
          _buildSlider('短休息', _shortBreakDuration, 1, 15, (v) {
            setState(() => _shortBreakDuration = v);
          }),
          _buildSlider('长休息', _longBreakDuration, 5, 30, (v) {
            setState(() => _longBreakDuration = v);
          }),
          _buildSlider('长休息间隔', _sessionsBeforeLongBreak, 2, 8, (v) {
            setState(() => _sessionsBeforeLongBreak = v);
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<PomodoroBloc>().add(
              PomodoroConfigUpdated(PomodoroConfig(
                workDuration: _workDuration,
                shortBreakDuration: _shortBreakDuration,
                longBreakDuration: _longBreakDuration,
                sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
              )),
            );
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value 分钟'),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/task_model.dart';
import '../../bloc/task/task_bloc.dart';
import '../../widgets/priority_selector.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isEditing = false;
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskPriority _selectedPriority = TaskPriority.none;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(TaskEvent.loadTask(id: widget.taskId));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _startEditing(Task task) {
    setState(() {
      _isEditing = true;
      _titleController.text = task.title;
      _descController.text = task.description ?? '';
      _selectedDate = task.dueDate;
      _selectedTime = task.dueTime != null 
          ? TimeOfDay(hour: task.dueTime!.hour, minute: task.dueTime!.minute)
          : null;
      _selectedPriority = task.priority;
    });
  }

  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) return;

    context.read<TaskBloc>().add(TaskEvent.updateTask(
      id: widget.taskId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _selectedDate,
      dueTime: _selectedTime != null 
          ? DateTime(2024, 1, 1, _selectedTime!.hour, _selectedTime!.minute)
          : null,
      priority: _selectedPriority,
    ));

    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskStateLoaded && state.selectedTask != null) {
          _task = state.selectedTask!;
          return _buildContent();
        }
        
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildContent() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑任务' : '任务详情'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _startEditing(_task),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'complete':
                    context.read<TaskBloc>().add(
                      TaskEvent.completeTask(id: _task.id),
                    );
                    break;
                  case 'delete':
                    _showDeleteConfirm();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _task.status == TaskStatus.done
                            ? Colors.grey
                            : AppTheme.successColor,
                      ),
                      const SizedBox(width: 8),
                      Text(_task.status == TaskStatus.done ? '标记未完成' : '标记完成'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('删除任务', style: TextStyle(color: Colors.red[700])),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            TextButton(
              onPressed: _saveChanges,
              child: const Text('保存'),
            ),
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('取消'),
            ),
          ],
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildDetailView(),
    );
  }

  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 优先级和状态
          Row(
            children: [
              _buildStatusChip(),
              const SizedBox(width: 8),
              _buildPriorityChip(_task.priority),
            ],
          ),
          const SizedBox(height: 16),

          // 标题
          Text(
            _task.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          // 描述
          if (_task.description != null && _task.description!.isNotEmpty) ...[
            Text(
              _task.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 24),
          ],

          // 信息卡片
          _buildInfoCard(),
          const SizedBox(height: 24),

          // 时间信息
          if (task.dueDate != null) _buildTimeSection(),

          // 标签
          if (task.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildTagsSection(),
          ],

          // 创建信息
          const SizedBox(height: 32),
          _buildCreationInfo(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final color = AppTheme.getStatusColor
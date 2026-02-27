import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/task_model.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onComplete;
  final VoidCallback? onDelete;
  final bool showCheckbox;
  final bool enableSlide;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.showCheckbox = true,
    this.enableSlide = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.done;
    final theme = Theme.of(context);

    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 复选框
            if (showCheckbox) ...[
              _buildCheckbox(isCompleted, theme),
              const SizedBox(width: 12),
            ],

            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    task.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? theme.textTheme.bodySmall?.color
                          : theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 描述（如果有）
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // 标签和日期行
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 优先级标签
                      _buildPriorityChip(),

                      // 截止日期
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 8),
                        _buildDueDate(),
                      ],

                      // 标签
                      if (task.tags.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildTags(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 添加滑动删除功能
    if (enableSlide && onDelete != null) {
      content = Dismissible(
        key: Key('task_${task.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        onDismissed: (_) => onDelete!(),
        child: content,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  Widget _buildCheckbox(bool isCompleted, ThemeData theme) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: isCompleted,
        onChanged: onComplete != null ? (v) => onComplete!(v ?? false) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: theme.dividerColor,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildPriorityChip() {
    final color = AppTheme.getPriorityColor(task.priority);
    final name = AppTheme.getPriorityName(task.priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDueDate() {
    final now = DateTime.now();
    final isOverdue = task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
    final isToday = task.dueDate!.year == now.year &&
        task.dueDate!.month == now.month &&
        task.dueDate!.day == now.day;

    Color color = Colors.grey;
    String text;

    if (isOverdue) {
      color = Colors.red;
      text = '已逾期';
    } else if (isToday) {
      color = AppTheme.primaryColor;
      text = '今天';
    } else {
      text = '${task.dueDate!.month}/${task.dueDate!.day}';
    }

    if (task.dueTime != null) {
      text += ' ${task.dueTime!.hour}:${task.dueTime!.minute.toString().padLeft(2, '0')}';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: task.tags.take(2).map((tag) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        );
      }).toList(),
    );
  }
}
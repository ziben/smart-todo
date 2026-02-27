import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/task_model.dart';

/// TaskListItem - 精致的任务列表项组件
/// 
/// 设计特点：
/// - 圆角卡片设计（参考 Things 3）
/// - 流畅的微交互动画
/// - 优先级色彩指示
/// - 滑动删除手势
class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final bool showCheckbox;
  final bool enableSlide;
  final int index;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.onArchive,
    this.showCheckbox = true,
    this.enableSlide = true,
    this.index = 0,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _completeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _completeAnimation;
  
  bool _isPressed = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.status == TaskStatus.done;
    
    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );
    
    // 完成动画控制器
    _completeController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppTheme.animationCurve,
    ));
    
    _completeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _completeController,
      curve: AppTheme.animationCurveBounce,
    ));
  }

  @override
  void didUpdateWidget(covariant TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCompleted = widget.task.status == TaskStatus.done;
    if (newCompleted != _isCompleted) {
      _isCompleted = newCompleted;
      if (_isCompleted) {
        _completeController.forward();
      } else {
        _completeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _completeController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleComplete(bool? value) {
    HapticFeedback.mediumImpact();
    final newValue = value ?? false;
    widget.onComplete?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.status == TaskStatus.done;
    final theme = Theme.of(context);
    final priorityColor = AppTheme.getPriorityColor(widget.task.priority);

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: _isPressed ? AppTheme.mediumShadow : AppTheme.lightShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 优先级指示条
                    _buildPriorityIndicator(priorityColor),
                    const SizedBox(width: 12),

                    // 复选框
                    if (widget.showCheckbox) ...[
                      _buildAnimatedCheckbox(isCompleted, theme),
                      const SizedBox(width: 12),
                    ],

                    // 内容区域
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标题
                          AnimatedBuilder(
                            animation: _completeAnimation,
                            builder: (context, child) {
                              return Text(
                                widget.task.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  decoration: isCompleted 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                  color: isCompleted
                                      ? theme.textTheme.bodySmall?.color?.withOpacity(0.5)
                                      : theme.textTheme.bodyLarge?.color,
                                  decorationColor: theme.textTheme.bodySmall?.color?.withOpacity(0.3),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),

                          // 描述（如果有）
                          if (widget.task.description != null && 
                              widget.task.description!.isNotEmpty &&
                              !isCompleted) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.task.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // 标签和日期行
                          if (!isCompleted) ...[
                            const SizedBox(height: 8),
                            _buildMetadataRow(),
                          ],
                        ],
                      ),
                    ),

                    // 右箭头（如果有onTap）
                    if (widget.onTap != null && !isCompleted) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.dividerColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // 添加滑动删除功能
    if (widget.enableSlide && widget.onDelete != null) {
      content = Dismissible(
        key: Key('task_${widget.task.id}'),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: 0.25,
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                '删除',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.heavyImpact();
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              title: const Text('删除任务'),
              content: Text('确定要删除 "${widget.task.title}" 吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          widget.onDelete!();
        },
        child: content,
      );
    }

    // 添加入场动画
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return AnimatedOpacity(
          duration: AppTheme.animationNormal,
          opacity: 1.0,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: content,
      ),
    );
  }

  Widget _buildPriorityIndicator(Color color) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildAnimatedCheckbox(bool isCompleted, ThemeData theme) {
    return GestureDetector(
      onTap: () => _handleComplete(!isCompleted),
      child: AnimatedContainer(
        duration: AppTheme.animationNormal,
        curve: AppTheme.animationCurve,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isCompleted ? AppTheme.successColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isCompleted 
                ? AppTheme.successColor 
                : theme.dividerColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: AppTheme.animationFast,
          child: isCompleted
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 优先级
        _buildPriorityChip(),

        // 截止日期
        if (widget.task.dueDate != null)
          _buildDueDateChip(),

        // 标签
        if (widget.task.tags.isNotEmpty)
          ...widget.task.tags.take(2).map((tag) => _buildTagChip(tag)),

        // 提醒
        if (widget.task.reminder != null)
          _buildIconChip(Icons.notifications_none, '提醒'),

        // 重复
        if (widget.task.recurrence != null)
          _buildIconChip(Icons.repeat, '重复'),
      ],
    );
  }

  Widget _buildPriorityChip() {
    final color = AppTheme.getPriorityColor(widget.task.priority);
    final name = AppTheme.getPriorityName(widget.task.priority);

    if (widget.task.priority == TaskPriority.none) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(
      widget.task.dueDate!.year,
      widget.task.dueDate!.month,
      widget.task.dueDate!.day,
    );

    Color color;
    String text;
    IconData icon;

    if (dateOnly.isBefore(today)) {
      color = AppTheme.errorColor;
      text = '已逾期';
      icon = Icons.warning_amber;
    } else if (dateOnly == today) {
      color = AppTheme.primaryColor;
      text = '今天';
      icon = Icons.today;
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      color = AppTheme.infoColor;
      text = '明天';
      icon = Icons.event;
    } else {
      color = AppTheme.lightTextSecondary;
      text = '${widget.task.dueDate!.month}/${widget.task.dueDate!.day}';
      icon = Icons.calendar_today;
    }

    if (widget.task.dueTime != null) {
      final hour = widget.task.dueTime!.hour.toString().padLeft(2, '0');
      final minute = widget.task.dueTime!.minute.toString().padLeft(2, '0');
      text += ' $hour:$minute';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.12),
          width: 0.5,
        ),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColor.withOpacity(0.8),
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildIconChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.lightTextTertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 12,
        color: AppTheme.lightTextSecondary,
      ),
    );
  }
}
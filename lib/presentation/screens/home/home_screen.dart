import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/task_model.dart';
import '../../bloc/task/task_bloc.dart';
import '../../widgets/task_list_item.dart';
import '../../widgets/nlp_input_field.dart';
import '../task/task_detail_screen.dart';
import '../calendar/calendar_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  
  final List<String> _tabs = ['今天', '待办', '日历', '设置'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildTodoTab(),
          const CalendarScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex != 3 ? _buildFAB() : null,
    );
  }

  // ============ 今天标签页 ============
  Widget _buildTodayTab() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            // 顶部标题栏
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('今天'),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                  ),
                  child: _buildTodayStats(state),
                ),
              ),
            ),
            
            // 快速输入框
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: NlpInputField(
                  onSubmit: (result) {
                    context.read<TaskBloc>().add(
                      TaskEvent.createTask(
                        title: result.title,
                        description: result.rawText,
                        priority: result.priority,
                        dueDate: result.dueDate,
                        dueTime: result.dueTime,
                        projectId: result.projectId,
                        tags: result.tags,
                        estimatedDuration: result.estimatedDuration,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 任务列表
            _buildTaskList(state),
          ],
        );
      },
    );
  }

  Widget _buildTodayStats(TaskState state) {
    if (state is! TaskStateLoaded) {
      return const SizedBox.shrink();
    }
    
    final completed = state.tasks.where((t) => t.status == TaskStatus.done).length;
    final total = state.tasks.length;
    final percentage = total > 0 ? (completed / total * 100).toInt() : 0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '已完成 $completed / $total 个任务',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ============ 待办标签页 ============
  Widget _buildTodoTab() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('待办'),
              floating: true,
              snap: true,
            ),
            
            // 筛选栏
            SliverToBoxAdapter(
              child: _buildFilterBar(state),
            ),
            
            // 任务列表
            _buildTaskList(state),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(TaskState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 优先级筛选
          _buildFilterChip('优先级', () {
            _showPriorityFilter(context);
          }),
          const SizedBox(width: 8),
          
          // 项目筛选
          _buildFilterChip('项目', () {
            _showProjectFilter(context);
          }),
          const SizedBox(width: 8),
          
          // 标签筛选
          _buildFilterChip('标签', () {
            _showTagFilter(context);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  // ============ 任务列表 ============
  Widget _buildTaskList(TaskState state) {
    if (state is TaskStateLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is TaskStateError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(state.message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<TaskBloc>().add(const TaskEvent.loadTasks());
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is TaskStateLoaded) {
      final tasks = state.filteredTasks;
      
      if (tasks.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '没有任务',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角的按钮添加任务',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final task = tasks[index];
            return TaskListItem(
              task: task,
              onTap: () => _onTaskTap(context, task),
              onComplete: (completed) => _onTaskComplete(context, task, completed),
              onDelete: () => _onTaskDelete(context, task),
            );
          },
          childCount: tasks.length,
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  // ============ 底部导航 ============
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.today, '今天', 0),
              _buildNavItem(Icons.check_circle_outline, '待办', 1),
              _buildNavItem(Icons.calendar_today, '日历', 2),
              _buildNavItem(Icons.settings_outlined, '设置', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 浮动按钮 ============
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddTaskDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('任务'),
      elevation: 4,
    );
  }

  // ============ 事件处理 ============
  void _onTaskTap(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  void _onTaskComplete(BuildContext context, Task task, bool completed) {
    if (completed) {
      context.read<TaskBloc>().add(TaskEvent.completeTask(id: task.id));
    } else {
      // 取消完成状态
      context.read<TaskBloc>().add(
        TaskEvent.updateTask(
          id: task.id,
          status: TaskStatus.todo,
        ),
      );
    }
  }

  void _onTaskDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除"${task.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskBloc>().add(TaskEvent.deleteTask(id: task.id));
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ============ 对话框 ============
  void _showAddTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: NlpInputField(
                onSubmit: (result) {
                  context.read<TaskBloc>().add(
                    TaskEvent.createTask(
                      title: result.title,
                      description: result.rawText,
                      priority: result.priority,
                      dueDate: result.dueDate,
                      dueTime: result.dueTime,
                      projectId: result.projectId,
                      tags: result.tags,
                      estimatedDuration: result.estimatedDuration,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityFilter(BuildContext context) {
    // 实现优先级筛选
  }

  void _showProjectFilter(BuildContext context) {
    // 实现项目筛选
  }

  void _showTagFilter(BuildContext context) {
    // 实现标签筛选
  }
}
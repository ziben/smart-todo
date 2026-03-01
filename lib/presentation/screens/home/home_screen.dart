import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../analytics/analytics_screen.dart';

/// HomeScreen - 智能清单应用首页
/// 
/// 设计特点：
/// - 优雅的渐变头部
/// - 流畅的页面切换动画
/// - 精致的底部导航栏
/// - 智能的统计展示
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabController;
  late AnimationController _pageController;
  int _currentIndex = 0;

  final List<String> _tabs = ['今天', '待办', '统计', '设置'];
  final List<IconData> _tabIcons = [
    Icons.wb_sunny_outlined,
    Icons.check_circle_outline,
    Icons.analytics_outlined,
    Icons.settings_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fabController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );
    _pageController = AnimationController(
      duration: AppTheme.animationSlow,
      vsync: this,
    );

    _tabController.addListener(_onTabChanged);
    _fabController.forward();
    _pageController.forward();
  }

  void _onTabChanged() {
    if (_tabController.index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = _tabController.index;
      });

      // FAB 动画
      if (_currentIndex == 3) {
        _fabController.reverse();
      } else {
        _fabController.forward();
      }

      // 页面切换动画
      _pageController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildTodayTab(),
          _buildTodoTab(),
          const AnalyticsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex != 3
          ? AnimatedBuilder(
              animation: _fabController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fabController,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _fabController,
                      curve: Curves.elasticOut,
                    ),
                    child: FloatingActionButton.extended(
                      onPressed: _showAddTaskSheet,
                      backgroundColor: AppTheme.primaryColor,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        '添加任务',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  /// 底部导航栏
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              final isSelected = _currentIndex == index;
              return _buildNavItem(
                icon: _tabIcons[index],
                label: _tabs[index],
                isSelected: isSelected,
                onTap: () {
                  _tabController.animateTo(index);
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 今日任务 Tab
  Widget _buildTodayTab() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskStateLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is TaskStateLoaded) {
          final todayTasks = state.tasks.where((task) {
            if (task.dueDate == null) return false;
            final now = DateTime.now();
            final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
            final today = DateTime(now.year, now.month, now.day);
            return due.isAtSameMomentAs(today);
          }).toList();

          return CustomScrollView(
            slivers: [
              // 头部统计
              SliverToBoxAdapter(
                child: _buildTodayHeader(state),
              ),
              
              // 任务列表
              if (todayTasks.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = todayTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskListItem(
                            task: task,
                            onTap: () => _navigateToTaskDetail(task),
                            onComplete: () => _completeTask(task),
                          ),
                        );
                      },
                      childCount: todayTasks.length,
                    ),
                  ),
                ),
            ],
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildTodayHeader(TaskStateLoaded state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayTasks = state.tasks.where((task) {
      if (task.dueDate == null) return false;
      final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return due.isAtSameMomentAs(today);
    }).toList();
    
    final completed = todayTasks.where((t) => t.status == TaskStatus.done).length;
    final pending = todayTasks.length - completed;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今天',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${now.month}月${now.day}日 ${_getWeekday(now.weekday)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${todayTasks.length}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('已完成', completed.toString(), Icons.check_circle),
              const SizedBox(width: 24),
              _buildStatItem('待完成', pending.toString(), Icons.pending),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 待办 Tab
  Widget _buildTodoTab() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskStateLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TaskStateLoaded) {
          final todoTasks = state.tasks
              .where((t) => t.status == TaskStatus.todo)
              .toList();

          if (todoTasks.isEmpty) {
            return _buildEmptyState(message: '暂无待办任务');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todoTasks.length,
            itemBuilder: (context, index) {
              final task = todoTasks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskListItem(
                  task: task,
                  onTap: () => _navigateToTaskDetail(task),
                  onComplete: () => _completeTask(task),
                ),
              );
            },
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message ?? '暂无任务',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加新任务',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 添加任务底部Sheet
  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 拖动手柄
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '添加任务',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // NLP 输入框
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: NlpInputField(
                  onSubmit: (result) {
                    _createTaskFromNlp(result);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createTaskFromNlp(NlpParseResult result) {
    if (result.title.isEmpty) return;

    context.read<TaskBloc>().add(TaskEvent.createTask(
      title: result.title,
      description: result.description,
      priority: result.priority,
      dueDate: result.dueDate,
      dueTime: result.dueTime,
      tags: result.tags,
      estimatedDuration: result.estimatedDuration,
    ));
  }

  void _navigateToTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  void _completeTask(Task task) {
    context.read<TaskBloc>().add(TaskEvent.completeTask(id: task.id));
  }

  String _getWeekday(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
}
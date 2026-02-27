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

  final List<String> _tabs = ['今天', '待办', '日历', '设置'];
  final List<IconData> _tabIcons = [
    Icons.wb_sunny_outlined,
    Icons.check_circle_outline,
    Icons.calendar_today_outlined,
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
          const CalendarScreen(),
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
                    scale: CurvedAnimation
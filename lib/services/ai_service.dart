import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import '../domain/models/task_model.dart';

/// AI 任务拆解结果
class TaskBreakdownResult {
  final String originalTask;
  final List<SubTask> subtasks;
  final String? estimatedDuration;
  final String? suggestedOrder;
  final List<String>? prerequisites;

  const TaskBreakdownResult({
    required this.originalTask,
    required this.subtasks,
    this.estimatedDuration,
    this.suggestedOrder,
    this.prerequisites,
  });
}

/// 子任务
class SubTask {
  final String title;
  final String? description;
  final TaskPriority priority;
  final Duration? estimatedDuration;
  final int order;
  final List<String>? dependencies;

  const SubTask({
    required this.title,
    this.description,
    this.priority = TaskPriority.none,
    this.estimatedDuration,
    this.order = 0,
    this.dependencies,
  });
}

/// AI 服务接口
abstract class AiService {
  /// 智能任务拆解
  Future<TaskBreakdownResult> breakdownTask(String taskDescription);
  
  /// 智能时间推荐
  Future<DateTime?> suggestBestTime(String taskDescription, List<DateTime> availableSlots);
  
  /// 任务优先级建议
  Future<TaskPriority> suggestPriority(String taskDescription, DateTime? dueDate);
  
  /// 批量任务优化排序
  Future<List<String>> optimizeTaskOrder(List<String> tasks);
}

/// AI 服务实现（使用模拟数据，可替换为真实 API）
@Injectable(as: AiService)
class AiServiceImpl implements AiService {
  final http.Client _httpClient;
  
  // 可以配置为使用 OpenAI、Claude 或其他 AI API
  static const String _apiKey = ''; // 从环境变量或配置读取
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  AiServiceImpl(this._httpClient);

  @override
  Future<TaskBreakdownResult> breakdownTask(String taskDescription) async {
    // 模拟 AI 解析，实际使用时调用真实 API
    await Future.delayed(const Duration(milliseconds: 800));

    // 基于关键词的智能拆解
    final subtasks = _generateSubtasks(taskDescription);
    
    return TaskBreakdownResult(
      originalTask: taskDescription,
      subtasks: subtasks,
      estimatedDuration: _estimateTotalDuration(subtasks),
      suggestedOrder: '按依赖关系顺序执行',
    );
  }

  List<SubTask> _generateSubtasks(String task) {
    final lower = task.toLowerCase();
    final subtasks = <SubTask>[];

    // 根据任务类型智能生成子任务
    if (lower.contains('发布会') || lower.contains('活动')) {
      subtasks.addAll([
        const SubTask(
          title: '确定场地和日期',
          description: '联系场地供应商，确认档期和价格',
          priority: TaskPriority.high,
          estimatedDuration: Duration(days: 2),
          order: 1,
        ),
        const SubTask(
          title: '邀请嘉宾和媒体',
          description: '发送邀请函，跟进确认出席情况',
          priority: TaskPriority.high,
          estimatedDuration: Duration(days: 5),
          order: 2,
          dependencies: ['确定场地和日期'],
        ),
        const SubTask(
          title: '准备演讲PPT',
          description: '制作 keynote 和演示材料',
          priority: TaskPriority.medium,
          estimatedDuration: Duration(days: 3),
          order: 3,
        ),
        const SubTask(
          title: '彩排和现场布置',
          description: '设备调试、走位彩排、物料布置',
          priority: TaskPriority.high,
          estimatedDuration: Duration(hours: 4),
          order: 4,
        ),
      ]);
    } else if (lower.contains('设计') || lower.contains('ui')) {
      subtasks.addAll([
        const SubTask(
          title: '需求分析和调研',
          description: '理解需求，参考竞品分析',
          priority: TaskPriority.high,
          estimatedDuration: Duration(days: 1),
          order: 1,
        ),
        const SubTask(
          title: '草图和线框图',
          description: '绘制低保真原型',
          priority: TaskPriority.medium,
          estimatedDuration: Duration(days: 2),
          order: 2,
        ),
        const SubTask(
          title: '视觉设计',
          description: '高保真设计稿，标注规范',
          priority: TaskPriority.high,
          estimatedDuration: Duration(days: 3),
          order: 3,
        ),
        const SubTask(
          title: '设计评审和修改',
          description: '收集反馈，迭代优化',
          priority: TaskPriority.medium,
          estimatedDuration: Duration(days: 1),
          order: 4,
        ),
      ]);
    } else {
      // 通用任务拆解
      subtasks.addAll([
        const SubTask(
          title: '明确任务目标和范围',
          description: '理解需求，确定交付标准',
          priority: TaskPriority.high,
          estimatedDuration: Duration(hours: 1),
          order: 1,
        ),
        const SubTask(
          title: '制定执行计划',
          description: '分解步骤，预估时间',
          priority: TaskPriority.medium,
          estimatedDuration: Duration(hours: 1),
          order: 2,
        ),
        const SubTask(
          title: '执行核心工作',
          description: '按计划推进，记录进展',
          priority: TaskPriority.high,
          estimatedDuration: Duration(hours: 4),
          order: 3,
        ),
        const SubTask(
          title: '检查与交付',
          description: '复核质量，提交成果',
          priority: TaskPriority.high,
          estimatedDuration: Duration(hours: 1),
          order: 4,
        ),
      ]);
    }

    return subtasks;
  }

  String? _estimateTotalDuration(List<SubTask> subtasks) {
    var totalMinutes = 0;
    for (final subtask in subtasks) {
      if (subtask.estimatedDuration != null) {
        totalMinutes += subtask.estimatedDuration!.inMinutes;
      }
    }

    if (totalMinutes == 0) return null;

    final days = totalMinutes ~/ (8 * 60); // 按8小时工作日计算
    final hours = (totalMinutes % (8 * 60)) ~/ 60;

    if (days > 0 && hours > 0) {
      return '约 ${days}天 ${hours}小时';
    } else if (days > 0) {
      return '约 ${days}天';
    } else if (hours > 0) {
      return '约 ${hours}小时';
    } else {
      return '约 ${totalMinutes}分钟';
    }
  }

  @override
  Future<DateTime?> suggestBestTime(String taskDescription, List<DateTime> availableSlots) async {
    // 模拟 AI 分析
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (availableSlots.isEmpty) return null;
    
    // 根据任务类型推荐最佳时间
    final lower = taskDescription.toLowerCase();
    
    // 创造性工作推荐上午
    if (lower.contains('设计') || lower.contains('写作') || lower.contains('创意')) {
      return availableSlots.firstWhere(
        (slot) => slot.hour >= 9 && slot.hour <= 11,
        orElse: () => availableSlots.first,
      );
    }
    
    // 会议或沟通推荐下午
    if (lower.contains('会议') || lower.contains('讨论') || lower.contains('汇报')) {
      return availableSlots.firstWhere(
        (slot) => slot.hour >= 14 && slot.hour <= 17,
        orElse: () => availableSlots.first,
      );
    }
    
    // 默认返回第一个可用时段
    return availableSlots.first;
  }

  @override
  Future<TaskPriority> suggestPriority(String taskDescription, DateTime? dueDate) async {
    final lower = taskDescription.toLowerCase();
    
    // 紧急关键词
    final urgentKeywords = ['紧急', '立刻', '马上', 'asap', 'p0', 'critical'];
    if (urgentKeywords.any((k) => lower.contains(k))) {
      return TaskPriority.urgent;
    }
    
    // 高优先级关键词
    final highKeywords = ['重要', 'p1', '高优先级', '尽快', 'high'];
    if (highKeywords.any((k) => lower.contains(k))) {
      return TaskPriority.high;
    }
    
    // 根据截止日期判断
    if (dueDate != null) {
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
      if (daysUntilDue <= 1) return TaskPriority.high;
      if (daysUntilDue <= 3) return TaskPriority.medium;
    }
    
    // 默认
    return TaskPriority.none;
  }

  @override
  Future<List<String>> optimizeTaskOrder(List<String> tasks) async {
    // 模拟优化排序
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 简单的启发式排序：
    // 1. 包含截止日期或时间的任务优先
    // 2. 包含"紧急"关键词的任务优先
    // 3. 较短的任务优先（快速获胜）
    
    final scored = tasks.map((task) {
      var score = 0;
      final lower = task.toLowerCase();
      
      // 紧急度
      if (lower.contains('紧急') || lower.contains('p0')) score += 100;
      if (lower.contains('明天') || lower.contains('今天')) score += 50;
      
      // 时间敏感度
      if (RegExp(r'\d{1,2}月\d{1,2}日').hasMatch(task)) score += 30;
      if (RegExp(r'\d{1,2}[:点]').hasMatch(task)) score += 20;
      
      // 长度惩罚（短任务优先）
      score -= task.length ~/ 10;
      
      return MapEntry(task, score);
    }).toList();
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }
}
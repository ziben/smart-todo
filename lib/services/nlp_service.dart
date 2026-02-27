import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:injectable/injectable.dart';
import '../core/constants/app_constants.dart';
import '../domain/models/task_model.dart';

/// NLP 解析结果
class NlpParseResult {
  final String title;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final String? projectId;
  final List<String> tags;
  final int? estimatedDuration;
  final String? rawText;

  const NlpParseResult({
    required this.title,
    this.priority = TaskPriority.none,
    this.dueDate,
    this.dueTime,
    this.projectId,
    this.tags = const [],
    this.estimatedDuration,
    this.rawText,
  });

  NlpParseResult copyWith({
    String? title,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? dueTime,
    String? projectId,
    List<String>? tags,
    int? estimatedDuration,
    String? rawText,
  }) {
    return NlpParseResult(
      title: title ?? this.title,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      projectId: projectId ?? this.projectId,
      tags: tags ?? this.tags,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  String toString() {
    return 'NlpParseResult(title: $title, priority: $priority, dueDate: $dueDate, dueTime: $dueTime)';
  }
}

/// NLP 服务接口
abstract class NlpService {
  /// 解析自然语言输入
  NlpParseResult parse(String input);
  
  /// 批量解析
  List<NlpParseResult> parseBatch(List<String> inputs);
  
  /// 验证解析结果
  bool validate(NlpParseResult result);
  
  /// 提取关键词
  List<String> extractKeywords(String input);
  
  /// 检测语言
  String detectLanguage(String input);
}

/// NLP 服务实现
@Injectable(as: NlpService)
class NlpServiceImpl implements NlpService {
  final DateTime _now = DateTime.now();
  
  @override
  NlpParseResult parse(String input) {
    if (input.trim().isEmpty) {
      return NlpParseResult(title: '', rawText: input);
    }

    String remainingText = input.trim();
    
    // 1. 解析优先级
    final priority = _extractPriority(remainingText);
    remainingText = _removePriorityKeywords(remainingText);
    
    // 2. 解析日期和时间
    final dateResult = _extractDateTime(remainingText);
    remainingText = dateResult.remainingText;
    
    // 3. 解析项目/清单
    final projectResult = _extractProject(remainingText);
    remainingText = projectResult.remainingText;
    
    // 4. 解析标签
    final tags = _extractTags(remainingText);
    remainingText = _removeTags(remainingText);
    
    // 5. 解析预计时长
    final duration = _extractDuration(remainingText);
    remainingText = _removeDurationKeywords(remainingText, duration);
    
    // 6. 清理剩余文本作为标题
    final title = _cleanTitle(remainingText);

    return NlpParseResult(
      title: title.isEmpty ? input : title,
      priority: priority,
      dueDate: dateResult.date,
      dueTime: dateResult.time,
      projectId: projectResult.projectId,
      tags: tags,
      estimatedDuration: duration,
      rawText: input,
    );
  }

  @override
  List<NlpParseResult> parseBatch(List<String> inputs) {
    return inputs.map((input) => parse(input)).toList();
  }

  @override
  bool validate(NlpParseResult result) {
    return result.title.trim().isNotEmpty;
  }

  @override
  List<String> extractKeywords(String input) {
    final keywords = <String>[];
    
    // 提取日期相关
    final datePatterns = [
      r'今天|明天|后天|大后天',
      r'周一|周二|周三|周四|周五|周六|周日',
      r'\d{1,2}月\d{1,2}日',
      r'\d{4}[-/]\d{1,2}[-/]\d{1,2}',
    ];
    
    for (final pattern in datePatterns) {
      final matches = RegExp(pattern).allMatches(input);
      for (final match in matches) {
        keywords.add(match.group(0)!);
      }
    }
    
    // 提取时间相关
    final timeMatches = RegExp(r'(\d{1,2})[:点](\d{0,2})?').allMatches(input);
    for (final match in timeMatches) {
      keywords.add(match.group(0)!);
    }
    
    // 提取标签（#tag 或 @mention）
    final tagMatches = RegExp(r'[#@](\w+)').allMatches(input);
    for (final match in tagMatches) {
      keywords.add(match.group(0)!);
    }
    
    return keywords.toSet().toList(); // 去重
  }

  @override
  String detectLanguage(String input) {
    // 简单检测：如果包含中文字符则认为是中文
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    final chineseMatches = chineseRegex.allMatches(input).length;
    
    if (chineseMatches > input.length * 0.1) {
      return 'zh';
    }
    
    // 检测日文
    final japaneseRegex = RegExp(r'[\u3040-\u309f\u30a0-\u30ff]');
    if (japaneseRegex.hasMatch(input)) {
      return 'ja';
    }
    
    // 检测韩文
    final koreanRegex = RegExp(r'[\uac00-\ud7af]');
    if (koreanRegex.hasMatch(input)) {
      return 'ko';
    }
    
    return 'en'; // 默认为英文
  }

  // ============ 私有辅助方法 ============

  TaskPriority _extractPriority(String text) {
    final lowerText = text.toLowerCase();
    
    // 最高优先级
    if (RegExp(r'(p0|紧急|最优先|critical|urgent|立刻|马上|立即|asap)').hasMatch(lowerText)) {
      return TaskPriority.urgent;
    }
    
    // 高优先级
    if (RegExp(r'(p1|高优先级|重要|high|important)').hasMatch(lowerText)) {
      return TaskPriority.high;
    }
    
    // 中优先级
    if (RegExp(r'(p2|中优先级|普通|medium|normal)').hasMatch(lowerText)) {
      return TaskPriority.medium;
    }
    
    // 低优先级
    if (RegExp(r'(p3|低优先级|不急|low|later|someday)').hasMatch(lowerText)) {
      return TaskPriority.low;
    }
    
    return TaskPriority.none;
  }

  String _removePriorityKeywords(String text) {
    return text
      .replaceAll(RegExp(r'(p0|p1|p2|p3)'), '')
      .replaceAll(RegExp(r'(紧急|最优先|高优先级|中优先级|低优先级|重要|普通|不急)'), '')
      .replaceAll(RegExp(r'(critical|urgent|high|medium|low|important|normal)'), '')
      .trim();
  }

  _DateTimeResult _extractDateTime(String text) {
    DateTime? date;
    DateTime? time;
    String remainingText = text;
    
    final now = DateTime.now();
    
    // 解析 "今天"
    if (remainingText.contains('今天')) {
      date = DateTime(now.year, now.month, now.day);
      remainingText = remainingText.replaceAll('今天', '');
    }
    
    // 解析 "明天"
    else if (remainingText.contains('明天')) {
      final tomorrow = now.add(const Duration(days: 1));
      date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      remainingText = remainingText.replaceAll('明天', '');
    }
    
    // 解析 "后天"
    else if (remainingText.contains('后天')) {
      final dayAfter = now.add(const Duration(days: 2));
      date = DateTime(dayAfter.year, dayAfter.month, dayAfter.day);
      remainingText = remainingText.replaceAll('后天', '');
    }
    
    // 解析 "大后天"
    else if (remainingText.contains('大后天')) {
      final threeDaysLater = now.add(const Duration(days: 3));
      date = DateTime(threeDaysLater.year, threeDaysLater.month, threeDaysLater.day);
      remainingText = remainingText.replaceAll('大后天', '');
    }
    
    // 解析 "下周X"
    final weekdayMatch = RegExp(r'下?周([一二三四五六日])').firstMatch(remainingText);
    if (weekdayMatch != null) {
      final weekdayChar = weekdayMatch.group(1);
      final targetWeekday = _chineseWeekdayToNumber(weekdayChar!);
      if (targetWeekday != null) {
        final isNextWeek = remainingText.contains('下周');
        date = _getNextWeekday(targetWeekday, isNextWeek: isNextWeek);
        remainingText = remainingText.replaceAll(weekdayMatch.group(0)!, '');
      }
    }
    
    // 解析具体时间 (X点Y分 或 X:Y)
    final timeMatch = RegExp(r'(\d{1,2})[:点](\d{0,2})?').firstMatch(remainingText);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2)?.isNotEmpty == true 
          ? int.parse(timeMatch.group(2)!) 
          : 0;
      
      // 处理 "下午X点" 等情况
      if (remainingText.contains('下午') || remainingText.contains('晚上')) {
        if (hour < 12) hour += 12;
      }
      
      time = DateTime(now.year, now.month, now.day, hour, minute);
      remainingText = remainingText.replaceAll(timeMatch.group(0)!, '');
    }
    
    // 解析 "早上/上午/中午/下午/晚上" 时间段
    if (time == null) {
      if (remainingText.contains('早上') || remainingText.contains('早晨')) {
        time = DateTime(now.year, now.month, now.day, 8, 0);
        remainingText = remainingText.replaceAll(RegExp(r'早上|早晨'), '');
      } else if (remainingText.contains('上午')) {
        time = DateTime(now.year, now.month, now.day, 10, 0);
        remainingText = remainingText.replaceAll('上午', '');
      } else if (remainingText.contains('中午')) {
        time = DateTime(now.year, now.month, now.day, 12, 0);
        remainingText = remainingText.replaceAll('中午', '');
      } else if (remainingText.contains('下午')) {
        time = DateTime(now.year, now.month, now.day, 14, 0);
        remainingText = remainingText.replaceAll('下午', '');
      } else if (remainingText.contains('傍晚')) {
        time = DateTime(now.year, now.month, now.day, 17, 0);
        remainingText = remainingText.replaceAll('傍晚', '');
      } else if (remainingText.contains('晚上')) {
        time = DateTime(now.year, now.month, now.day, 19, 0);
        remainingText = remainingText.replaceAll('晚上', '');
      } else if (remainingText.contains('深夜')) {
        time = DateTime(now.year, now.month, now.day, 23, 0);
        remainingText = remainingText.replaceAll('深夜', '');
      }
    }
    
    // 如果解析到了时间但没有日期，默认使用今天
    if (time != null && date == null) {
      date = DateTime(now.year, now.month, now.day);
    }
    
    return _DateTimeResult(
      date: date,
      time: time,
      remainingText: remainingText.trim(),
    );
  }

  int? _chineseWeekdayToNumber(String weekday) {
    const map = {
      '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7,
    };
    return map[weekday];
  }

  DateTime _getNextWeekday(int targetWeekday, {bool isNextWeek = false}) {
    final now = DateTime.now();
    int currentWeekday = now.weekday; // 1-7 (Monday-Sunday)
    
    int daysToAdd;
    if (isNextWeek) {
      daysToAdd = (7 - currentWeekday) + targetWeekday;
    } else {
      if (targetWeekday >= currentWeekday) {
        daysToAdd = targetWeekday - currentWeekday;
      } else {
        daysToAdd = (7 - currentWeekday) + targetWeekday;
      }
    }
    
    return now.add(Duration(days: daysToAdd));
  }

  _ProjectResult _extractProject(String text) {
    // 匹配 "在[项目名]中" 或 "@[项目名]" 或 "#[项目名]"
    final patterns = [
      RegExp(r'在["\']?([^"\']+)["\']?中'),
      RegExp(r'@([^\s]+)'),
      RegExp(r'#([^\s]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final projectName = match.group(1)!.trim();
        // 这里应该通过 projectName 查找 projectId
        // 暂时返回 null，实际应用需要查询数据库
        return _ProjectResult(
          projectId: null, // TODO: 通过名称查找 projectId
          remainingText: text.replaceFirst(match.group(0)!, '').trim(),
        );
      }
    }
    
    return _ProjectResult(
      projectId: null,
      remainingText: text,
    );
  }

  List<String> _extractTags(String text) {
    final tags = <String>[];
    
    // 匹配 #tag 格式
    final tagMatches = RegExp(r'#([^\s#]+)').allMatches(text);
    for (final match in tagMatches) {
      tags.add(match.group(1)!);
    }
    
    // 匹配 "标签：[标签名]" 格式
    final labelMatches = RegExp(r'标签[：:]\s*([^\s,，]+)').allMatches(text);
    for (final match in labelMatches) {
      tags.add(match.group(1)!);
    }
    
    return tags.toSet().toList(); // 去重
  }

  String _removeTags(String text) {
    return text
      .replaceAll(RegExp(r'#[^\s#]+'), '')
      .replaceAll(RegExp(r'标签[：:]\s*[^\s,，]+'), '')
      .trim();
  }

  int? _extractDuration(String text) {
    // 匹配 "X小时Y分钟" 或 "XhYm" 或 "X个小时"
    final hourMinuteMatch = RegExp(r'(\d+)\s*[个小]?时[钟]?\s*(\d+)?\s*分[钟]?').firstMatch(text);
    if (hourMinuteMatch != null) {
      final hours = int.parse(hourMinuteMatch.group(1)!);
      final minutes = hourMinuteMatch.group(2) != null 
          ? int.parse(hourMinuteMatch.group(2)!) 
          : 0;
      return hours * 60 + minutes;
    }
    
    // 匹配 "X分钟" 或 "Xmin"
    final minuteMatch = RegExp(r'(\d+)\s*分[钟]?').firstMatch(text);
    if (minuteMatch != null) {
      return int.parse(minuteMatch.group(1)!);
    }
    
    // 匹配 "X小时" 或 "Xh"
    final hourMatch = RegExp(r'(\d+)\s*[个小]?时[钟]?').firstMatch(text);
    if (hourMatch != null) {
      return int.parse(hourMatch.group(1)!) * 60;
    }
    
    return null;
  }

  String _removeDurationKeywords(String text, int? duration) {
    if (duration == null) return text;
    
    return text
      .replaceAll(RegExp(r'\d+\s*[个小]?时[钟]?\s*\d*\s*分[钟]?'), '')
      .replaceAll(RegExp(r'\d+\s*分[钟]?'), '')
      .replaceAll(RegExp(r'\d+\s*[个小]?时[钟]?'), '')
      .trim();
  }

  String _cleanTitle(String text) {
    return text
      .replaceAll(RegExp(r'\s+'), ' ')  // 多个空格合并
      .replaceAll(RegExp(r'^[\s,，]+'), '')  // 去除开头的空格和逗号
      .replaceAll(RegExp(r'[\s,，]+$'), '')  // 去除结尾的空格和逗号
      .trim();
  }
}

// 辅助类
class _DateTimeResult {
  final DateTime? date;
  final DateTime? time;
  final String remainingText;

  _DateTimeResult({
    this.date,
    this.time,
    required this.remainingText,
  });
}

class _ProjectResult {
  final String? projectId;
  final String remainingText;

  _ProjectResult({
    this.projectId,
    required this.remainingText,
  });
}
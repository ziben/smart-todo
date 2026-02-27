class AppConstants {
  // App Info
  static const String appName = '智能清单';
  static const String appNameEn = 'Smart Todo';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'smart_todo.db';
  static const int databaseVersion = 1;
  
  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String userBox = 'user';
  static const String cacheBox = 'cache';
  
  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration maxSyncRetry = Duration(hours: 24);
  
  // Notification
  static const String notificationChannelId = 'smart_todo_channel';
  static const String notificationChannelName = '任务提醒';
  static const String notificationChannelDesc = '任务截止日期和提醒通知';
  
  // NLP
  static const List<String> dateKeywords = [
    '今天', '明天', '后天', '大后天',
    '周一', '周二', '周三', '周四', '周五', '周六', '周日',
    '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日',
    '下周', '下月', '明年',
  ];
  
  static const List<String> priorityKeywords = [
    '紧急', '重要', '高优先级', 'p1', 'p0',
    '普通', '一般', '中优先级', 'p2',
    '低优先级', '不急', 'p3',
  ];
  
  static const List<String> timeKeywords = [
    '早上', '上午', '中午', '下午', '傍晚', '晚上', '深夜',
    '凌晨', '早晨', '午后', '黄昏', '午夜',
  ];
  
  // Default Settings
  static const int defaultTaskLimit = 50;
  static const int defaultPageSize = 20;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration defaultSnackbarDuration = Duration(seconds: 3);
  
  // Feature Flags
  static const bool enableNlp = true;
  static const bool enableSync = true;
  static const bool enableNotifications = true;
  static const bool enableLocationReminders = true;
  static const bool enableAiSuggestions = false; // Future feature
  
  // Debug
  static const bool enableLogging = true;
  static const bool enableCrashReporting = true;
}
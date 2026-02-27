import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:injectable/injectable.dart';
import '../core/constants/app_constants.dart';
import '../domain/models/task_model.dart';

/// 通知服务接口
abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleTaskReminder(Task task);
  Future<void> cancelTaskReminder(String taskId);
  Future<void> cancelAllReminders();
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  });
  Future<void> scheduleRepeatingReminder({
    required String id,
    required String title,
    required String body,
    required DateTime startTime,
    required Duration interval,
  });
}

/// 通知服务实现
@Injectable(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化时区数据
    tz_data.initializeTimeZones();

    // Android 初始化设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 初始化设置
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 执行初始化
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // 创建通知渠道（Android）
    await _createNotificationChannel();

    _isInitialized = true;
  }

  /// 创建 Android 通知渠道
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 处理通知点击事件
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // 解析 payload 并导航到相应页面
      final data = jsonDecode(payload);
      final taskId = data['taskId'] as String?;
      if (taskId != null) {
        // 导航到任务详情页
      }
    }
  }

  @override
  Future<void> scheduleTaskReminder(Task task) async {
    if (task.dueDate == null) return;

    final scheduledDate = _calculateReminderTime(task);
    if (scheduledDate == null) return;

    // 检查时间是否在未来
    if (scheduledDate.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'taskId': task.id,
      'type': 'task_reminder',
    });

    await _notifications.zonedSchedule(
      task.id.hashCode, // 使用任务ID的hash作为通知ID
      task.title,
      '任务截止时间到了',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  DateTime? _calculateReminderTime(Task task) {
    if (task.dueDate == null) return null;

    var reminderTime = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    // 如果有具体时间，使用具体时间；否则默认早上9点
    if (task.dueTime != null) {
      reminderTime = DateTime(
        reminderTime.year,
        reminderTime.month,
        reminderTime.day,
        task.dueTime!.hour,
        task.dueTime!.minute,
      );
    } else {
      reminderTime = reminderTime.add(const Duration(hours: 9));
    }

    // 根据优先级调整提醒时间
    switch (task.priority) {
      case TaskPriority.urgent:
        // 紧急任务提前30分钟提醒
        reminderTime = reminderTime.subtract(const Duration(minutes: 30));
        break;
      case TaskPriority.high:
        // 高优先级提前15分钟提醒
        reminderTime = reminderTime.subtract(const Duration(minutes: 15));
        break;
      default:
        break;
    }

    return reminderTime;
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  @override
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  @override
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      '即时通知',
      channelDescription: '应用内即时通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  @override
  Future<void> scheduleRepeatingReminder({
    required String id,
    required String title,
    required String body,
    required DateTime startTime,
    required Duration interval,
  }) async {
    // 使用循环调度或定期通知
    // 注意：flutter_local_notifications 对重复通知的支持有限
    // 可能需要使用 WorkManager 来实现复杂的重复调度
  }
}

// 添加缺失的导入
import 'dart:convert';
import 'package:flutter/services.dart';
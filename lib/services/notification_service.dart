import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:notes/models/event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  NotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'event_channel',
          channelName: 'Event Notifications',
          channelDescription: 'Notifications for scheduled events',
          defaultColor: Colors.purple,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          enableLights: true,
          enableVibration: true,
          locked: true,
          criticalAlerts: true,
          defaultPrivacy: NotificationPrivacy.Public,
        )
      ],
      debug: true,
    );

    await requestNotificationPermissions();

    await AwesomeNotifications().setListeners(
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  Future<void> requestNotificationPermissions() async {
    try {
      // 检查通知权限
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      debugPrint('Current notification permission status: $isAllowed');
      
      if (!isAllowed) {
        // 请求通知权限
        final userResponse = await AwesomeNotifications().requestPermissionToSendNotifications(
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
            NotificationPermission.Vibration,
            NotificationPermission.Light,
            NotificationPermission.FullScreenIntent,
            NotificationPermission.CriticalAlert,
          ]
        );
        
        debugPrint('Notification permission request response: $userResponse');
        
        // 再次检查权限状态
        final finalStatus = await AwesomeNotifications().isNotificationAllowed();
        debugPrint('Final notification permission status: $finalStatus');
        
        if (!finalStatus) {
          debugPrint('用户拒绝了通知权限或权限请求失败');
        } else {
          debugPrint('用户授予了通知权限');
        }
      } else {
        debugPrint('已经有通知权限');
      }
    } catch (e) {
      debugPrint('请求通知权限时出错: $e');
    }
  }

  Future<void> showNotification(Event event) async {
    try {
      debugPrint('Attempting to show notification for event: ${event.title}');
      
      // 确保有通知权限
      final hasPermission = await AwesomeNotifications().isNotificationAllowed();
      if (!hasPermission) {
        debugPrint('No notification permission, requesting...');
        await requestNotificationPermissions();
      }

      // 检查通知时间是否有效
      final notificationTime = event.dateTime.subtract(
          Duration(minutes: event.notificationMinutesBefore ?? 0));
      final now = DateTime.now();
      
      debugPrint('Current time: ${now.toIso8601String()}');
      debugPrint('Notification time: ${notificationTime.toIso8601String()}');
      
      // 如果通知时间已过，立即显示通知
      if (notificationTime.isBefore(now)) {
        debugPrint('Notification time has passed, showing immediate notification');
        await _showImmediateNotification(event);
      } else {
        debugPrint('Scheduling notification for future time');
        await _scheduleNotification(event, notificationTime);
      }
      
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<void> _showImmediateNotification(Event event) async {
    try {
      // 播放声音
      await _audioPlayer.play(AssetSource('stylish.mp3'));
      debugPrint('Sound played successfully for event: ${event.title}');

      // 创建即时通知
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id ?? 0,
          channelKey: 'event_channel',
          title: event.title,
          body: _getNotificationBody(event),
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Event,
          wakeUpScreen: true,
          criticalAlert: true,
          autoDismissible: false,
        ),
      );
      debugPrint('Immediate notification created successfully');
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  Future<void> _scheduleNotification(Event event, DateTime notificationTime) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id ?? 0,
          channelKey: 'event_channel',
          title: event.title,
          body: _getNotificationBody(event),
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Event,
          wakeUpScreen: true,
          criticalAlert: true,
          autoDismissible: false,
        ),
        schedule: NotificationCalendar.fromDate(
          date: notificationTime,
          preciseAlarm: true,
          allowWhileIdle: true,
          repeats: false,
        ),
      );
      debugPrint('Scheduled notification created successfully for ${notificationTime.toIso8601String()}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.title}');
  }

  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.title}');
  }

  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.title}');
  }

  String _getNotificationBody(Event event) {
    final buffer = StringBuffer();
    buffer.writeln('📅 ${_formatDateTime(event.dateTime)}');

    if (event.location != null && event.location!.isNotEmpty) {
      buffer.writeln('📍 ${event.location}');
    }

    if (event.notes != null && event.notes!.isNotEmpty) {
      buffer.writeln('📝 ${event.notes}');
    }

    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../models/event_reminder.dart';
import '../constants/app_constants.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel for reminders
    const reminderChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Smart reminders extracted from your notes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create foreground service channel (low importance)
    const foregroundChannel = AndroidNotificationChannel(
      AppConstants.foregroundChannelId,
      AppConstants.foregroundChannelName,
      description: 'Myspace AI background service',
      importance: Importance.low,
      playSound: false,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(foregroundChannel);

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation handled by app on resume
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Schedules smart notifications for an event reminder.
  /// Returns the list of notification IDs that were scheduled.
  Future<List<int>> scheduleEventNotifications(EventReminder event) async {
    final ids = <int>[];
    final offsets = _getNotificationOffsets(event.eventDateTime);

    for (final (offsetDuration, bodyTemplate) in offsets) {
      final scheduledTime = event.eventDateTime.subtract(offsetDuration);
      if (scheduledTime.isBefore(DateTime.now())) continue;

      final id = _generateNotificationId();
      final body = bodyTemplate.replaceAll('{event}', event.eventName);

      try {
        await _plugin.zonedSchedule(
          id,
          'Myspace AI Reminder',
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              AppConstants.notificationChannelId,
              AppConstants.notificationChannelName,
              channelDescription: 'Smart reminders from your notes',
              importance: Importance.high,
              priority: Priority.high,
              color: const Color(0xFFFF6B2B),
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'event:${event.id}',
        );
        ids.add(id);
      } catch (e) {
        debugPrint('Failed to schedule notification: $e');
      }
    }
    return ids;
  }

  /// Schedules a one-off reminder from a voice note.
  Future<int?> scheduleVoiceReminder({
    required String task,
    required DateTime scheduledAt,
    String? noteId,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return null;
    final id = _generateNotificationId();

    try {
      await _plugin.zonedSchedule(
        id,
        'Reminder',
        task,
        tz.TZDateTime.from(scheduledAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: 'Smart reminders from your notes',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFFF6B2B),
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: noteId != null ? 'note:$noteId' : null,
      );
      return id;
    } catch (e) {
      debugPrint('Failed to schedule voice reminder: $e');
      return null;
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = _generateNotificationId();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFFFF6B2B),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> cancelNotifications(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Smart timing logic ───────────────────────────────────────────────────

  List<(Duration, String)> _getNotificationOffsets(DateTime eventDateTime) {
    final now = DateTime.now();
    final timeUntil = eventDateTime.difference(now);
    final offsets = <(Duration, String)>[];

    if (timeUntil > const Duration(days: 7)) {
      offsets.addAll([
        (const Duration(days: 7), '{event} is in one week'),
        (const Duration(days: 1), '{event} is tomorrow'),
        (const Duration(hours: 2), '{event} starts in 2 hours'),
      ]);
    } else if (timeUntil > const Duration(days: 1)) {
      offsets.addAll([
        (const Duration(days: 1), '{event} is tomorrow'),
        (const Duration(hours: 2), '{event} starts in 2 hours'),
      ]);
    } else if (timeUntil > const Duration(hours: 2)) {
      offsets.addAll([
        (const Duration(hours: 2), '{event} starts in 2 hours'),
        (const Duration(minutes: 30), '{event} starts in 30 minutes'),
      ]);
    } else if (timeUntil > const Duration(minutes: 30)) {
      offsets.add((const Duration(minutes: 30), '{event} starts in 30 minutes'));
    } else if (timeUntil > Duration.zero) {
      offsets.add((const Duration(minutes: 5), '{event} starts in 5 minutes'));
    }

    return offsets;
  }

  int _generateNotificationId() => Random().nextInt(1 << 30);
}

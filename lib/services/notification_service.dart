import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../screens/post_prepareration.dart';
import 'app_navigator.dart';
import 'draft_store.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'post_prep_schedule';
  static const String _channelName = 'Post reminders';
  static const String _channelDescription = 'Show a notification at publish time';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _launchPayload;

  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    _launchPayload = launchDetails?.notificationResponse?.payload;

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response.payload);
      },
    );

    await _createAndroidChannel();
    _initialized = true;
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosGranted =
        await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    final androidGranted = await androidPlugin?.requestNotificationsPermission() ?? true;
    return iosGranted && androidGranted;
  }

  Future<void> scheduleDraftNotification(Draft draft) async {
    if (!_initialized) await initialize();
    final scheduledAt = DateTime.fromMillisecondsSinceEpoch(draft.publishAt);
    if (scheduledAt.isBefore(DateTime.now())) return;
    final granted = await requestPermissions();
    if (!granted) return;

    final title = draft.title.trim().isNotEmpty ? draft.title.trim() : 'Time to post';
    final body = draft.generated.trim().isNotEmpty ? draft.generated.trim() : 'Your post is ready.';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
    );

    final scheduledTz = tz.TZDateTime.from(scheduledAt, tz.local);
    final notificationId = _notificationIdFromDraftId(draft.id);
    await _plugin.cancel(notificationId);
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledTz,
      details,
      payload: draft.id,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelDraftNotification(String draftId) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(_notificationIdFromDraftId(draftId));
  }

  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  Future<void> handleInitialNotificationTap() async {
    if (!_initialized) await initialize();
    if (_launchPayload == null) {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      _launchPayload = launchDetails?.notificationResponse?.payload;
    }
    final payload = _launchPayload;
    if (payload == null || payload.isEmpty) return;
    _launchPayload = null;
    _handleNotificationTap(payload);
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      _launchPayload = payload;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(
        MaterialPageRoute(builder: (_) => PostPreparerationScreen(draftId: payload)),
      );
    });
  }

  int _notificationIdFromDraftId(String draftId) {
    final parsed = int.tryParse(draftId);
    if (parsed != null) return parsed & 0x7fffffff;
    return draftId.hashCode & 0x7fffffff;
  }
}

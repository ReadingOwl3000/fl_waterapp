//import 'package:fl_waterapp/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:fl_waterapp/main.dart';

//logic to sceduale and display notifications, does not register tasks itself
//these need to be top level because it's a plugin requirement
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification tap
  print(
    'Notification tapped in background: ${notificationResponse.payload}',
  );
}

@pragma('vm:entry-point')
Future<void> callbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("calback dispather");
  _isAndroidPermissionGranted();
  // _requestPermissions();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {},
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  Workmanager().executeTask((task, inputData) async {
    print(
        "Native called background task: $task"); //simpleTask will be emitted here.

    await scheduleTestNotification();
    print("should be scheduled");
    return Future.value(true);
  });
}

Future<void> _isAndroidPermissionGranted() async {
  final bool _granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ??
      false;
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    linux: initializationSettingsLinux);

const LinuxInitializationSettings initializationSettingsLinux =
    LinuxInitializationSettings(defaultActionName: 'Open notification');

Future<void> scheduleTestNotification() async {
  print("notification...");
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel_id', // ID
    'Reminder Channel', // Name
    description: 'Channel for reminder notifications', // Description
    importance: Importance.high,
  );
  print("1");

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  print("2");
  //needs to be at top level bc workmanager needs it and workmanager has to be top level per the rules
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminder_channel_id', // Unique ID for the channel
    'Reminder Channel', // Channel name
    channelDescription: 'Channel for reminder notifications',
    importance: Importance.high,
    priority: Priority.high,
  );
  print("3");
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  print("4");
  drankToday = prefs.getInt("drankToday") ?? 0;
  watergoal = prefs.getInt("watergoal") ?? 2000;
  var lastLoggedDay = prefs.getInt(
    "lastLoggedDay",
  );
  String body =
      'You have reached ${drankToday / watergoal * 100}% of your daily goal';

  print("4.1");
  print("$drankToday , $watergoal");
  try {
    if (!(lastLoggedDay == DateTime.now().day)) {
      //if its a new day display 0 bc you have not opend the app therefore not logged anything
      body = 'You have reached 0% of your daily goal';
    }
    //dont show notification if user's reached the goal:
    if (drankToday / watergoal * 100 < 100 ||
        lastLoggedDay != DateTime.now().day) {
      await flutterLocalNotificationsPlugin.show(
        100, // Notification ID
        'Remember to drink enough water!', // Title
        body, // Body
        notificationDetails,
        payload: 'reminder', // Data associated with the notification
      );
    }
    print("notification should be there");
  } catch (e, stacktrace) {
    print("Error showing notification: $e");
    print(stacktrace);
  }
}

bool notificationsEnabled = false;

class Permissions {
  //late bool notificationsEnabled;

  static Future<void> isAndroidPermissionGranted() async {
    final bool granted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;

    notificationsEnabled = granted;
  }

  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? grantedNotificationPermission =
        await androidImplementation?.requestNotificationsPermission();
    notificationsEnabled = grantedNotificationPermission ?? false;
  }
}

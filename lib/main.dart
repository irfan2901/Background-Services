import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

void initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Set to false initially
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false, // Set to false initially
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Initialize the local notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Define a periodic task to update the notification with the current time
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    final String currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      usesChronometer: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Service Running',
      'Updated Time: $currentTime',
      platformChannelSpecifics,
    );
  });
}

FutureOr<bool> onIosBackground(ServiceInstance service) async {
  // iOS-specific background code
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings =
      InitializationSettings(iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Define a periodic task to update the notification with the current time
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final String currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(iOS: iosPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Service Running',
      'Updated Time: $currentTime',
      platformChannelSpecifics,
    );
  });
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    initializeBackgroundService(); // Call initialization here
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Service Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                FlutterBackgroundService().startService();
              },
              child: const Text('Start Service'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FlutterBackgroundService().invoke('stopService');
              },
              child: const Text('Stop Service'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm Clock',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AlarmHomePage(),
    );
  }
}

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({super.key});

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  List<Alarm> alarms = [];
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadAlarms();
    // Update time every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    final local = tz.getLocation('America/New_York');  // Or your timezone
    tz.setLocalLocation(local);
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  void _handleNotificationTap(NotificationResponse details) {
    // Handle notification tap
    if (details.payload != null) {
      // Navigate to alarm ring screen or perform other actions
    }
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmsJson = prefs.getString('alarms');
    if (alarmsJson != null) {
      final List<dynamic> decoded = jsonDecode(alarmsJson);
      setState(() {
        alarms = decoded.map((item) => Alarm.fromJson(item)).toList();
      });
      // Reschedule enabled alarms
      for (var alarm in alarms) {
        if (alarm.isEnabled) {
          _scheduleAlarm(alarm);
        }
      }
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String alarmsJson = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString('alarms', alarmsJson);
  }

  Future<void> _scheduleAlarm(Alarm alarm) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      int.parse(alarm.id),
      'Alarm',
      'Time to wake up!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Channel',
          channelDescription: 'Channel for alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(alarm.tone.split('.').first),
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'alarm_sound.wav',
          presentSound: true,
          presentAlert: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: alarm.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  void _addAlarm() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      final newAlarm = Alarm(
        time: selectedTime,
        isEnabled: true,
      );

      setState(() {
        alarms.add(newAlarm);
      });

      await _scheduleAlarm(newAlarm);
      await _saveAlarms();
    }
  }

  Future<void> _toggleAlarm(int index, bool value) async {
    setState(() {
      alarms[index].isEnabled = value;
    });

    if (value) {
      await _scheduleAlarm(alarms[index]);
    } else {
      await flutterLocalNotificationsPlugin.cancel(int.parse(alarms[index].id));
    }
    await _saveAlarms();
  }

  Future<void> _deleteAlarm(int index) async {
    await flutterLocalNotificationsPlugin.cancel(int.parse(alarms[index].id));
    setState(() {
      alarms.removeAt(index);
    });
    await _saveAlarms();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('Alarm Clock'),
      ),
      body: Column(
        children: [
          // Current Time Display
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm:ss').format(_currentTime),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  DateFormat('EEE, MMM d').format(_currentTime),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          // Alarm List
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                return AlarmTile(
                  alarm: alarms[index],
                  onToggle: (bool value) {
                    setState(() {
                      alarms[index].isEnabled = value;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      alarms.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add_alarm),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Alarm {
  TimeOfDay time;
  bool isEnabled;
  String tone;
  String id;

  Alarm({
    required this.time,
    required this.isEnabled,
    this.tone = 'default_alarm.mp3',
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Add these methods for JSON serialization
  Map<String, dynamic> toJson() => {
        'hour': time.hour,
        'minute': time.minute,
        'isEnabled': isEnabled,
        'tone': tone,
        'id': id,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        time: TimeOfDay(hour: json['hour'], minute: json['minute']),
        isEnabled: json['isEnabled'],
        tone: json['tone'],
        id: json['id'],
      );
}

class AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final Function(bool) onToggle;
  final VoidCallback onDelete;

  const AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(
        '${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: alarm.isEnabled,
            onChanged: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

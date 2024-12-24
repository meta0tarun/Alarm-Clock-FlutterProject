import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmRingScreen extends StatefulWidget {
  final String alarmId;

  const AlarmRingScreen({required this.alarmId, Key? key}) : super(key: key);

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSnoozed = false;

  @override
  void initState() {
    super.initState();
    _playAlarm();
  }

  Future<void> _playAlarm() async {
    await _audioPlayer.play(AssetSource('alarm_sound.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _stopAlarm() {
    _audioPlayer.stop();
    Navigator.of(context).pop();
  }

  void _snoozeAlarm() {
    setState(() {
      _isSnoozed = true;
    });
    _audioPlayer.stop();
    // Reschedule alarm for 5 minutes later
    // Add your snooze logic here
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.alarm_on,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Wake Up!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _snoozeAlarm,
                    child: const Text('Snooze'),
                  ),
                  ElevatedButton(
                    onPressed: _stopAlarm,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
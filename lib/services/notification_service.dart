import 'dart:io';

class NotificationService {
  static Process? _alarmProcess;

  // Find the first available system sound file
  static String? _getAvailableSoundPath() {
    const List<String> soundCandidates = [
      '/usr/share/sounds/sound-icons/piano-3.wav',
      '/usr/share/sounds/sound-icons/guitar-12.wav',
      '/usr/share/sounds/sound-icons/electric-piano-3.wav',
      '/usr/share/sounds/sound-icons/glass-water-1.wav',
      '/usr/share/sounds/sound-icons/chord-7.wav',
      '/usr/share/sounds/speech-dispatcher/test.wav',
    ];

    for (final path in soundCandidates) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  // Show a system notification
  static Future<void> showNotification(String title, String body) async {
    if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-t', '10000', // 10 seconds timeout
          '-i', 'dialog-information',
          title,
          body,
        ]);
      } catch (e) {
        print('Error showing Linux notification: $e');
      }
    }
  }

  // Play alarm sound in the background
  static Future<void> playAlarm() async {
    // If an alarm is already playing, stop it first
    stopAlarm();

    if (Platform.isLinux) {
      final soundPath = _getAvailableSoundPath();
      if (soundPath != null) {
        try {
          // Start the process asynchronously so we can control/kill it later
          _alarmProcess = await Process.start('pw-play', [soundPath]);
        } catch (e) {
          print('Error playing sound with pw-play: $e');
          // Try fallback cvlc
          try {
            _alarmProcess = await Process.start('cvlc', ['--play-and-exit', soundPath]);
          } catch (ex) {
            print('Error playing sound with cvlc: $ex');
          }
        }
      } else {
        print('No candidate sound files found on this system.');
      }
    }
  }

  // Stop the alarm sound if playing
  static void stopAlarm() {
    if (_alarmProcess != null) {
      _alarmProcess!.kill();
      _alarmProcess = null;
    }
  }
}

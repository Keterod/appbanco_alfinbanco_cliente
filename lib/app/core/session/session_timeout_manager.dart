import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTimeoutManager {
  static const _keyLastActivity = 'last_session_activity';
  static const sessionTimeout = Duration(minutes: 5);

  static Future<void> saveActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_keyLastActivity, now);
    debugPrint('[AUTH] session activity saved at $now');
  }

  static Future<void> clearActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastActivity);
    debugPrint('[AUTH] session activity cleared');
  }

  static Future<int?> getLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastActivity);
  }

  static Future<bool> isSessionStillValid() async {
    final last = await getLastActivity();
    if (last == null) {
      debugPrint('[AUTH] no last activity found');
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = Duration(milliseconds: now - last);
    final valid = diff <= sessionTimeout;

    debugPrint('[AUTH] session age valid=$valid (elapsed=${diff.inSeconds}s, limit=${sessionTimeout.inSeconds}s)');
    return valid;
  }
}

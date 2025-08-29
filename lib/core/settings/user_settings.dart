import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static const _kTzKey = 'user_timezone_iana';

  /// Returns the saved IANA timezone or a sane default.
  /// (You can later detect device tz and map to IANA.)
  static Future<String> getTimezone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kTzKey) ?? 'Europe/Madrid';
  }

  static Future<void> setTimezone(String ianaTz) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTzKey, ianaTz);
  }
}

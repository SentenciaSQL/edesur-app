import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class LocalStore {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async => _prefs ??= await SharedPreferences.getInstance();

  Future<String?> read() async => (await _store).getString(AppConstants.storageKey);

  Future<void> write(String value) async {
    await (await _store).setString(AppConstants.storageKey, value);
  }

  Future<void> clear() async {
    await (await _store).remove(AppConstants.storageKey);
  }
}

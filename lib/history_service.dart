import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const _key = 'conversion_history';

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    final list = jsonDecode(s) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> save(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> add(Map<String, dynamic> item) async {
    final list = await load();
    list.insert(0, item);
    if (list.length > 100) list.removeLast();
    await save(list);
  }
}

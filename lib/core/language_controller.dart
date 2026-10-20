import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static const _key = 'app_lang';
  String _code = 'en';

  String get code => _code;
  Locale get locale => Locale(_code == 'fil' ? 'fil' : 'en', 'PH');

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _code = p.getString(_key) ?? 'en';
    Intl.defaultLocale = _code == 'fil' ? 'fil_PH' : 'en_PH';
    notifyListeners();
  }

  Future<void> set(String code) async {
    if (code == _code) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, code);
    _code = code;
    Intl.defaultLocale = code == 'fil' ? 'fil_PH' : 'en_PH';
    notifyListeners();
  }
}
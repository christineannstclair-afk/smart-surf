import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  Map<String, String> _en = {};
  Map<String, String> _es = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final enString = await rootBundle.loadString('assets/lang/en.json');
      final esString = await rootBundle.loadString('assets/lang/es.json');
      _en = Map<String, String>.from(jsonDecode(enString));
      _es = Map<String, String>.from(jsonDecode(esString));
      _initialized = true;
    } catch (e) {
      print('Localization fallback: Failed to load JSON files. $e');
    }
  }

  String translate(String key, bool isSpanish) {
    if (!_initialized) return _fallback(key);
    final map = isSpanish ? _es : _en;
    return map[key] ?? _en[key] ?? _fallback(key);
  }

  String _fallback(String key) {
    // Simple fallback logic if key not found or error
    return key.split('_').last; 
  }
}

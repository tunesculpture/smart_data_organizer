import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode           = ThemeMode.light;
  bool      _aiEnabled           = true;
  String    _defaultExportFormat = 'xlsx';
  String    _dateFormat          = 'dd-MM-yyyy';
  String    _currencyFormat      = '₹ (INR)';
  String    _userApiKey          = '';
  String    _customEndpoint      = '';
  String    _customModel         = '';

  ThemeMode get themeMode           => _themeMode;
  bool      get aiEnabled           => _aiEnabled;
  String    get defaultExportFormat => _defaultExportFormat;
  String    get dateFormat          => _dateFormat;
  String    get currencyFormat      => _currencyFormat;
  String    get userApiKey          => _userApiKey;
  String    get customEndpoint      => _customEndpoint;
  String    get customModel         => _customModel;
  bool      get hasApiKey           => _userApiKey.trim().isNotEmpty;

  // ── Auto-detect provider from key prefix ──────────────────────────────────
  String get resolvedProviderId {
    if (_customEndpoint.isNotEmpty) return 'custom';
    final k = _userApiKey.trim().toLowerCase();
    if (k.startsWith('aiza'))    return 'gemini';
    if (k.startsWith('sk-ant-')) return 'claude';
    if (k.startsWith('gsk_'))    return 'groq';
    if (k.startsWith('xai-'))    return 'xai';      // xAI / Grok
    if (k.startsWith('toget'))   return 'together'; // Together AI
    if (k.startsWith('hf_'))     return 'hf';       // HuggingFace
    // All others (sk-proj-, sk-, deepseek, mistral, etc.) → OpenAI-compatible
    return 'openai';
  }

  String get resolvedEndpoint {
    if (_customEndpoint.isNotEmpty) return _customEndpoint;
    switch (resolvedProviderId) {
      case 'gemini':   return 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
      case 'claude':   return 'https://api.anthropic.com/v1/messages';
      case 'groq':     return 'https://api.groq.com/openai/v1/chat/completions';
      case 'xai':      return 'https://api.x.ai/v1/chat/completions';
      case 'together': return 'https://api.together.xyz/v1/chat/completions';
      case 'hf':       return 'https://api-inference.huggingface.co/v1/chat/completions';
      default:         return 'https://api.openai.com/v1/chat/completions';
    }
  }

  String get resolvedModel {
    if (_customModel.isNotEmpty) return _customModel;
    switch (resolvedProviderId) {
      case 'gemini':   return 'gemini-1.5-flash';
      case 'claude':   return 'claude-3-haiku-20240307';
      case 'groq':     return 'llama3-8b-8192';
      case 'xai':      return 'grok-beta';
      case 'together': return 'meta-llama/Llama-3-8b-chat-hf';
      case 'hf':       return 'HuggingFaceH4/zephyr-7b-beta';
      default:         return 'gpt-3.5-turbo';
    }
  }

  String get providerDisplayName {
    switch (resolvedProviderId) {
      case 'gemini':   return 'Google Gemini';
      case 'claude':   return 'Anthropic Claude';
      case 'groq':     return 'Groq';
      case 'xai':      return 'xAI (Grok)';
      case 'together': return 'Together AI';
      case 'hf':       return 'HuggingFace';
      case 'custom':   return 'Custom API';
      default:         return 'OpenAI';
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx   = prefs.getInt(AppConstants.keyThemeMode) ?? 0;
    _themeMode           = ThemeMode.values[idx.clamp(0, 2)];
    _aiEnabled           = prefs.getBool(AppConstants.keyAiEnabled) ?? true;
    _defaultExportFormat = prefs.getString(AppConstants.keyDefaultExportFormat) ?? 'xlsx';
    _dateFormat          = prefs.getString(AppConstants.keyDateFormat) ?? 'dd-MM-yyyy';
    _currencyFormat      = prefs.getString(AppConstants.keyCurrencyFormat) ?? '₹ (INR)';
    _userApiKey          = prefs.getString(AppConstants.keyUserApiKey) ?? '';
    _customEndpoint      = prefs.getString(AppConstants.keyCustomEndpoint) ?? '';
    _customModel         = prefs.getString(AppConstants.keyCustomModel) ?? '';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await SharedPreferences.getInstance().then((p) => p.setInt(AppConstants.keyThemeMode, mode.index));
    notifyListeners();
  }
  Future<void> setAiEnabled(bool v) async {
    _aiEnabled = v;
    await SharedPreferences.getInstance().then((p) => p.setBool(AppConstants.keyAiEnabled, v));
    notifyListeners();
  }
  Future<void> setDefaultExportFormat(String v) async {
    _defaultExportFormat = v;
    await SharedPreferences.getInstance().then((p) => p.setString(AppConstants.keyDefaultExportFormat, v));
    notifyListeners();
  }
  Future<void> setDateFormat(String v) async {
    _dateFormat = v;
    await SharedPreferences.getInstance().then((p) => p.setString(AppConstants.keyDateFormat, v));
    notifyListeners();
  }
  Future<void> setCurrencyFormat(String v) async {
    _currencyFormat = v;
    await SharedPreferences.getInstance().then((p) => p.setString(AppConstants.keyCurrencyFormat, v));
    notifyListeners();
  }
  Future<void> setUserApiKey(String key) async {
    _userApiKey = key.trim();
    await SharedPreferences.getInstance().then((p) => p.setString(AppConstants.keyUserApiKey, _userApiKey));
    notifyListeners();
  }
  Future<void> setCustomEndpoint(String url) async {
    _customEndpoint = url.trim();
    await SharedPreferences.getInstance().then((p) => p.setString(AppConstants.keyCustomEndpoint, _customEndpoint));
    notifyListeners();
  }
  Future<void> setCustomModel(String model) async {
    _customModel = model.trim();
    await SharedPreferences.getInstance().then((p) => p.setString(AppConstants.keyCustomModel, _customModel));
    notifyListeners();
  }
}

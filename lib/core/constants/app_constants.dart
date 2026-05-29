class AppConstants {
  // ── AdMob Test IDs ─────────────────────────────────────────────────────────
  static const String admobAppId           = 'ca-app-pub-3940256099942544~3347511713';
  static const String bannerAdUnitId       = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // ── App info ───────────────────────────────────────────────────────────────
  static const String appName    = 'Smart Data Organizer';
  static const String appVersion = '1.0.0';

  // ── SharedPrefs keys ───────────────────────────────────────────────────────
  static const String keyThemeMode           = 'theme_mode';
  static const String keyAiEnabled           = 'ai_enabled';
  static const String keyDefaultExportFormat = 'default_export_format';
  static const String keyDateFormat          = 'date_format';
  static const String keyCurrencyFormat      = 'currency_format';
  static const String keyHistory             = 'history_records';
  static const String keyUserApiKey          = 'user_api_key';
  static const String keyAiProvider          = 'ai_provider';      // NEW
  static const String keyCustomEndpoint      = 'custom_endpoint';  // NEW
  static const String keyCustomModel         = 'custom_model';     // NEW

  // ── Parsing ────────────────────────────────────────────────────────────────
  static const double aiConfidenceThreshold = 0.55;
  static const int    maxFileSizeBytes      = 50 * 1024 * 1024;
  static const int    aiSampleRows          = 5;

  // ── Supported AI Providers ─────────────────────────────────────────────────
  static const List<Map<String, String>> aiProviders = [
    {
      'id':       'openai',
      'name':     'OpenAI',
      'url':      'https://api.openai.com/v1/chat/completions',
      'model':    'gpt-3.5-turbo',
      'keyHint':  'sk-proj-...',
      'keyLabel': 'OpenAI API Key',
      'docsUrl':  'platform.openai.com/api-keys',
    },
    {
      'id':       'gemini',
      'name':     'Google Gemini',
      'url':      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
      'model':    'gemini-1.5-flash',
      'keyHint':  'AIza...',
      'keyLabel': 'Gemini API Key',
      'docsUrl':  'aistudio.google.com/app/apikey',
    },
    {
      'id':       'groq',
      'name':     'Groq (Fast & Free)',
      'url':      'https://api.groq.com/openai/v1/chat/completions',
      'model':    'llama3-8b-8192',
      'keyHint':  'gsk_...',
      'keyLabel': 'Groq API Key',
      'docsUrl':  'console.groq.com/keys',
    },
    {
      'id':       'deepseek',
      'name':     'DeepSeek',
      'url':      'https://api.deepseek.com/v1/chat/completions',
      'model':    'deepseek-chat',
      'keyHint':  'sk-...',
      'keyLabel': 'DeepSeek API Key',
      'docsUrl':  'platform.deepseek.com/api-keys',
    },
    {
      'id':       'claude',
      'name':     'Anthropic Claude',
      'url':      'https://api.anthropic.com/v1/messages',
      'model':    'claude-3-haiku-20240307',
      'keyHint':  'sk-ant-...',
      'keyLabel': 'Claude API Key',
      'docsUrl':  'console.anthropic.com/settings/keys',
    },
    {
      'id':       'custom',
      'name':     'Custom / Other',
      'url':      '',
      'model':    '',
      'keyHint':  'Your API key...',
      'keyLabel': 'API Key',
      'docsUrl':  '',
    },
  ];

  // ── Supported extensions ───────────────────────────────────────────────────
  static const List<String> supportedExtensions = ['xlsx','xls','csv','txt','json'];
  static const List<String> exportFormats       = ['xlsx','csv','json','txt','pdf'];
  static const List<String> dateFormats         = [
    'dd-MM-yyyy','MM-dd-yyyy','yyyy-MM-dd','dd/MM/yyyy','MM/dd/yyyy',
  ];
  static const List<String> currencyFormats     = [
    '₹ (INR)', '\$ (USD)', '€ (EUR)', '£ (GBP)',
  ];
  static const List<String> columnTypes         = [
    'Text','Name','Phone','Email','Date',
    'Amount','City','ID','Status','Number','Address','Notes',
  ];
}

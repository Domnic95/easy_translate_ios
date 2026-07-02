import 'package:easy_translate/models/language.dart';

class AppConstants {
  AppConstants._();
  static const configUrl = "https://savaliya.xyz/appmanager/api/appsetting";
  static const packageName = 'easy_translate_ios';
  static const apiSecretKey = '123';
}

class K {
  K._();
  static const appName = 'Easy Translate';

  static const boxHistory = 'history';
  static const boxFavorites = 'favorites';
  static const boxSettings = 'settings';
  static const boxConversations = 'conversations';

  static const prefOnboardingDone = 'onboarding_done';
}

class S {
  S._();
  static const splash = 'Easy Translate';
  static const skip = 'Skip';
  static const next = 'NEXT';
  static const getStarted = 'Get Started';
  static const textTranslate = 'Text Translate';
  static const voiceTranslate = 'Voice Translate';
  static const conversation = 'Conversation';
  static const cameraTranslate = 'Camera Translate';
  static const galleryTranslate = 'Gallery Translate';
  static const history = 'History';
  static const favorites = 'Favorites';
  static const settings = 'Settings';
  static const copied = 'Copied to clipboard';
  static const tapToSpeak = 'Tap to speak';
  static const listening = 'Listening…';

  static const onboarding = [
    (
      'Translate anything',
      'Real-time text, voice and camera translation in 100+ languages.',
    ),
    (
      'Talk across languages',
      'Have face-to-face conversations with instant two-way translation.',
    ),
    (
      'Works offline',
      'Download languages once and translate without an internet connection.',
    ),
  ];
}

class Languages {
  Languages._();

  static const auto = Language('auto', 'Auto', 'Auto', '\u{1F310}');

  static const all = <Language>[
    Language('af', 'Afrikaans', 'Afrikaans', '\u{1F1FF}\u{1F1E6}'),
    Language('sq', 'Albanian', 'Shqip', '\u{1F1E6}\u{1F1F1}'),
    Language('am', 'Amharic', 'አማርኛ', '\u{1F1EA}\u{1F1F9}'),
    Language('ar', 'Arabic', 'العربية', '\u{1F1F8}\u{1F1E6}'),
    Language('hy', 'Armenian', 'Հայերեն', '\u{1F1E6}\u{1F1F2}'),
    Language('az', 'Azerbaijani', 'Azərbaycan', '\u{1F1E6}\u{1F1FF}'),
    Language('eu', 'Basque', 'Euskara', '\u{1F1EA}\u{1F1F8}'),
    Language('be', 'Belarusian', 'Беларуская', '\u{1F1E7}\u{1F1FE}'),
    Language('bn', 'Bengali', 'বাংলা', '\u{1F1E7}\u{1F1E9}'),
    Language('bs', 'Bosnian', 'Bosanski', '\u{1F1E7}\u{1F1E6}'),
    Language('bg', 'Bulgarian', 'Български', '\u{1F1E7}\u{1F1EC}'),
    Language('ca', 'Catalan', 'Català', '\u{1F1EA}\u{1F1F8}'),
    Language('ceb', 'Cebuano', 'Cebuano', '\u{1F1F5}\u{1F1ED}'),
    Language('ny', 'Chichewa', 'Chichewa', '\u{1F1F2}\u{1F1FC}'),
    Language('zh', 'Chinese', '中文', '\u{1F1E8}\u{1F1F3}'),
    Language('co', 'Corsican', 'Corsu', '\u{1F1EB}\u{1F1F7}'),
    Language('hr', 'Croatian', 'Hrvatski', '\u{1F1ED}\u{1F1F7}'),
    Language('cs', 'Czech', 'Čeština', '\u{1F1E8}\u{1F1FF}'),
    Language('da', 'Danish', 'Dansk', '\u{1F1E9}\u{1F1F0}'),
    Language('nl', 'Dutch', 'Nederlands', '\u{1F1F3}\u{1F1F1}'),
    Language('en', 'English', 'English', '\u{1F1FA}\u{1F1F8}'),
    Language('eo', 'Esperanto', 'Esperanto', '\u{1F310}'),
    Language('et', 'Estonian', 'Eesti', '\u{1F1EA}\u{1F1EA}'),
    Language('tl', 'Filipino', 'Filipino', '\u{1F1F5}\u{1F1ED}'),
    Language('fi', 'Finnish', 'Suomi', '\u{1F1EB}\u{1F1EE}'),
    Language('fr', 'French', 'Français', '\u{1F1EB}\u{1F1F7}'),
    Language('fy', 'Frisian', 'Frysk', '\u{1F1F3}\u{1F1F1}'),
    Language('gl', 'Galician', 'Galego', '\u{1F1EA}\u{1F1F8}'),
    Language('ka', 'Georgian', 'ქართული', '\u{1F1EC}\u{1F1EA}'),
    Language('de', 'German', 'Deutsch', '\u{1F1E9}\u{1F1EA}'),
    Language('el', 'Greek', 'Ελληνικά', '\u{1F1EC}\u{1F1F7}'),
    Language('gu', 'Gujarati', 'ગુજરાતી', '\u{1F1EE}\u{1F1F3}'),
    Language('ht', 'Haitian Creole', 'Kreyòl', '\u{1F1ED}\u{1F1F9}'),
    Language('ha', 'Hausa', 'Hausa', '\u{1F1F3}\u{1F1EC}'),
    Language('haw', 'Hawaiian', 'Hawaiʻi', '\u{1F1FA}\u{1F1F8}'),
    Language('iw', 'Hebrew', 'עברית', '\u{1F1EE}\u{1F1F1}'),
    Language('hi', 'Hindi', 'हिन्दी', '\u{1F1EE}\u{1F1F3}'),
    Language('hmn', 'Hmong', 'Hmoob', '\u{1F1F1}\u{1F1E6}'),
    Language('hu', 'Hungarian', 'Magyar', '\u{1F1ED}\u{1F1FA}'),
    Language('is', 'Icelandic', 'Íslenska', '\u{1F1EE}\u{1F1F8}'),
    Language('ig', 'Igbo', 'Igbo', '\u{1F1F3}\u{1F1EC}'),
    Language('id', 'Indonesian', 'Bahasa Indonesia', '\u{1F1EE}\u{1F1E9}'),
    Language('ga', 'Irish', 'Gaeilge', '\u{1F1EE}\u{1F1EA}'),
    Language('it', 'Italian', 'Italiano', '\u{1F1EE}\u{1F1F9}'),
    Language('ja', 'Japanese', '日本語', '\u{1F1EF}\u{1F1F5}'),
    Language('jw', 'Javanese', 'Basa Jawa', '\u{1F1EE}\u{1F1E9}'),
    Language('kn', 'Kannada', 'ಕನ್ನಡ', '\u{1F1EE}\u{1F1F3}'),
    Language('kk', 'Kazakh', 'Қазақ', '\u{1F1F0}\u{1F1FF}'),
    Language('km', 'Khmer', 'ខ្មែរ', '\u{1F1F0}\u{1F1ED}'),
    Language('rw', 'Kinyarwanda', 'Kinyarwanda', '\u{1F1F7}\u{1F1FC}'),
    Language('ko', 'Korean', '한국어', '\u{1F1F0}\u{1F1F7}'),
    Language('ku', 'Kurdish', 'Kurdî', '\u{1F1EE}\u{1F1F6}'),
    Language('ky', 'Kyrgyz', 'Кыргызча', '\u{1F1F0}\u{1F1EC}'),
    Language('lo', 'Lao', 'ລາວ', '\u{1F1F1}\u{1F1E6}'),
    Language('la', 'Latin', 'Latina', '\u{1F1FB}\u{1F1E6}'),
    Language('lv', 'Latvian', 'Latviešu', '\u{1F1F1}\u{1F1FB}'),
    Language('lt', 'Lithuanian', 'Lietuvių', '\u{1F1F1}\u{1F1F9}'),
    Language('lb', 'Luxembourgish', 'Lëtzebuergesch', '\u{1F1F1}\u{1F1FA}'),
    Language('mk', 'Macedonian', 'Македонски', '\u{1F1F2}\u{1F1F0}'),
    Language('mg', 'Malagasy', 'Malagasy', '\u{1F1F2}\u{1F1EC}'),
    Language('ms', 'Malay', 'Bahasa Melayu', '\u{1F1F2}\u{1F1FE}'),
    Language('ml', 'Malayalam', 'മലയാളം', '\u{1F1EE}\u{1F1F3}'),
    Language('mt', 'Maltese', 'Malti', '\u{1F1F2}\u{1F1F9}'),
    Language('mi', 'Maori', 'Māori', '\u{1F1F3}\u{1F1FF}'),
    Language('mr', 'Marathi', 'मराठी', '\u{1F1EE}\u{1F1F3}'),
    Language('mn', 'Mongolian', 'Монгол', '\u{1F1F2}\u{1F1F3}'),
    Language('my', 'Myanmar', 'မြန်မာ', '\u{1F1F2}\u{1F1F2}'),
    Language('ne', 'Nepali', 'नेपाली', '\u{1F1F3}\u{1F1F5}'),
    Language('no', 'Norwegian', 'Norsk', '\u{1F1F3}\u{1F1F4}'),
    Language('or', 'Odia', 'ଓଡ଼ିଆ', '\u{1F1EE}\u{1F1F3}'),
    Language('ps', 'Pashto', 'پښتو', '\u{1F1E6}\u{1F1EB}'),
    Language('fa', 'Persian', 'فارسی', '\u{1F1EE}\u{1F1F7}'),
    Language('pl', 'Polish', 'Polski', '\u{1F1F5}\u{1F1F1}'),
    Language('pt', 'Portuguese', 'Português', '\u{1F1F5}\u{1F1F9}'),
    Language('pa', 'Punjabi', 'ਪੰਜਾਬੀ', '\u{1F1EE}\u{1F1F3}'),
    Language('ro', 'Romanian', 'Română', '\u{1F1F7}\u{1F1F4}'),
    Language('ru', 'Russian', 'Русский', '\u{1F1F7}\u{1F1FA}'),
    Language('sm', 'Samoan', 'Samoa', '\u{1F1FC}\u{1F1F8}'),
    Language('gd', 'Scots Gaelic', 'Gàidhlig', '\u{1F1EC}\u{1F1E7}'),
    Language('sr', 'Serbian', 'Српски', '\u{1F1F7}\u{1F1F8}'),
    Language('st', 'Sesotho', 'Sesotho', '\u{1F1F1}\u{1F1F8}'),
    Language('sn', 'Shona', 'Shona', '\u{1F1FF}\u{1F1FC}'),
    Language('sd', 'Sindhi', 'سنڌي', '\u{1F1F5}\u{1F1F0}'),
    Language('si', 'Sinhala', 'සිංහල', '\u{1F1F1}\u{1F1F0}'),
    Language('sk', 'Slovak', 'Slovenčina', '\u{1F1F8}\u{1F1F0}'),
    Language('sl', 'Slovenian', 'Slovenščina', '\u{1F1F8}\u{1F1EE}'),
    Language('so', 'Somali', 'Soomaali', '\u{1F1F8}\u{1F1F4}'),
    Language('es', 'Spanish', 'Español', '\u{1F1EA}\u{1F1F8}'),
    Language('su', 'Sundanese', 'Basa Sunda', '\u{1F1EE}\u{1F1E9}'),
    Language('sw', 'Swahili', 'Kiswahili', '\u{1F1F0}\u{1F1EA}'),
    Language('sv', 'Swedish', 'Svenska', '\u{1F1F8}\u{1F1EA}'),
    Language('tg', 'Tajik', 'Тоҷикӣ', '\u{1F1F9}\u{1F1EF}'),
    Language('ta', 'Tamil', 'தமிழ்', '\u{1F1EE}\u{1F1F3}'),
    Language('tt', 'Tatar', 'Татар', '\u{1F1F7}\u{1F1FA}'),
    Language('te', 'Telugu', 'తెలుగు', '\u{1F1EE}\u{1F1F3}'),
    Language('th', 'Thai', 'ไทย', '\u{1F1F9}\u{1F1ED}'),
    Language('tr', 'Turkish', 'Türkçe', '\u{1F1F9}\u{1F1F7}'),
    Language('tk', 'Turkmen', 'Türkmen', '\u{1F1F9}\u{1F1F2}'),
    Language('uk', 'Ukrainian', 'Українська', '\u{1F1FA}\u{1F1E6}'),
    Language('ur', 'Urdu', 'اردو', '\u{1F1F5}\u{1F1F0}'),
    Language('ug', 'Uyghur', 'ئۇيغۇرچە', '\u{1F1E8}\u{1F1F3}'),
    Language('uz', 'Uzbek', 'Oʻzbek', '\u{1F1FA}\u{1F1FF}'),
    Language('vi', 'Vietnamese', 'Tiếng Việt', '\u{1F1FB}\u{1F1F3}'),
    Language('cy', 'Welsh', 'Cymraeg', '\u{1F1EC}\u{1F1E7}'),
    Language('xh', 'Xhosa', 'isiXhosa', '\u{1F1FF}\u{1F1E6}'),
    Language('yi', 'Yiddish', 'ייִדיש', '\u{1F1EE}\u{1F1F1}'),
    Language('yo', 'Yoruba', 'Yorùbá', '\u{1F1F3}\u{1F1EC}'),
    Language('zu', 'Zulu', 'isiZulu', '\u{1F1FF}\u{1F1E6}'),
  ];

  static Language byCode(String code) {
    if (code == auto.code) return auto;
    return all.firstWhere((l) => l.code == code, orElse: () => all.first);
  }
}

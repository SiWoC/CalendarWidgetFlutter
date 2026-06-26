import 'app_localizations.dart';

/// Locale tags derived from [AppLocalizations.supportedLocales].
///
/// To add a locale: create `app_xx.arb`, run `flutter gen-l10n`, add
/// `languageXxx` to every ARB, and add a case in [labelForLocale].
abstract final class AppLocale {
  /// Empty-prefs default; must match Kotlin `WidgetConstants.DEFAULT_LOCALE`
  /// and be present in [supportedTags].
  static const defaultTag = 'en';

  static List<String> get supportedTags =>
      AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toList(growable: false);

  static bool isSupported(String tag) => supportedTags.contains(tag);

  static String normalize(String tag) => isSupported(tag) ? tag : defaultTag;
}

extension AppLocalizationsLocaleLabels on AppLocalizations {
  /// Endonym-style label for a supported locale tag in the current UI language.
  String labelForLocale(String locale) {
    switch (locale) {
      case 'en':
        return languageEnglish;
      case 'nl':
        return languageDutch;
      default:
        return labelForLocale(AppLocale.defaultTag);
    }
  }
}

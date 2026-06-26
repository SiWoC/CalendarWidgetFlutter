// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calendar Widget';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String refreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get previewTapRefresh => 'Tap refresh to load calendar data.';

  @override
  String get permissionDeniedMessage =>
      'Calendar access is denied. Allow access in app settings.';

  @override
  String get permissionRequiredMessage =>
      'This app needs access to your calendar to show appointments.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsHeaderColor => 'Header color';

  @override
  String get settingsHeaderFontSize => 'Header font size';

  @override
  String get settingsEventFontSize => 'Event font size';

  @override
  String get settingsFetchDays => 'Days to fetch';

  @override
  String settingsFontSizeValue(int size) {
    return '$size';
  }

  @override
  String settingsFetchDaysValue(int days) {
    return '$days days';
  }

  @override
  String get settingsBackground => 'Background';

  @override
  String get settingsBackgroundColor => 'Color';

  @override
  String get settingsBackgroundOpacity => 'Opacity';

  @override
  String settingsOpacityValue(int percent) {
    return '$percent%';
  }
}

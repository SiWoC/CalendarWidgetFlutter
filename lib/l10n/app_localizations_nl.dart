// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get settingsHeaderColor => 'Kopkleur';

  @override
  String get settingsHeaderFontSize => 'Lettergrootte kop';

  @override
  String get settingsEventFontSize => 'Lettergrootte afspraken';

  @override
  String get settingsFetchDays => 'Dagen ophalen';

  @override
  String settingsFontSizeValue(int size) {
    return '$size';
  }

  @override
  String settingsFetchDaysValue(int days) {
    return '$days dagen';
  }

  @override
  String get settingsBackground => 'Achtergrond';

  @override
  String get settingsBackgroundColor => 'Kleur';

  @override
  String get settingsBackgroundOpacity => 'Dekking';

  @override
  String settingsOpacityValue(int percent) {
    return '$percent%';
  }
}

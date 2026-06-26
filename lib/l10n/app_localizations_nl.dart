// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Agenda Widget';

  @override
  String get actionRefresh => 'Vernieuwen';

  @override
  String refreshFailed(String error) {
    return 'Vernieuwen mislukt: $error';
  }

  @override
  String get previewTapRefresh =>
      'Tik op vernieuwen om agenda-gegevens te laden.';

  @override
  String get permissionDeniedMessage =>
      'Agenda-toegang is geweigerd. Sta toegang toe in de app-instellingen.';

  @override
  String get permissionRequiredMessage =>
      'Deze app heeft toegang tot je agenda nodig om afspraken te tonen.';

  @override
  String get openSettings => 'Open instellingen';

  @override
  String get grantPermission => 'Toestemming geven';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

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

import 'package:calendarwidget/calendar_widget_data.dart';
import 'package:calendarwidget/widget_constants.dart';
import 'package:calendarwidget/widget_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJson = '''
{
  "schemaVersion": 1,
  "error": null,
  "headerDate": "Vrijdag 12 juni 2026",
  "headerColor": "#FF000000",
  "headerFontsize": 14,
  "sections": [
    {
      "title": "VANDAAG",
      "events": [
        {
          "color": "#FFCC0000",
          "fontsize": 14,
          "time": "19:00-21:00",
          "title": "TNH Meetup",
          "location": "Pub",
          "isAllDay": false
        },
        {
          "color": "#FF008000",
          "fontsize": 14,
          "title": "Vakantie",
          "isAllDay": true
        }
      ]
    },
    {
      "title": "MORGEN",
      "events": [
        {
          "color": "#FFCC0000",
          "fontsize": 14,
          "time": "19:00-21:00",
          "title": "Quinn helpen",
          "location": "Pub",
          "isAllDay": false
        }
      ]
    }
  ]
}
''';

  test('fromJsonString parses README sample', () {
    final data = CalendarWidgetData.fromJsonString(sampleJson);

    expect(data.schemaVersion, WidgetConstants.SCHEMA_VERSION);
    expect(data.error, isNull);
    expect(data.headerDate, 'Vrijdag 12 juni 2026');
    expect(data.headerFontSize, 14);
    expect(data.sections, hasLength(2));
    expect(data.sections.first.title, 'VANDAAG');
    expect(data.sections.first.events, hasLength(2));
    expect(data.sections.first.events.first.time, '19:00-21:00');
    expect(data.sections.first.events.last.isAllDay, isTrue);
    expect(data.sections.first.events.last.fontSize, 14);
  });

  test('toJson always writes fontsize on events', () {
    final data = CalendarWidgetData.fromJsonString(sampleJson);
    final eventJson = data.sections.first.events.last.toJson();

    expect(eventJson['fontsize'], 14);
  });

  test('toJsonString round-trips', () {
    final original = CalendarWidgetData.fromJsonString(sampleJson);
    final roundTrip = CalendarWidgetData.fromJsonString(
      original.toJsonString(),
    );

    expect(roundTrip.schemaVersion, original.schemaVersion);
    expect(roundTrip.headerDate, original.headerDate);
    expect(roundTrip.headerColor, original.headerColor);
    expect(roundTrip.headerFontSize, original.headerFontSize);
    expect(roundTrip.sections.length, original.sections.length);
    expect(
      roundTrip.sections.first.events.first.title,
      original.sections.first.events.first.title,
    );
  });

  test('error factory copies display values from settings', () {
    const settings = WidgetSettings();
    final data = CalendarWidgetData.error(
      code: WidgetConstants.ERROR_PERMISSION_DENIED,
      message: 'Agenda-toestemming vereist',
      settings: settings,
    );

    expect(data.hasError, isTrue);
    expect(data.error!.code, WidgetConstants.ERROR_PERMISSION_DENIED);
    expect(data.schemaVersion, WidgetConstants.SCHEMA_VERSION);
    expect(data.headerColor, settings.headerColor);
    expect(data.headerFontSize, settings.headerFontSize);
    expect(data.sections, isEmpty);
    expect(data.isEmpty, isTrue);

    final json = data.toJson();
    expect(json['error'], isNotNull);
    expect(json['sections'], isEmpty);
  });

  test('fromJson throws when contract field is missing', () {
    expect(
      () => CalendarWidgetData.fromJson({
        'headerDate': 'Vandaag',
        'sections': [],
      }),
      throwsA(isA<TypeError>()),
    );
  });
}

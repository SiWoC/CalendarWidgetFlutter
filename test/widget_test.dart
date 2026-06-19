import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calendarwidget/calendar_widget_data.dart';
import 'package:calendarwidget/widget_settings.dart';
import 'package:calendarwidget/widgets/calendar_preview.dart';

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
          "isAllDay": false
        },
        {
          "color": "#FF008000",
          "fontsize": 14,
          "title": "Vakantie",
          "isAllDay": true
        }
      ]
    }
  ]
}
''';

  testWidgets('CalendarPreview shows header and sections', (tester) async {
    const settings = WidgetSettings();
    final data = CalendarWidgetData.fromJsonString(sampleJson);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarPreview(settings: settings, data: null),
        ),
      ),
    );
    expect(
      find.text('Tik op vernieuwen om kalendergegevens te laden.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarPreview(settings: settings, data: data),
        ),
      ),
    );

    expect(find.text('Vrijdag 12 juni 2026'), findsOneWidget);
    expect(find.text('VANDAAG'), findsOneWidget);
    expect(find.text('• Vakantie'), findsOneWidget);
    expect(find.text('19:00-21:00 TNH Meetup'), findsOneWidget);
  });
}

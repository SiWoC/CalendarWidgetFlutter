import 'package:flutter/material.dart';

import '../calendar_widget_data.dart';
import '../utils.dart';
import '../widget_settings.dart';

/// In-app preview matching the home-screen widget layout.
///
/// Display fonts and header color come from [settings]; event line colors
/// come from the calendar snapshot ([data]).
class CalendarPreview extends StatelessWidget {
  const CalendarPreview({
    super.key,
    required this.settings,
    this.data,
    this.backgroundColor = const Color(0xFFD8CED4),
    this.isLoading = false,
  });

  final WidgetSettings settings;
  final CalendarWidgetData? data;
  final Color backgroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null) {
      return const Center(
        child: Text('Tik op vernieuwen om kalendergegevens te laden.'),
      );
    }

    if (data!.hasError) {
      return Center(
        child: Text(
          data!.error!.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Utils.hexToColor(settings.headerColor),
            fontSize: settings.headerFontSize.toDouble(),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data!.headerDate,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Utils.hexToColor(settings.headerColor),
            fontSize: settings.headerFontSize.toDouble(),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final section in data!.sections) ...[
          if (section.events.isNotEmpty) ...[
            Text(
              section.title,
              style: TextStyle(
                color: Utils.hexToColor(settings.headerColor),
                fontSize: settings.eventFontSize.toDouble(),
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final event in section.events)
              _EventLine(event: event, fontSize: settings.eventFontSize),
            const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.event, required this.fontSize});

  final CalendarEvent event;
  final int fontSize;

  @override
  Widget build(BuildContext context) {
    final color = Utils.hexToColor(event.color);
    final fontSizeValue = fontSize.toDouble();
    final locationSuffix =
        event.location != null ? ' [${event.location}]' : '';

    if (event.isAllDay) {
      return Text(
        '• ${event.title}$locationSuffix',
        style: TextStyle(color: color, fontSize: fontSizeValue),
      );
    }

    final timePrefix = event.time != null ? '${event.time} ' : '';
    return Text(
      '$timePrefix${event.title}$locationSuffix',
      style: TextStyle(color: color, fontSize: fontSizeValue),
    );
  }
}

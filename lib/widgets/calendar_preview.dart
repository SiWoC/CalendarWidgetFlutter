import 'package:flutter/material.dart';

import '../calendar_widget_data.dart';
import '../utils.dart';
import '../widget_settings.dart';

/// In-app preview matching the home-screen widget layout.
///
/// Render values come from the calendar snapshot ([data]); [settings] is kept
/// for API compatibility (e.g. background chrome from the parent frame).
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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

    final headerColor = Utils.hexToColor(data!.headerColor);

    if (data!.hasError) {
      return Center(
        child: Text(
          data!.error!.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: headerColor,
            fontSize: data!.headerFontSize.toDouble(),
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
            color: headerColor,
            fontSize: data!.headerFontSize.toDouble(),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        for (final section in data!.sections) ...[
          if (section.events.isNotEmpty) ...[
            Text(
              section.title,
              style: TextStyle(
                color: headerColor,
                fontSize: section.events.first.fontSize.toDouble(),
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final event in section.events)
              _EventLine(event: event, headerColor: headerColor),
            const SizedBox(height: 4),
          ],
        ],
      ],
    );
  }
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.event, required this.headerColor});

  final CalendarEvent event;
  final Color headerColor;

  @override
  Widget build(BuildContext context) {
    final eventColor = Utils.hexToColor(event.color);
    final fontSizeValue = event.fontSize.toDouble();
    final locationSuffix = event.location != null ? ' [${event.location}]' : '';

    final prefix = event.isAllDay
        ? '● '
        : (event.time != null ? '${event.time} ' : '');

    final baseStyle = TextStyle(
      fontSize: fontSizeValue,
      fontWeight: FontWeight.bold,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prefix.isNotEmpty)
          Text(prefix, style: baseStyle.copyWith(color: headerColor)),
        Expanded(
          child: Text(
            '${event.title}$locationSuffix',
            style: baseStyle.copyWith(color: eventColor),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../calendar_widget_data.dart';
import '../l10n/app_localizations.dart';
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
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null) {
      return Center(
        child: Text(AppLocalizations.of(context)!.previewTapRefresh),
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

    final baseStyle = TextStyle(fontSize: fontSizeValue);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prefix.isNotEmpty)
          Text(prefix, style: baseStyle.copyWith(color: headerColor, fontWeight: FontWeight.bold)),
        Expanded(
          child: _OutlinedText(
            text: '${event.title}$locationSuffix',
            color: eventColor,
            style: baseStyle,
          ),
        ),
      ],
    );
  }
}

/// Three 1-logical-pixel outline offsets; fill drawn on top.
class _OutlinedText extends StatelessWidget {
  const _OutlinedText({
    required this.text,
    required this.style,
    required this.color,
  });

  final String text;
  final TextStyle style;
  final Color color;

  static const _outlineOffsets = <Offset>[
    Offset(-1, 0),
    Offset(2, 0),
    //Offset(0, -1),
    //Offset(0, 1),
    //Offset(-1, -1),
    Offset(1, -1),
    //Offset(-1, 1),
    //Offset(1, 1),
  ];

  @override
  Widget build(BuildContext context) {
    final outline = Utils.outlineColorForFill(color);
    final fillStyle = style.copyWith(color: color);
    final outlineStyle = style.copyWith(color: outline);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final offset in _outlineOffsets)
          Transform.translate(
            offset: offset,
            child: Text(
              text,
              style: outlineStyle,
            ),
          ),
        Text(
          text,
          style: fillStyle,
        ),
      ],
    );
  }
}

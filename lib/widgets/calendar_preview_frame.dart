import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../calendar_widget_data.dart';
import '../utils.dart';
import '../widget_settings.dart';
import 'calendar_preview.dart';

/// Preview chrome: home wallpaper with the calendar widget card on top.
class CalendarPreviewFrame extends StatelessWidget {
  const CalendarPreviewFrame({
    super.key,
    required this.settings,
    this.data,
    this.wallpaperPng,
    this.isLoading = false,
  });

  final WidgetSettings settings;
  final CalendarWidgetData? data;
  final Uint8List? wallpaperPng;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _WallpaperLayer(wallpaperPng: wallpaperPng),
          CalendarPreview(
            settings: settings,
            data: data,
            isLoading: isLoading,
            backgroundColor: Utils.backgroundFill(
              settings.backgroundColor,
              settings.backgroundOpacity,
            ),
          ),
        ],
      ),
    );
  }
}

class _WallpaperLayer extends StatelessWidget {
  const _WallpaperLayer({this.wallpaperPng});

  final Uint8List? wallpaperPng;

  @override
  Widget build(BuildContext context) {
    if (wallpaperPng != null) {
      return Image.memory(
        wallpaperPng!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return const ColoredBox(color: Color.fromARGB(255, 24, 112, 43));
  }
}

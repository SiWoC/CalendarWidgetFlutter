import 'package:flutter/material.dart';

abstract final class Utils {
  static int hexToArgb(String hex) {
    final normalized = hex.startsWith('#')
        ? hex.substring(1)
        : hex.startsWith('0x') || hex.startsWith('0X')
        ? hex.substring(2)
        : hex;
    return int.parse(normalized, radix: 16);
  }

  static String argbToHex(int argb) =>
      '#${argb.toRadixString(16).padLeft(8, '0')}';

  static Color hexToColor(String hex) => Color(hexToArgb(hex));

  static Color backgroundFill(String hex, int opacityPercent) {
    final clamped = opacityPercent.clamp(0, 100);
    return hexToColor(hex).withValues(alpha: clamped / 100);
  }
}

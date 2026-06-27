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

  /// WCAG 2.x contrast ratio between two sRGB colors.
  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Black or white outline that contrasts best with [fill].
  static Color outlineColorForFill(Color fill) {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    return contrastRatio(fill, black) >= contrastRatio(fill, white)
        ? black
        : white;
  }
}

import 'package:flutter/material.dart';

class Style {
  static const double titleSize = 34;
  static const double fontSize = 20;
  static double iconSize = 26;
  static double iconPadding = 15;
  static const double buttonSize = 52;

  /// Circular button shape used by all meeting control buttons.
  static final ButtonStyle circleButton = FilledButton.styleFrom(
    shape: const CircleBorder(),
    fixedSize: const Size(buttonSize, buttonSize),
    padding: EdgeInsets.zero,
  );
}

/// Centralized color palette for all Chime SDK UI components.
///
/// Use these constants instead of hard-coded hex values so the theme can be
/// updated in one place.
class ChimeColors {
  ChimeColors._();

  /// Darkest background — Scaffold background.
  static const Color background = Color(0xffffffff);

  /// Primary surface — control bar, dialogs.
  static const Color surface = Color(0xffffffff);

  static const Color onSurface = Color(0xff070d13);

  /// Secondary surface — participant tile and overflow tile background.
  static const Color surfaceVariant = Color(0xffeaf6fd);

  /// Interactive element background in its default (active) state.
  static const Color buttonBackground = Color(0xff0c68fe);

  /// Ring color drawn around the active speaker tile.
  static const Color activeSpeaker = Color(0xff4CAF50);

  /// Poor connection banner background.
  static const Color connectionPoor = Color(0xffE65100);

  /// End-call button background.
  static const Color error = Color(0xffff6e01);

  /// Deterministic avatar background palette — index chosen by name hash.
  static const List<Color> avatarPalette = [
    Color(0xff4A90D9),
    Color(0xff7B61FF),
    Color(0xffE06C75),
    Color(0xff61AFEF),
    Color(0xff98C379),
    Color(0xffE5C07B),
    Color(0xffC678DD),
    Color(0xff56B6C2),
  ];
}

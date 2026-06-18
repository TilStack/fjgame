// Styles typographiques : Cinzel pour les titres (thème antique), Inter pour le corps.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle cinzel({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      GoogleFonts.cinzel(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );

  static TextStyle inter({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      );
}

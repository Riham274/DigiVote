import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle displayLg = GoogleFonts.cairo(
    fontSize: 57,
    fontWeight: FontWeight.w900, // Black
    color: AppColors.onSurface,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle displayMd = GoogleFonts.cairo(
    fontSize: 45,
    fontWeight: FontWeight.w900,
    color: AppColors.onSurface,
    height: 1.15,
  );

  static TextStyle headlineMd = GoogleFonts.cairo(
    fontSize: 28,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.onSurface,
    height: 1.6, // RTL optimized
  );

  static TextStyle titleLg = GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.6,
  );

  static TextStyle bodyLg = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.6,
  );

  static TextStyle bodyMd = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.6,
  );

  static TextStyle labelLg = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 0.1,
    height: 1.6,
  );
}

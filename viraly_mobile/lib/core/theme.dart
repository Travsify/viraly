import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViralyTheme {
  // Neo-Dark Cyber Color Palette
  static const Color background = Color(0xFF07090E);
  static const Color surface = Color(0xFF0E131F);
  static const Color surfaceElevated = Color(0xFF161D2E);
  static const Color border = Color(0xFF1F293D);

  // Accent Colors
  static const Color emerald = Color(0xFF00F59B); // High-voltage emerald glow
  static const Color teal = Color(0xFF00D2B4);
  static const Color indigo = Color(0xFF6366F1);
  static const Color rose = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFF59E0B);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: emerald,
      cardColor: surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: emerald,
        secondary: indigo,
        surface: surface,
        error: rose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: emerald,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }

  // Neo-Glow Box Decoration
  static BoxDecoration neoCardDecoration({Color? borderColor, double borderRadius = 20}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? border, width: 1),
      boxShadow: [
        BoxShadow(
          color: (borderColor ?? emerald).withAlpha(15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Glowing Emerald Gradient
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [emerald, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF131A29), Color(0xFF0E131F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// color_chooser.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ColorChooser {
  static final Random _random = Random();

  // ========== PRIMARY COLORS (9) ==========
  static const Color primaryPurple = Color(0xFF6B4EFF);
  static const Color primaryDarkPurple = Color(0xFF4A3AFF);
  static const Color primaryLightPurple = Color(0xFF9B7EFF);
  static const Color primaryBlue = Color(0xFF2E5BFF);
  static const Color primaryDarkBlue = Color(0xFF1E3A8A);
  static const Color primaryNavy = Color(0xFF1E2A5E);
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color primaryViolet = Color(0xFF7C3AED);
  static const Color primaryDeepPurple = Color(0xFF4C1D95);

  // ========== SECONDARY COLORS (9) ==========
  static const Color secondaryTeal = Color(0xFF14B8A6);
  static const Color secondaryCyan = Color(0xFF06B6D4);
  static const Color secondarySky = Color(0xFF0EA5E9);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color secondaryEmerald = Color(0xFF059669);
  static const Color secondaryMint = Color(0xFF34D399);
  static const Color secondaryOcean = Color(0xFF0891B2);
  static const Color secondaryTurquoise = Color(0xFF2DD4BF);
  static const Color secondarySage = Color(0xFF84CC16);

  // ========== ACCENT COLORS (9) ==========
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentCoral = Color(0xFFFB7185);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentMagenta = Color(0xFFD946EF);
  static const Color accentLavender = Color(0xFFC084FC);

  // ========== NEUTRAL COLORS (12) ==========
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGray50 = Color(0xFFF9FAFB);
  static const Color neutralGray100 = Color(0xFFF3F4F6);
  static const Color neutralGray200 = Color(0xFFE5E7EB);
  static const Color neutralGray300 = Color(0xFFD1D5DB);
  static const Color neutralGray400 = Color(0xFF9CA3AF);
  static const Color neutralGray500 = Color(0xFF6B7280);
  static const Color neutralGray600 = Color(0xFF4B5563);
  static const Color neutralGray700 = Color(0xFF374151);
  static const Color neutralGray800 = Color(0xFF1F2937);
  static const Color neutralGray900 = Color(0xFF111827);
  static const Color neutralBlack = Color(0xFF000000);

  // ========== SUCCESS COLORS (4) ==========
  static const Color successGreen = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successForest = Color(0xFF15803D);

  // ========== WARNING COLORS (4) ==========
  static const Color warningYellow = Color(0xFFEAB308);
  static const Color warningLight = Color(0xFFFDE047);
  static const Color warningDark = Color(0xFFCA8A04);
  static const Color warningOrange = Color(0xFFF59E0B);

  // ========== ERROR COLORS (4) ==========
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorCrimson = Color(0xFFBE123C);

  // ========== INFO COLORS (4) ==========
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoSky = Color(0xFF38BDF8);

  // ========== BACKGROUND COLORS (6) ==========
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgOffWhite = Color(0xFFF9F9FB);
  static const Color bgGray = Color(0xFFF3F4F6);
  static const Color bgDark = Color(0xFF1E1E2E);
  static const Color bgCard = Color(0xFFFFFFFF);

  // ========== TEXT COLORS (6) ==========
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFF3F4F6);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  // ========== LEGAL THEME COLORS (12) ==========
  static const Color legalNavy = Color(0xFF0F172A);
  static const Color legalMaroon = Color(0xFF4A0E2E);
  static const Color legalBronze = Color(0xFFCD7F32);
  static const Color legalGold = Color(0xFFD4AF37);
  static const Color legalSilver = Color(0xFFC0C0C0);
  static const Color legalMahogany = Color(0xFFC04000);
  static const Color legalBurgundy = Color(0xFF800020);
  static const Color legalCharcoal = Color(0xFF36454F);
  static const Color legalIvory = Color(0xFFFFFFF0);
  static const Color legalCream = Color(0xFFFFFDD0);
  static const Color legalParchment = Color(0xFFFCF5E5);
  static const Color legalSeal = Color(0xFF8B0000);

  // ========== GRADIENT PAIRS (20 pairs = 40 colors) ==========
  static const List<List<Color>> gradientPairs = [
    [Color(0xFF6B4EFF), Color(0xFF4A3AFF)],
    [Color(0xFF2E5BFF), Color(0xFF1E3A8A)],
    [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    [Color(0xFF14B8A6), Color(0xFF0D9488)],
    [Color(0xFF06B6D4), Color(0xFF0891B2)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFF97316), Color(0xFFEA580C)],
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    [Color(0xFF10B981), Color(0xFF14B8A6)],
    [Color(0xFFF59E0B), Color(0xFFF97316)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF6B4EFF), Color(0xFF8B5CF6)],
    [Color(0xFF1E2A5E), Color(0xFF3F51B5)],
    [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    [Color(0xFF0F172A), Color(0xFF1E3A8A)],
  ];

  // ========== ALL COLOR LIST (121+ colors) ==========
  static List<Color> getAllColors() {
    return [
      // Primary Colors (9)
      primaryPurple,
      primaryDarkPurple,
      primaryLightPurple,
      primaryBlue,
      primaryDarkBlue,
      primaryNavy,
      primaryIndigo,
      primaryViolet,
      primaryDeepPurple,

      // Secondary Colors (9)
      secondaryTeal,
      secondaryCyan,
      secondarySky,
      secondaryGreen,
      secondaryEmerald,
      secondaryMint,
      secondaryOcean,
      secondaryTurquoise,
      secondarySage,

      // Accent Colors (9)
      accentGold,
      accentAmber,
      accentOrange,
      accentCoral,
      accentRose,
      accentRed,
      accentPink,
      accentMagenta,
      accentLavender,

      // Neutral Colors (12)
      neutralWhite,
      neutralGray50,
      neutralGray100,
      neutralGray200,
      neutralGray300,
      neutralGray400,
      neutralGray500,
      neutralGray600,
      neutralGray700,
      neutralGray800,
      neutralGray900,
      neutralBlack,

      // Success Colors (4)
      successGreen,
      successLight,
      successDark,
      successForest,

      // Warning Colors (4)
      warningYellow,
      warningLight,
      warningDark,
      warningOrange,

      // Error Colors (4)
      errorRed,
      errorLight,
      errorDark,
      errorCrimson,

      // Info Colors (4)
      infoBlue,
      infoLight,
      infoDark,
      infoSky,

      // Background Colors (6)
      bgWhite,
      bgLight,
      bgOffWhite,
      bgGray,
      bgDark,
      bgCard,

      // Text Colors (6)
      textPrimary,
      textSecondary,
      textTertiary,
      textLight,
      textDark,
      textMuted,

      // Legal Theme Colors (12)
      legalNavy,
      legalMaroon,
      legalBronze,
      legalGold,
      legalSilver,
      legalMahogany,
      legalBurgundy,
      legalCharcoal,
      legalIvory,
      legalCream,
      legalParchment,
      legalSeal,

      // Gradient Pair Colors (40 unique colors)
      for (var pair in gradientPairs) ...[pair[0], pair[1]],
    ];
  }

  // Remove duplicates from gradient pairs to get unique colors
  static List<Color> getUniqueColors() {
    final uniqueColors = <Color>{};
    uniqueColors.addAll(getAllColors());
    return uniqueColors.toList();
  }

  // ========== RANDOM COLOR METHODS ==========

  /// Get a completely random color from all colors
  static Color getRandomColor() {
    final colors = getAllColors();
    final randomIndex = _random.nextInt(colors.length);
    return colors[randomIndex];
  }

  /// Get a random primary color
  static Color getRandomPrimaryColor() {
    final colors = [
      primaryPurple,
      primaryDarkPurple,
      primaryLightPurple,
      primaryBlue,
      primaryDarkBlue,
      primaryNavy,
      primaryIndigo,
      primaryViolet,
      primaryDeepPurple,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  /// Get a random accent color
  static Color getRandomAccentColor() {
    final colors = [
      accentGold,
      accentAmber,
      accentOrange,
      accentCoral,
      accentRose,
      accentRed,
      accentPink,
      accentMagenta,
      accentLavender,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  /// Get a random neutral color
  static Color getRandomNeutralColor() {
    final colors = [
      neutralGray50,
      neutralGray100,
      neutralGray200,
      neutralGray300,
      neutralGray400,
      neutralGray500,
      neutralGray600,
      neutralGray700,
      neutralGray800,
      neutralGray900,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  /// Get a random legal theme color
  static Color getRandomLegalColor() {
    final colors = [
      legalNavy,
      legalMaroon,
      legalBronze,
      legalGold,
      legalSilver,
      legalMahogany,
      legalBurgundy,
      legalCharcoal,
      legalIvory,
      legalCream,
      legalParchment,
      legalSeal,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  /// Get a random color from a specific category
  static Color getRandomColorFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'primary':
        return getRandomPrimaryColor();
      case 'accent':
        return getRandomAccentColor();
      case 'neutral':
        return getRandomNeutralColor();
      case 'legal':
        return getRandomLegalColor();
      case 'success':
        return [successGreen, successLight, successDark, successForest][
        _random.nextInt(4)];
      case 'warning':
        return [warningYellow, warningLight, warningDark, warningOrange][
        _random.nextInt(4)];
      case 'error':
        return [errorRed, errorLight, errorDark, errorCrimson][
        _random.nextInt(4)];
      case 'info':
        return [infoBlue, infoLight, infoDark, infoSky][_random.nextInt(4)];
      default:
        return getRandomColor();
    }
  }

  /// Get random gradient pair
  static List<Color> getRandomGradient() {
    return gradientPairs[_random.nextInt(gradientPairs.length)];
  }

  /// Get random color with opacity
  static Color getRandomColorWithOpacity(double opacity) {
    final color = getRandomColor();
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Get random color for status badges
  static Color getRandomStatusColor() {
    final statusColors = [
      successGreen,
      warningYellow,
      errorRed,
      infoBlue,
      accentGold,
      accentOrange,
      accentRose,
      accentLavender,
    ];
    return statusColors[_random.nextInt(statusColors.length)];
  }

  /// Get random shade of a base color
  static Color getRandomShade(Color baseColor) {
    final shades = [
      baseColor,
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      baseColor.withOpacity(0.4),
      baseColor.withOpacity(0.2),
    ];
    return shades[_random.nextInt(shades.length)];
  }

  /// Get a color suitable for text on a given background
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// Extension for easier color access
extension ColorExtension on BuildContext {
  Color get randomColor => ColorChooser.getRandomColor();
  Color get randomPrimary => ColorChooser.getRandomPrimaryColor();
  Color get randomAccent => ColorChooser.getRandomAccentColor();
  Color get randomLegal => ColorChooser.getRandomLegalColor();
  List<Color> get randomGradient => ColorChooser.getRandomGradient();
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/task_model.dart';

class AppTheme {
  AppTheme._();

  // 品牌色
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03A9F4);
  static const Color accentColor = Color(0xFFFF9800);
  
  // 优先级颜色
  static const Color urgentColor = Color(0xFFF44336);
  static const Color highColor = Color(0xFFFF5722);
  static const Color mediumColor = Color(0xFFFF9800);
  static const Color lowColor = Color(0xFF4CAF50);
  static const Color noneColor = Color(0xFF9E9E9E);
  
  // 状态颜色
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // 亮色背景
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE0E0E0);
  
  // 暗色背景
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color dividerDark = Color(0xFF424242);
  
  // 文字颜色
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // 获取优先级颜色
  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent: return urgentColor;
      case TaskPriority.high: return highColor;
      case TaskPriority.medium: return mediumColor;
      case TaskPriority.low: return lowColor;
      case TaskPriority.none: return noneColor;
    }
  }

  // 获取优先级名称
  static String getPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent: return '紧急';
      case TaskPriority.high: return '高';
      case TaskPriority.medium: return '中';
      case TaskPriority.low: return '低';
      case TaskPriority.none: return '无';
    }
  }

  // 获取状态颜色
  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.inbox: return infoColor;
      case TaskStatus.todo: return primaryColor;
      case TaskStatus.inProgress: return warningColor;
      case TaskStatus.done: return successColor;
      case TaskStatus.archived: return noneColor;
      case TaskStatus.deleted: return errorColor;
    }
  }

  // 获取状态名称
  static String getStatusName(TaskStatus status) {
    switch (status) {
      case TaskStatus.inbox: return '收件箱';
      case TaskStatus.todo: return '待办';
      case TaskStatus.inProgress: return '进行中';
      case TaskStatus.done: return '已完成';
      case TaskStatus.archived: return '已归档';
      case TaskStatus.deleted: return '已删除';
    }
  }

  // 亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      dividerColor: dividerLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        background: lightBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        selectedColor: primaryColor,
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // 暗色主题
  static ThemeData get darkTheme {
    final light = lightTheme;
    return light.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      dividerColor: dividerDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        background: darkBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      inputDecorationTheme: light.inputDecorationTheme.copyWith(
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerDark),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? darkTextPrimary : lightTextPrimary;
    
    final baseTextTheme = GoogleFonts.notoSansScTextTheme();
    
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: primaryColor),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, color: primaryColor),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, color: primaryColor),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0, color: primaryColor),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0, color: primaryColor),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0, color: primaryColor),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0, color: primaryColor),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: primaryColor),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: primaryColor),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: primaryColor),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: primaryColor),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: primaryColor),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: primaryColor),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: primaryColor),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: primaryColor),
    );
  }
}
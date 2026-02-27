import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/task_model.dart';

/// AppTheme - 全面美化的主题系统
/// 
/// 参考设计风格：
/// - Things 3: 极简优雅、柔和配色、大圆角、精致阴影
/// - Todoist: 红色强调、清晰层级、优先级色彩
/// - TickTick: 丰富动画、圆角设计、现代感
/// 
/// 设计原则：
/// 1. 色彩：柔和、优雅、不刺眼
/// 2. 间距：舒适、透气
/// 3. 圆角：统一、现代
/// 4. 动画：流畅、自然
class AppTheme {
  AppTheme._();

  // ==================== 品牌色系统（Things 3 风格柔和配色）====================
  /// 主色调 - 深邃优雅的蓝紫色
  static const Color primaryColor = Color(0xFF5856D6);
  static const Color primaryLight = Color(0xFF7B7BE0);
  static const Color primaryDark = Color(0xFF4A49B0);
  
  /// 次要色 - 温暖珊瑚色
  static const Color secondaryColor = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF8E8E);
  
  /// 强调色 - 金黄色
  static const Color accentColor = Color(0xFFFFD93D);
  
  /// Todoist 风格红色强调
  static const Color todoistRed = Color(0xFFE44332);
  static const Color todoistRedLight = Color(0xFFFF6B5B);

  // ==================== 优先级颜色系统（Things 3 + Todoist 融合）====================
  static const Color urgentColor = Color(0xFFFF3B30);   // 鲜艳红色
  static const Color highColor = Color(0xFFFF9500);   // 橙色
  static const Color mediumColor = Color(0xFFFFCC00);   // 黄色
  static const Color lowColor = Color(0xFF34C759);      // 绿色
  static const Color noneColor = Color(0xFF8E8E93);     // 灰色
  
  // 优先级渐变背景
  static LinearGradient getUrgentGradient() => const LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF3B30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient getHighGradient() => const LinearGradient(
    colors: [Color(0xFFFFA07A), Color(0xFFFF6347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== 状态颜色 ====================
  static const Color successColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color infoColor = Color(0xFF5856D6);
  
  // ==================== 亮色主题背景（Things 3 风格温暖色调）====================
  /// 主背景 - 温暖的米白色
  static const Color lightBackground = Color(0xFFF2F2F7);
  /// 表面色 - 纯白
  static const Color lightSurface = Color(0xFFFFFFFF);
  /// 卡片色 - 纯白
  static const Color lightCard = Color(0xFFFFFFFF);
  /// 悬浮背景
  static const Color lightHover = Color(0xFFE5E5EA);
  /// 分割线
  static const Color dividerLight = Color(0xFFE5E5EA);
  
  // ==================== 暗色主题背景（精致深蓝灰）====================
  /// 主背景 - 深蓝灰
  static const Color darkBackground = Color(0xFF1C1C1E);
  /// 表面色 - 深灰
  static const Color darkSurface = Color(0xFF2C2C2E);
  /// 卡片色 - 中灰
  static const Color darkCard = Color(0xFF3A3A3C);
  /// 悬浮背景
  static const Color darkHover = Color(0xFF48484A);
  /// 分割线
  static const Color dividerDark = Color(0xFF38383A);
  
  // ==================== 文字颜色 ====================
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightTextTertiary = Color(0xFFC7C7CC);
  
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF636366);

  // ==================== 精致阴影系统 ====================
  /// 卡片阴影 - 微妙提升
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];
  
  /// 悬浮阴影 - 更明显
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  /// 模态阴影 - 最突出
  static List<BoxShadow> get modalShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  /// 深色模式阴影（更柔和）
  static List<BoxShadow> darkCardShadow(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ==================== 圆角系统 ====================
  /// 小圆角 - 小元素
  static const double radiusSmall = 4.0;
  /// 中圆角 - 按钮、输入框
  static const double radiusMedium = 8.0;
  /// 大圆角 - 卡片
  static const double radiusLarge = 16.0;
  /// 超大圆角 - 模态、底部弹窗
  static const double radiusXLarge = 24.0;
  /// 全圆角 - 标签、胶囊
  static const double radiusFull = 999.0;

  // ==================== 动画配置 ====================
  /// 快速动画 - 微交互
  static const Duration animationFast = Duration(milliseconds: 150);
  /// 正常动画 - 标准过渡
  static const Duration animationNormal = Duration(milliseconds: 250);
  /// 慢速动画 - 复杂过渡
  static const Duration animationSlow = Duration(milliseconds: 350);
  /// 曲线 - 平滑
  static const Curve animationCurve = Curves.easeInOutCubic;
  /// 曲线 - 弹性
  static const Curve animationCurveBounce = Curves.easeOutBack;
  /// 曲线 - 减速
  static const Curve animationCurveDecelerate = Curves.decelerate;

  // ==================== 间距系统 ====================
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;
  static const double spacingXxxl = 48.0;

  // ==================== 优先级方法 ====================
  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent: return urgentColor;
      case TaskPriority.high: return highColor;
      case TaskPriority.medium: return mediumColor;
      case TaskPriority.low: return lowColor;
      case TaskPriority.none: return noneColor;
    }
  }

  static String getPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent: return '紧急';
      case TaskPriority.high: return '高';
      case TaskPriority.medium: return '中';
      case TaskPriority.low: return '低';
      case TaskPriority.none: return '无';
    }
  }

  // ==================== 状态方法 ====================
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

  // ==================== 字体系统 ====================
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? darkTextPrimary : lightTextPrimary;
    
    final baseTextTheme = GoogleFonts.notoSansScTextTheme();
    
    return baseTextTheme.copyWith(
      // 展示级 - 大标题
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 57, 
        fontWeight: FontWeight.w300, 
        letterSpacing: -0.25, 
        color: primaryColor,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 45, 
        fontWeight: FontWeight.w300, 
        letterSpacing: 0, 
        color: primaryColor,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36, 
        fontWeight: FontWeight.w400, 
        letterSpacing: 0, 
        color: primaryColor,
      ),
      // 标题级
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32, 
        fontWeight: FontWeight.w400, 
        letterSpacing: 0, 
        color: primaryColor,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28, 
        fontWeight: FontWeight.w400, 
        letterSpacing: 0, 
        color: primaryColor,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24, 
        fontWeight: FontWeight.w400, 
        letterSpacing: 0, 
        color: primaryColor,
      ),
      // 标题级
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22, 
        fontWeight: FontWeight.w500, 
        letterSpacing: 0, 
        color: primaryColor,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16, 
        fontWeight: FontWeight.w500, 
        letterSpacing: 0.15, 
        color: primaryColor,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14, 
        fontWeight: FontWeight.w500, 
        letterSpacing: 0.1, 
        color: primaryColor,
      ),
      // 正文
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16, 
        fontWeight: FontWeight.w400, 
        letterSpacing: 0.5, 
        color: primaryColor,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14, 
        fontWeight: FontWeight.w400, 
        letterSpacing: 0.25, 
        color: primaryColor,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12, 
        fontWeight: FontWeight.w400, 
        letterSpacing: 0.4, 
        color: isDark ? darkTextSecondary : lightTextSecondary,
        height: 1.4,
      ),
      // 标签
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14, 
        fontWeight: FontWeight.w500, 
        letterSpacing: 0.1, 
        color: primaryColor,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12, 
        fontWeight: FontWeight.w500, 
        letterSpacing: 0.5, 
        color: isDark ? darkTextSecondary : lightTextSecondary,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11, 
        fontWeight: FontWeight.w500, 
        letterSpacing: 0.5, 
        color: isDark ? darkTextSecondary : lightTextSecondary,
      ),
    );
  }

  // ==================== 亮色主题 ====================
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
      
      // AppBar 主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: _buildTextTheme(Brightness.light).titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        elevation: 0,
        color: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingS),
      ),
      
      // FAB 主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: spacingXl, vertical: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: spacingXl, vertical: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      
      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        selectedColor: primaryColor,
        labelStyle: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacingS, vertical: spacingXxs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 1,
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return lightTextTertiary;
        }),
      ),
      
      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.1),
      ),
      
      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      
      // 底部弹窗主题
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
      ),
      
      // 菜单主题
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: MaterialStateProperty.all(lightSurface),
          elevation: MaterialStateProperty.all(8),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusLarge),
            ),
          ),
        ),
      ),
      
      // 提示主题
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // ==================== 暗色主题 ====================
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
      
      // AppBar 主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: _buildTextTheme(Brightness.dark).titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingS),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkTextSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: dividerDark,
        thickness: 1,
        space: 1,
      ),
      
      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.2),
        selectedColor: primaryColor,
        labelStyle: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacingS, vertical: spacingXxs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),
      
      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      
      // 底部弹窗主题
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
      ),
    );
  }

  // ==================== 渐变生成器 ====================
  static LinearGradient getPrimaryGradient() => const LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient getSuccessGradient() => const LinearGradient(
    colors: [successColor, Color(0xFF30D158)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient getStatGradient() => const LinearGradient(
    colors: [Color(0xFF5856D6), Color(0xFF7B7BE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 统计卡片渐变
  static LinearGradient getTodayGradient() => const LinearGradient(
    colors: [Color(0xFF5856D6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient getCompletedGradient() => const LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF30D158)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient getPendingGradient() => const LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

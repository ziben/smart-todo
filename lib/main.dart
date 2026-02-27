import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/task/task_bloc.dart';
import 'presentation/screens/home/home_screen.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖注入
  await configureDependencies();
  
  // 初始化服务
  await _initializeServices();
  
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  try {
    // 初始化通知服务
    final notificationService = getIt<NotificationService>();
    await notificationService.initialize();
    
    // 初始化同步服务
    final syncService = getIt<SyncService>();
    await syncService.initialize();
  } catch (e) {
    debugPrint('服务初始化失败: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<TaskBloc>()..add(const TaskEvent.watchTasks()),
        ),
        // 添加其他 BLoC...
      ],
      child: MaterialApp(
        title: '智能清单',
        debugShowCheckedModeBanner: false,
        
        // 主题
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        
        // 本地化
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
          Locale('en', 'US'),
        ],
        locale: const Locale('zh', 'CN'),
        
        // 路由
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          // 添加其他路由...
        },
      ),
    );
  }
}

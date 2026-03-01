// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../data/local/database.dart' as _i3;
import '../data/repositories/task_repository_impl.dart' as _i5;
import '../domain/repositories/task_repository.dart' as _i4;
import '../domain/usecases/task_usecases.dart' as _i6;
import '../services/ai_service.dart' as _i7;
import '../services/notification_service.dart' as _i8;
import '../services/sync_service.dart' as _i9';
import '../presentation/bloc/task/task_bloc.dart' as _i10;

extension GetItInjectableX on _i1.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt $initGetIt(_i1.GetIt getIt, {String? environment}) {
    final gh = _i2.GetItHelper(getIt, environment);
    
    // Database
    gh.lazySingleton<_i3.AppDatabase>(() => _i3.AppDatabase());
    
    // Repositories
    gh.lazySingleton<_i4.TaskRepository>(
      () => _i5.TaskRepositoryImpl(gh<_i3.AppDatabase>()),
    );
    
    // UseCases
    gh.lazySingleton<_i6.GetTasksUseCase>(
      () => _i6.GetTasksUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.GetTaskByIdUseCase>(
      () => _i6.GetTaskByIdUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.CreateTaskUseCase>(
      () => _i6.CreateTaskUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.UpdateTaskUseCase>(
      () => _i6.UpdateTaskUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.DeleteTaskUseCase>(
      () => _i6.DeleteTaskUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.CompleteTaskUseCase>(
      () => _i6.CompleteTaskUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.SearchTasksUseCase>(
      () => _i6.SearchTasksUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.GetTodayTasksUseCase>(
      () => _i6.GetTodayTasksUseCase(gh<_i4.TaskRepository>()),
    );
    gh.lazySingleton<_i6.GetOverdueTasksUseCase>(
      () => _i6.GetOverdueTasksUseCase(gh<_i4.TaskRepository>()),
    );
    
    // Services
    gh.lazySingleton<_i7.AiService>(() => _i7.AiServiceImpl(gh<_i7.http.Client>()));
    gh.lazySingleton<_i8.NotificationService>(() => _i8.NotificationServiceImpl());
    gh.lazySingleton<_i9.SyncService>(() => _i9.SyncServiceImpl(
      gh<_i3.AppDatabase>(),
      gh<_i9.Connectivity>(),
    ));
    
    // BLoCs
    gh.factory<_i10.TaskBloc>(() => _i10.TaskBloc(
      getTasksUseCase: gh<_i6.GetTasksUseCase>(),
      getTaskByIdUseCase: gh<_i6.GetTaskByIdUseCase>(),
      createTaskUseCase: gh<_i6.CreateTaskUseCase>(),
      updateTaskUseCase: gh<_i6.UpdateTaskUseCase>(),
      deleteTaskUseCase: gh<_i6.DeleteTaskUseCase>(),
      completeTaskUseCase: gh<_i6.CompleteTaskUseCase>(),
      searchTasksUseCase: gh<_i6.SearchTasksUseCase>(),
      getTodayTasksUseCase: gh<_i6.GetTodayTasksUseCase>(),
      getOverdueTasksUseCase: gh<_i6.GetOverdueTasksUseCase>(),
    ));
    
    return getIt;
  }
}
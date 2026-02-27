import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import '../core/constants/app_constants.dart';
import '../data/local/database.dart';
import '../domain/models/task_model.dart';

/// 同步冲突策略
enum ConflictStrategy {
  localWins,    // 本地优先
  remoteWins,   // 远程优先
  newerWins,    // 较新的优先
  manual,       // 手动解决
}

/// 同步服务接口
abstract class SyncService {
  Future<void> initialize();
  Future<void> syncAll({ConflictStrategy strategy = ConflictStrategy.newerWins});
  Future<void> syncTask(String taskId);
  Future<void> forceFullSync();
  Stream<SyncStatus> get syncStatus;
  void dispose();
}

/// 同步状态
class SyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? currentItem;
  final double progress; // 0.0 - 1.0

  const SyncStatus({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.currentItem,
    this.progress = 0.0,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? currentItem,
    double? progress,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      currentItem: currentItem ?? this.currentItem,
      progress: progress ?? this.progress,
    );
  }
}

/// 同步服务实现
@Injectable(as: SyncService)
class SyncServiceImpl implements SyncService {
  final AppDatabase _database;
  final Connectivity _connectivity;
  
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Timer? _syncTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;

  SyncServiceImpl(this._database, this._connectivity);

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 监听网络状态
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // 网络恢复，触发同步
        syncAll();
      }
    });

    // 定期自动同步
    _syncTimer = Timer.periodic(
      AppConstants.syncInterval,
      (_) => syncAll(),
    );

    _isInitialized = true;
    
    // 初始同步状态
    _updateStatus(const SyncStatus());
  }

  @override
  Future<void> syncAll({ConflictStrategy strategy = ConflictStrategy.newerWins}) async {
    if (_isSyncing) return;
    
    // 检查网络
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _updateStatus(const SyncStatus(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      return;
    }

    _isSyncing = true;
    
    try {
      // 1. 获取待同步的任务
      final tasksToSync = await _database.getTasksToSync();
      final pendingCount = tasksToSync.length;
      
      if (pendingCount == 0) {
        _updateStatus(SyncStatus(
          isSyncing: false,
          lastSyncTime: DateTime.now(),
        ));
        _isSyncing = false;
        return;
      }

      // 2. 逐个同步
      int completedCount = 0;
      for (final task in tasksToSync) {
        _updateStatus(SyncStatus(
          isSyncing: true,
          pendingCount: pendingCount - completedCount,
          currentItem: task.title,
          progress: completedCount / pendingCount,
        ));

        await _syncTask(task, strategy);
        completedCount++;
      }

      // 3. 同步完成
      _updateStatus(SyncStatus(
        isSyncing: false,
        pendingCount: 0,
        lastSyncTime: DateTime.now(),
        progress: 1.0,
      ));

    } catch (e) {
      // 同步失败
      _updateStatus(SyncStatus(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTask(Task task, ConflictStrategy strategy) async {
    // TODO: 实现具体的同步逻辑
    // 1. 检查远程是否有更新
    // 2. 根据冲突策略解决冲突
    // 3. 上传本地更改或合并数据
    // 4. 更新本地同步状态
    
    // 暂时标记为已同步
    await _database.markTaskSynced(task.id);
  }

  @override
  Future<void> syncTask(String taskId) async {
    final task = await _database.getTaskById(taskId);
    if (task != null && task.isDirty) {
      await _syncTask(task, ConflictStrategy.newerWins);
    }
  }

  @override
  Future<void> forceFullSync() async {
    // 重置所有任务的同步状态，强制全量同步
    final allTasks = await _database.getAllTasks();
    for (final task in allTasks) {
      // 标记为需要同步
      // await _database.markTaskDirty(task.id);
    }
    await syncAll();
  }

  @override
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  void _updateStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

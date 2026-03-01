import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/task_model.dart';
import '../local/database.dart';

/// Firebase 远程数据源
@lazySingleton
class FirebaseRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseRemoteDataSource(this._firestore, this._auth);

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _tasksCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('tasks');
  }

  CollectionReference get _projectsCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('projects');
  }

  // ============ 任务同步 ============

  /// 获取远程所有任务
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final snapshot = await _tasksCollection.get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// 监听远程任务变化
  Stream<List<Map<String, dynamic>>> watchTasks() {
    return _tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  /// 上传单个任务
  Future<void> uploadTask(Task task) async {
    await _tasksCollection.doc(task.id).set(task.toJson());
  }

  /// 更新远程任务
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toJson());
  }

  /// 删除远程任务
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  /// 批量上传任务
  Future<void> batchUploadTasks(List<Task> tasks) async {
    final batch = _firestore.batch();
    for (final task in tasks) {
      final doc = _tasksCollection.doc(task.id);
      batch.set(doc, task.toJson());
    }
    await batch.commit();
  }

  // ============ 项目同步 ============

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final snapshot = await _projectsCollection.get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> uploadProject(Map<String, dynamic> project) async {
    await _projectsCollection.doc(project['id']).set(project);
  }

  // ============ 冲突检测 ============

  /// 检测远程是否有更新
  Future<bool> hasRemoteUpdates(String taskId, int localVersion) async {
    final doc = await _tasksCollection.doc(taskId).get();
    if (!doc.exists) return false;
    
    final remoteVersion = doc.data()?['version'] ?? 0;
    return remoteVersion > localVersion;
  }

  /// 获取远程任务
  Future<Map<String, dynamic>?> getRemoteTask(String taskId) async {
    final doc = await _tasksCollection.doc(taskId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }
}

/// Firebase 认证服务
@lazySingleton
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService(this._auth);

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  // 匿名登录（临时使用）
  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }
}
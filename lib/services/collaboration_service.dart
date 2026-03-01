import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/models/task_model.dart';

/// 协作服务 - 处理任务共享和协作功能
@lazySingleton
class CollaborationService {
  final FirebaseFirestore _firestore;

  CollaborationService(this._firestore);

  // ============ 邀请协作 ============

  /// 邀请用户到项目
  Future<void> inviteToProject({
    required String projectId,
    required String email,
    required String invitedBy,
    String? message,
  }) async {
    final projectRef = _firestore.collection('projects').doc(projectId);
    
    // 创建邀请
    final inviteRef = _firestore.collection('invitations').doc();
    await inviteRef.set({
      'id': inviteRef.id,
      'projectId': projectId,
      'projectName': (await projectRef.get()).data()?['name'] ?? '项目',
      'email': email,
      'invitedBy': invitedBy,
      'message': message,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(days: 7)),
    });

    // TODO: 发送邮件通知
  }

  /// 接受邀请
  Future<void> acceptInvitation(String inviteId, String userId) async {
    final inviteRef = _firestore.collection('invitations').doc(inviteId);
    final invite = await inviteRef.get();
    final data = invite.data()!;

    // 添加用户到项目成员
    await _firestore.collection('projects').doc(data['projectId']).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    // 更新邀请状态
    await inviteRef.update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 拒绝邀请
  Future<void> declineInvitation(String inviteId) async {
    await _firestore.collection('invitations').doc(inviteId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ 成员管理 ============

  /// 获取项目成员列表
  Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    final project = await _firestore.collection('projects').doc(projectId).get();
    final memberIds = List<String>.from(project.data()?['members'] ?? []);

    final members = <ProjectMember>[];
    for (final userId in memberIds) {
      final user = await _firestore.collection('users').doc(userId).get();
      if (user.exists) {
        members.add(ProjectMember(
          id: userId,
          name: user.data()?['displayName'] ?? '未知用户',
          email: user.data()?['email'] ?? '',
          avatarUrl: user.data()?['avatarUrl'],
          role: ProjectRole.member,
        ));
      }
    }
    return members;
  }

  /// 移除项目成员
  Future<void> removeMember({
    required String projectId,
    required String userId,
  }) async {
    await _firestore.collection('projects').doc(projectId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  /// 更新成员角色
  Future<void> updateMemberRole({
    required String projectId,
    required String userId,
    required ProjectRole role,
  }) async {
    await _firestore.collection('projects').doc(projectId).collection('roles').doc(userId).set({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ 任务分配 ============

  /// 分配任务给用户
  Future<void> assignTask({
    required String taskId,
    required String userId,
    required String assignedBy,
  }) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'assignedTo': userId,
      'assignedBy': assignedBy,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 取消任务分配
  Future<void> unassignTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'assignedTo': FieldValue.delete(),
      'assignedBy': FieldValue.delete(),
      'assignedAt': FieldValue.delete(),
    });
  }

  /// 获取分配给我的任务
  Stream<List<Task>> watchAssignedTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return Task(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'],
            status: TaskStatus.values[data['status'] ?? 1],
            priority: TaskPriority.values[data['priority'] ?? 0],
            dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
            dueTime: data['dueTime'] != null ? DateTime.parse(data['dueTime']) : null,
            projectId: data['projectId'],
            tags: List<String>.from(data['tags'] ?? []),
            createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
            updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : DateTime.now(),
            assignedTo: data['assignedTo'],
            createdBy: data['createdBy'],
            collaborators: List<String>.from(data['collaborators'] ?? []),
            syncStatus: SyncStatus.synced,
            isDirty: false,
            version: data['version'] ?? 1,
          );
        }).toList());
  }

  // ============ 评论 ============

  /// 添加评论
  Future<void> addComment({
    required String taskId,
    required String userId,
    required String content,
  }) async {
    final commentRef = _firestore.collection('tasks').doc(taskId).collection('comments').doc();
    
    await commentRef.set({
      'id': commentRef.id,
      'taskId': taskId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 发送通知给任务相关人员
    await _sendCommentNotification(taskId, userId, content);
  }

  /// 获取任务评论
  Future<List<TaskComment>> getComments(String taskId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    final comments = <TaskComment>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final user = await _firestore.collection('users').doc(data['userId']).get();
      
      comments.add(TaskComment(
        id: doc.id,
        taskId: taskId,
        userId: data['userId'],
        userName: user.data()?['displayName'] ?? '未知用户',
        userAvatar: user.data()?['avatarUrl'],
        content: data['content'],
        createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: data['updatedAt']?.toDate(),
      ));
    }
    return comments;
  }

  /// 删除评论
  Future<void> deleteComment(String taskId, String commentId) async {
    await _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  // ============ 通知 ============

  Future<void> _sendCommentNotification(String taskId, String authorId, String content) async {
    // TODO: 实现评论通知
  }
}

/// 项目成员
class ProjectMember {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final ProjectRole role;

  const ProjectMember({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
  });
}

enum ProjectRole {
  owner,      // 所有者
  admin,      // 管理员
  member,     // 成员
  viewer,     // 查看者
}

/// 任务评论
class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });
}
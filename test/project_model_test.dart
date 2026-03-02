import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/domain/models/project_model.dart';

void main() {
  group('Project 模型测试', () {
    test('创建基础清单', () {
      final project = Project.create(name: '我的清单');
      
      expect(project.name, '我的清单');
      expect(project.color, ProjectColor.blue);
      expect(project.icon, ProjectIcon.inbox);
      expect(project.id, isNotEmpty);
      expect(project.isDefault, isFalse);
    });

    test('创建带所有属性的清单', () {
      final project = Project.create(
        name: '工作项目',
        color: ProjectColor.red,
        icon: ProjectIcon.work,
        isDefault: true,
      );
      
      expect(project.name, '工作项目');
      expect(project.color, ProjectColor.red);
      expect(project.icon, ProjectIcon.work);
      expect(project.isDefault, isTrue);
    });

    test('Project.copyWith', () {
      final project = Project.create(name: '原名称');
      final copied = project.copyWith(
        name: '新名称',
        color: ProjectColor.green,
      );
      
      expect(copied.name, '新名称');
      expect(copied.color, ProjectColor.green);
      expect(copied.id, project.id); // ID 不变
    });

    test('Project JSON 序列化', () {
      final project = Project.create(name: 'JSON测试');
      final json = project.toJson();
      final restored = Project.fromJson(json);
      
      expect(restored.name, project.name);
      expect(restored.id, project.id);
    });

    test('完成率计算', () {
      final project = Project(
        id: 'test',
        name: '测试',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalTasks: 10,
        completedTasks: 5,
      );
      
      expect(project.completionRate, 0.5);
    });

    test('完成率为0', () {
      final project = Project(
        id: 'test',
        name: '测试',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalTasks: 0,
        completedTasks: 0,
      );
      
      expect(project.completionRate, 0.0);
    });

    test('嵌套清单', () {
      final parent = Project.create(name: '父清单');
      final child = Project.create(
        name: '子清单',
        parentId: parent.id,
      );
      
      expect(parent.parentId, isNull);
      expect(child.parentId, parent.id);
    });
  });

  group('ProjectColor 测试', () {
    test('所有颜色都有 hex 值', () {
      for (final color in ProjectColor.values) {
        expect(color.hexValue, isNotEmpty);
        expect(color.hexValue.startsWith('#'), isTrue);
      }
    });

    test('所有颜色都有 colorValue', () {
      for (final color in ProjectColor.values) {
        expect(color.colorValue, isNonZero);
      }
    });

    test('特定颜色值', () {
      expect(ProjectColor.red.hexValue, '#FF5252');
      expect(ProjectColor.blue.hexValue, '#2196F3');
      expect(ProjectColor.green.hexValue, '#4CAF50');
    });
  });

  group('ProjectIcon 测试', () {
    test('所有图标都有 codePoint', () {
      for (final icon in ProjectIcon.values) {
        expect(icon.iconCodePoint, isNonZero);
      }
    });

    test('所有图标都有名称', () {
      for (final icon in ProjectIcon.values) {
        expect(icon.iconName, isNotEmpty);
      }
    });

    test('特定图标名称', () {
      expect(ProjectIcon.inbox.iconName, 'inbox');
      expect(ProjectIcon.home.iconName, 'home');
      expect(ProjectIcon.work.iconName, 'work');
      expect(ProjectIcon.star.iconName, 'star');
    });
  });

  group('Project 统计测试', () {
    test('更新统计数据', () {
      final project = Project(
        id: 'test',
        name: '测试',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalTasks: 20,
        completedTasks: 15,
        overdueTasks: 2,
      );
      
      expect(project.totalTasks, 20);
      expect(project.completedTasks, 15);
      expect(project.overdueTasks, 2);
      expect(project.completionRate, 0.75);
    });
  });
}
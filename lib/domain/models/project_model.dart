import 'package:drift/drift.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

/// 清单颜色
enum ProjectColor {
  @JsonValue('red')
  red,
  @JsonValue('orange')
  orange,
  @JsonValue('yellow')
  yellow,
  @JsonValue('green')
  green,
  @JsonValue('teal')
  teal,
  @JsonValue('blue')
  blue,
  @JsonValue('indigo')
  indigo,
  @JsonValue('purple')
  purple,
  @JsonValue('pink')
  pink,
  @JsonValue('brown')
  brown,
  @JsonValue('grey')
  grey,
}

/// 清单图标
enum ProjectIcon {
  @JsonValue('inbox')
  inbox,
  @JsonValue('home')
  home,
  @JsonValue('work')
  work,
  @JsonValue('star')
  star,
  @JsonValue('favorite')
  favorite,
  @JsonValue('bookmark')
  bookmark,
  @JsonValue('shopping_cart')
  shoppingCart,
  @JsonValue('fitness_center')
  fitnessCenter,
  @JsonValue('restaurant')
  restaurant,
  @JsonValue('directions_car')
  directionsCar,
  @JsonValue('flight')
  flight,
  @JsonValue('local_hospital')
  localHospital,
  @JsonValue('school')
  school,
  @JsonValue('code')
  code,
  @JsonValue('music_note')
  musicNote,
  @JsonValue('movie')
  movie,
  @JsonValue('sports_esports')
  sportsEsports,
  @JsonValue('pets')
  pets,
  @JsonValue('child_care')
  childCare,
  @JsonValue('fitness_center')
  gym,
  @JsonValue('nature')
  nature,
}

/// 清单/项目数据模型
@freezed
class Project with _$Project {
  const factory Project({
    /// 唯一标识
    required String id,
    
    /// 清单名称
    required String name,
    
    /// 清单颜色
    @Default(ProjectColor.blue) ProjectColor color,
    
    /// 清单图标
    @Default(ProjectIcon.inbox) ProjectIcon icon,
    
    /// 排序顺序
    @Default(0) int sortOrder,
    
    /// 是否默认清单
    @Default(false) bool isDefault,
    
    /// 是否已完成（归档）
    @Default(false) bool isArchived,
    
    /// 父项目ID（支持嵌套清单）
    String? parentId,
    
    /// 创建时间
    required DateTime createdAt,
    
    /// 更新时间
    required DateTime updatedAt,
    
    /// 创建者ID
    String? createdBy,
    
    /// 成员ID列表
    @Default([]) List<String> memberIds,
    
    /// 统计：任务总数
    @Default(0) int totalTasks,
    
    /// 统计：已完成任务数
    @Default(0) int completedTasks,
    
    /// 统计：逾期任务数
    @Default(0) int overdueTasks,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  /// 创建新清单
  factory Project.create({
    required String name,
    ProjectColor color = ProjectColor.blue,
    ProjectIcon icon = ProjectIcon.inbox,
    String? parentId,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return Project(
      id: _generateId(),
      name: name,
      color: color,
      icon: icon,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _generateId() {
    return 'proj_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 获取完成率
  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }
}

/// 获取颜色对应的 hex 值
extension ProjectColorExtension on ProjectColor {
  String get hexValue {
    switch (this) {
      case ProjectColor.red:
        return '#FF5252';
      case ProjectColor.orange:
        return '#FF9800';
      case ProjectColor.yellow:
        return '#FFEB3B';
      case ProjectColor.green:
        return '#4CAF50';
      case ProjectColor.teal:
        return '#009688';
      case ProjectColor.blue:
        return '#2196F3';
      case ProjectColor.indigo:
        return '#3F51B5';
      case ProjectColor.purple:
        return '#9C27B0';
      case ProjectColor.pink:
        return '#E91E63';
      case ProjectColor.brown:
        return '#795548';
      case ProjectColor.grey:
        return '#9E9E9E';
    }
  }

  /// Material Color
  int get colorValue {
    switch (this) {
      case ProjectColor.red:
        return 0xFFFF5252;
      case ProjectColor.orange:
        return 0xFFFF9800;
      case ProjectColor.yellow:
        return 0xFFFFEB3B;
      case ProjectColor.green:
        return 0xFF4CAF50;
      case ProjectColor.teal:
        return 0xFF009688;
      case ProjectColor.blue:
        return 0xFF2196F3;
      case ProjectColor.indigo:
        return 0xFF3F51B5;
      case ProjectColor.purple:
        return 0xFF9C27B0;
      case ProjectColor.pink:
        return 0xFFE91E63;
      case ProjectColor.brown:
        return 0xFF795548;
      case ProjectColor.grey:
        return 0xFF9E9E9E;
    }
  }
}

/// 获取图标对应的 Material Icons code point
extension ProjectIconExtension on ProjectIcon {
  int get iconCodePoint {
    switch (this) {
      case ProjectIcon.inbox:
        return 0xe0e5; // Icons.inbox
      case ProjectIcon.home:
        return 0xe318; // Icons.home
      case ProjectIcon.work:
        return 0xe8f9; // Icons.work
      case ProjectIcon.star:
        return 0xe838; // Icons.star
      case ProjectIcon.favorite:
        return 0xe87d; // Icons.favorite
      case ProjectIcon.bookmark:
        return 0xe8e4; // Icons.bookmark
      case ProjectIcon.shoppingCart:
        return 0xe8cc; // Icons.shopping_cart
      case ProjectIcon.fitnessCenter:
        return 0xeb43; // Icons.fitness_center
      case ProjectIcon.restaurant:
        return 0xe56c; // Icons.restaurant
      case ProjectIcon.directionsCar:
        return 0xe531; // Icons.directions_car
      case ProjectIcon.flight:
        return 0xe539; // Icons.flight
      case ProjectIcon.localHospital:
        return 0xe548; // Icons.local_hospital
      case ProjectIcon.school:
        return 0xe80c; // Icons.school
      case ProjectIcon.code:
        return 0xe86f; // Icons.code
      case ProjectIcon.musicNote:
        return 0xe405; // Icons.music_note
      case ProjectIcon.movie:
        return 0xe02c; // Icons.movie
      case ProjectIcon.sportsEsports:
        return 0xea1b; // Icons.sports_esports
      case ProjectIcon.pets:
        return 0xe91d; // Icons.pets
      case ProjectIcon.childCare:
        return 0xeb41; // Icons.child_care
      case ProjectIcon.gym:
        return 0xeb43; // Icons.fitness_center
      case ProjectIcon.nature:
        return 0xe405; // Icons.nature (using music_note as fallback)
    }
  }

  String get iconName {
    switch (this) {
      case ProjectIcon.inbox:
        return 'inbox';
      case ProjectIcon.home:
        return 'home';
      case ProjectIcon.work:
        return 'work';
      case ProjectIcon.star:
        return 'star';
      case ProjectIcon.favorite:
        return 'favorite';
      case ProjectIcon.bookmark:
        return 'bookmark';
      case ProjectIcon.shoppingCart:
        return 'shopping_cart';
      case ProjectIcon.fitnessCenter:
        return 'fitness_center';
      case ProjectIcon.restaurant:
        return 'restaurant';
      case ProjectIcon.directionsCar:
        return 'directions_car';
      case ProjectIcon.flight:
        return 'flight';
      case ProjectIcon.localHospital:
        return 'local_hospital';
      case ProjectIcon.school:
        return 'school';
      case ProjectIcon.code:
        return 'code';
      case ProjectIcon.musicNote:
        return 'music_note';
      case ProjectIcon.movie:
        return 'movie';
      case ProjectIcon.sportsEsports:
        return 'sports_esports';
      case ProjectIcon.pets:
        return 'pets';
      case ProjectIcon.childCare:
        return 'child_care';
      case ProjectIcon.gym:
        return 'gym';
      case ProjectIcon.nature:
        return 'nature';
    }
  }
}
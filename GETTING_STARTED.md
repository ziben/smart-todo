# Flutter 智能清单应用 - 快速开始指南

## 项目概述

已完成全功能 Flutter 智能清单应用，包含：
- ✅ AI 智能任务拆解
- ✅ 自然语言解析 (NLP)
- ✅ 数据统计分析
- ✅ 日历视图
- ✅ 离线优先架构
- ✅ 主题切换
- ✅ 本地通知

## 环境要求

- Flutter 3.16.0 或更高版本
- Dart 3.0.0 或更高版本
- Android SDK (Android 5.0+) 或 iOS SDK (iOS 12+)

## 快速开始

### 1. 安装依赖

```bash
cd flutter_todo_app
flutter pub get
```

### 2. 生成代码

项目使用了代码生成工具（Drift、Freezed、Injectable），需要运行：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

如果代码有更新，需要重新生成：

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. 运行应用


**Android:**
```bash
flutter run
```

**iOS:** (需要 macOS 和 Xcode)
```bash
flutter run
```

**指定设备:**
```bash
# 查看可用设备
flutter devices

# 指定设备运行
flutter run -d <device_id>
```

### 4. 构建发布版本


**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── core/
│   ├── constants/           # 常量定义
│   ├── theme/              # 主题样式 (Material 3)
│   └── di/                 # 依赖注入
├── data/
│   └── local/              # Drift/SQLite 数据库
├── domain/
│   └── models/             # 数据模型 (Freezed)
├── presentation/
│   ├── bloc/               # BLoC 状态管理
│   ├── screens/            # 页面
│   │   ├── home/           # 首页
│   │   ├── task/           # 任务详情
│   │   ├── calendar/       # 日历视图
│   │   ├── analytics/      # 数据统计
│   │   ├── collaboration/  # 协作分享
│   │   └── settings/       # 设置
│   └── widgets/            # 核心组件
└── services/
    ├── nlp_service.dart    # 自然语言解析
    ├── ai_service.dart     # AI 任务拆解
    ├── sync_service.dart   # 离线同步
    └── notification_service.dart  # 本地通知
```

## 核心功能

### 1. 智能任务添加
- 自然语言输入：`明天下午三点开会 P1`
- 自动解析日期、时间、优先级、标签
- AI 智能任务拆解

### 2. 多维度视图
- 列表视图：筛选、排序、批量操作
- 日历视图：月/周/双周切换
- 统计视图：完成趋势、任务分布、生产力热力图

### 3. 离线优先
- 本地 SQLite 数据库
- 自动同步队列
- 冲突解决策略

### 4. 智能提醒
- 基于时间提醒
- 基于位置提醒（待实现）
- 智能最佳时间推荐

## 开发调试

### 重置数据库
```bash
# 删除应用数据后重新安装
# 或在代码中调用
await database.deleteEverything();
```

### 查看日志
```bash
flutter logs
```

### 性能分析
```bash
flutter run --profile
flutter build apk --analyze-size
```

## 常见问题

### Q: 代码生成失败？
A: 确保安装了 build_runner：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Q: 数据库迁移？
A: 修改 `database.dart` 中的 `schemaVersion` 并在 `migration` 中处理升级逻辑。

### Q: 主题不生效？
A: 确保使用了 `Theme.of(context)` 获取主题，并检查 `MaterialApp` 的 `theme` 和 `darkTheme` 配置。

## 下一步

- [ ] 接入 Firebase 实现云同步
- [ ] 添加单元测试和集成测试
- [ ] 实现地理位置提醒
- [ ] 添加语音输入功能
- [ ] 优化列表性能和动画

## 反馈与支持

如有问题或建议，请提交 Issue 或联系开发团队。

---

**当前版本**: 1.0.0  
**最后更新**: 2024-02-27
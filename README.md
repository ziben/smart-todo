# 智能清单应用 (Smart To-Do App)

基于 Flutter 的全栈生产力调度应用，支持离线优先架构。

## 核心特性

- **离线优先 (Offline-First)**: 本地 SQLite 数据库，支持完全无网络使用
- **自然语言解析 (NLP)**: 智能识别 "明天下午三点跟进项目 P1"
- **多维度视图**: 列表、日历、时间轴、看板
- **层级任务**: 无限子任务支持
- **实时协作**: 基于 Firebase 的多人同步
- **智能提醒**: 时间 + 地理位置触发

## 架构

```
lib/
├── core/                    # 核心配置
│   ├── constants/
│   ├── theme/
│   └── router/
├── data/                    # 数据层
│   ├── local/              # SQLite / Hive
│   ├── remote/             # Firebase / REST API
│   └── repositories/
├── domain/                  # 领域层
│   ├── models/             # Entity
│   └── usecases/           # 业务逻辑
├── presentation/            # 表现层
│   ├── bloc/               # 状态管理
│   ├── screens/
│   └── widgets/
└── services/               # 服务
    ├── nlp_service.dart    # 自然语言处理
    ├── sync_service.dart   # 数据同步
    └── notification_service.dart
```

## 技术栈

- **Framework**: Flutter 3.x
- **State Management**: Bloc / Riverpod
- **Local DB**: Drift (SQLite) + Hive
- **Remote**: Firebase (Firestore, Auth, FCM)
- **NLP**: 本地正则 + 云端 NLP API
- **Calendar**: table_calendar
- **图表**: fl_chart

## Getting Started

```bash
flutter pub get
flutter run
```

## 构建配置

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web (PWA)
flutter build web --release
```
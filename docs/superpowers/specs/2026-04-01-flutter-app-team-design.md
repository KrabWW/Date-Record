# Flutter App Team Collaboration Design

## Overview

基于现有 web 项目（React + Express）和 Figma 原型，使用团队协作模式并行开发 Flutter 版 Love4Lili 情侣约会记录 app。目标平台 iOS + Android，连接现有 Express 后端 API。

## Tech Stack

- **Framework**: Flutter 3.x + Dart
- **State Management**: Riverpod (flutter_riverpod)
- **Routing**: go_router
- **Networking**: dio (JWT interceptor)
- **Local Storage**: flutter_secure_storage (token persistence)
- **Images**: cached_network_image + image_picker
- **Video**: video_player + file_picker

## Architecture

```
flutter_app/lib/
├── main.dart                    # Entry + ProviderScope
├── app.dart                     # MaterialApp + GoRouter
├── config/
│   ├── theme.dart               # Pink gradient theme (match Figma)
│   ├── routes.dart              # Route definitions + auth guard
│   └── api_config.dart          # Backend URL config
├── services/
│   ├── api_client.dart          # Dio wrapper + JWT interceptor
│   ├── auth_service.dart        # Auth API calls
│   ├── couple_service.dart      # Couple space API
│   ├── record_service.dart      # Date records API
│   └── media_service.dart       # Media upload API
├── providers/
│   ├── auth_provider.dart       # Auth state (Riverpod)
│   ├── couple_provider.dart     # Couple state
│   └── record_provider.dart     # Records state
├── models/
│   ├── user.dart
│   ├── couple.dart
│   ├── record.dart
│   └── media.dart
├── pages/
│   ├── auth/                    # Login/Register
│   ├── home/                    # Dashboard
│   ├── records/                 # List/Detail/Edit
│   ├── gallery/                 # Photo/Video gallery
│   ├── profile/                 # Profile/Settings
│   └── couple_setup/            # Create/Join couple space
├── widgets/
│   ├── bottom_navigation.dart
│   ├── mood_selector.dart
│   ├── emotion_tags.dart
│   ├── media_upload.dart
│   └── storage_info.dart
└── utils/
    ├── date_formatter.dart
    └── validators.dart
```

## Figma Design Reference

File key: `vBp8XfCMyMcSYS8EB87u2k`

Key pages:
- **HomePage** (15:3): Couple info, day counter (216), recent records, quick actions
- **Auth** (25:282, 25:547, 25:605): Login, register, welcome
- **CoupleSetup** (25:703, 25:788, 25:860): Create/join space
- **Gallery** (25:1070): Photo/video grid, storage stats
- **Records** (38:3, 44:3, 45:3): Record list, detail, add form
- **Profile** (46:2): User info, couple space, storage, settings

Bottom navigation: 首页 / 记录 / 相册 / 我的

Color palette: Pink/purple gradients, soft cream backgrounds, romantic theme

Mood system: 5-level emoji (loving, happy, good, okay, meh)

## Team Structure & Execution

### Phase 1: Architect (blocking)

搭建项目骨架：
- Flutter project init + pubspec.yaml
- Theme system (pink gradients matching Figma)
- go_router config with auth guard
- Dio API client (baseURL, JWT interceptor, error handling)
- Riverpod provider skeletons
- All model class definitions
- Bottom navigation widget
- main.dart + app.dart entry points

**Output**: Compilable shell app with placeholder pages

### Phase 2: Parallel Feature Development (5 agents)

| Agent | Scope | References |
|-------|-------|------------|
| auth-dev | Login/Register + Couple Setup pages | Figma Auth/CoupleSetup + web AuthPage/CoupleSetupPage/AuthContext |
| home-dev | Dashboard (day counter, recent records, quick actions) | Figma HomePage + web HomePage |
| record-dev | Record list/detail/edit + mood selector + emotion tags | Figma Records + web RecordsPage/RecordEditPage/MoodSelector/EmotionTags |
| gallery-dev | Gallery browse/upload + storage management | Figma Gallery + web GalleryPage/MediaGallery/MediaUpload |
| profile-dev | Profile + Settings + Couple space management | Figma Profile + web ProfilePage/SettingsPage |

Each agent: Read Figma design -> Reference web code logic -> Write Flutter pages + wire providers

### Phase 3: Integration

- Merge all agent code
- End-to-end testing
- Fix integration issues

## Feature Scope (Phase 1 - Full Feature)

1. **Auth**: Register/Login with email/password, JWT token management, auto-login
2. **Couple Space**: Create space with name + anniversary, join via invite code, day counter
3. **Date Records**: CRUD with mood (5 levels), emotion tags (JSON), location, search/filter
4. **Gallery**: Photo/video upload with captions, grid view, storage tracking (1GB quota)
5. **Profile**: User info, couple details, storage stats, settings, logout

## Backend API Endpoints (existing)

- `/api/auth/*` - register, login, me, logout, profile update
- `/api/couples/*` - create, join, get current, update, delete
- `/api/records/*` - CRUD, stats
- `/api/upload/*` - upload photo/video, get media, delete, storage info

## Data Models

```dart
// User: id, email, name, avatarUrl, isVip, usedStorage
// Couple: id, user1Id, user2Id, coupleName, inviteCode, anniversaryDate
// Record: id, coupleId, createdBy, title, description, recordDate, location, mood, emotionTags, tags
// Media: id, coupleId, recordId, fileUrl, fileType, caption, fileSize, duration, thumbnailUrl
```

## Constraints

- Must connect to existing Express backend (no new backend)
- Target iOS + Android
- Match Figma design fidelity (pink gradient theme)
- Chinese UI (中文界面)
- JWT auth flow matching web version

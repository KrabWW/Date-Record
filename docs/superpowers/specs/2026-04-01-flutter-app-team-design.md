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
- **Testing**: flutter_test + mockito

## Architecture

```
flutter_app/lib/
├── main.dart                    # Entry + ProviderScope
├── app.dart                     # MaterialApp + GoRouter
├── config/
│   ├── theme.dart               # Pink gradient theme (match Figma)
│   ├── routes.dart              # Route definitions + auth guard + couple guard
│   ├── api_config.dart          # Backend URL config
│   └── constants.dart           # Mood values, emotion tags catalog
├── services/
│   ├── api_client.dart          # Dio wrapper + JWT interceptor
│   ├── auth_service.dart        # Auth API calls
│   ├── couple_service.dart      # Couple space API
│   ├── record_service.dart      # Date records API
│   ├── wishlist_service.dart    # Wishlist API calls
│   └── media_service.dart       # Media upload API
├── providers/
│   ├── auth_provider.dart       # Auth state (Riverpod)
│   ├── couple_provider.dart     # Couple state
│   ├── record_provider.dart     # Records state
│   └── wishlist_provider.dart   # Wishlist state
├── models/
│   ├── user.dart
│   ├── couple.dart
│   ├── record.dart
│   ├── wishlist.dart
│   └── media.dart
├── pages/
│   ├── auth/                    # Login/Register
│   ├── home/                    # Dashboard
│   ├── records/                 # List/Detail/Edit
│   ├── wishlists/               # Wishlist list/detail
│   ├── gallery/                 # Photo/Video gallery
│   ├── profile/                 # Profile/Settings
│   └── couple_setup/            # Create/Join couple space
├── widgets/
│   ├── bottom_navigation.dart   # Bottom nav: 首页/记录/相册/我的
│   ├── mood_selector.dart       # 5-level mood picker (shared)
│   ├── emotion_tags.dart        # 17 emotion tags (shared)
│   ├── media_upload.dart        # Photo/video upload
│   ├── storage_info.dart        # Storage usage bar
│   └── loading_error.dart       # Loading/error/empty states
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

## Mood System

5-level mood values (matching database CHECK constraint):
| Value | Chinese | Emoji |
|-------|---------|-------|
| amazing | 超开心 | 🥰 |
| happy | 很开心 | 😊 |
| good | 开心 | 😌 |
| okay | 一般 | 😐 |
| meh | 不太好 | 😕 |

## Emotion Tags Catalog

17 tags with Chinese labels, emojis, and colors (from web EmotionTags.jsx):

| ID | Label | Emoji |
|----|-------|-------|
| romantic | 浪漫 | 💕 |
| fun | 有趣 | 🎉 |
| peaceful | 安静 | 🍃 |
| exciting | 刺激 | ⚡ |
| cozy | 温馨 | 🏠 |
| adventurous | 冒险 | 🏔️ |
| relaxing | 放松 | ☕ |
| sweet | 甜蜜 | 🍬 |
| surprise | 惊喜 | 🎁 |
| intimate | 亲密 | 💑 |
| sweetness_overload | 甜到掉牙 | 🍰 |
| heart_flutter | 心动 | 💓 |
| roller_coaster | 跌宕起伏 | 🎢 |
| after_rain | 雨过天晴 | 🌈 |
| healing | 治愈 | 🌿 |
| looking_forward | 期待 | ✨ |
| disappointing | 失望 | 💔 |

## Team Structure & Execution

### Phase 1: Architect (blocking)

搭建项目骨架 + 共享组件：
- Flutter project init + pubspec.yaml
- Theme system (pink gradients matching Figma)
- go_router config with auth guard (checks token) + couple guard (checks couple exists)
- Dio API client (baseURL, JWT interceptor, error handling)
- Riverpod provider skeletons (all providers)
- All model class definitions (with full field lists, see Data Models)
- **Shared widgets** (bottom_navigation, mood_selector, emotion_tags, loading_error, storage_info)
- main.dart + app.dart entry points
- constants.dart with mood values and emotion tags catalog

**Output**: Compilable shell app with placeholder pages + all shared widgets ready

### Phase 2: Parallel Feature Development (6 agents)

| Agent | Scope | References |
|-------|-------|------------|
| auth-dev | Login/Register + Couple Setup pages | Figma Auth/CoupleSetup + web AuthPage/CoupleSetupPage/AuthContext |
| home-dev | Dashboard (day counter, recent records, wishlist stats, quick actions) | Figma HomePage + web HomePage |
| record-dev | Record list/detail/edit (uses shared mood_selector + emotion_tags) | Figma Records + web RecordsPage/RecordEditPage |
| gallery-dev | Gallery browse/upload + storage management | Figma Gallery + web GalleryPage/MediaGallery/MediaUpload |
| profile-dev | Profile + Settings + Couple space management | Figma Profile + web ProfilePage/SettingsPage |
| wishlist-dev | Wishlist CRUD + priorities + completion tracking + convert to record | web WishlistPage |

Each agent: Read Figma design -> Reference web code logic -> Write Flutter pages + wire providers

### Phase 3: Integration

- Merge all agent code
- End-to-end testing (auth flow -> couple setup -> record CRUD -> gallery -> wishlist)
- Fix integration issues

## Feature Scope (Phase 1 - Full Feature)

1. **Auth**: Register/Login with email/password, JWT token management, auto-login
2. **Couple Space**: Create space with name + anniversary, join via invite code, day counter
3. **Date Records**: CRUD with mood (5 levels), emotion tags (17 tags), location, search/filter
4. **Wishlist**: CRUD with priority (1-5), completion tracking, convert wish to record
5. **Gallery**: Photo/video upload with captions, grid view, storage tracking (1GB quota)
6. **Profile**: User info, couple details, storage stats, settings, logout

## Error Handling Strategy

Match web app patterns:
- **Network errors**: Check `error.response` existence, show "网络连接失败" message
- **401 Unauthorized**: Clear stored token, redirect to login page
- **Loading states**: Show shimmer/skeleton loading on all list pages
- **Empty states**: Show illustration + CTA text when no data
- **Retry**: Error views include retry button that re-triggers the provider

## Backend API Endpoints & Response Shapes

### Auth
- `POST /api/auth/register` → `{ message, token, user }` (user: id, email, name, avatar_url, is_vip, used_storage, vip_expires_at, created_at, updated_at)
- `POST /api/auth/login` → `{ message, token, user }`
- `GET /api/auth/me` → `{ user }` (full user row minus password_hash)
- `PUT /api/auth/profile` → `{ message, user }`

### Couples
- `POST /api/couples` → `{ message, couple }`
- `POST /api/couples/join` → `{ message, couple }`
- `GET /api/couples/me` → `{ couple }` (includes joined: user1_name, user1_email, user2_name, user2_email)
- `PUT /api/couples/:id` → `{ message, couple }`

### Records
- `GET /api/records` → `{ records: [...], pagination: { current_page, total_pages, total_records, has_next, has_prev } }`
- `GET /api/records/:id` → `{ record }` (includes photos array)
- `POST /api/records` → `{ message, record }`
- `PUT /api/records/:id` → `{ message, record }`
- `DELETE /api/records/:id` → `{ message }`
- `GET /api/records/stats/summary` → `{ total_records, recent_records, monthly_stats, mood_distribution, top_emotion_tags }`

### Wishlists
- `GET /api/wishlists` → `{ wishlists }`
- `POST /api/wishlists` → `{ message, wishlist }`
- `PUT /api/wishlists/:id` → `{ message, wishlist }`
- `DELETE /api/wishlists/:id` → `{ message }`
- `PUT /api/wishlists/:id/toggle` → `{ message, wishlist }`
- `POST /api/wishlists/:id/convert` → `{ message, record }`

### Upload
- `POST /api/upload/photo` → formData fields: `photo` (file), `couple_id`, `record_id`, `caption` → `{ success, mediaId, fileUrl, fileType }`
- `POST /api/upload/video` → formData field: `video` (file) → `{ success, mediaId, fileUrl, thumbnailUrl }`
- `GET /api/upload/media` → `{ media }`
- `DELETE /api/upload/media/:id` → `{ message }`
- `GET /api/upload/storage-info` → `{ isVip, maxStorage, usedStorage, availableStorage, usagePercentage, limits }`

## Data Models (complete field lists)

```dart
class User {
  final int id;
  final String email;
  final String name;
  final String? avatarUrl;
  final bool isVip;
  final int usedStorage;
  final DateTime? vipExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Couple {
  final int id;
  final int user1Id;
  final int? user2Id;
  final String coupleName;
  final String inviteCode;
  final DateTime? anniversaryDate;
  // Joined fields from GET /couples/me
  final String? user1Name;
  final String? user1Email;
  final String? user2Name;
  final String? user2Email;
}

class Record {
  final int id;
  final int coupleId;
  final int createdBy;
  final String title;
  final String? description;
  final DateTime recordDate;
  final String? location;
  final String? mood; // amazing|happy|good|okay|meh
  final List<String>? emotionTags; // JSON array
  final List<String>? tags; // JSON array
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Media>? photos;
}

class Wishlist {
  final int id;
  final int coupleId;
  final String title;
  final String? description;
  final int priority; // 1-5
  final bool isCompleted;
  final DateTime? targetDate;
  final DateTime? completedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Media {
  final int id;
  final int coupleId;
  final int? recordId;
  final String fileUrl;
  final String fileType; // photo|video
  final String? caption;
  final int? fileSize;
  final double? duration;
  final String? thumbnailUrl;
}
```

## Couple Access Middleware

Server middleware `validateCoupleAccess` runs on protected endpoints. It:
1. Checks user has an associated couple
2. Adds `req.couple` to the request context

Flutter routing must enforce:
- **Auth guard**: No token → redirect to login
- **Couple guard**: Token exists but no couple → redirect to couple setup page

## Media Upload Specification

- Photos: multipart/form-data, field name `photo`, max 10MB, accepted: jpg/png/webp
- Videos: multipart/form-data, field name `video`, max 100MB
- Video thumbnails generated server-side by FFmpeg
- Storage quota: 1GB (non-VIP), shown via `/api/upload/storage-info`

## Testing Strategy

- **Unit tests**: Models, services (with mocked dio), providers
- **Widget tests**: Individual widgets (MoodSelector, EmotionTags, etc.)
- **Integration tests**: Full auth flow, record CRUD
- Test files mirror lib/ structure in `test/` directory

## Constraints

- Must connect to existing Express backend (no new backend)
- Target iOS + Android
- Match Figma design fidelity (pink gradient theme)
- Chinese UI (中文界面)
- JWT auth flow matching web version
- File size limits: photos 10MB, videos 100MB

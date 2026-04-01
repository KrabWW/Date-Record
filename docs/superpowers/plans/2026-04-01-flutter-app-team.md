# Flutter App Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development to implement this plan.

**Goal:** Build a full-featured Flutter app for Love4Lili using team of 7 parallel agents

**Architecture:** Flutter + Riverpod + go_router + dio, connecting to existing Express backend

**Tech Stack:** Flutter 3.x, Riverpod, go_router, dio, flutter_secure_storage

---

## Phase 1: Architect (blocking - must complete first)

### Task 1: Project Initialization

**Files:**
- Create: `flutter_app/pubspec.yaml`
- Create: `flutter_app/lib/main.dart`
- Create: `flutter_app/lib/app.dart`

- [ ] Initialize Flutter project with dependencies: flutter_riverpod, go_router, dio, flutter_secure_storage, cached_network_image, image_picker, video_player, file_picker, intl
- [ ] Create main.dart with ProviderScope wrapper
- [ ] Create app.dart with MaterialApp + GoRouter skeleton
- [ ] Run `flutter create` and verify project compiles

### Task 2: Theme & Constants

**Files:**
- Create: `flutter_app/lib/config/theme.dart`
- Create: `flutter_app/lib/config/constants.dart`
- Create: `flutter_app/lib/config/api_config.dart`

- [ ] Create pink gradient theme matching Figma (love-pink #FF6B9D, love-purple #C084FC)
- [ ] Define mood options: amazing/happy/good/okay/meh with emojis and colors
- [ ] Define 17 emotion tags with labels, emojis, colors
- [ ] Set API base URL config

### Task 3: Data Models

**Files:**
- Create: `flutter_app/lib/models/user.dart`
- Create: `flutter_app/lib/models/couple.dart`
- Create: `flutter_app/lib/models/record.dart`
- Create: `flutter_app/lib/models/wishlist.dart`
- Create: `flutter_app/lib/models/media.dart`

- [ ] User model: id, email, name, avatarUrl, isVip, usedStorage, vipExpiresAt, createdAt, updatedAt
- [ ] Couple model: id, user1Id, user2Id, coupleName, inviteCode, anniversaryDate, user1Name, user1Email, user2Name, user2Email
- [ ] Record model: id, coupleId, createdBy, title, description, recordDate, location, mood, emotionTags, tags, photos, createdAt, updatedAt
- [ ] Wishlist model: id, coupleId, title, description, priority, isCompleted, targetDate, completedDate
- [ ] Media model: id, coupleId, recordId, fileUrl, fileType, caption, fileSize, duration, thumbnailUrl

### Task 4: API Client & Services

**Files:**
- Create: `flutter_app/lib/services/api_client.dart`
- Create: `flutter_app/lib/services/auth_service.dart`
- Create: `flutter_app/lib/services/couple_service.dart`
- Create: `flutter_app/lib/services/record_service.dart`
- Create: `flutter_app/lib/services/wishlist_service.dart`
- Create: `flutter_app/lib/services/media_service.dart`

- [ ] Dio client with JWT interceptor, 401 redirect, network error handling
- [ ] Auth service: register, login, getMe, updateProfile, logout
- [ ] Couple service: create, join, getCurrent, update, delete
- [ ] Record service: getAll (paginated), getById, create, update, delete, getStats
- [ ] Wishlist service: getAll, create, update, delete, toggleComplete, convertToRecord
- [ ] Media service: uploadPhoto (multipart), uploadVideo (multipart), getMedia, deleteMedia, getStorageInfo

### Task 5: Providers

**Files:**
- Create: `flutter_app/lib/providers/auth_provider.dart`
- Create: `flutter_app/lib/providers/couple_provider.dart`
- Create: `flutter_app/lib/providers/record_provider.dart`
- Create: `flutter_app/lib/providers/wishlist_provider.dart`

- [ ] Auth provider: login, register, logout, user state, token persistence
- [ ] Couple provider: couple state, createCouple, joinCouple, getPartner
- [ ] Record provider: records list, current record, stats, CRUD operations
- [ ] Wishlist provider: wishlists list, CRUD, toggle, convert

### Task 6: Shared Widgets & Navigation

**Files:**
- Create: `flutter_app/lib/widgets/bottom_navigation.dart`
- Create: `flutter_app/lib/widgets/mood_selector.dart`
- Create: `flutter_app/lib/widgets/emotion_tags.dart`
- Create: `flutter_app/lib/widgets/loading_error.dart`
- Create: `flutter_app/lib/widgets/storage_info.dart`
- Create: `flutter_app/lib/config/routes.dart`

- [ ] Bottom navigation: 首页/记录/相册/我的
- [ ] Mood selector: 5-level emoji picker with labels (from web MoodSelector.jsx)
- [ ] Emotion tags: 17 tags, max 3 selection (from web EmotionTags.jsx)
- [ ] Loading/error/empty state widgets
- [ ] Storage info bar widget
- [ ] Routes with auth guard + couple guard, all placeholder pages

---

## Phase 2: Parallel Feature Agents (6 agents, run simultaneously)

### Task 7: Auth Pages (auth-dev)

**Files:**
- Create: `flutter_app/lib/pages/auth/login_page.dart`
- Create: `flutter_app/lib/pages/auth/register_page.dart`
- Create: `flutter_app/lib/pages/couple_setup/couple_setup_page.dart`
- Create: `flutter_app/lib/pages/couple_setup/create_couple_page.dart`
- Create: `flutter_app/lib/pages/couple_setup/join_couple_page.dart`

- Reference: Figma nodes 25:282, 25:547, 25:605, 25:703, 25:788, 25:860
- Reference: web AuthPage.jsx, CoupleSetupPage.jsx, AuthContext.jsx
- [ ] Login page: email/password fields, toggle to register, error handling
- [ ] Register page: name/email/password fields, toggle to login
- [ ] Couple setup: create/join mode selection
- [ ] Create couple: couple name + anniversary date form
- [ ] Join couple: invite code input
- [ ] Wire all pages to auth_provider and couple_provider

### Task 8: Home Page (home-dev)

**Files:**
- Create: `flutter_app/lib/pages/home/home_page.dart`

- Reference: Figma node 15:3, web HomePage.jsx
- [ ] Couple welcome banner with day counter
- [ ] Quick action buttons (add record, wishlist, gallery)
- [ ] Recent records list with mood display
- [ ] Monthly statistics section
- [ ] Empty state for new users
- [ ] Wire to couple_provider, record_provider

### Task 9: Record Pages (record-dev)

**Files:**
- Create: `flutter_app/lib/pages/records/records_page.dart`
- Create: `flutter_app/lib/pages/records/record_detail_page.dart`
- Create: `flutter_app/lib/pages/records/record_edit_page.dart`

- Reference: Figma nodes 38:3, 44:3, 45:3, web RecordsPage/RecordDetailPage/RecordEditPage
- [ ] Records list: search bar, filters (all/recent/mood), record cards with mood+tags
- [ ] Record detail: full record view with photos, mood, tags, location
- [ ] Record edit: form with title/date/location/description + mood_selector + emotion_tags + custom tags
- [ ] Wire to record_provider, use shared mood_selector and emotion_tags widgets

### Task 10: Gallery Page (gallery-dev)

**Files:**
- Create: `flutter_app/lib/pages/gallery/gallery_page.dart`
- Create: `flutter_app/lib/widgets/media_upload.dart`

- Reference: Figma node 25:1070, web GalleryPage/MediaGallery/MediaUpload
- [ ] Grid/list view toggle for media
- [ ] Filter: all/photos/videos
- [ ] Upload button with image_picker/file_picker
- [ ] Media preview modal
- [ ] Storage stats display (photo count, video count, total size)
- [ ] Delete media functionality
- [ ] Wire to media_service, storage_info widget

### Task 11: Profile Page (profile-dev)

**Files:**
- Create: `flutter_app/lib/pages/profile/profile_page.dart`
- Create: `flutter_app/lib/pages/profile/settings_page.dart`

- Reference: Figma node 46:2, web ProfilePage/SettingsPage
- [ ] User info card with avatar
- [ ] Couple space info with partner details
- [ ] Invite code display with copy
- [ ] Storage usage bar
- [ ] Settings: profile edit, couple management, privacy
- [ ] Logout button
- [ ] Wire to auth_provider, couple_provider

### Task 12: Wishlist Page (wishlist-dev)

**Files:**
- Create: `flutter_app/lib/pages/wishlists/wishlist_page.dart`

- Reference: web WishlistPage.jsx
- [ ] Wishlist list with priority color coding (1-5)
- [ ] Filter: all/pending/completed
- [ ] Add/edit modal: title, description, priority, target date
- [ ] Toggle completion with checkmark
- [ ] Overdue indicator for past target dates
- [ ] Convert wish to record action
- [ ] Wire to wishlist_provider

---

## Phase 3: Integration

### Task 13: Integration & Testing

- [ ] Merge all agent code
- [ ] Verify all routes work end-to-end
- [ ] Test auth flow: register → couple setup → home
- [ ] Test CRUD: create record → view → edit → delete
- [ ] Test media: upload photo → view in gallery → delete
- [ ] Test wishlist: create → complete → convert to record
- [ ] Fix any compilation errors or integration issues

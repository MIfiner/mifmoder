# LIGHTGRAM V2 — COMPLETE FEATURE GUIDE

## 1. Design System & Theme
- **AMOLED Black (`#000000`) & Deep Graphite (`#121214`)**: Pure black backgrounds optimized for iPhone OLED displays to minimize battery consumption.
- **Card Surface (`#1C1C1E`) & Elevated Cards (`#252528`)**: Distinct hierarchical surface separation with subtle `#2C2C2E` borders.
- **Signature LightGram Electric Amber (`#EDB400` / `#FFC700`)**: Vibrant brand accent applied across interactive elements, badges, toggles, and highlights.
- **Unified Corner Radii**: 16pt cards, 18pt message bubbles, 12pt inputs/buttons, 20pt badges/pills.
- **Haptic Feedback**: Context-aware physical tactile feedback (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, `UISelectionFeedbackGenerator`).

## 2. Inline Spy Mode (Anti-Recall)
- **Inline Deleted Messages**:
  - Remote deletions from peers and channel admins do not erase messages from your chat.
  - Messages remain in their exact chronological position in the chat.
  - Styled with a crimson border (`#FF3B30`), crimson background tint, and a `🔴 DELETED MESSAGE` header badge.
  - Media (photos, videos, voice notes, stickers, files) remains cached and viewable.
- **Inline Edited Messages**:
  - Previous text versions remain directly attached to edited messages.
  - Highlighted with an amber border (`#EDB400`) and a `🟡 EDITED [Rev X]: "..."` banner.
  - Supports multiple sequential revisions (Rev 1, Rev 2, Rev 3...).
  - Full revision timeline viewable via context menu or Spy Archive.
- **Dedicated Spy Archive**:
  - Comprehensive secondary viewer with tabs for Deleted Messages and Edit History.
  - Real-time search across text, sender names, and chat titles.
  - Chat filtering action sheet, individual record deletion, and complete archive wipe.

## 3. Ghost Mode 2.0
- **Don't Send Read Receipts**: View and scroll messages without sending read acknowledgements to the peer.
- **Hide Typing Status**: Suppresses typing, recording voice, and uploading media indicators.
- **Stealth Online Presence**: Maintains offline status on the Telegram network while actively using the client.
- **Stealth Story Views**: View stories without leaving your profile in the viewers list.
- **Mark as Read on Reply**: Automatically marks a conversation as read when you choose to send a reply.

## 4. Smart Folders
- Preconfigured tabs: All Chats, Unread, Personal (DMs), Groups, Channels, Bots, Work, Important, Archived.
- Custom toggle switches to enable/disable specific tabs.
- Drag-and-drop reordering with persistent JSON configuration.
- Optional auto-sorting to surface unread conversations to the top.

## 5. Message Tools
- **Save to Personal Notes**: Save any message directly into your private local notes collection via the context menu.
- **Set Message Reminders**: Schedule reminder alerts for follow-up on critical messages.
- **Notes & Reminders Hub**: Manage, search, complete, and delete saved notes and scheduled reminders.
- **Quick Copy**: One-tap text copying directly from context menus and detail cards.

## 6. Media Center
- Storage breakdown with dynamic size calculation (KB / MB / GB).
- Dedicated categories: Photos & Images, Videos & Reels, Documents & Files, Voice Messages, Shared Links, Music & Audio.
- Quick cache clearing tool to free up device space without losing chat history.

## 7. Bot Manager & Group Tools
- Curated favorite bot shortcuts palette (@wallet, @botfather, @stickers, @gif, @vote).
- Group administrator quick audit utilities (privileges, admin logs, pinned messages center, slow mode).

## 8. Privacy & Security Center
- **Biometric Archive Lock**: Require Face ID / Touch ID authentication to access the Spy Archive and private notes.
- **Notification Privacy**: Hide message sender and preview on lock screen.
- **Data Retention TTL**: Configurable storage life (7, 14, 30, 60, 90, 365 days) with automatic pruning.
- **JSON Export**: Export captured deleted and edited records as portable JSON files.

# LightGram V2 — Known Limitations & Edge Cases

## 1. Overview

While LightGram V2 provides inline message anti-recall, network privacy suppression, and extended productivity tools, certain edge cases are governed by the fundamental constraints of MTProto 2.0 protocol and iOS sandbox restrictions. This document outlines those limitations.

---

## 2. Protocol & Synchronization Limitations

### 2.1 Messages Sent and Deleted While LightGram Was Completely Offline
* **Scenario:** User B sends a message to User A at 10:00. At 10:05, User B deletes the message for everyone. User A only opens LightGram at 11:00.
* **Behavior:** When LightGram opens, it requests `updates.getDifference(pts: ..., date: ...)`. The Telegram DC returns the current channel state without including the ephemeral message that no longer exists in server storage.
* **Explanation:** A client cannot preserve a message it never received over the MTProto transport. For Spy Mode to retain a message, LightGram's process or background push notification handler must have received the encrypted packet at least once before deletion occurred.

### 2.2 Server-Side Secret Chat Expiration
* **Scenario:** In an end-to-end encrypted Secret Chat (E2EE), a sender sets a self-destruct timer of 5 seconds.
* **Behavior:** LightGram's Spy Mode retains the message text and media locally in `LightGramSpyManager`. However, if the user manually resets their local database or signs out of the account, secret chat encryption keys (`auth_key` derived for that chat) are discarded by design and cannot be restored from cloud backup.

### 2.3 Supergroup Message Clear ("Clear All History")
* **Scenario:** An administrator of a supergroup with >100,000 messages invokes "Clear Group History for All Members".
* **Behavior:** Telegram servers issue `UpdateDeleteChannelMessages` with a list of message IDs. LightGram marks all locally cached messages within that list as deleted and keeps them inline. However, messages older than the client's local cache horizon (messages not yet scrolled to or downloaded into local SQLite) cannot be retroactively materialized.

### 2.4 Multi-Device Synchronization
* **Scenario:** User reads a deleted message in LightGram on iPhone 13 mini, then opens official Telegram Desktop on macOS or Telegram Web.
* **Behavior:** The deleted message will **not** appear on Telegram Desktop or Web.
* **Explanation:** LightGram's Spy Mode retention is entirely local to the device running LightGram. The Telegram server has officially deleted the message, so other standard clients will not display it.

---

## 3. Storage & iOS Operating System Constraints

### 3.1 Device Storage Management
* **Behavior:** By default, preserving all deleted media (high-definition video, large photo albums, voice notes) consumes disk storage over time.
* **Mitigation in V2:**
  - LightGram includes an integrated **Media Center** (`LightGramMediaCenterController.swift`) and **Privacy Center Retention TTL** (7 to 365 days).
  - Users can configure automatic purging of media older than 30 days while retaining text transcripts indefinitely.
  - One-tap cache cleaning releases disk space without compromising recent anti-recall logs.

### 3.2 iOS Background Execution Budget
* **Behavior:** iOS restricts continuous background execution for third-party applications when not actively playing audio or tracking location.
* **Mitigation in V2:**
  - LightGram utilizes APNs VoIP and silent push notifications (`content-available: 1`) to perform background difference checks before the app is fully terminated by iOS Jetsam memory pressure.

---

## 4. Feature Summary & Recommendations

| Feature | Operational Guarantee | Recommended Best Practice |
| :--- | :--- | :--- |
| **Inline Anti-Recall** | 100% for all delivered messages | Keep background app refresh enabled in iOS Settings. |
| **Ghost Mode 2.0** | 100% suppressed at TL RPC level | Enable "Don't Send Read Receipts" and "Hide Typing". |
| **Media Preservation** | 100% for cached files | Set auto-clean retention to 30 or 60 days in Media Center. |
| **Personal Notes** | Local SQLite + encrypted JSON | Use the built-in JSON export feature for off-device backups. |

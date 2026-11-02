# LightGram V2 — Build & Packaging Specification

## 1. Overview & Build Architecture

LightGram is built using Google Bazel with Apple rules (`rules_apple` and `rules_swift`), targeting iOS 15.0+ with specific hardware optimizations for **iPhone 13 mini (iOS 18.6.2)**.

```
                 +-----------------------------+
                 |    LightGram CI/CD Pipeline |
                 |     GitHub Actions Runner   |
                 |      macOS-15-arm64         |
                 +--------------+--------------+
                                |
                                v
               +--------------------------------+
               | Xcode 16.4 Toolchain Selection |
               | Swift 6.0 / Apple Clang 16     |
               +----------------+---------------+
                                |
                                v
         +--------------------------------------------+
         | Bazel Build: //Telegram:Telegram (-c opt)  |
         | Submodules: LightGramCore, TelegramUI, etc.|
         +----------------------+---------------------+
                                |
                                v
                 +-----------------------------+
                 | IPA Packaging & CodeSign    |
                 | Mach-O arm64 binary         |
                 | Payload/Telegram.app        |
                 +--------------+--------------+
                                |
                                v
                 +-----------------------------+
                 | Release Asset Deployment    |
                 | GitHub Actions + Release v2 |
                 +-----------------------------+
```

---

## 2. Toolchain & Environment Specifications

| Component | Specification |
| :--- | :--- |
| **Operating System** | macOS 15.x Sequoia (Hosted Apple Silicon arm64 runner) |
| **Xcode Version** | Xcode 16.4 (Build 16E140) selected via `xcode-select` |
| **Swift Compiler** | Swift 6.0 (`swift-driver` version 1.115) |
| **Build System** | Bazel 7.x via `tools/bazel` wrapper |
| **Target Architecture** | `arm64` (Apple A15 Bionic for iPhone 13 mini) |
| **Minimum iOS Target** | iOS 15.0 (Running on iOS 18.6.2) |
| **Signing Identity** | Ad-hoc / Development signing with Wildcard Provisioning |

---

## 3. Core Bazel Build Targets

1. **`//Telegram:Telegram`**
   - The primary application bundle containing all submodules, localization strings, asset catalogs, and embedded frameworks.
2. **`//submodules/LightGramCore:LightGramCore`**
   - The modular core library containing:
     - `LightGramDesignSystem.swift`: Visual tokens, AMOLED colors, typography, haptics.
     - `LightGramSettings.swift`: Reactive settings engine.
     - `LightGramNotesManager.swift` & `LightGramNotesController.swift`: Message annotations.
     - `LightGramSmartFoldersController.swift`: Chat categorization.
     - `LightGramMediaCenterController.swift`: Storage auditor.
     - `LightGramBotManagerController.swift`: Quick bot dashboard.
     - `LightGramPrivacyCenterController.swift`: Face ID lock & retention.
     - `LightGramControlCenterController.swift`: Master control center.
3. **`//submodules/TelegramCore:TelegramCore`**
   - Intercepted MTProto synchronization engine and `LightGramSpyManager.swift`.
4. **`//submodules/TelegramUI:TelegramUI`**
   - AsyncDisplayKit / Texture UI layer and inline bubble badges (`ChatMessageBubbleItemNode.swift`).

---

## 4. Build Configuration & Credential Injection

During the CI step `Apply and verify production API credentials`, the workflow dynamically configures:
- `telegram_api_id` = Extracted from GitHub Secret `LIGHTGRAM_API_ID`
- `telegram_api_hash` = Extracted from GitHub Secret `LIGHTGRAM_API_HASH`
- Injected into `Telegram/Telegram-iOS/Config-Fork.xcconfig` and `submodules/TelegramCore/Sources/Network/Network.swift`
- Verification step guarantees `api_id != 8` (no fallback to revoked sample ID).

---

## 5. Artifact Verification & Mach-O Integrity

The IPA validation script checks:
1. `unzip -q LightGram-V1.ipa -d ipa_contents`
2. Binary inspection: `file ipa_contents/Payload/Telegram.app/Telegram`
   - Output must contain: `Mach-O 64-bit executable arm64`.
3. Asset presence:
   - `LightGram.bundle` or compiled resources.
   - Info.plist `CFBundleIdentifier = org.telegram.Telegram-iOS` (or custom fork identifier).
4. Signature verification: `codesign --verify --deep --strict ipa_contents/Payload/Telegram.app`.

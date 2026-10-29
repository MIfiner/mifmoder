# LightGram V1 — Руководство по сборке и установке

Данный документ содержит полное руководство по сборке IPA-пакета **LightGram V1** через GitHub Actions или локальный macOS-раннер, настройке секретов и установке приложения на iPhone через современные методы sideloading.

---

## 1. Архитектура и ключевые компоненты

LightGram V1 построен на базе официального репозитория `TelegramMessenger/Telegram-iOS` с сохранением полной функциональности Telegram (MTProto, сквозное шифрование, секретные чаты, аудио/видеозвонки, каналы, боты).

### Ключевые изменения:
1. **Брендинг:**
   - Отображаемое имя: `LightGram V1`.
   - Название исполняемого файла: `LightGram`.
   - Bundle ID: `site.lightgram.ios`.
   - Версия: `1.0`.
   - URL-схема: `lightgram://`.
2. **Иконка приложения:**
   - 79 сгенерированных иконок из исходного ресурса `/opt/lightgram/assets/icon.png` (минималистичная золотисто-жёлтая лампа с бумажным самолётиком на глубоком графитовом фоне).
   - Обновлены `DefaultAppIcon.xcassets`, `AppIcons.xcassets`, альт-иконки и ресурсы WatchApp/Widgets.
3. **Фирменная цветовая схема (Black & Yellow):**
   - Глубокая OLED Black (`#000000`) и графитовая (`#121214` / `#1C1C1E`) основа.
   - Фирменный золотисто-жёлтый акцент (`#EDB400` / `0xedb400`): активные вкладки, кнопки, бейджи непрочитанных чатов, переключатели.
   - Поддержка тем: Тёмная (по умолчанию), Светлая и Системная.
4. **Модуль `LightGramCore` (AyuGram-адаптация):**
   - **Ghost Mode:** Подавление отчётов о прочтении (`messages.readHistory`), скрытие индикатора набора текста (`messages.setTyping`), скрытный просмотр историй (`stories.readStories`), ручная отметка прочтения.
   - **Spy Mode:** Локальный архив удалённых сообщений (`SpyDeletedMessageRecord`), история ревизий редактирования (`SpyEditRecord`), просмотр версий, настраиваемый срок хранения (TTL) и защита архива через Face ID / Touch ID / код-пароль.
   - **Smart Filters:** Фильтрация чатов (Личные, Группы, Каналы, Боты, Непрочитанные).
   - **Tools & Bots:** Быстрые шаблоны сообщений и быстрые команды ботов.

---

## 2. Сборка IPA через GitHub Actions

В проект добавлен готовый workflow:
[`.github/workflows/lightgram-build.yml`](.github/workflows/lightgram-build.yml)

### Шаги для запуска:
1. Запушьте ветку `lightgram-v1` (или `master`) в ваш репозиторий на GitHub.
2. Перейдите во вкладку **Actions** в веб-интерфейсе GitHub.
3. Выберите workflow **«LightGram V1 — Build & Release IPA»**.
4. Нажмите **Run workflow**:
   - **Build configuration:** `release_arm64` (по умолчанию для iPhone).
   - **Code signing mode:** 
     - `sideloading_self_signed` — для установки через TrollStore, AltStore, Sideloadly, Scarlet (не требует платного аккаунта Apple Developer).
     - `custom_secrets` — для подписи вашим личным сертификатом Apple Developer / Ad-Hoc.
   - **Create GitHub Release:** `true` (автоматически создаст релиз и прикрепит IPA).
5. Дождитесь завершения сборки (~20-40 минут на раннере `macos-14` с M-процессором).
6. Скачайте собранный артефакт **`LightGram-V1.ipa`** со страницы сборки или раздела Releases.

---

## 3. GitHub Secrets (Переменные окружения)

Если вы хотите использовать собственные ключи Telegram API или подписать приложение личным сертификатом разработчика, добавьте следующие секреты в **Settings -> Secrets and variables -> Actions**:

| Имя секрета | Обязателен? | Описание |
|---|---|---|
| `LIGHTGRAM_API_ID` | Опционально | Ваш собственный `api_id`, полученный на [my.telegram.org/apps](https://my.telegram.org/apps). По умолчанию используется официальный тестовый API ID `8`. |
| `LIGHTGRAM_API_HASH` | Опционально | Ваш собственный `api_hash` с [my.telegram.org/apps](https://my.telegram.org/apps). |
| `LIGHTGRAM_BUNDLE_ID` | Опционально | Пользовательский Bundle ID (по умолчанию: `site.lightgram.ios`). |
| `LIGHTGRAM_TEAM_ID` | Опционально | 10-значный Team ID вашего аккаунта Apple Developer. |
| `LIGHTGRAM_CERTIFICATE_P12_BASE64` | Опционально | Сертификат разработчика (`.p12`), закодированный в base64: `base64 -w 0 cert.p12`. |
| `LIGHTGRAM_CERTIFICATE_PASSWORD` | Опционально | Пароль от файла `.p12`. |
| `LIGHTGRAM_PROVISIONING_PROFILE_BASE64` | Опционально | Provisioning Profile (`.mobileprovision`), закодированный в base64: `base64 -w 0 profile.mobileprovision`. |

> **Примечание:** Если секреты сертификатов не заданы, workflow автоматически использует режим `sideloading_self_signed` с генератором самоподписанных сертификатов. Такой IPA идеально подходит для TrollStore и сторонних утилит переподписи.

---

## 4. Установка на iPhone (Sideloading)

### Способ 1: TrollStore (iOS 14.0 — 17.0 в зависимости от модели)
1. Откройте TrollStore на вашем iPhone.
2. Нажмите `+` -> `Install IPA File`.
3. Выберите скачанный файл `LightGram-V1.ipa`.
4. Приложение установится мгновенно без ограничений срока действия (revokes) и с полной функциональностью push-уведомлений и Face ID.

### Способ 2: AltStore / SideStore
1. Подключите iPhone к компьютеру или активируйте SideStore.
2. Откройте вкладку «My Apps» в AltStore.
3. Нажмите кнопку `+` и выберите `LightGram-V1.ipa`.
4. AltStore автоматически переподпишет приложение вашим бесплатным Apple ID и установит его на устройство.

### Способ 3: Sideloadly (macOS / Windows)
1. Скачайте и запустите [Sideloadly](https://sideloadly.io/).
2. Подключите iPhone по кабелю или через Wi-Fi.
3. Перетащите `LightGram-V1.ipa` в окно Sideloadly.
4. Введите ваш Apple ID и нажмите кнопку **Start**.

### Способ 4: LiveContainer / Scarlet / ESign
1. Импортируйте `LightGram-V1.ipa` в менеджер приложений.
2. Примените подпись корпоративным или персональным сертификатом.
3. Запустите установку.

---

## 5. Доступ к дополнительным функциям в приложении

После первого запуска LightGram V1:
1. Авторизуйтесь под своим аккаунтом Telegram (поддерживаются звонки, СМС, код в приложении).
2. Перейдите во вкладку **Настройки** (Settings).
3. В верхней части списка откройте пункт **«LightGram Settings»** (отмечен золотистым бейджем `V1`).
4. Настройте:
   - **Ghost Mode:** включите скрытие прочтения и статуса набора текста.
   - **Spy Mode:** управляйте архивом удалённых сообщений, историей правок и сроком хранения.
   - **Privacy:** активируйте биометрическую защиту архива через Face ID / Touch ID.
   - **Smart Filters:** включите быстрые вкладки для каналов, групп и ботов.

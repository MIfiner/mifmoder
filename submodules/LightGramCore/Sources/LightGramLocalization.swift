import Foundation

public enum LightGramLanguage: String {
    case english = "en"
    case russian = "ru"
    case polish = "pl"
    
    public static var current: LightGramLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? Locale.current.languageCode?.lowercased() ?? "en"
        if preferred.hasPrefix("ru") {
            return .russian
        } else if preferred.hasPrefix("pl") {
            return .polish
        }
        return .english
    }
}

public struct LightGramStrings {
    public static func tr(_ key: String) -> String {
        let lang = LightGramLanguage.current
        if let dict = strings[lang], let val = dict[key] {
            return val
        }
        if let fallback = strings[.english]?[key] {
            return fallback
        }
        return key
    }
    
    private static let strings: [LightGramLanguage: [String: String]] = [
        .english: [
            // General & Headers
            "LightGram": "LightGram",
            "Settings": "Settings",
            "Appearance": "Appearance",
            "Cancel": "Cancel",
            "Done": "Done",
            "Save": "Save",
            "Delete": "Delete",
            "Copy": "Copy",
            "OK": "OK",
            "Search": "Search",
            "Clear": "Clear",
            
            // Ghost Mode
            "GhostMode": "Ghost Mode",
            "GhostMode_Header": "GHOST MODE (STEALTH)",
            "GhostMode_Master": "Ghost Mode Master Switch",
            "GhostMode_Master_Desc": "Enables complete stealth mode across all activities.",
            "GhostMode_NoReadReceipts": "Don't Send Read Receipts",
            "GhostMode_NoReadReceipts_Desc": "Do not send read acknowledgements when opening or reading messages in chats.",
            "GhostMode_HideTyping": "Hide Typing Status",
            "GhostMode_HideTyping_Desc": "Do not transmit typing, recording voice, or uploading actions to other users.",
            "GhostMode_StealthOnline": "Stealth Online Presence",
            "GhostMode_StealthOnline_Desc": "Never send presence updates to keep your online status completely hidden.",
            "GhostMode_StealthStory": "Stealth Story Views",
            "GhostMode_StealthStory_Desc": "View Telegram stories without appearing in the viewers list.",
            "GhostMode_MarkOnReply": "Mark as Read on Reply",
            "GhostMode_MarkOnReply_Desc": "Automatically mark incoming messages as read when you send a reply in that chat.",
            
            // Spy Mode
            "SpyMode": "Spy Mode",
            "SpyMode_Header": "SPY MODE (ANTI-RECALL)",
            "SpyMode_Master": "Spy Mode Master Switch",
            "SpyMode_Master_Desc": "Enables anti-recall archiving for deleted and edited messages.",
            "SpyMode_SaveDeleted": "Save Deleted Messages",
            "SpyMode_SaveDeleted_Desc": "Retain deleted messages in chats with a red outline and compact badge.",
            "SpyMode_SaveEdits": "Save Edit History",
            "SpyMode_SaveEdits_Desc": "Retain all message revisions with an amber outline and revision badge.",
            "SpyMode_InlineBadges": "Inline Chat Badges",
            "SpyMode_InlineBadges_Desc": "Render compact badges directly over modified message bubbles in chat timelines.",
            "SpyMode_OpenArchive": "Open Spy Archive",
            "SpyMode_OpenArchive_Desc": "Browse all preserved deleted and edited messages with full search and filters.",
            
            // Spy Archive
            "SpyArchive_Title": "Spy Archive",
            "SpyArchive_DeletedTab": "Deleted",
            "SpyArchive_EditsTab": "Edited Revisions",
            "SpyArchive_EmptyDeleted": "No deleted messages recorded yet.",
            "SpyArchive_EmptyEdits": "No edited revisions recorded yet.",
            "SpyArchive_ClearAll": "Clear Archive",
            "SpyArchive_ClearConfirm": "Are you sure you want to permanently clear the Spy Archive?",
            "SpyArchive_DetailsTitle": "Message Details",
            
            // Logos & Themes
            "Logos_Title": "LightGram Logos",
            "Logos_Header": "LIGHTGRAM LOGO PACK",
            "Logos_Footer": "Choose your signature LightGram tile logo. Theme accent colors will synchronize automatically.",
            "Logos_Amber": "Amber",
            "Logos_Amber_Desc": "Signature Yellow · AMOLED Edition",
            "Logos_Ice": "Ice",
            "Logos_Ice_Desc": "Cyan Blue · Arctic Glaze",
            "Logos_Violet": "Violet",
            "Logos_Violet_Desc": "Deep Purple · Cyber Glow",
            "Logos_Emerald": "Emerald",
            "Logos_Emerald_Desc": "Lush Green · Matrix Neon",
            "Logos_Active": "Active Logo",
            "Logos_Apply": "Apply Logo",
            "Logos_AppliedNotice": "Logo and theme accent synchronized successfully.",
            
            // Smart Folders
            "SmartFolders_Title": "Smart Folders",
            "SmartFolders_Header": "INTELLIGENT CHAT CATEGORIES",
            "SmartFolders_All": "All Chats",
            "SmartFolders_Unread": "Unread",
            "SmartFolders_Personal": "Personal (DMs)",
            "SmartFolders_Groups": "Groups",
            "SmartFolders_Channels": "Channels",
            "SmartFolders_Bots": "Bots",
            "SmartFolders_Work": "Work",
            "SmartFolders_Important": "Important",
            "SmartFolders_Archived": "Archived",
            
            // Notes & Reminders
            "Notes_Title": "Notes & Reminders",
            "Notes_NewNote": "New Note",
            "Notes_Empty": "No notes yet. Create one to keep thoughts and reminders handy.",
            "Notes_Placeholder": "Write your note here...",
            "Notes_Reminder": "Set Reminder",
            
            // Media Center
            "MediaCenter_Title": "Media Center",
            "MediaCenter_Storage": "Storage Usage",
            "MediaCenter_Photos": "Photos",
            "MediaCenter_Videos": "Videos",
            "MediaCenter_Audio": "Audio",
            "MediaCenter_Files": "Files & Documents",
            "MediaCenter_Voice": "Voice & Video Notes",
            "MediaCenter_ClearCache": "Clear Storage Cache",
            "MediaCenter_CacheCleared": "Cache cleared successfully.",
            
            // Bot & Group Manager
            "BotManager_Title": "Bot & Group Manager",
            "BotManager_Header": "FAVORITE BOTS & TOOLS",
            "BotManager_Audit": "Group Security Audit",
            
            // Privacy Center
            "PrivacyCenter_Title": "Privacy Center",
            "PrivacyCenter_Header": "BIOMETRIC LOCK & DATA SECURITY",
            "PrivacyCenter_Biometrics": "Require Face ID / Touch ID",
            "PrivacyCenter_Biometrics_Desc": "Lock Spy Archive behind biometric authentication.",
            "PrivacyCenter_Preview": "Hide Notification Previews",
            "PrivacyCenter_Preview_Desc": "Obscure sender names and message contents in notification banners.",
            "PrivacyCenter_TTL": "Retention Period (TTL)",
            "PrivacyCenter_ExportJSON": "Export Archive to JSON",
            
            // Context Menus & Bubble Badges
            "Badge_Deleted": "🔴 DELETED",
            "Badge_Edited": "🟡 EDITED / REV",
            "Menu_DeletedDetails": "Deleted Message Details",
            "Menu_EditHistory": "Edit Revisions History",
            "Menu_CopyOriginal": "Copy Original Text",
            "Menu_SaveToNotes": "Save to Notes"
        ],
        .russian: [
            // General & Headers
            "LightGram": "LightGram",
            "Settings": "Настройки",
            "Appearance": "Оформление",
            "Cancel": "Отмена",
            "Done": "Готово",
            "Save": "Сохранить",
            "Delete": "Удалить",
            "Copy": "Скопировать",
            "OK": "ОК",
            "Search": "Поиск",
            "Clear": "Очистить",
            
            // Ghost Mode
            "GhostMode": "Режим призрака",
            "GhostMode_Header": "РЕЖИМ ПРИЗРАКА (СТЕРИЛЬНОСТЬ)",
            "GhostMode_Master": "Главный переключатель Ghost Mode",
            "GhostMode_Master_Desc": "Включает полную скрытность действий во всех чатах.",
            "GhostMode_NoReadReceipts": "Не отправлять статус прочтения",
            "GhostMode_NoReadReceipts_Desc": "Сообщения не отмечаются прочитанными для собеседника при открытии чата.",
            "GhostMode_HideTyping": "Скрывать статус набора текста",
            "GhostMode_HideTyping_Desc": "Собеседники не видят, когда вы печатаете, записываете голос или отправляете медиа.",
            "GhostMode_StealthOnline": "Скрывать статус «В сети»",
            "GhostMode_StealthOnline_Desc": "Не отправлять статус активности на серверы Telegram.",
            "GhostMode_StealthStory": "Скрытный просмотр историй",
            "GhostMode_StealthStory_Desc": "Просмотр историй Telegram без добавления в список зрителей.",
            "GhostMode_MarkOnReply": "Отмечать прочитанным при ответе",
            "GhostMode_MarkOnReply_Desc": "Автоматически отмечать сообщения прочитанными только при отправке ответа в чат.",
            
            // Spy Mode
            "SpyMode": "Шпионский режим",
            "SpyMode_Header": "ШПИОНСКИЙ РЕЖИМ (АНТИ-ОТЗЫВ)",
            "SpyMode_Master": "Главный переключатель Spy Mode",
            "SpyMode_Master_Desc": "Включает сохранение удалённых и изменённых сообщений.",
            "SpyMode_SaveDeleted": "Сохранять удалённые сообщения",
            "SpyMode_SaveDeleted_Desc": "Сохранять удалённые собеседником сообщения с красной рамкой и аккуратным бейджем.",
            "SpyMode_SaveEdits": "Сохранять историю редакций",
            "SpyMode_SaveEdits_Desc": "Сохранять все версии текста при редактировании с жёлтой рамкой и номером ревизии.",
            "SpyMode_InlineBadges": "Бейджи в ленте сообщений",
            "SpyMode_InlineBadges_Desc": "Отображать компактные индикаторы прямо на пузырях сообщений в чате.",
            "SpyMode_OpenArchive": "Открыть архив сообщений",
            "SpyMode_OpenArchive_Desc": "Просмотр всех сохранённых удалённых и изменённых сообщений с быстрым поиском.",
            
            // Spy Archive
            "SpyArchive_Title": "Шпионский архив",
            "SpyArchive_DeletedTab": "Удалённые",
            "SpyArchive_EditsTab": "Правки",
            "SpyArchive_EmptyDeleted": "Пока нет сохранённых удалённых сообщений.",
            "SpyArchive_EmptyEdits": "Пока нет сохранённых правок текста.",
            "SpyArchive_ClearAll": "Очистить архив",
            "SpyArchive_ClearConfirm": "Вы уверены, что хотите навсегда очистить архив сообщений?",
            "SpyArchive_DetailsTitle": "Детали сообщения",
            
            // Logos & Themes
            "Logos_Title": "Логотипы LightGram",
            "Logos_Header": "НАБОР ЛОГОТИПОВ LIGHTGRAM",
            "Logos_Footer": "Выберите фирменный стиль иконки LightGram. Акцентные цвета темы синхронизируются автоматически.",
            "Logos_Amber": "Янтарный (Amber)",
            "Logos_Amber_Desc": "Фирменный жёлтый · Издание AMOLED",
            "Logos_Ice": "Ледяной (Ice)",
            "Logos_Ice_Desc": "Холодный циан · Арктический лёд",
            "Logos_Violet": "Фиолетовый (Violet)",
            "Logos_Violet_Desc": "Глубокий пурпур · Кибер-свечение",
            "Logos_Emerald": "Изумрудный (Emerald)",
            "Logos_Emerald_Desc": "Насыщенный зелёный · Матрица Неон",
            "Logos_Active": "Текущий логотип",
            "Logos_Apply": "Применить логотип",
            "Logos_AppliedNotice": "Логотип и акцентный цвет темы успешно обновлены.",
            
            // Smart Folders
            "SmartFolders_Title": "Умные папки",
            "SmartFolders_Header": "ИНТЕЛЛЕКТУАЛЬНЫЕ КАТЕГОРИИ ЧАТОВ",
            "SmartFolders_All": "Все чаты",
            "SmartFolders_Unread": "Непрочитанные",
            "SmartFolders_Personal": "Личные сообщения",
            "SmartFolders_Groups": "Группы",
            "SmartFolders_Channels": "Каналы",
            "SmartFolders_Bots": "Боты",
            "SmartFolders_Work": "Работа",
            "SmartFolders_Important": "Важное",
            "SmartFolders_Archived": "Архив",
            
            // Notes & Reminders
            "Notes_Title": "Заметки и напоминания",
            "Notes_NewNote": "Новая заметка",
            "Notes_Empty": "Заметок пока нет. Создайте заметку, чтобы сохранить важную информацию.",
            "Notes_Placeholder": "Введите текст заметки...",
            "Notes_Reminder": "Установить напоминание",
            
            // Media Center
            "MediaCenter_Title": "Хранилище медиа",
            "MediaCenter_Storage": "Использование памяти",
            "MediaCenter_Photos": "Фотографии",
            "MediaCenter_Videos": "Видеозаписи",
            "MediaCenter_Audio": "Музыка и аудио",
            "MediaCenter_Files": "Файлы и документы",
            "MediaCenter_Voice": "Голосовые и видеосообщения",
            "MediaCenter_ClearCache": "Очистить кэш памяти",
            "MediaCenter_CacheCleared": "Кэш успешно очищен.",
            
            // Bot & Group Manager
            "BotManager_Title": "Боты и группы",
            "BotManager_Header": "ИЗБРАННЫЕ БОТЫ И ИНСТРУМЕНТЫ",
            "BotManager_Audit": "Аудит безопасности групп",
            
            // Privacy Center
            "PrivacyCenter_Title": "Конфиденциальность",
            "PrivacyCenter_Header": "БИОМЕТРИЯ И ЗАЩИТА ДАННЫХ",
            "PrivacyCenter_Biometrics": "Вход по Face ID / Touch ID",
            "PrivacyCenter_Biometrics_Desc": "Защищать доступ к архиву биометрической аутентификацией.",
            "PrivacyCenter_Preview": "Скрывать текст в уведомлениях",
            "PrivacyCenter_Preview_Desc": "Скрывать имя отправителя и текст в пуш-уведомлениях.",
            "PrivacyCenter_TTL": "Срок хранения архива (TTL)",
            "PrivacyCenter_ExportJSON": "Экспорт архива в JSON",
            
            // Context Menus & Bubble Badges
            "Badge_Deleted": "🔴 УДАЛЕНО",
            "Badge_Edited": "🟡 ИЗМЕНЕНО / РЕВ",
            "Menu_DeletedDetails": "Детали удалённого сообщения",
            "Menu_EditHistory": "История правок сообщения",
            "Menu_CopyOriginal": "Скопировать оригинал",
            "Menu_SaveToNotes": "Сохранить в заметки"
        ],
        .polish: [
            // General & Headers
            "LightGram": "LightGram",
            "Settings": "Ustawienia",
            "Appearance": "Wygląd",
            "Cancel": "Anuluj",
            "Done": "Gotowe",
            "Save": "Zapisz",
            "Delete": "Usuń",
            "Copy": "Kopiuj",
            "OK": "OK",
            "Search": "Szukaj",
            "Clear": "Wyczyść",
            
            // Ghost Mode
            "GhostMode": "Tryb Ducha",
            "GhostMode_Header": "TRYB DUCHA (NIEWIDOCZNOŚĆ)",
            "GhostMode_Master": "Główny przełącznik Trybu Ducha",
            "GhostMode_Master_Desc": "Włącza pełną niewidoczność we wszystkich konwersacjach.",
            "GhostMode_NoReadReceipts": "Nie wysyłaj potwierdzeń przeczytania",
            "GhostMode_NoReadReceipts_Desc": "Wiadomości nie będą oznaczane jako przeczytane podczas otwierania czatów.",
            "GhostMode_HideTyping": "Ukryj status pisania",
            "GhostMode_HideTyping_Desc": "Rozmówcy nie widzą, kiedy piszesz lub nagrywasz wiadomość głosową.",
            "GhostMode_StealthOnline": "Ukryj status online",
            "GhostMode_StealthOnline_Desc": "Nie wysyłaj statusu aktywności do serwerów Telegram.",
            "GhostMode_StealthStory": "Dyskretne oglądanie relacji",
            "GhostMode_StealthStory_Desc": "Oglądaj relacje Telegram bez pojawiania się na liście widzów.",
            "GhostMode_MarkOnReply": "Oznacz jako przeczytane przy odpowiedzi",
            "GhostMode_MarkOnReply_Desc": "Automatycznie oznaczaj wiadomości jako przeczytane dopiero po wysłaniu odpowiedzi.",
            
            // Spy Mode
            "SpyMode": "Tryb Szpiegowski",
            "SpyMode_Header": "TRYB SZPIEGOWSKI (ANTI-RECALL)",
            "SpyMode_Master": "Główny przełącznik Trybu Szpiegowskiego",
            "SpyMode_Master_Desc": "Włącza archiwizację usuniętych i edytowanych wiadomości.",
            "SpyMode_SaveDeleted": "Zapisuj usunięte wiadomości",
            "SpyMode_SaveDeleted_Desc": "Zachowuj usunięte wiadomości z czerwoną obwódką i etykietą.",
            "SpyMode_SaveEdits": "Zapisuj historię edycji",
            "SpyMode_SaveEdits_Desc": "Zachowuj wszystkie wersje edytowanych wiadomości z żółtą obwódką.",
            "SpyMode_InlineBadges": "Wskaźniki na dymkach wiadomości",
            "SpyMode_InlineBadges_Desc": "Wyświetlaj kompaktowe etykiety bezpośrednio na zmienionych wiadomościach.",
            "SpyMode_OpenArchive": "Otwórz Archiwum",
            "SpyMode_OpenArchive_Desc": "Przeglądaj wszystkie zachowane wiadomości z wyszukiwaniem.",
            
            // Spy Archive
            "SpyArchive_Title": "Archiwum Szpiegowskie",
            "SpyArchive_DeletedTab": "Usunięte",
            "SpyArchive_EditsTab": "Edycje",
            "SpyArchive_EmptyDeleted": "Brak usuniętych wiadomości w archiwum.",
            "SpyArchive_EmptyEdits": "Brak edytowanych wiadomości w archiwum.",
            "SpyArchive_ClearAll": "Wyczyść archiwum",
            "SpyArchive_ClearConfirm": "Czy na pewno chcesz bezpowrotnie wyczyścić archiwum?",
            "SpyArchive_DetailsTitle": "Szczegóły wiadomości",
            
            // Logos & Themes
            "Logos_Title": "Logo LightGram",
            "Logos_Header": "PAKIET LOGO LIGHTGRAM",
            "Logos_Footer": "Wybierz swój wariant logo LightGram. Akcenty kolorystyczne zsynchronizują się automatycznie.",
            "Logos_Amber": "Bursztynowy (Amber)",
            "Logos_Amber_Desc": "Złocisty żółty · Edycja AMOLED",
            "Logos_Ice": "Lodowy (Ice)",
            "Logos_Ice_Desc": "Arktyczny błękit cyjanowy",
            "Logos_Violet": "Fioletowy (Violet)",
            "Logos_Violet_Desc": "Głęboki fiolet · Neonowy blask",
            "Logos_Emerald": "Szmaragdowy (Emerald)",
            "Logos_Emerald_Desc": "Soczysta zieleń · Styl Matrix",
            "Logos_Active": "Aktywne logo",
            "Logos_Apply": "Zastosuj logo",
            "Logos_AppliedNotice": "Logo oraz akcent motywu zostały pomyślnie zaktualizowane.",
            
            // Smart Folders
            "SmartFolders_Title": "Inteligentne Foldery",
            "SmartFolders_Header": "INTELIGENTNE KATEGORIE CZATÓW",
            "SmartFolders_All": "Wszystkie",
            "SmartFolders_Unread": "Nieprzeczytane",
            "SmartFolders_Personal": "Prywatne",
            "SmartFolders_Groups": "Grupy",
            "SmartFolders_Channels": "Kanały",
            "SmartFolders_Bots": "Boty",
            "SmartFolders_Work": "Praca",
            "SmartFolders_Important": "Ważne",
            "SmartFolders_Archived": "Archiwum",
            
            // Notes & Reminders
            "Notes_Title": "Notatki i Przypomnienia",
            "Notes_NewNote": "Nowa notatka",
            "Notes_Empty": "Brak notatek. Utwórz notatkę, aby zachować ważne informacje.",
            "Notes_Placeholder": "Wpisz treść notatki...",
            "Notes_Reminder": "Ustaw przypomnienie",
            
            // Media Center
            "MediaCenter_Title": "Centrum Multimediów",
            "MediaCenter_Storage": "Pamięć podręczna",
            "MediaCenter_Photos": "Zdjęcia",
            "MediaCenter_Videos": "Wideo",
            "MediaCenter_Audio": "Muzyka i dźwięki",
            "MediaCenter_Files": "Pliki i dokumenty",
            "MediaCenter_Voice": "Wiadomości głosowe i wideo",
            "MediaCenter_ClearCache": "Wyczyść pamięć podręczną",
            "MediaCenter_CacheCleared": "Pamięć podręczna została pomyślnie wyczyszczona.",
            
            // Bot & Group Manager
            "BotManager_Title": "Menedżer Botów i Grup",
            "BotManager_Header": "ULUBIONE BOTY I NARZĘDZIA",
            "BotManager_Audit": "Audyt bezpieczeństwa grup",
            
            // Privacy Center
            "PrivacyCenter_Title": "Centrum Prywatności",
            "PrivacyCenter_Header": "BIOMETRIA I BEZPIECZEŃSTWO DANYCH",
            "PrivacyCenter_Biometrics": "Wymagaj Face ID / Touch ID",
            "PrivacyCenter_Biometrics_Desc": "Chroń dostęp do archiwum blokadą biometryczną.",
            "PrivacyCenter_Preview": "Ukryj podgląd w powiadomieniach",
            "PrivacyCenter_Preview_Desc": "Ukrywaj nadawcę i treść wiadomości na ekranie blokady.",
            "PrivacyCenter_TTL": "Okres przechowywania (TTL)",
            "PrivacyCenter_ExportJSON": "Eksportuj archiwum do JSON",
            
            // Context Menus & Bubble Badges
            "Badge_Deleted": "🔴 USUNIĘTO",
            "Badge_Edited": "🟡 EDYTOWANO / WER",
            "Menu_DeletedDetails": "Szczegóły usuniętej wiadomości",
            "Menu_EditHistory": "Historia edycji wiadomości",
            "Menu_CopyOriginal": "Kopiuj tekst oryginalny",
            "Menu_SaveToNotes": "Zapisz w notatkach"
        ]
    ]
}

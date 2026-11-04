#include "Localization.hpp"
#include <QLocale>

namespace LightGram {

Localization& Localization::instance() {
    static Localization inst;
    return inst;
}

Localization::Localization() {
    initStrings();
    // Detect system language
    QString sysLang = QLocale::system().name().toLower();
    if (sysLang.startsWith("ru")) {
        m_currentLanguage = Language::Russian;
    } else if (sysLang.startsWith("pl")) {
        m_currentLanguage = Language::Polish;
    } else {
        m_currentLanguage = Language::English;
    }
}

QString Localization::languageCode() const {
    switch (m_currentLanguage) {
    case Language::Russian: return "ru";
    case Language::Polish: return "pl";
    default: return "en";
    }
}

void Localization::setLanguage(Language lang) {
    if (m_currentLanguage != lang) {
        m_currentLanguage = lang;
        emit languageChanged(lang);
    }
}

void Localization::setLanguageByCode(const QString& code) {
    QString c = code.trimmed().toLower();
    if (c == "ru") setLanguage(Language::Russian);
    else if (c == "pl") setLanguage(Language::Polish);
    else setLanguage(Language::English);
}

QString Localization::get(const QString& key) const {
    if (m_strings.contains(m_currentLanguage)) {
        const auto& curMap = m_strings.value(m_currentLanguage);
        if (curMap.contains(key)) {
            return curMap.value(key);
        }
    }
    // Fallback to English
    if (m_strings.contains(Language::English)) {
        const auto& enMap = m_strings.value(Language::English);
        if (enMap.contains(key)) {
            return enMap.value(key);
        }
    }
    return key;
}

QString Localization::get(const QString& key, const QString& defaultVal) const {
    QString res = get(key);
    return (res == key) ? defaultVal : res;
}

void Localization::initStrings() {
    // ================= EN =================
    QMap<QString, QString> en;
    en["AppTitle"] = "LightGram Desktop";
    en["Settings"] = "Settings";
    en["Appearance"] = "Appearance";
    en["Cancel"] = "Cancel";
    en["Done"] = "Done";
    en["Save"] = "Save";
    en["Delete"] = "Delete";
    en["Copy"] = "Copy";
    en["OK"] = "OK";
    en["Search"] = "Search";
    en["Clear"] = "Clear";
    en["Close"] = "Close";
    en["Refresh"] = "Refresh";
    en["Apply"] = "Apply";
    en["Filter"] = "Filter";
    en["All"] = "All";

    // Ghost Mode
    en["GhostMode"] = "Ghost Mode";
    en["GhostMode_Header"] = "GHOST MODE (STEALTH)";
    en["GhostMode_Master"] = "Ghost Mode Master Switch";
    en["GhostMode_Master_Desc"] = "Enables complete stealth mode across all activities.";
    en["GhostMode_NoReadReceipts"] = "Don't Send Read Receipts";
    en["GhostMode_NoReadReceipts_Desc"] = "Do not send read acknowledgements when opening messages.";
    en["GhostMode_HideTyping"] = "Hide Typing Status";
    en["GhostMode_HideTyping_Desc"] = "Do not transmit typing, recording or uploading actions.";
    en["GhostMode_StealthOnline"] = "Stealth Online Presence";
    en["GhostMode_StealthOnline_Desc"] = "Never send presence updates to keep your online status hidden.";
    en["GhostMode_StealthStory"] = "Stealth Story Views";
    en["GhostMode_StealthStory_Desc"] = "View Telegram stories without appearing in the viewers list.";
    en["GhostMode_MarkOnReply"] = "Mark as Read on Reply";
    en["GhostMode_MarkOnReply_Desc"] = "Automatically mark messages as read when you send a reply.";
    en["GhostMode_Notice"] = "Notice: Sending a message to a chat will update read pointer on Telegram servers.";

    // Spy Mode
    en["SpyMode"] = "Spy Mode";
    en["SpyMode_Header"] = "SPY MODE (ANTI-RECALL)";
    en["SpyMode_Master"] = "Spy Mode Master Switch";
    en["SpyMode_Master_Desc"] = "Enables anti-recall archiving for deleted and edited messages.";
    en["SpyMode_SaveDeleted"] = "Save Deleted Messages";
    en["SpyMode_SaveDeleted_Desc"] = "Retain deleted messages in chats with a red outline and badge.";
    en["SpyMode_SaveEdits"] = "Save Edit History";
    en["SpyMode_SaveEdits_Desc"] = "Retain all message revisions with an amber outline and revision badge.";
    en["SpyMode_OpenArchive"] = "Open Spy Archive";
    en["SpyArchive_Title"] = "Spy Archive";
    en["SpyArchive_DeletedTab"] = "Deleted Messages";
    en["SpyArchive_EditsTab"] = "Edited Revisions";
    en["SpyArchive_EmptyDeleted"] = "No deleted messages recorded yet.";
    en["SpyArchive_EmptyEdits"] = "No edited messages recorded yet.";
    en["Badge_Deleted"] = "🔴 DELETED";
    en["Badge_Edited"] = "🟡 EDITED";

    // LightGram Studio
    en["Studio_Title"] = "LightGram Studio";
    en["Studio_Subtitle"] = "Liquid Glass & Appearance Customizer";
    en["Studio_PresetThemes"] = "Preset Themes";
    en["Studio_PrimaryAccent"] = "Primary Accent Color";
    en["Studio_SecondaryAccent"] = "Secondary Accent Color";
    en["Studio_BgColor"] = "Window Background";
    en["Studio_SidebarColor"] = "Sidebar Background";
    en["Studio_IncomingBubble"] = "Incoming Bubble";
    en["Studio_OutgoingBubble"] = "Outgoing Bubble";
    en["Studio_TextColor"] = "Primary Text";
    en["Studio_CornerRadius"] = "Corner Radius";
    en["Studio_GlassOpacity"] = "Glass Opacity";
    en["Studio_BlurIntensity"] = "Blur Intensity";
    en["Studio_Import"] = "Import Theme...";
    en["Studio_Export"] = "Export Theme...";
    en["Studio_Duplicate"] = "Duplicate";
    en["Studio_ResetDefaults"] = "Reset to Defaults";
    en["Studio_LivePreview"] = "Live Preview";

    // Statistics Center
    en["Statistics_Title"] = "Statistics Center";
    en["Statistics_Header"] = "LIGHTGRAM ANALYTICS & STATS";
    en["Statistics_7Days"] = "7 Days";
    en["Statistics_30Days"] = "30 Days";
    en["Statistics_AllTime"] = "All Time";
    en["Statistics_Sent"] = "Sent Messages";
    en["Statistics_Received"] = "Received Messages";
    en["Statistics_Total"] = "Total Messages";
    en["Statistics_ActiveChats"] = "Active Chats";
    en["Statistics_HourlyHeader"] = "HOURLY ACTIVITY BREAKDOWN";
    en["Statistics_DailyHeader"] = "DAILY ACTIVITY TREND";
    en["Statistics_TopChatsHeader"] = "TOP ACTIVE CHATS";
    en["Statistics_ExportPNG"] = "Export Image";
    en["Statistics_ExportPDF"] = "Export Report";
    en["Statistics_PeakHour"] = "Peak Hour";
    en["Statistics_PeakDay"] = "Peak Day";
    en["Statistics_AvgDay"] = "Avg Messages / Day";

    // Media Vault
    en["MediaVault_Title"] = "Media Vault";
    en["MediaVault_All"] = "All Files";
    en["MediaVault_Photos"] = "Photos";
    en["MediaVault_Videos"] = "Videos";
    en["MediaVault_Circles"] = "Circles";
    en["MediaVault_Voice"] = "Voice Notes";
    en["MediaVault_Files"] = "Documents";
    en["MediaVault_Favorites"] = "★ Favorites";
    en["MediaVault_SaveToVault"] = "Save to Media Vault";
    en["MediaVault_StorageUsed"] = "Vault Storage Used";
    en["MediaVault_ClearVault"] = "Clear Vault (keep favorites)";
    en["MediaVault_ExportBatch"] = "Batch Export Files";

    // Circle Studio
    en["CircleStudio_Title"] = "Circle Studio";
    en["CircleStudio_Subtitle"] = "1:1 Video Note Maker";
    en["CircleStudio_CropSquare"] = "Crop Video to Square Circle";
    en["CircleStudio_PlayPreview"] = "Play Circular Preview";
    en["CircleStudio_Save"] = "Save to Media Vault";

    // Notes & Reminders
    en["Notes_Title"] = "Notes & Reminders";
    en["Notes_TabNotes"] = "Personal Notes";
    en["Notes_TabReminders"] = "Reminders";
    en["Notes_NewNote"] = "New Note";
    en["Notes_NewReminder"] = "New Reminder";
    en["Notes_SaveFromChat"] = "Save Message to Notes";

    // Smart Folders
    en["SmartFolders_Title"] = "Smart Folders";
    en["SmartFolders_All"] = "All Chats";
    en["SmartFolders_Unread"] = "Unread";
    en["SmartFolders_Personal"] = "Personal";
    en["SmartFolders_Groups"] = "Groups";
    en["SmartFolders_Channels"] = "Channels";
    en["SmartFolders_Bots"] = "Bots";
    en["SmartFolders_Work"] = "Work";
    en["SmartFolders_Important"] = "Important";
    en["SmartFolders_Archived"] = "Archived";

    // Diagnostics
    en["Diagnostics_Title"] = "Network Diagnostics";
    en["Diagnostics_DC1"] = "DC1 (Miami, USA)";
    en["Diagnostics_DC2"] = "DC2 (Amsterdam, Europe)";
    en["Diagnostics_DC3"] = "DC3 (Miami, USA)";
    en["Diagnostics_DC4"] = "DC4 (Amsterdam, Europe)";
    en["Diagnostics_DC5"] = "DC5 (Singapore, Asia)";
    en["Diagnostics_PingAll"] = "Ping All Data Centers";

    // Desktop features
    en["Desktop_Tabs"] = "Chat Tabs";
    en["Desktop_DetachWindow"] = "Open in New Window";
    en["Desktop_GlobalSearch"] = "Search chats, messages & tools (Ctrl+K)...";
    en["Desktop_DropFiles"] = "Drop files here to send";
    en["Desktop_Autostart"] = "Launch on System Startup";
    en["Desktop_MinimizeToTray"] = "Minimize to System Tray";
    en["Desktop_CompactMode"] = "Compact Layout Mode";
    en["Desktop_Fullscreen"] = "Fullscreen Mode (F11)";
    en["Desktop_Accounts"] = "Accounts";
    en["Desktop_AddAccount"] = "Add Account";
    en["Desktop_Logout"] = "Log Out";

    // Auth
    en["Auth_Title"] = "Login to Telegram";
    en["Auth_Phone"] = "Phone Number";
    en["Auth_Code"] = "Telegram / SMS Code";
    en["Auth_Password"] = "2FA Cloud Password";
    en["Auth_SendCode"] = "Send Code";
    en["Auth_Login"] = "Log In";
    en["Auth_QrLogin"] = "Log in via QR Code";
    m_strings[Language::English] = en;

    // ================= RU =================
    QMap<QString, QString> ru;
    ru["AppTitle"] = "LightGram Desktop";
    ru["Settings"] = "Настройки";
    ru["Appearance"] = "Оформление";
    ru["Cancel"] = "Отмена";
    ru["Done"] = "Готово";
    ru["Save"] = "Сохранить";
    ru["Delete"] = "Удалить";
    ru["Copy"] = "Копировать";
    ru["OK"] = "ОК";
    ru["Search"] = "Поиск";
    ru["Clear"] = "Очистить";
    ru["Close"] = "Закрыть";
    ru["Refresh"] = "Обновить";
    ru["Apply"] = "Применить";
    ru["Filter"] = "Фильтр";
    ru["All"] = "Все";

    // Ghost Mode
    ru["GhostMode"] = "Ghost Mode";
    ru["GhostMode_Header"] = "РЕЖИМ НЕВИДИМКИ (GHOST MODE)";
    ru["GhostMode_Master"] = "Главный переключатель Ghost Mode";
    ru["GhostMode_Master_Desc"] = "Включает скрытный режим для всех сетевых активностей.";
    ru["GhostMode_NoReadReceipts"] = "Не отправлять статус прочтения";
    ru["GhostMode_NoReadReceipts_Desc"] = "Не посылать подтверждения прочтения при открытии сообщений.";
    ru["GhostMode_HideTyping"] = "Скрывать статус набора текста";
    ru["GhostMode_HideTyping_Desc"] = "Не отправлять статусы «печатает», «записывает голосовое».";
    ru["GhostMode_StealthOnline"] = "Скрытный онлайн";
    ru["GhostMode_StealthOnline_Desc"] = "Не передавать регулярный онлайн-статус в сеть Telegram.";
    ru["GhostMode_StealthStory"] = "Скрытный просмотр историй";
    ru["GhostMode_StealthStory_Desc"] = "Просматривать истории без отображения в списке зрителей.";
    ru["GhostMode_MarkOnReply"] = "Отмечать прочитанным при ответе";
    ru["GhostMode_MarkOnReply_Desc"] = "Автоматически отмечать чат прочитанным только при отправке ответа.";
    ru["GhostMode_Notice"] = "Внимание: отправка сообщения в чат снимет статус непрочитанного на серверах Telegram.";

    // Spy Mode
    ru["SpyMode"] = "Spy Mode";
    ru["SpyMode_Header"] = "SPY MODE (ANTI-RECALL)";
    ru["SpyMode_Master"] = "Главный переключатель Spy Mode";
    ru["SpyMode_Master_Desc"] = "Включает сохранение удалённых сообщений и истории редакций.";
    ru["SpyMode_SaveDeleted"] = "Сохранять удалённые сообщения";
    ru["SpyMode_SaveDeleted_Desc"] = "Оставлять удалённые сообщения с красной рамкой и меткой.";
    ru["SpyMode_SaveEdits"] = "Сохранять историю редакций";
    ru["SpyMode_SaveEdits_Desc"] = "Сохранять все ревизии текста с янтарной рамкой и меткой.";
    ru["SpyMode_OpenArchive"] = "Открыть Spy Archive";
    ru["SpyArchive_Title"] = "Архив Spy Mode";
    ru["SpyArchive_DeletedTab"] = "Удалённые сообщения";
    ru["SpyArchive_EditsTab"] = "История редакций";
    ru["SpyArchive_EmptyDeleted"] = "Удалённых сообщений пока нет.";
    ru["SpyArchive_EmptyEdits"] = "Отредактированных сообщений пока нет.";
    ru["Badge_Deleted"] = "🔴 УДАЛЕНО";
    ru["Badge_Edited"] = "🟡 ИЗМЕНЕНО";

    // LightGram Studio
    ru["Studio_Title"] = "LightGram Studio";
    ru["Studio_Subtitle"] = "Редактор стиля и Liquid Glass";
    ru["Studio_PresetThemes"] = "Готовые темы оформления";
    ru["Studio_PrimaryAccent"] = "Основной акцентный цвет";
    ru["Studio_SecondaryAccent"] = "Дополнительный акцентный цвет";
    ru["Studio_BgColor"] = "Цвет фона окна";
    ru["Studio_SidebarColor"] = "Цвет боковой панели";
    ru["Studio_IncomingBubble"] = "Входящие сообщения";
    ru["Studio_OutgoingBubble"] = "Исходящие сообщения";
    ru["Studio_TextColor"] = "Основной цвет текста";
    ru["Studio_CornerRadius"] = "Радиус скругления";
    ru["Studio_GlassOpacity"] = "Прозрачность стекла";
    ru["Studio_BlurIntensity"] = "Интенсивность размытия";
    ru["Studio_Import"] = "Импорт темы...";
    ru["Studio_Export"] = "Экспорт темы...";
    ru["Studio_Duplicate"] = "Дублировать";
    ru["Studio_ResetDefaults"] = "Сброс к исходным";
    ru["Studio_LivePreview"] = "Живой предпросмотр";

    // Statistics Center
    ru["Statistics_Title"] = "Центр статистики";
    ru["Statistics_Header"] = "СТАТИСТИКА И АНАЛИТИКА LIGHTGRAM";
    ru["Statistics_7Days"] = "7 дней";
    ru["Statistics_30Days"] = "30 дней";
    ru["Statistics_AllTime"] = "За всё время";
    ru["Statistics_Sent"] = "Отправлено сообщений";
    ru["Statistics_Received"] = "Получено сообщений";
    ru["Statistics_Total"] = "Всего сообщений";
    ru["Statistics_ActiveChats"] = "Активных диалогов";
    ru["Statistics_HourlyHeader"] = "АКТИВНОСТЬ ПО ЧАСАМ СУТОК";
    ru["Statistics_DailyHeader"] = "ТРЕНД АКТИВНОСТИ ПО ДНЯМ";
    ru["Statistics_TopChatsHeader"] = "САМЫЕ АКТИВНЫЕ ЧАТЫ";
    ru["Statistics_ExportPNG"] = "Экспорт изображения";
    ru["Statistics_ExportPDF"] = "Экспорт отчёта";
    ru["Statistics_PeakHour"] = "Час пик";
    ru["Statistics_PeakDay"] = "День пик";
    ru["Statistics_AvgDay"] = "Ср. сообщений в день";

    // Media Vault
    ru["MediaVault_Title"] = "Сейф медиафайлов";
    ru["MediaVault_All"] = "Все файлы";
    ru["MediaVault_Photos"] = "Фото";
    ru["MediaVault_Videos"] = "Видео";
    ru["MediaVault_Circles"] = "Кружки";
    ru["MediaVault_Voice"] = "Голосовые";
    ru["MediaVault_Files"] = "Документы";
    ru["MediaVault_Favorites"] = "★ Избранное";
    ru["MediaVault_SaveToVault"] = "Сохранить в Сейф";
    ru["MediaVault_StorageUsed"] = "Занято места в Сейфе";
    ru["MediaVault_ClearVault"] = "Очистить (кроме избранного)";
    ru["MediaVault_ExportBatch"] = "Пакетный экспорт файлов";

    // Circle Studio
    ru["CircleStudio_Title"] = "Circle Studio";
    ru["CircleStudio_Subtitle"] = "Создание видеозаметок 1:1";
    ru["CircleStudio_CropSquare"] = "Кадрировать видео в круг";
    ru["CircleStudio_PlayPreview"] = "Воспроизвести круглый плеер";
    ru["CircleStudio_Save"] = "Сохранить в Сейф";

    // Notes & Reminders
    ru["Notes_Title"] = "Заметки и напоминания";
    ru["Notes_TabNotes"] = "Личные заметки";
    ru["Notes_TabReminders"] = "Напоминания";
    ru["Notes_NewNote"] = "Новая заметка";
    ru["Notes_NewReminder"] = "Новое напоминание";
    ru["Notes_SaveFromChat"] = "Сохранить сообщение в заметки";

    // Smart Folders
    ru["SmartFolders_Title"] = "Умные папки";
    ru["SmartFolders_All"] = "Все чаты";
    ru["SmartFolders_Unread"] = "Непрочитанные";
    ru["SmartFolders_Personal"] = "Личные";
    ru["SmartFolders_Groups"] = "Группы";
    ru["SmartFolders_Channels"] = "Каналы";
    ru["SmartFolders_Bots"] = "Боты";
    ru["SmartFolders_Work"] = "Работа";
    ru["SmartFolders_Important"] = "Важные";
    ru["SmartFolders_Archived"] = "Архив";

    // Diagnostics
    ru["Diagnostics_Title"] = "Сетевая диагностика";
    ru["Diagnostics_DC1"] = "DC1 (Майами, США)";
    ru["Diagnostics_DC2"] = "DC2 (Амстердам, Европа)";
    ru["Diagnostics_DC3"] = "DC3 (Майами, США)";
    ru["Diagnostics_DC4"] = "DC4 (Амстердам, Европа)";
    ru["Diagnostics_DC5"] = "DC5 (Сингапур, Азия)";
    ru["Diagnostics_PingAll"] = "Пинг всех дата-центров";

    // Desktop features
    ru["Desktop_Tabs"] = "Вкладки чатов";
    ru["Desktop_DetachWindow"] = "Открыть в отдельном окне";
    ru["Desktop_GlobalSearch"] = "Поиск по чатам, сообщениям и функциям (Ctrl+K)...";
    ru["Desktop_DropFiles"] = "Перетащите файлы сюда для отправки";
    ru["Desktop_Autostart"] = "Автозапуск при старте системы";
    ru["Desktop_MinimizeToTray"] = "Сворачивать в системный трей";
    ru["Desktop_CompactMode"] = "Компактный режим";
    ru["Desktop_Fullscreen"] = "Полноэкранный режим (F11)";
    ru["Desktop_Accounts"] = "Аккаунты";
    ru["Desktop_AddAccount"] = "Добавить аккаунт";
    ru["Desktop_Logout"] = "Выйти из аккаунта";

    // Auth
    ru["Auth_Title"] = "Вход в Telegram";
    ru["Auth_Phone"] = "Номер телефона";
    ru["Auth_Code"] = "Код подтверждения";
    ru["Auth_Password"] = "Облачный пароль 2FA";
    ru["Auth_SendCode"] = "Отправить код";
    ru["Auth_Login"] = "Войти";
    ru["Auth_QrLogin"] = "Вход по QR-коду";
    m_strings[Language::Russian] = ru;

    // ================= PL =================
    QMap<QString, QString> pl;
    pl["AppTitle"] = "LightGram Desktop";
    pl["Settings"] = "Ustawienia";
    pl["Appearance"] = "Wygląd";
    pl["Cancel"] = "Anuluj";
    pl["Done"] = "Gotowe";
    pl["Save"] = "Zapisz";
    pl["Delete"] = "Usuń";
    pl["Copy"] = "Kopiuj";
    pl["OK"] = "OK";
    pl["Search"] = "Szukaj";
    pl["Clear"] = "Wyczyść";
    pl["Close"] = "Zamknij";
    pl["Refresh"] = "Odśwież";
    pl["Apply"] = "Zastosuj";
    pl["Filter"] = "Filtr";
    pl["All"] = "Wszystkie";

    // Ghost Mode
    pl["GhostMode"] = "Tryb Ducha";
    pl["GhostMode_Header"] = "TRYB DUCHA (NIEWIDOCZNOŚĆ)";
    pl["GhostMode_Master"] = "Główny przełącznik Trybu Ducha";
    pl["GhostMode_Master_Desc"] = "Włącza pełną niewidoczność we wszystkich aktywnościach.";
    pl["GhostMode_NoReadReceipts"] = "Nie wysyłaj potwierdzeń przeczytania";
    pl["GhostMode_NoReadReceipts_Desc"] = "Nie wysyłaj potwierdzenia po otwarciu wiadomości.";
    pl["GhostMode_HideTyping"] = "Ukryj status pisania";
    pl["GhostMode_HideTyping_Desc"] = "Nie transmituj statusów pisania ani nagrywania.";
    pl["GhostMode_StealthOnline"] = "Dyskretny status online";
    pl["GhostMode_StealthOnline_Desc"] = "Nigdy nie wysyłaj aktualizacji obecności.";
    pl["GhostMode_StealthStory"] = "Dyskretny podgląd relacji";
    pl["GhostMode_StealthStory_Desc"] = "Oglądaj relacje bez pojawiania się na liście widzów.";
    pl["GhostMode_MarkOnReply"] = "Oznacz jako przeczytane przy odpowiedzi";
    pl["GhostMode_MarkOnReply_Desc"] = "Automatycznie oznaczaj jako przeczytane po wysłaniu odpowiedzi.";
    pl["GhostMode_Notice"] = "Uwaga: wysłanie wiadomości na czacie zaktualizuje wskaźnik przeczytania na serwerze.";

    // Spy Mode
    pl["SpyMode"] = "Tryb Szpiega";
    pl["SpyMode_Header"] = "TRYB SZPIEGA (ANTI-RECALL)";
    pl["SpyMode_Master"] = "Główny przełącznik Trybu Szpiega";
    pl["SpyMode_Master_Desc"] = "Włącza archiwizację usuniętych i edytowanych wiadomości.";
    pl["SpyMode_SaveDeleted"] = "Zachowuj usunięte wiadomości";
    pl["SpyMode_SaveDeleted_Desc"] = "Zostawiaj usunięte wiadomości z czerwoną ramką i etykietą.";
    pl["SpyMode_SaveEdits"] = "Zachowuj historię edycji";
    pl["SpyMode_SaveEdits_Desc"] = "Zapisuj wszystkie wersje tekstu z bursztynową ramką.";
    pl["SpyMode_OpenArchive"] = "Otwórz Archiwum Szpiega";
    pl["SpyArchive_Title"] = "Archiwum Szpiega";
    pl["SpyArchive_DeletedTab"] = "Usunięte wiadomości";
    pl["SpyArchive_EditsTab"] = "Wersje edytowane";
    pl["SpyArchive_EmptyDeleted"] = "Brak usuniętych wiadomości.";
    pl["SpyArchive_EmptyEdits"] = "Brak edytowanych wiadomości.";
    pl["Badge_Deleted"] = "🔴 USUNIĘTO";
    pl["Badge_Edited"] = "🟡 EDYTOWANO";

    // LightGram Studio
    pl["Studio_Title"] = "LightGram Studio";
    pl["Studio_Subtitle"] = "Edytor stylu Liquid Glass";
    pl["Studio_PresetThemes"] = "Gotowe motywy";
    pl["Studio_PrimaryAccent"] = "Główny kolor akcentu";
    pl["Studio_SecondaryAccent"] = "Dodatkowy kolor akcentu";
    pl["Studio_BgColor"] = "Tło okna";
    pl["Studio_SidebarColor"] = "Tło panelu bocznego";
    pl["Studio_IncomingBubble"] = "Wiadomość przychodząca";
    pl["Studio_OutgoingBubble"] = "Wiadomość wychodząca";
    pl["Studio_TextColor"] = "Główny kolor tekstu";
    pl["Studio_CornerRadius"] = "Promień zaokrąglenia";
    pl["Studio_GlassOpacity"] = "Przezroczystość szkła";
    pl["Studio_BlurIntensity"] = "Intensywność rozmycia";
    pl["Studio_Import"] = "Importuj motyw...";
    pl["Studio_Export"] = "Eksportuj motyw...";
    pl["Studio_Duplicate"] = "Duplikuj";
    pl["Studio_ResetDefaults"] = "Przywróć domyślne";
    pl["Studio_LivePreview"] = "Podgląd na żywo";

    // Statistics Center
    pl["Statistics_Title"] = "Centrum Statystyk";
    pl["Statistics_Header"] = "STATYSTYKI LIGHTGRAM";
    pl["Statistics_7Days"] = "7 dni";
    pl["Statistics_30Days"] = "30 dni";
    pl["Statistics_AllTime"] = "Cały czas";
    pl["Statistics_Sent"] = "Wysłane";
    pl["Statistics_Received"] = "Odebrane";
    pl["Statistics_Total"] = "Łącznie wiadomości";
    pl["Statistics_ActiveChats"] = "Aktywne czaty";
    pl["Statistics_HourlyHeader"] = "AKTYWNOŚĆ WG GODZIN";
    pl["Statistics_DailyHeader"] = "AKTYWNOŚĆ WG DNI";
    pl["Statistics_TopChatsHeader"] = "NAJAKTYWNIEJSZE CZATY";
    pl["Statistics_ExportPNG"] = "Eksportuj obraz";
    pl["Statistics_ExportPDF"] = "Eksportuj raport";
    pl["Statistics_PeakHour"] = "Godzina szczytu";
    pl["Statistics_PeakDay"] = "Dzień szczytu";
    pl["Statistics_AvgDay"] = "Śr. wiadomości / dzień";

    // Media Vault
    pl["MediaVault_Title"] = "Sejf Multimediów";
    pl["MediaVault_All"] = "Wszystkie";
    pl["MediaVault_Photos"] = "Zdjęcia";
    pl["MediaVault_Videos"] = "Wideo";
    pl["MediaVault_Circles"] = "Kółka";
    pl["MediaVault_Voice"] = "Głos";
    pl["MediaVault_Files"] = "Pliki";
    pl["MediaVault_Favorites"] = "★ Ulubione";
    pl["MediaVault_SaveToVault"] = "Zapisz w Sejfie";
    pl["MediaVault_StorageUsed"] = "Zajęta pamięć";
    pl["MediaVault_ClearVault"] = "Wyczyść (poza ulubionymi)";
    pl["MediaVault_ExportBatch"] = "Eksportuj pliki";

    // Circle Studio
    pl["CircleStudio_Title"] = "Studio Kółek Wideo";
    pl["CircleStudio_Subtitle"] = "Wiadomości wideo 1:1";
    pl["CircleStudio_CropSquare"] = "Kadruj wideo do koła";
    pl["CircleStudio_PlayPreview"] = "Podgląd wideo";
    pl["CircleStudio_Save"] = "Zapisz w Sejfie";

    // Notes & Reminders
    pl["Notes_Title"] = "Notatki i Przypomnienia";
    pl["Notes_TabNotes"] = "Notatki osobiste";
    pl["Notes_TabReminders"] = "Przypomnienia";
    pl["Notes_NewNote"] = "Nowa notatka";
    pl["Notes_NewReminder"] = "Nowe przypomnienie";
    pl["Notes_SaveFromChat"] = "Zapisz wiadomość w notatkach";

    // Smart Folders
    pl["SmartFolders_Title"] = "Inteligentne Foldery";
    pl["SmartFolders_All"] = "Wszystkie";
    pl["SmartFolders_Unread"] = "Nieprzeczytane";
    pl["SmartFolders_Personal"] = "Prywatne";
    pl["SmartFolders_Groups"] = "Grupy";
    pl["SmartFolders_Channels"] = "Kanały";
    pl["SmartFolders_Bots"] = "Boty";
    pl["SmartFolders_Work"] = "Praca";
    pl["SmartFolders_Important"] = "Ważne";
    pl["SmartFolders_Archived"] = "Archiwum";

    // Diagnostics
    pl["Diagnostics_Title"] = "Diagnostyka sieci";
    pl["Diagnostics_DC1"] = "DC1 (Miami, USA)";
    pl["Diagnostics_DC2"] = "DC2 (Amsterdam, Europa)";
    pl["Diagnostics_DC3"] = "DC3 (Miami, USA)";
    pl["Diagnostics_DC4"] = "DC4 (Amsterdam, Europa)";
    pl["Diagnostics_DC5"] = "DC5 (Singapur, Azja)";
    pl["Diagnostics_PingAll"] = "Testuj wszystkie DC";

    // Desktop features
    pl["Desktop_Tabs"] = "Karty czatów";
    pl["Desktop_DetachWindow"] = "Otwórz w osobnym oknie";
    pl["Desktop_GlobalSearch"] = "Szukaj czatów, wiadomości i opcji (Ctrl+K)...";
    pl["Desktop_DropFiles"] = "Upuść pliki tutaj, aby wysłać";
    pl["Desktop_Autostart"] = "Uruchamiaj ze startem systemu";
    pl["Desktop_MinimizeToTray"] = "Minimalizuj do zasobnika systemowego";
    pl["Desktop_CompactMode"] = "Tryb kompaktowy";
    pl["Desktop_Fullscreen"] = "Tryb pełnoekranowy (F11)";
    pl["Desktop_Accounts"] = "Konta";
    pl["Desktop_AddAccount"] = "Dodaj konto";
    pl["Desktop_Logout"] = "Wyloguj";

    // Auth
    pl["Auth_Title"] = "Logowanie do Telegram";
    pl["Auth_Phone"] = "Numer telefonu";
    pl["Auth_Code"] = "Kod weryfikacyjny";
    pl["Auth_Password"] = "Hasło w chmurze (2FA)";
    pl["Auth_SendCode"] = "Wyślij kod";
    pl["Auth_Login"] = "Zaloguj";
    pl["Auth_QrLogin"] = "Logowanie przez kod QR";
    m_strings[Language::Polish] = pl;
}

} // namespace LightGram

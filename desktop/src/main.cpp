#include <QApplication>
#include <QIcon>
#include <QCommandLineParser>
#include <QTimer>
#include "ui/MainWindow.hpp"
#include "core/ThemeEngine.hpp"
#include "core/Settings.hpp"
#include "core/Localization.hpp"
#include "core/TelegramClient.hpp"

int main(int argc, char* argv[]) {
    // High-DPI support
    QApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

    QApplication app(argc, argv);
    app.setApplicationName("LightGram");
    app.setApplicationDisplayName("LightGram Desktop");
    app.setOrganizationName("LightGram");
    app.setOrganizationDomain("lightgram.site");
    app.setApplicationVersion("1.0.0");

    // Default icon
    app.setWindowIcon(QIcon(":/icons/amber.png"));

    // Command line parser
    QCommandLineParser parser;
    parser.setApplicationDescription("LightGram Desktop — High-Performance Telegram Client with Liquid Glass & iOS 27 design");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption startMinimizedOption(QStringList() << "m" << "minimized", "Start application minimized to tray");
    parser.addOption(startMinimizedOption);

    QCommandLineOption smokeTestOption("smoke-test", "Run smoke test and exit");
    parser.addOption(smokeTestOption);

    parser.process(app);

    // Initialize core subsystems
    LightGram::Settings::instance();
    LightGram::Localization::instance().setLanguageByCode(LightGram::Settings::instance().language());
    LightGram::ThemeEngine::instance();
    LightGram::TelegramClient::instance().startConnection();

    // Launch Main Window
    LightGram::MainWindow mainWindow;
    if (parser.isSet(startMinimizedOption)) {
        mainWindow.hide();
    } else {
        mainWindow.show();
    }

    if (parser.isSet(smokeTestOption)) {
        QTimer::singleShot(1500, &app, &QCoreApplication::quit);
    }

    return app.exec();
}

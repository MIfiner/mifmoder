#include "AuthDialog.hpp"
#include "../core/TelegramClient.hpp"
#include "../core/Localization.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QMessageBox>

namespace LightGram {

AuthDialog::AuthDialog(QWidget* parent) : QDialog(parent) {
    setWindowTitle(trL("Auth_Title"));
    setFixedSize(400, 480);
    setupUi();
}

void AuthDialog::setupUi() {
    QVBoxLayout* mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(24, 24, 24, 24);
    mainLayout->setSpacing(16);

    QLabel* logo = new QLabel("⚡", this);
    logo->setStyleSheet("font-size: 36px; color: #EDB400;");
    logo->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(logo);

    QLabel* title = new QLabel("Telegram Login", this);
    title->setStyleSheet("font-size: 20px; font-weight: bold; color: #FFFFFF;");
    title->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(title);

    m_stack = new QStackedWidget(this);

    // Page 0: Phone Number
    QWidget* phonePage = new QWidget(m_stack);
    QVBoxLayout* pl = new QVBoxLayout(phonePage);
    pl->setSpacing(12);

    QLabel* phLbl = new QLabel(trL("Auth_Phone") + ":", phonePage);
    pl->addWidget(phLbl);

    m_phoneEdit = new QLineEdit(phonePage);
    m_phoneEdit->setPlaceholderText("+1 234 567 8900");
    pl->addWidget(m_phoneEdit);

    m_sendCodeBtn = new QPushButton(trL("Auth_SendCode"), phonePage);
    m_sendCodeBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(m_sendCodeBtn, &QPushButton::clicked, this, &AuthDialog::onSendPhone);
    pl->addWidget(m_sendCodeBtn);

    QPushButton* qrBtn = new QPushButton(trL("Auth_QrLogin"), phonePage);
    connect(qrBtn, &QPushButton::clicked, this, &AuthDialog::onSwitchToQr);
    pl->addWidget(qrBtn);
    pl->addStretch();
    m_stack->addWidget(phonePage);

    // Page 1: Auth Code
    QWidget* codePage = new QWidget(m_stack);
    QVBoxLayout* cl = new QVBoxLayout(codePage);
    cl->setSpacing(12);

    QLabel* codeLbl = new QLabel(trL("Auth_Code") + ":", codePage);
    cl->addWidget(codeLbl);

    m_codeEdit = new QLineEdit(codePage);
    m_codeEdit->setPlaceholderText("12345");
    cl->addWidget(m_codeEdit);

    m_loginBtn = new QPushButton(trL("Auth_Login"), codePage);
    m_loginBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(m_loginBtn, &QPushButton::clicked, this, &AuthDialog::onSendCode);
    cl->addWidget(m_loginBtn);
    cl->addStretch();
    m_stack->addWidget(codePage);

    // Page 2: 2FA Password
    QWidget* passPage = new QWidget(m_stack);
    QVBoxLayout* passl = new QVBoxLayout(passPage);
    passl->setSpacing(12);

    QLabel* pLbl = new QLabel(trL("Auth_Password") + ":", passPage);
    passl->addWidget(pLbl);

    m_passEdit = new QLineEdit(passPage);
    m_passEdit->setEchoMode(QLineEdit::Password);
    passl->addWidget(m_passEdit);

    m_passBtn = new QPushButton(trL("Auth_Login"), passPage);
    m_passBtn->setStyleSheet("QPushButton { background-color: #EDB400; color: #000000; font-weight: bold; }");
    connect(m_passBtn, &QPushButton::clicked, this, &AuthDialog::onSendPassword);
    passl->addWidget(m_passBtn);
    passl->addStretch();
    m_stack->addWidget(passPage);

    // Page 3: QR Code
    QWidget* qrPage = new QWidget(m_stack);
    QVBoxLayout* qrl = new QVBoxLayout(qrPage);
    qrl->setSpacing(12);

    QLabel* qrInfo = new QLabel("Scan this QR code with Telegram on your phone:", qrPage);
    qrInfo->setWordWrap(true);
    qrInfo->setAlignment(Qt::AlignCenter);
    qrl->addWidget(qrInfo);

    m_qrLabel = new QLabel("QR Code", qrPage);
    m_qrLabel->setFixedSize(200, 200);
    m_qrLabel->setAlignment(Qt::AlignCenter);
    m_qrLabel->setStyleSheet("background: #FFFFFF; color: #000000; font-weight: bold; border-radius: 12px;");
    qrl->addWidget(m_qrLabel, 0, Qt::AlignCenter);

    QPushButton* backPhoneBtn = new QPushButton("Log in via Phone Number", qrPage);
    connect(backPhoneBtn, &QPushButton::clicked, this, &AuthDialog::onSwitchToPhone);
    qrl->addWidget(backPhoneBtn);
    qrl->addStretch();
    m_stack->addWidget(qrPage);

    mainLayout->addWidget(m_stack, 1);
}

void AuthDialog::onSendPhone() {
    QString p = m_phoneEdit->text().trimmed();
    if (p.isEmpty()) {
        QMessageBox::warning(this, "Login", "Please enter a valid phone number.");
        return;
    }
    TelegramClient::instance().sendPhoneNumber(p);
    m_stack->setCurrentIndex(1); // Code page
}

void AuthDialog::onSendCode() {
    QString c = m_codeEdit->text().trimmed();
    if (c.isEmpty()) {
        QMessageBox::warning(this, "Login", "Please enter the code received on your devices.");
        return;
    }
    TelegramClient::instance().sendAuthCode(c);
    if (TelegramClient::instance().isAuthorized()) {
        QMessageBox::information(this, "Login", "Authorized successfully!");
        accept();
    } else {
        m_stack->setCurrentIndex(2); // 2FA page if needed
    }
}

void AuthDialog::onSendPassword() {
    QString pass = m_passEdit->text();
    TelegramClient::instance().sendPassword(pass);
    if (TelegramClient::instance().isAuthorized()) {
        accept();
    }
}

void AuthDialog::onSwitchToQr() {
    TelegramClient::instance().requestQrCode();
    m_stack->setCurrentIndex(3);
}

void AuthDialog::onSwitchToPhone() {
    m_stack->setCurrentIndex(0);
}

} // namespace LightGram

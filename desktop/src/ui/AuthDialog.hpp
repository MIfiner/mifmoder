#pragma once

#include <QDialog>
#include <QLineEdit>
#include <QPushButton>
#include <QLabel>
#include <QStackedWidget>

namespace LightGram {

class AuthDialog : public QDialog {
    Q_OBJECT
public:
    explicit AuthDialog(QWidget* parent = nullptr);

private slots:
    void onSendPhone();
    void onSendCode();
    void onSendPassword();
    void onSwitchToQr();
    void onSwitchToPhone();

private:
    void setupUi();

    QStackedWidget* m_stack = nullptr;

    // Phone page
    QLineEdit* m_phoneEdit = nullptr;
    QPushButton* m_sendCodeBtn = nullptr;

    // Code page
    QLineEdit* m_codeEdit = nullptr;
    QPushButton* m_loginBtn = nullptr;

    // 2FA page
    QLineEdit* m_passEdit = nullptr;
    QPushButton* m_passBtn = nullptr;

    // QR page
    QLabel* m_qrLabel = nullptr;
};

} // namespace LightGram

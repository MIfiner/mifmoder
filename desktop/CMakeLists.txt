cmake_minimum_required(VERSION 3.16)

project(LightGramDesktop
    VERSION 1.0.0
    DESCRIPTION "LightGram Desktop — High-Performance Telegram Client with Liquid Glass Design System"
    HOMEPAGE_URL "https://lightgram.site"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.2 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Network
    Sql
    Svg
)

if (MSVC)
    add_compile_options(/utf-8 /W3)
endif()

set(CORE_SOURCES
    src/core/Types.hpp
    src/core/Localization.hpp
    src/core/Localization.cpp
    src/core/Settings.hpp
    src/core/Settings.cpp
    src/core/GhostController.hpp
    src/core/GhostController.cpp
    src/core/SpyManager.hpp
    src/core/SpyManager.cpp
    src/core/StatisticsManager.hpp
    src/core/StatisticsManager.cpp
    src/core/MediaVaultManager.hpp
    src/core/MediaVaultManager.cpp
    src/core/NotesManager.hpp
    src/core/NotesManager.cpp
    src/core/ThemeEngine.hpp
    src/core/ThemeEngine.cpp
    src/core/TelegramClient.hpp
    src/core/TelegramClient.cpp
)

set(UI_SOURCES
    src/ui/LiquidGlassWidget.hpp
    src/ui/LiquidGlassWidget.cpp
    src/ui/ChatTabsWidget.hpp
    src/ui/ChatTabsWidget.cpp
    src/ui/SidebarWidget.hpp
    src/ui/SidebarWidget.cpp
    src/ui/ChatViewWidget.hpp
    src/ui/ChatViewWidget.cpp
    src/ui/LightGramStudioDialog.hpp
    src/ui/LightGramStudioDialog.cpp
    src/ui/SpyArchiveDialog.hpp
    src/ui/SpyArchiveDialog.cpp
    src/ui/StatisticsDialog.hpp
    src/ui/StatisticsDialog.cpp
    src/ui/MediaVaultDialog.hpp
    src/ui/MediaVaultDialog.cpp
    src/ui/CircleStudioDialog.hpp
    src/ui/CircleStudioDialog.cpp
    src/ui/SmartFoldersDialog.hpp
    src/ui/SmartFoldersDialog.cpp
    src/ui/NotesDialog.hpp
    src/ui/NotesDialog.cpp
    src/ui/ControlCenterDialog.hpp
    src/ui/ControlCenterDialog.cpp
    src/ui/DiagnosticsDialog.hpp
    src/ui/DiagnosticsDialog.cpp
    src/ui/AuthDialog.hpp
    src/ui/AuthDialog.cpp
    src/ui/MainWindow.hpp
    src/ui/MainWindow.cpp
)

set(RESOURCES
    resources/lightgram.qrc
)

set(WIN_RESOURCES "")
if (WIN32)
    set(WIN_RESOURCES resources/lightgram.rc)
endif()

add_executable(lightgram-desktop
    src/main.cpp
    ${CORE_SOURCES}
    ${UI_SOURCES}
    ${RESOURCES}
    ${WIN_RESOURCES}
)

target_include_directories(lightgram-desktop PRIVATE
    src
    src/core
    src/ui
)

target_link_libraries(lightgram-desktop PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Network
    Qt6::Sql
    Qt6::Svg
)

if (WIN32)
    set_target_properties(lightgram-desktop PROPERTIES
        WIN32_EXECUTABLE TRUE
        OUTPUT_NAME "LightGram"
    )
elseif (APPLE)
    set_target_properties(lightgram-desktop PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "LightGram"
        MACOSX_BUNDLE_GUI_IDENTIFIER "site.lightgram.desktop"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
    )
endif()

if (WIN32)
    install(TARGETS lightgram-desktop
        RUNTIME DESTINATION .
    )

    find_package(Qt6Core REQUIRED)
    get_target_property(_qmake_executable Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
    find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${_qt_bin_dir}")

    if (WINDEPLOYQT_EXECUTABLE)
        install(CODE "
            file(TO_NATIVE_PATH \"\${CMAKE_INSTALL_PREFIX}/LightGram.exe\" _native_exe)
            message(STATUS \"Running windeployqt on \${_native_exe}...\")
            execute_process(
                COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
                    --no-translations
                    --compiler-runtime
                    \"\${_native_exe}\"
                RESULT_VARIABLE _windeployqt_res
            )
            if (NOT _windeployqt_res EQUAL 0)
                message(WARNING \"windeployqt returned code: \${_windeployqt_res}\")
            endif()
        ")
    endif()
else()
    install(TARGETS lightgram-desktop
        BUNDLE DESTINATION .
        RUNTIME DESTINATION bin
    )
endif()

# CPack Packaging Configuration
set(CPACK_PACKAGE_NAME "LightGram")
set(CPACK_PACKAGE_VENDOR "LightGram Team")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "LightGram Desktop Telegram Client")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")

if (WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    set(CPACK_PACKAGE_FILE_NAME "LightGram-${PROJECT_VERSION}-Windows-x64")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "LightGram")
    set(CPACK_NSIS_DISPLAY_NAME "LightGram Desktop")
    set(CPACK_NSIS_PACKAGE_NAME "LightGram Desktop")
    set(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/lightgram.ico")
    set(CPACK_NSIS_MUI_UNIICON "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/lightgram.ico")
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    set(CPACK_NSIS_MODIFY_PATH OFF)
    set(CPACK_NSIS_CREATE_ICONS_EXTRA
        "CreateShortCut '$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\LightGram.lnk' '$INSTDIR\\\\LightGram.exe'"
        "CreateShortCut '$DESKTOP\\\\LightGram.lnk' '$INSTDIR\\\\LightGram.exe'"
    )
    set(CPACK_NSIS_DELETE_ICONS_EXTRA
        "Delete '$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\LightGram.lnk'"
        "Delete '$DESKTOP\\\\LightGram.lnk'"
    )
else()
    set(CPACK_GENERATOR "TGZ;DEB")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "LightGram <support@lightgram.site>")
    set(CPACK_DEBIAN_PACKAGE_SECTION "net")
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "libqt6widgets6t64, libqt6network6t64, libqt6svg6")
endif()

include(CPack)

# Unit Tests Target
enable_testing()
find_package(Qt6 REQUIRED COMPONENTS Test)
add_executable(test_lightgram
    tests/test_lightgram.cpp
    ${CORE_SOURCES}
    ${RESOURCES}
)
target_include_directories(test_lightgram PRIVATE
    src
    src/core
    src/ui
)
target_link_libraries(test_lightgram PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Network
    Qt6::Sql
    Qt6::Svg
    Qt6::Test
)
add_test(NAME LightGramDesktopTests COMMAND test_lightgram)

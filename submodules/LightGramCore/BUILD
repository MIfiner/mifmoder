load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl", "ios_test_runner")

swift_library(
    name = "LightGramCore",
    module_name = "LightGramCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/AlertUI:AlertUI",
        "//submodules/AppBundle:AppBundle",
    ],
    visibility = [
        "//visibility:public",
    ],
)

swift_library(
    name = "LightGramCoreTestsLib",
    testonly = True,
    srcs = glob([
        "Tests/**/*.swift",
    ]),
    deps = [
        ":LightGramCore",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
)

ios_test_runner(
    name = "LightGramCoreTestRunner",
    device_type = "iPhone 17",
    os_version = "26.5",
)

ios_unit_test(
    name = "LightGramCoreTests",
    deps = [
        ":LightGramCoreTestsLib",
    ],
    runner = ":LightGramCoreTestRunner",
    minimum_os_version = "15.0",
)

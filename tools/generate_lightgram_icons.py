#!/usr/bin/env python3
import os
import sys
from PIL import Image

def resize_icon(src_img, target_path, width, height):
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    resized = src_img.resize((width, height), Image.Resampling.LANCZOS)
    resized.save(target_path, "PNG", optimize=True)
    print(f"Generated: {target_path} ({width}x{height})")

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    src_icon_path = os.path.join(repo_root, "assets", "icon.png")
    if not os.path.exists(src_icon_path):
        print(f"Error: {src_icon_path} not found")
        sys.exit(1)

    src_img = Image.open(src_icon_path).convert("RGB")
    print(f"Loaded source icon: {src_icon_path} size={src_img.size}")

    # 1. DefaultAppIcon.xcassets/AppIconLLC.appiconset
    default_appiconset = os.path.join(repo_root, "Telegram", "Telegram-iOS", "DefaultAppIcon.xcassets", "AppIconLLC.appiconset")
    specs_default = [
        ("Simple-iTunesArtwork.png", 1024, 1024),
        ("BlueIcon@3x.png", 180, 180),
        ("BlueIcon@2x.png", 120, 120),
        ("BlueIcon@2x-1.png", 120, 120),
        ("BlueIconLargeIpad@2x.png", 167, 167),
        ("BlueIconIpad@2x.png", 152, 152),
        ("Simple@87x87.png", 87, 87),
        ("Simple@80x80.png", 80, 80),
        ("Simple@80x80-1.png", 80, 80),
        ("Simple@58x58.png", 58, 58),
        ("Simple@58x58-1.png", 58, 58),
        ("Simple@40x40-1.png", 40, 40),
        ("Simple@29x29.png", 29, 29),
        ("BlueNotificationIcon@3x.png", 60, 60),
        ("BlueNotificationIcon@2x.png", 40, 40),
        ("BlueNotificationIcon@2x-1.png", 40, 40),
        ("BlueNotificationIcon.png", 20, 20),
    ]
    for filename, w, h in specs_default:
        resize_icon(src_img, os.path.join(default_appiconset, filename), w, h)

    # 2. Telegram-iOS/BlueIcon.alticon and BlackIcon.alticon
    for folder in ["BlueIcon.alticon", "BlackIcon.alticon"]:
        alticon_dir = os.path.join(repo_root, "Telegram", "Telegram-iOS", folder)
        prefix = "Blue" if "Blue" in folder else "Black"
        specs_alt = [
            (f"{prefix}Icon@3x.png", 180, 180),
            (f"{prefix}Icon@2x.png", 120, 120),
            (f"{prefix}IconLargeIpad@2x.png", 167, 167),
            (f"{prefix}IconIpad@2x.png", 152, 152),
            (f"{prefix}IconIpad.png", 76, 76),
            (f"{prefix}NotificationIcon@3x.png", 60, 60),
            (f"{prefix}NotificationIcon@2x.png", 40, 40),
            (f"{prefix}NotificationIcon.png", 20, 20),
        ]
        for filename, w, h in specs_alt:
            resize_icon(src_img, os.path.join(alticon_dir, filename), w, h)

    # 3. AppIcons.xcassets
    for iconset, prefix in [("BlueIcon.appiconset", "Icon1"), ("BlackIcon.appiconset", "Icon2")]:
        appicon_dir = os.path.join(repo_root, "Telegram", "Telegram-iOS", "AppIcons.xcassets", iconset)
        specs_appicon = [
            (f"{prefix}@180x180.png", 180, 180),
            (f"{prefix}@167x167.png", 167, 167),
            (f"{prefix}@152x152.png", 152, 152),
            (f"{prefix}@120x120.png", 120, 120),
            (f"{prefix}@120x120-1.png", 120, 120),
            (f"{prefix}@87x87.png", 87, 87),
            (f"{prefix}@80x80.png", 80, 80),
            (f"{prefix}@80x80-1.png", 80, 80),
            (f"{prefix}@76x76.png", 76, 76),
            (f"{prefix}@60x60.png", 60, 60),
            (f"{prefix}@58x58.png", 58, 58),
            (f"{prefix}@58x58-1.png", 58, 58),
            (f"{prefix}@40x40.png", 40, 40),
            (f"{prefix}@40x40-1.png", 40, 40),
            (f"{prefix}@40x40-2.png", 40, 40),
            (f"{prefix}@29x29.png", 29, 29),
            (f"{prefix}@20x20.png", 20, 20),
        ]
        for filename, w, h in specs_appicon:
            resize_icon(src_img, os.path.join(appicon_dir, filename), w, h)

    # 4. WatchApp icons
    watch_app_icon = os.path.join(repo_root, "Telegram", "WatchApp", "tgwatch Watch App", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")
    resize_icon(src_img, watch_app_icon, 1024, 1024)

    watch_dir = os.path.join(repo_root, "Telegram", "Watch", "App", "Assets.xcassets", "AppIcon.appiconset")
    specs_watch = [
        ("Simple-iTunesArtwork.png", 1024, 1024),
        ("Watch216@2x.png", 216, 216),
        ("Watch196@2x.png", 196, 196),
        ("Watch172@2x.png", 172, 172),
        ("Watch100@2x.png", 100, 100),
        ("Watch88@2x.png", 88, 88),
        ("Watch55@2x.png", 55, 55),
        ("Watch48@2x.png", 48, 48),
        ("Simple@87x87.png", 87, 87),
        ("Simple@80x80.png", 80, 80),
        ("Simple@58x58.png", 58, 58),
    ]
    for filename, w, h in specs_watch:
        resize_icon(src_img, os.path.join(watch_dir, filename), w, h)

    print("\n[SUCCESS] All LightGram icons successfully generated across asset catalogs!")

if __name__ == "__main__":
    main()

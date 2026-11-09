#!/usr/bin/env python3
import os
import sys
import json
import base64
import hashlib
import subprocess
import urllib.request
import shutil
import re
import glob

def fetch_and_cache(url, expected_sha256, repo_cache_dir, temp_dir):
    expected_sha256 = expected_sha256.lower().strip()
    target_dir = os.path.join(repo_cache_dir, "content_addressable", "sha256", expected_sha256)
    target_file = os.path.join(target_dir, "file")

    url_id_hash = hashlib.sha256(url.encode("utf-8")).hexdigest()
    marker_file = os.path.join(target_dir, f"id-{url_id_hash}")

    if os.path.isfile(target_file) and os.path.getsize(target_file) > 0:
        print(f"Already cached: {url}")
        if not os.path.isfile(marker_file):
            try:
                with open(marker_file, "w") as mf:
                    mf.write(f"{url}\n")
            except Exception:
                pass
        return True

    os.makedirs(target_dir, exist_ok=True)
    print(f"Prefetching: {url} -> {expected_sha256}")

    downloaded = False
    # If GitHub Release, prefer authenticated `gh release download`
    if "github.com" in url and "/releases/download/" in url:
        try:
            parts = url.split("/")
            owner = parts[3]
            repo = parts[4]
            tag = parts[7]
            filename = parts[8]
            cmd = ["gh", "release", "download", tag, "--repo", f"{owner}/{repo}", "--pattern", filename, "--dir", temp_dir, "--clobber"]
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=90)
            downloaded_file = os.path.join(temp_dir, filename)
            if res.returncode == 0 and os.path.isfile(downloaded_file):
                shutil.move(downloaded_file, target_file)
                downloaded = True
        except Exception as e:
            print(f"gh release download failed for {url}: {e}")

    if not downloaded:
        try:
            # Use GitHub token header if available
            gh_token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
            curl_headers = ["-H", f"Authorization: Bearer {gh_token}"] if (gh_token and "github.com" in url) else []
            cmd = ["curl", "-sSL", "--connect-timeout", "15", "--max-time", "120", "--retry", "3"] + curl_headers + [url, "-o", target_file]
            res = subprocess.run(cmd, timeout=130)
            if res.returncode == 0 and os.path.isfile(target_file) and os.path.getsize(target_file) > 0:
                downloaded = True
        except Exception as e:
            print(f"curl download failed for {url}: {e}")

    if downloaded and os.path.isfile(target_file):
        with open(target_file, "rb") as f:
            actual_sha256 = hashlib.sha256(f.read()).hexdigest()
        if actual_sha256 == expected_sha256:
            print(f"Verified OK: {url}")
            with open(marker_file, "w") as mf:
                mf.write(f"{url}\n")
            return True
        else:
            print(f"Checksum mismatch for {url}: expected {expected_sha256}, got {actual_sha256}")
            try:
                os.remove(target_file)
            except Exception:
                pass
            return False
    return False

def find_all_module_http_rules(root_dir):
    rules = []
    pattern = re.compile(r'(http_archive|http_file)\s*\(\s*(.*?)\n\)', re.DOTALL)
    is_darwin = sys.platform == "darwin"
    is_linux = sys.platform.startswith("linux")

    for p in glob.glob(os.path.join(root_dir, "**/MODULE.bazel"), recursive=True):
        try:
            with open(p, "r", encoding="utf-8") as f:
                content = f.read()
            for m in pattern.finditer(content):
                block = m.group(2)
                urls_match = re.search(r'urls?\s*=\s*\[(.*?)\]', block, re.DOTALL)
                sha_match = re.search(r'sha256\s*=\s*\"([0-9a-fA-F]{64})\"', block)
                if urls_match and sha_match:
                    raw_urls = re.findall(r'\"(https?://[^\"]+)\"', urls_match.group(1))
                    sha = sha_match.group(1).lower()
                    for u in raw_urls:
                        # Skip mismatched OS packages to save bandwidth and CI time
                        if is_darwin and ("-linux" in u.lower() or "_linux" in u.lower()):
                            continue
                        if is_linux and ("-macos" in u.lower() or "_macos" in u.lower() or "-mac" in u.lower() or "_mac" in u.lower()):
                            continue
                        rules.append((u, sha))
        except Exception as e:
            print(f"Warning scanning {p}: {e}")
    return rules

def main():
    repo_cache_dir = sys.argv[1] if len(sys.argv) > 1 else "/private/var/tmp/bazel-repo-cache"
    lock_file = sys.argv[2] if len(sys.argv) > 2 else "MODULE.bazel.lock"
    workspace_dir = os.path.dirname(os.path.abspath(lock_file))

    temp_dir = "/tmp/bcr_prefetch"
    os.makedirs(temp_dir, exist_ok=True)

    # 1. Prefetch BCR source dependencies from MODULE.bazel.lock
    if os.path.exists(lock_file):
        with open(lock_file, "r") as f:
            data = json.load(f)

        sources = [k for k in data.get("registryFileHashes", {}) if "source.json" in k]
        print(f"Prefetching {len(sources)} BCR sources into {repo_cache_dir}...")

        for s in sources:
            try:
                req = urllib.request.Request(s, headers={"User-Agent": "Bazel-Prefetch/1.0"})
                with urllib.request.urlopen(req, timeout=10) as response:
                    info = json.loads(response.read().decode("utf-8"))
            except Exception as e:
                print(f"Warning: could not fetch {s}: {e}")
                continue

            url = info.get("url", "")
            integ = info.get("integrity", "")
            if not url or not integ:
                continue

            if not integ.startswith("sha256-"):
                continue

            expected_sha256 = base64.b64decode(integ.split("-")[1]).hex()
            fetch_and_cache(url, expected_sha256, repo_cache_dir, temp_dir)

    # 2. Prefetch non-BCR http_file and http_archive rules from all MODULE.bazel files
    module_rules = find_all_module_http_rules(workspace_dir)
    print(f"Prefetching {len(module_rules)} MODULE.bazel http rules into {repo_cache_dir}...")
    for url, sha in module_rules:
        fetch_and_cache(url, sha, repo_cache_dir, temp_dir)

    print("All dependency prefetching complete.")
    return 0

if __name__ == "__main__":
    sys.exit(main())

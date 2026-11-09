#!/usr/bin/env python3
import os
import sys
import json
import base64
import hashlib
import subprocess
import urllib.request
import shutil

def main():
    repo_cache_dir = sys.argv[1] if len(sys.argv) > 1 else "/private/var/tmp/bazel-repo-cache"
    lock_file = sys.argv[2] if len(sys.argv) > 2 else "MODULE.bazel.lock"
    
    if not os.path.exists(lock_file):
        print(f"Lock file {lock_file} not found.")
        return 0

    with open(lock_file, "r") as f:
        data = json.load(f)

    sources = [k for k in data.get("registryFileHashes", {}) if "source.json" in k]
    print(f"Prefetching {len(sources)} BCR sources into {repo_cache_dir}...")

    temp_dir = "/tmp/bcr_prefetch"
    os.makedirs(temp_dir, exist_ok=True)

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
        target_dir = os.path.join(repo_cache_dir, "content_addressable", "sha256", expected_sha256)
        target_file = os.path.join(target_dir, "file")

        if os.path.isfile(target_file) and os.path.getsize(target_file) > 0:
            print(f"Already cached: {url}")
            continue

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
                res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
                downloaded_file = os.path.join(temp_dir, filename)
                if res.returncode == 0 and os.path.isfile(downloaded_file):
                    shutil.move(downloaded_file, target_file)
                    downloaded = True
            except Exception as e:
                print(f"gh release download failed for {url}: {e}")

        if not downloaded:
            try:
                cmd = ["curl", "-sSL", "--connect-timeout", "15", "--max-time", "60", "--retry", "3", url, "-o", target_file]
                res = subprocess.run(cmd, timeout=70)
                if res.returncode == 0 and os.path.isfile(target_file) and os.path.getsize(target_file) > 0:
                    downloaded = True
            except Exception as e:
                print(f"curl download failed for {url}: {e}")

        if downloaded and os.path.isfile(target_file):
            with open(target_file, "rb") as f:
                actual_sha256 = hashlib.sha256(f.read()).hexdigest()
            if actual_sha256 == expected_sha256:
                print(f"Verified OK: {url}")
            else:
                print(f"Checksum mismatch for {url}: expected {expected_sha256}, got {actual_sha256}")
                try:
                    os.remove(target_file)
                except Exception:
                    pass

    print("BCR prefetching complete.")
    return 0

if __name__ == "__main__":
    sys.exit(main())

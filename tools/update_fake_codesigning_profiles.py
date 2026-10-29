#!/usr/bin/env python3
import os
import sys
import plistlib
import subprocess
import tempfile
import datetime

def update_profiles(repo_dir, bundle_id="site.lightgram.ios", team_id="C67CF9S4VU"):
    profiles_dir = os.path.join(repo_dir, "build-system/fake-codesigning/profiles")
    certs_dir = os.path.join(repo_dir, "build-system/fake-codesigning/certs")
    p12_path = os.path.join(certs_dir, "SelfSigned.p12")

    if not os.path.exists(profiles_dir) or not os.path.exists(p12_path):
        print(f"Error: {profiles_dir} or {p12_path} does not exist")
        sys.exit(1)

    # Extract PEM from SelfSigned.p12
    # Try with -legacy flag first, then fallback without it
    proc = subprocess.run(["openssl", "pkcs12", "-in", p12_path, "-passin", "pass:", "-nodes", "-legacy"], capture_output=True)
    if proc.returncode != 0:
        proc = subprocess.run(["openssl", "pkcs12", "-in", p12_path, "-passin", "pass:", "-nodes"], capture_output=True)
    if proc.returncode != 0:
        print("Failed to extract PEM from p12:", proc.stderr.decode())
        sys.exit(1)
    
    p12_pem = proc.stdout

    with tempfile.NamedTemporaryFile("wb", delete=False) as pem_file:
        pem_file.write(p12_pem)
        pem_path = pem_file.name

    try:
        old_bundle_id = "ph.telegra.Telegraph"
        old_team_id = "C67CF9S4VU"

        for file_name in sorted(os.listdir(profiles_dir)):
            if not file_name.endswith(".mobileprovision"):
                continue

            file_path = os.path.join(profiles_dir, file_name)
            
            # Read profile plist
            res = subprocess.run(
                ["openssl", "smime", "-inform", "der", "-verify", "-noverify", "-in", file_path],
                capture_output=True
            )
            if res.returncode != 0:
                print(f"Warning: Failed to verify {file_name}: {res.stderr.decode()}")
                continue

            plist = plistlib.loads(res.stdout)

            # Update dates
            now = datetime.datetime.now(datetime.timezone.utc)
            plist["CreationDate"] = now
            plist["ExpirationDate"] = now + datetime.timedelta(days=1000)
            plist["TimeToLive"] = 1000

            # Update Name
            if "Name" in plist and isinstance(plist["Name"], str):
                plist["Name"] = plist["Name"].replace(old_bundle_id, bundle_id)

            # Update TeamIdentifier
            if "TeamIdentifier" in plist:
                plist["TeamIdentifier"] = [team_id]

            # Update Entitlements
            entitlements = plist.get("Entitlements", {})
            if "com.apple.developer.team-identifier" in entitlements:
                entitlements["com.apple.developer.team-identifier"] = team_id

            if "application-identifier" in entitlements:
                app_id = entitlements["application-identifier"]
                if app_id.startswith(f"{old_team_id}.{old_bundle_id}"):
                    suffix = app_id[len(f"{old_team_id}.{old_bundle_id}"):]
                    entitlements["application-identifier"] = f"{team_id}.{bundle_id}{suffix}"

            if "com.apple.security.application-groups" in entitlements:
                entitlements["com.apple.security.application-groups"] = [f"group.{bundle_id}"]

            if "com.apple.developer.icloud-container-identifiers" in entitlements:
                entitlements["com.apple.developer.icloud-container-identifiers"] = [f"iCloud.{bundle_id}"]
            if "com.apple.developer.icloud-container-development-container-identifiers" in entitlements:
                entitlements["com.apple.developer.icloud-container-development-container-identifiers"] = [f"iCloud.{bundle_id}"]
            if "com.apple.developer.ubiquity-container-identifiers" in entitlements:
                entitlements["com.apple.developer.ubiquity-container-identifiers"] = [f"iCloud.{bundle_id}"]

            if "keychain-access-groups" in entitlements:
                entitlements["keychain-access-groups"] = [f"{team_id}.*", "com.apple.token"]

            if "com.apple.developer.ubiquity-kvstore-identifier" in entitlements:
                entitlements["com.apple.developer.ubiquity-kvstore-identifier"] = f"{team_id}.*"

            # Write updated plist to temp file
            updated_plist_bytes = plistlib.dumps(plist)
            with tempfile.NamedTemporaryFile("wb", delete=False) as in_file:
                in_file.write(updated_plist_bytes)
                in_path = in_file.name

            out_path = tempfile.mktemp()
            try:
                # Sign with openssl smime
                subprocess.check_call([
                    "openssl", "smime", "-sign",
                    "-signer", pem_path,
                    "-inkey", pem_path,
                    "-nodetach",
                    "-outform", "DER",
                    "-in", in_path,
                    "-out", out_path
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

                # Overwrite original profile
                with open(out_path, "rb") as f_out, open(file_path, "wb") as f_dest:
                    f_dest.write(f_out.read())

                print(f"Updated and re-signed {file_name}: {entitlements.get('application-identifier')}")
            finally:
                if os.path.exists(in_path):
                    os.unlink(in_path)
                if os.path.exists(out_path):
                    os.unlink(out_path)

    finally:
        if os.path.exists(pem_path):
            os.unlink(pem_path)

if __name__ == "__main__":
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    b_id = sys.argv[1] if len(sys.argv) > 1 else "site.lightgram.ios"
    t_id = sys.argv[2] if len(sys.argv) > 2 else "C67CF9S4VU"
    update_profiles(repo_root, bundle_id=b_id, team_id=t_id)

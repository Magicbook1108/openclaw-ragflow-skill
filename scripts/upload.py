#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RAGFlow Document Upload
Upload documents to RAGFlow using session cookie from browser
"""

import os
import sys
import json
import urllib.request
import io

# Fix Windows UTF-8 output
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def load_env():
    """Load .env file from parent directory"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_file = os.path.join(script_dir, '..', '.env')

    if not os.path.exists(env_file):
        openclaw_env = os.path.expanduser('~/.openclaw/workspace/skills/ragflow-knowledge/.env')
        if os.path.exists(openclaw_env):
            env_file = openclaw_env

    if not os.path.exists(env_file):
        return {}

    env_vars = {}
    with open(env_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line and not line.startswith('export'):
                key, value = line.split('=', 1)
                value = value.strip()
                if value.startswith('[') and value.endswith(']'):
                    try:
                        env_vars[key.strip()] = json.loads(value)
                    except:
                        env_vars[key.strip()] = value
                else:
                    env_vars[key.strip()] = value

    return env_vars

def upload_document(session_cookie, dataset_id, file_path):
    """Upload document to RAGFlow using session cookie"""
    api_url = os.getenv('RAGFLOW_API_URL', 'http://127.0.0.1')

    if not os.path.exists(file_path):
        print(f"[Error] File not found: {file_path}")
        return False

    filename = os.path.basename(file_path)

    # Read file content
    with open(file_path, 'rb') as f:
        file_content = f.read()

    # Create multipart/form-data boundary
    boundary = '----WebKitFormBoundary' + os.urandom(16).hex()

    # Build request body
    body = (
        f'------{boundary}\r\n'
        f'Content-Disposition: form-data; name="kb_id"\r\n\r\n'
        f'{dataset_id}\r\n'
        f'------{boundary}\r\n'
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
        f'Content-Type: application/octet-stream\r\n\r\n'
    ).encode('utf-8')

    body += file_content
    body += f'\r\n------{boundary}--\r\n'.encode('utf-8')

    # Make request
    url = f"{api_url}/api/v1/document/upload"
    req = urllib.request.Request(url, data=body, method='POST')

    # Set headers
    req.add_header('Content-Type', f'multipart/form-data; boundary=----{boundary}')
    req.add_header('Cookie', session_cookie)

    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.loads(response.read().decode('utf-8'))
            if result.get('code') == 0:
                print(f"[OK] File uploaded successfully!")
                print(f"     Result: {result.get('data', [])}")
                return True
            else:
                print(f"[Error] Upload failed: {result.get('message', 'Unknown error')}")
                return False
    except urllib.error.HTTPError as e:
        print(f"[Error] HTTP Error {e.code}: {e.reason}")
        return False
    except Exception as e:
        print(f"[Error] Upload failed: {e}")
        return False

def main():
    if len(sys.argv) < 3:
        print("RAGFlow Document Upload (requires browser session)")
        print("")
        print("Usage: python upload.py <dataset_id> <file_path>")
        print("")
        print("Get session cookie from browser:")
        print("1. Login to RAGFlow in your browser")
        print("2. Open Developer Tools (F12)")
        print("3. Go to Application > Cookies")
        print("4. Find the session cookie (usually 'session' or 'user_session')")
        print("5. Copy the cookie value")
        print("")
        print("Set environment variable:")
        echo "export RAGFLOW_SESSION_COOKIE='your-cookie-here'"
        return

    dataset_id = sys.argv[1]
    file_path = sys.argv[2]

    # Get session cookie from environment
    session_cookie = os.getenv('RAGFLOW_SESSION_COOKIE')

    if not session_cookie:
        print("[Error] RAGFLOW_SESSION_COOKIE not set!")
        print("")
        print("Please set it:")
        print("  export RAGFLOW_SESSION_COOKIE='your-cookie-here'")
        print("")
        print("Or add to .env file:")
        print("  RAGFLOW_SESSION_COOKIE=your-cookie-here")
        sys.exit(1)

    upload_document(session_cookie, dataset_id, file_path)

if __name__ == '__main__':
    main()

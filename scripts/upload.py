#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Upload one or more documents to a RAGFlow dataset using the current SDK API.
Usage: python scripts/upload.py <dataset_id> <file1> [file2 ...]
"""

import json
import mimetypes
import os
import sys
import uuid
from urllib import request, error
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')


def load_env():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_file = os.path.join(script_dir, '..', '.env')
    if not os.path.exists(env_file):
        return {}

    env_vars = {}
    with open(env_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line or line.startswith('export'):
                continue
            key, value = line.split('=', 1)
            env_vars[key.strip()] = value.strip()
    return env_vars


def build_multipart(file_paths):
    boundary = '----OpenClawBoundary' + uuid.uuid4().hex
    body = bytearray()

    for file_path in file_paths:
        filename = os.path.basename(file_path)
        mime = mimetypes.guess_type(filename)[0] or 'application/octet-stream'
        with open(file_path, 'rb') as f:
            content = f.read()

        body.extend(f'--{boundary}\r\n'.encode())
        body.extend(
            f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode()
        )
        body.extend(f'Content-Type: {mime}\r\n\r\n'.encode())
        body.extend(content)
        body.extend(b'\r\n')

    body.extend(f'--{boundary}--\r\n'.encode())
    return boundary, bytes(body)


def upload_documents(dataset_id, file_paths):
    env = load_env()
    api_url = env.get('RAGFLOW_API_URL', 'http://127.0.0.1').rstrip('/')
    api_key = env.get('RAGFLOW_API_KEY', '')

    if not api_key:
        print('[Error] RAGFLOW_API_KEY not set in .env')
        return 1

    missing = [p for p in file_paths if not os.path.exists(p)]
    if missing:
        print('[Error] File(s) not found:')
        for p in missing:
            print(f'  - {p}')
        return 1

    boundary, data = build_multipart(file_paths)
    url = f'{api_url}/api/v1/datasets/{dataset_id}/documents'
    req = request.Request(url, data=data, method='POST')
    req.add_header('Authorization', f'Bearer {api_key}')
    req.add_header('Content-Type', f'multipart/form-data; boundary={boundary}')

    try:
        with request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode('utf-8'))
    except error.HTTPError as e:
        print(f'[Error] HTTP {e.code}: {e.reason}')
        try:
            print(e.read().decode('utf-8'))
        except Exception:
            pass
        return 1
    except Exception as e:
        print(f'[Error] Upload failed: {e}')
        return 1

    if result.get('code') != 0:
        print(f"[Error] Upload failed: {result.get('message', 'unknown error')}")
        return 1

    docs = result.get('data', [])
    print(f'[OK] Uploaded {len(docs)} document(s) to dataset {dataset_id}')
    for doc in docs:
        print(json.dumps({
            'id': doc.get('id'),
            'name': doc.get('name'),
            'dataset_id': doc.get('dataset_id'),
            'run': doc.get('run'),
            'chunk_method': doc.get('chunk_method')
        }, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python scripts/upload.py <dataset_id> <file1> [file2 ...]')
        sys.exit(1)
    sys.exit(upload_documents(sys.argv[1], sys.argv[2:]))

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import mimetypes
import os
import urllib.error
import urllib.request
import uuid
from pathlib import Path
from typing import Any

from common import (
    ApiError,
    ConfigError,
    ScriptError,
    configure_stdio_utf8,
    current_timestamp,
    decode_json_response,
    ensure_success,
    extract_error_message,
    format_json,
    load_repo_env,
    repo_root_from_path,
    require_api_key,
    resolve_base_url,
)


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Upload one or more documents to a RAGFlow dataset.")
    parser.add_argument("dataset_id", help="Dataset ID")
    parser.add_argument("files", nargs="+", help="File paths to upload")
    parser.add_argument("--json", action="store_true", dest="json_output", help="Print JSON output")
    parser.add_argument(
        "--base-url",
        help="Base URL for the RAGFlow server (priority: --base-url > RAGFLOW_API_URL > RAGFLOW_BASE_URL > HOST_ADDRESS > default)",
    )
    return parser.parse_args(argv)


def _build_multipart(file_paths: list[str]) -> tuple[str, bytes]:
    boundary = "----OpenClawBoundary" + uuid.uuid4().hex
    body = bytearray()

    for file_path in file_paths:
        filename = os.path.basename(file_path)
        mime = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        with open(file_path, "rb") as file_obj:
            content = file_obj.read()

        body.extend(f"--{boundary}\r\n".encode())
        body.extend(
            f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode()
        )
        body.extend(f"Content-Type: {mime}\r\n\r\n".encode())
        body.extend(content)
        body.extend(b"\r\n")

    body.extend(f"--{boundary}--\r\n".encode())
    return boundary, bytes(body)


def _normalize_document(document: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": document.get("id"),
        "name": document.get("name"),
        "dataset_id": document.get("dataset_id"),
        "run": document.get("run"),
        "chunk_method": document.get("chunk_method"),
    }


def upload_documents(dataset_id: str, file_paths: list[str], *, base_url: str, api_key: str) -> dict[str, Any]:
    missing = [path for path in file_paths if not Path(path).exists()]
    if missing:
        raise ConfigError("File(s) not found: " + ", ".join(missing))

    boundary, body = _build_multipart(file_paths)
    url = f"{base_url}/api/v1/datasets/{dataset_id}/documents"
    request_obj = urllib.request.Request(url, data=body, method="POST")
    request_obj.add_header("Authorization", f"Bearer {api_key}")
    request_obj.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")

    try:
        with urllib.request.urlopen(request_obj, timeout=120) as response:
            payload = decode_json_response(response.read())
    except urllib.error.HTTPError as exc:
        message = extract_error_message(exc.read())
        if message:
            raise ApiError(message) from None
        raise ApiError(f"HTTP request failed with status {exc.code}.") from None
    except urllib.error.URLError as exc:
        reason = getattr(exc, "reason", exc)
        raise ApiError(f"Upload failed: {reason}") from None

    ensure_success(payload)
    raw_documents = payload.get("data")
    if not isinstance(raw_documents, list):
        raise ScriptError("Upload response missing data list.")

    documents = [_normalize_document(document) for document in raw_documents]
    return {
        "dataset_id": dataset_id,
        "uploaded_at": current_timestamp(),
        "uploaded_count": len(documents),
        "document_ids": [document["id"] for document in documents if isinstance(document.get("id"), str)],
        "documents": documents,
    }


def _format_text(payload: dict[str, Any]) -> str:
    lines = [
        f"Dataset: {payload['dataset_id']}",
        f"Uploaded at: {payload['uploaded_at']}",
        f"Uploaded: {payload['uploaded_count']} document(s)",
    ]

    for document in payload["documents"]:
        lines.extend(
            [
                "",
                f"- {document.get('name') or 'unknown'}",
                f"  id: {document.get('id') or 'unknown'}",
                f"  run: {document.get('run') or 'unknown'}",
                f"  chunk_method: {document.get('chunk_method') or 'unknown'}",
            ]
        )

    if payload["document_ids"]:
        lines.extend(
            [
                "",
                "Next:",
                f"python scripts/parse.py {payload['dataset_id']} {' '.join(payload['document_ids'])}",
            ]
        )
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    configure_stdio_utf8()
    load_repo_env(repo_root_from_path(__file__))
    args = _parse_args(argv)

    try:
        payload = upload_documents(
            args.dataset_id,
            args.files,
            base_url=resolve_base_url(args.base_url),
            api_key=require_api_key(),
        )
        print(format_json(payload) if args.json_output else _format_text(payload))
        return 0
    except ScriptError as exc:
        if args.json_output:
            print(
                format_json(
                    {
                        "dataset_id": args.dataset_id,
                        "uploaded_at": current_timestamp(),
                        "uploaded_count": 0,
                        "document_ids": [],
                        "documents": [],
                        "error": str(exc),
                    }
                )
            )
        else:
            print(f"Error: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

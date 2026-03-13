---
name: ragflow-dataset-ingest
description: "Use for RAGFlow dataset ingestion tasks: list datasets, upload documents into a dataset, start parsing uploaded documents, return the current parser status immediately, and explicitly check, poll, or background-monitor parsing status until target documents finish processing."
---

# RAGFlow Dataset Ingest

Use only the bundled scripts in `scripts/`.

## Workflow

```bash
python scripts/datasets.py list
python scripts/datasets.py info DATASET_ID
```

1. Confirm the target dataset.
2. Upload files.

```bash
python scripts/upload.py DATASET_ID /path/to/file1 [/path/to/file2 ...]
```

Upload output returns `document_ids`. Pass those IDs into the next step.

3. Start parsing and return parser status.

```bash
python scripts/parse.py DATASET_ID DOC_ID1 [DOC_ID2 ...]
```

`parse.py` always starts parsing first, then returns status in one of three modes:
- default: return one current parser status snapshot
- `--watch`: poll until the target documents reach terminal states
- `--background`: start a detached watcher and return `pid`, `output_path`, and `error_path`

4. Query parser status directly when needed.

```bash
python scripts/parse_status.py DATASET_ID --doc-ids DOC1,DOC2
python scripts/parse_status.py DATASET_ID --doc-ids DOC1,DOC2 --watch
python scripts/parse_status.py DATASET_ID --doc-ids DOC1,DOC2 --background --output /tmp/parse-status.json
```

## Scope

Support only:
- list datasets
- upload documents to a dataset
- start parsing documents in a dataset
- query parser status once
- poll parser status
- background-monitor parser status

Do not use this skill for retrieval, chunk editing, memory APIs, or other RAGFlow capabilities.

## Environment

Configure `.env` with:

```bash
RAGFLOW_API_URL=base-url-here
RAGFLOW_API_KEY=ragflow-your-api-key-here
```

## Endpoints

- `GET /api/v1/datasets`
- `POST /api/v1/datasets/<dataset_id>/documents`
- `POST /api/v1/datasets/<dataset_id>/chunks`
- `GET /api/v1/datasets/<dataset_id>/documents`

## Commands

```bash
python scripts/datasets.py list
python scripts/datasets.py info DATASET_ID
python scripts/upload.py DATASET_ID ./example.pdf --json
python scripts/parse.py DATASET_ID DOC_ID1 --json
python scripts/parse.py DATASET_ID DOC_ID1 --watch --json
python scripts/parse.py DATASET_ID DOC_ID1 --background --output /tmp/parse-status.json --json
python scripts/parse_status.py DATASET_ID --doc-ids DOC_ID1 --json
python scripts/parse_status.py DATASET_ID --doc-ids DOC_ID1 --watch --interval 10 --timeout 1800
python scripts/parse_status.py DATASET_ID --doc-ids DOC_ID1 --background --output /tmp/parse-status.json --json
```

## Notes

- Upload does not start parsing by itself.
- Parsing is asynchronous.
- `parse.py` returns parser status immediately after the start request; use `--watch` or `--background` when you need continued tracking.
- `parse_status.py` reports document state from the dataset document list API. It does not fabricate percentage progress.
- Prefer `--doc-ids` after a fresh upload/parse so you monitor only the target documents instead of the entire dataset.
- `--background` writes the final JSON payload to `output_path`. Use `parse_status.py` again if you need a live snapshot before the background watcher finishes.

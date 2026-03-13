---
name: ragflow-dataset-ingest
description: Use for RAGFlow dataset ingestion tasks: list datasets, upload documents into a dataset, and start parsing uploaded documents so they become retrievable later. Trigger when the user wants to see available datasets, upload files to a dataset, or launch parsing/chunking for uploaded documents.
---

# RAGFlow Dataset Ingest

Use only the bundled scripts for this skill.

## Supported operations

```bash
# List datasets
python scripts/datasets.py list

# Upload one or more files to a dataset
python scripts/upload.py DATASET_ID /path/to/file1 [/path/to/file2 ...]

# Start parsing uploaded documents
python scripts/parse.py DATASET_ID DOC_ID1 [DOC_ID2 ...]
```

## Scope

This skill intentionally supports only:
- list datasets
- upload documents to a dataset
- start parsing documents in a dataset

Do not use this skill for retrieval, chunk editing, memory APIs, or any other RAGFlow capability.

## Environment

Configure `.env` with:

```bash
RAGFLOW_API_URL=http://127.0.0.1
RAGFLOW_API_KEY=ragflow-your-api-key-here
```

## API endpoints used

- `GET /api/v1/datasets`
- `POST /api/v1/datasets/<dataset_id>/documents`
- `POST /api/v1/datasets/<dataset_id>/chunks`

## Workflow

1. List datasets and confirm the target dataset.
2. Upload one or more documents to that dataset.
3. Read returned document IDs from upload output.
4. Start parsing with those document IDs.
5. Tell the user parsing is asynchronous and may take time.

## Notes

- Upload does not make a document retrievable by itself; parsing must be started separately.
- Parsing is asynchronous. After `parse.py` succeeds, the user may need to check status later in another workflow.
- If upload returns document metadata, preserve the document IDs because they are required for parsing.

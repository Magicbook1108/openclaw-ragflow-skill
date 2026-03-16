---
name: ragflow-dataset-ingest
description: "Use for RAGFlow dataset management and retrieval. Trigger on requests to create, list, inspect, update, or delete datasets; list, upload, update, or delete documents in a dataset; start parsing, stop parsing by explicit document ID, check parse progress or parser status, or retrieve relevant chunks from one or more RAGFlow datasets."
---

# RAGFlow Dataset And Retrieval

Use only the bundled scripts in `scripts/`.

## When To Use

- dataset create, list, inspect, update, delete
- document list, upload, update, delete
- parse start
- parse stop for specific document IDs
- parser status or progress checks
- retrieval against one or more datasets or document IDs

Do not use this skill for chunk editing, memory APIs, or other RAGFlow features outside dataset operations and retrieval.

## Routing Rules

- dataset create, list, inspect, delete: `scripts/datasets.py`
- dataset update: `scripts/update_dataset.py`
- document list, upload, delete: `scripts/upload.py`
- document update: `scripts/update_document.py`
- start parsing: `scripts/parse.py`
- stop parsing: `scripts/stop_parse_documents.py`
- status or progress without starting a new parse: `scripts/parse_status.py`
- retrieval: `scripts/search.py`

- For upload then parse flows:
  create or confirm dataset, upload files, capture returned `document_ids`, then pass those IDs into `scripts/parse.py`.
- For broad progress requests:
  no dataset specified -> inspect all datasets and aggregate results
  dataset specified -> inspect all documents in that dataset
  document IDs specified -> inspect only those documents
- Use `scripts/search.py --retrieval-test` only for explicit single-dataset debugging requests.

## Safety Rules

- dataset deletion requires explicit dataset IDs
- document deletion requires explicit dataset ID and explicit document IDs
- stop-parse requires explicit dataset ID and explicit document IDs
- if the user gives filenames, partial names, or a fuzzy description for delete or stop actions, list documents first, resolve exact IDs, and only then act
- do not perform fuzzy batch delete operations
- do not perform fuzzy batch stop operations
- uploads should prefer explicit local file paths; drag-and-drop is secondary and may fail for large files
- parsing is asynchronous; a stop request may not flip to `CANCEL` immediately, so confirm with returned status or a later status check

## Core Commands

```bash
python scripts/datasets.py list --json
python scripts/datasets.py info DATASET_ID --json
python scripts/datasets.py create "Example Dataset" --description "Quarterly reports" --json
python scripts/update_dataset.py DATASET_ID --name "Renamed Dataset" --json
python scripts/datasets.py delete --ids DATASET_ID1,DATASET_ID2 --json

python scripts/upload.py list DATASET_ID --json
python scripts/upload.py DATASET_ID /path/to/file1 [/path/to/file2 ...] --json
python scripts/update_document.py DATASET_ID DOC_ID --name "Renamed Document" --json
python scripts/upload.py delete DATASET_ID --ids DOC_ID1,DOC_ID2 --json

python scripts/parse.py DATASET_ID DOC_ID1 [DOC_ID2 ...] --json
python scripts/parse.py DATASET_ID DOC_ID1 --watch --json
python scripts/parse.py DATASET_ID DOC_ID1 --background --output /tmp/parse-status.json --json
python scripts/stop_parse_documents.py DATASET_ID DOC_ID1 [DOC_ID2 ...] --json
python scripts/parse_status.py DATASET_ID --json
python scripts/parse_status.py DATASET_ID --doc-ids DOC_ID1,DOC_ID2 --json

python scripts/search.py "What does the warranty policy say?"
python scripts/search.py "What does the warranty policy say?" DATASET_ID
python scripts/search.py --dataset-ids DATASET_ID1,DATASET_ID2 --doc-ids DOC_ID1,DOC_ID2 "What does the warranty policy say?"
python scripts/search.py --retrieval-test --kb-id DATASET_ID "query"
```

## Response Contract

- dataset commands should return IDs and basic metadata when relevant
- uploads should return `document_ids`; use those IDs for follow-up parse or stop requests
- `scripts/parse.py` always starts parsing before reporting status
- `scripts/stop_parse_documents.py` should return the current status snapshot for the requested document IDs after the stop request
- for progress responses, summarize `RUNNING` files first and do not invent percentage progress
- when no dataset is specified for a progress request, aggregate status across datasets
- retrieval responses should reflect the actual dataset or document scope used

## Environment

Configure `.env` with:

```bash
RAGFLOW_BASE_URL=http://127.0.0.1:9380
RAGFLOW_API_KEY=ragflow-your-api-key-here
RAGFLOW_DATASET_IDS=["dataset-id-1", "dataset-id-2"]
```

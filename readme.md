# RAGFlow Assistant Prompt Library

A collection of commonly used prompts for operating RAGFlow datasets.  
These prompts cover file upload, parsing control, status inspection, and task troubleshooting.

---

# 1. File Upload

## Upload a file to a dataset

**Prompt**

Upload this file to the `{dataset_name}` dataset in RAGFlow.

---

## Upload a file from a local path

**Prompt**

Upload the file located at `{file_path}` to the `{dataset_name}` dataset.

---

# 2. Upload and Start Parsing

## Upload and parse

**Prompt**

Upload this file to `{dataset_name}` and start parsing.

---

## Upload + parse + progress reporting

**Prompt**

Upload this file to `{dataset_name}`, start parsing, and report progress every `{interval}` seconds.

---

# 3. Parsing Task Control

## Parse specific files

**Prompt**

Parse these files.

---

## Re-parse a document

**Prompt**

Re-parse the document with `document_id = {document_id}`.

---

# 4. Parsing Progress Query

## Check the parsing progress of a file

**Prompt**

Check the parsing progress.

---

## Check parsing progress of all files in a dataset

**Prompt**

Show the parsing progress of all files in `{dataset_name}`.

---

# 5. Dataset Information

## List all files in a dataset

**Prompt**

List all files in `{dataset_name}`.

---

## Show dataset parsing status summary

**Prompt**

Show the parsing status summary of `{dataset_name}`.

The summary should include:

- Total number of files
- RUNNING
- DONE
- FAIL

---

# 6. Task Troubleshooting

## Check why parsing failed

**Prompt**

Check the reason why this document failed to parse.

---

## Show detailed information of a document

**Prompt**

Show the parsing details of `document_id = {document_id}`.

---

# 7. Recommended Automation Prompt

**Prompt**

Upload this file to `{dataset_name}`, start parsing, and report progress every 10 seconds until parsing is complete.

---

# 8. Core Prompt Set

If only the most essential prompts are needed:

1. Upload this file to `{dataset_name}`.

2. Upload this file to `{dataset_name}` and start parsing.

3. Check the parsing progress.

4. Show the parsing status of all files in `{dataset_name}`.

5. Check why parsing failed.

---

# 9. Standard RAGFlow Workflow

A typical workflow for document ingestion:

Upload file  
→ Start parsing  
→ Monitor parsing progress  
→ Check dataset status  
→ Troubleshoot failed tasks
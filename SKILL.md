---
name: ragflow_knowledge
description: RAGFlow knowledge base retrieval via HTTP API for intelligent document search and dataset management
homepage: https://ragflow.io
metadata:
  {
    "openclaw":
      {
        "emoji": "📚",
        "requires": { "bins": ["curl"], "env": ["RAGFLOW_API_URL", "RAGFLOW_API_KEY"] },
        "primaryEnv": "RAGFLOW_API_KEY",
      },
  }
---

# RAGFlow Knowledge

RAGFlow-powered knowledge retrieval and dataset management via HTTP API.

## Setup

1. Set environment variables:

```bash
export RAGFLOW_API_URL="http://127.0.0.1"
export RAGFLOW_API_KEY="ragflow-your-api-key-here"
export RAGFLOW_DATASET_IDS='["dataset-id-1", "dataset-id-2"]'  # Optional
export RAGFLOW_TOP_K="5"  # Optional, default: 5
export RAGFLOW_SIMILARITY_THRESHOLD="0.2"  # Optional, default: 0.2
```

2. Verify connection:

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/datasets" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}"
```

## API Basics

All requests require Bearer token authentication:

```bash
# Base request format
curl -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

## Dataset Management

### List All Datasets

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/datasets" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" | jq '.data[] | {
    name: .name,
    id: .id,
    description: .description,
    chunk_count: .chunk_count,
    created_at: .created_at
  }'
```

### Get Dataset by ID

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/datasets" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" | \
  jq '.data[] | select(.id == "DATASET_ID")'
```

### Dataset Response Fields

- `name` - Dataset name
- `id` - Unique dataset identifier
- `description` - Dataset description
- `chunk_count` - Number of document chunks
- `created_at` - Creation timestamp
- `permission` - Access permissions
- `document_count` - Number of documents
- `token_num` - Token count
- `chunk_method` - Chunking method used

## Retrieval Operations

### Basic Search

Search knowledge base for relevant content:

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the remote work policy?"
  }'
```

### Search with Parameters

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"question\": \"USER_QUERY_HERE\",
    \"dataset_ids\": ${RAGFLOW_DATASET_IDS},
    \"top_k\": ${RAGFLOW_TOP_K:-5},
    \"similarity_threshold\": ${RAGFLOW_SIMILARITY_THRESHOLD:-0.2}
  }"
```

### Search with Advanced Options

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "search query",
    "dataset_ids": ["dataset-id-1", "dataset-id-2"],
    "top_k": 10,
    "similarity_threshold": 0.3,
    "vector_similarity_weight": 0.3,
    "keyword": true
  }' | jq '.data.chunks[] | {
    document: .document_keyword,
    similarity: (.similarity * 100 | floor),
    content: .content[0:200]
  }'
```

## Retrieval Request Parameters

### Core Parameters

- `question` (string, required) - Search query or question
- `dataset_ids` (array, optional) - Specific dataset IDs to search (empty = search all)
- `top_k` (integer, optional) - Maximum chunks to retrieve (default: 1024)
- `similarity_threshold` (float, optional) - Minimum similarity score (0-1, default: 0.2)

### Similarity Control

- `vector_similarity_weight` (float, optional) - Weight for vector similarity vs keyword similarity (default: 0.3)
  - Lower value (e.g., 0.1) favors keyword matching
  - Higher value (e.g., 0.7) favors semantic vector similarity
- `keywords_similarity_weight` (float, optional) - Alternative way to set keyword weight (inverse of vector weight)

### Pagination

- `page` (integer, optional) - Page number for pagination (default: 1)
- `size` (integer, optional) - Number of results per page (default: 30)

### Content Filtering

- `doc_ids` (array, optional) - Limit search to specific document IDs
- `meta_data_filter` (object, optional) - Filter by document metadata

### Advanced Features

- `keyword` (boolean, optional) - Extract and use keywords for better matching (default: false)
- `rerank_id` (string, optional) - Reranking model ID for improved results
- `use_kg` (boolean, optional) - Include knowledge graph in retrieval (default: false)
- `cross_languages` (array, optional) - Languages to translate query for multilingual search (e.g., ["en", "zh"])

## Retrieval Response

```json
{
  "code": 0,
  "data": {
    "chunks": [
      {
        "chunk_id": "unique-chunk-id",
        "content": "Actual document content...",
        "content_with_weight": "Content with keyword weights...",
        "similarity": 0.8923,
        "document_keyword": "document-name.pdf",
        "doc_id": "document-id",
        "dataset_id": "dataset-id",
        "docnm_kwd": "document-name.pdf",
        "important_kwd": ["keyword1", "keyword2"],
        "question_kwd": ["question1"],
        "position_int": [[page, x, y, width, height]]
      }
    ],
    "doc_aggs": [
      {
        "doc_id": "document-id",
        "count": 5,
        "doc_name": "document-name.pdf"
      }
    ]
  }
}
```

### Response Fields

- `code` - Status code (0 = success)
- `data.chunks` - Array of relevant document chunks
  - `chunk_id` - Unique chunk identifier
  - `content` - Plain text content
  - `content_with_weight` - Content with keyword highlighting
  - `similarity` - Relevance score (0-1, higher = better)
  - `document_keyword` / `docnm_kwd` - Document name
  - `doc_id` - Source document ID
  - `dataset_id` - Source dataset ID
  - `important_kwd` - Important keywords in chunk
  - `question_kwd` - Related questions
  - `position_int` - Position in document (for PDFs)
- `data.doc_aggs` - Aggregation by document

## Chunk Management

### Get Chunk Details

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/chunk/get" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -G --data-urlencode "chunk_id=CHUNK_ID"
```

### Create Chunk

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/create" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "doc_id": "document-id",
    "content_with_weight": "New chunk content",
    "important_kwd": ["keyword1"],
    "question_kwd": ["related question"]
  }'
```

### Update Chunk

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/set" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "doc_id": "document-id",
    "chunk_id": "chunk-id",
    "content_with_weight": "Updated content",
    "important_kwd": ["new-keyword"],
    "available_int": 1
  }'
```

### Toggle Chunk Availability

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/switch" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "doc_id": "document-id",
    "chunk_ids": ["chunk-id-1", "chunk-id-2"],
    "available_int": 1
  }'
```

### Delete Chunks

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/rm" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "doc_id": "document-id",
    "chunk_ids": ["chunk-id-1", "chunk-id-2"]
  }'
```

### List Chunks in Document

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/list" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "doc_id": "document-id",
    "page": 1,
    "size": 30,
    "keywords": "search terms"
  }'
```

## Search Templates

### Quick Answer Retrieval

```bash
get_answer() {
  local query="$1"
  curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
    -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"question\": \"${query}\", \"top_k\": 3}" | \
    jq -r '.data.chunks[] | "[\(.document_keyword)] (相似度: \(.similarity * 100 | floor)%)\n\(.content)\n"'
}
```

### Document-Aware Search

```bash
search_in_docs() {
  local query="$1"
  local doc_ids="$2"
  curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
    -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"question\": \"${query}\",
      \"doc_ids\": ${doc_ids},
      \"top_k\": 10,
      \"similarity_threshold\": 0.4
    }"
}
```

### High-Precision Search

```bash
precise_search() {
  local query="$1"
  curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
    -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"question\": \"${query}\",
      \"top_k\": 5,
      \"similarity_threshold\": 0.7,
      \"vector_similarity_weight\": 0.7
    }"
}
```

### Knowledge Graph Enhanced Search

```bash
kg_search() {
  local query="$1"
  curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
    -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"question\": \"${query}\",
      \"use_kg\": true
    }"
}
```

## Response Parsing

### Pretty Print Results

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"question": "query"}' | \
  jq -r '.data.chunks[] | "
📄 \(.document_keyword)
   相似度: \(.similarity * 100 | floor)%
   ───────────────────
   \(.content)
   "'
```

### Extract Only Content

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"question": "query"}' | \
  jq -r '.data.chunks[].content'
```

### Get Top Result Only

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"question": "query", "top_k": 1}' | \
  jq -r '.data.chunks[0].content // "No results"'
```

## Troubleshooting

### Connection Issues

```bash
# Test API connectivity
curl -v "${RAGFLOW_API_URL}/api/v1/datasets" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}"
```

### Authentication Errors

```bash
# Verify API key
echo "API Key: ${RAGFLOW_API_KEY:0:20}..."

# Test with fresh token
curl -s "${RAGFLOW_API_URL}/api/v1/datasets" \
  -H "Authorization: Bearer $(cat ~/.ragflow/api_key)"
```

### No Results Found

```bash
# Lower similarity threshold
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"question": "query", "similarity_threshold": 0.0, "top_k": 50}'

# Enable keyword extraction
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"question": "query", "keyword": true}'
```

## Best Practices

1. **Always provide clear questions** - Full questions work better than keywords
2. **Use similarity_threshold** - Start with 0.2, adjust based on result quality
3. **Leverage vector_similarity_weight** - Increase for semantic queries, decrease for exact matching
4. **Enable keyword extraction** - Use `keyword: true` for technical queries
5. **Use knowledge graphs** - Enable `use_kg: true` for conceptually related content
6. **Specify datasets** - Limit search with `dataset_ids` for faster, more relevant results
7. **Handle no results** - Try rephrasing or lowering `similarity_threshold`

## Related Resources

- RAGFlow Documentation: https://ragflow.io/docs
- HTTP API Reference: https://ragflow.io/docs/dev/http_api_reference
- OpenClaw Skills: https://docs.openclaw.ai/skills
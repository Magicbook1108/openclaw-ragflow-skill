---
name: ragflow_knowledge
description: RAGFlow knowledge base retrieval via HTTP API for intelligent document search, dataset management, memory operations, and retrieval testing
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

RAGFlow-powered knowledge retrieval, dataset management, memory operations, and retrieval testing via HTTP API.

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

## API Endpoints Overview

### Knowledge Base & Retrieval
- `POST /api/v1/retrieval` - Basic retrieval (no authentication required for public datasets)
- `POST /api/v1/chunk/retrieval_test` - Advanced retrieval test (requires login)
- `GET /api/v1/datasets` - List all datasets
- `GET /api/v1/chunk/get` - Get chunk details
- `POST /api/v1/chunk/create` - Create new chunk
- `POST /api/v1/chunk/set` - Update chunk
- `POST /api/v1/chunk/switch` - Toggle chunk availability
- `POST /api/v1/chunk/rm` - Delete chunks
- `POST /api/v1/chunk/list` - List chunks in document
- `GET /api/v1/chunk/knowledge_graph` - Get knowledge graph for document

### Memory Management
- `POST /api/v1/memories` - Create memory
- `PUT /api/v1/memories/<memory_id>` - Update memory
- `DELETE /api/v1/memories/<memory_id>` - Delete memory
- `GET /api/v1/memories` - List memories
- `GET /api/v1/memories/<memory_id>/config` - Get memory configuration
- `GET /api/v1/memories/<memory_id>` - Get memory messages
- `POST /api/v1/messages` - Add message to memory
- `DELETE /api/v1/messages/<memory_id>:<message_id>` - Forget message
- `PUT /api/v1/messages/<memory_id>:<message_id>` - Update message status
- `GET /api/v1/messages/search` - Search messages
- `GET /api/v1/messages` - Get recent messages
- `GET /api/v1/messages/<memory_id>:<message_id>/content` - Get message content

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
- `avatar` - Dataset avatar/icon
- `tenant_id` - Owner tenant ID

## Retrieval Operations

### Basic Retrieval (No Login)

Search knowledge base for relevant content:

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the remote work policy?"
  }'
```

### Advanced Retrieval Test (Requires Login)

For authenticated users with additional features:

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/retrieval_test" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "kb_id": "dataset-id",
    "question": "search query",
    "page": 1,
    "size": 30
  }'
```

**Note**: `retrieval_test` requires:
- `kb_id` (required) - Dataset ID(s) to search (string or array)
- `question` (required) - Search query
- User authentication (login required)

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
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/retrieval_test" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "kb_id": ["dataset-id-1", "dataset-id-2"],
    "question": "search query",
    "top_k": 10,
    "similarity_threshold": 0.3,
    "vector_similarity_weight": 0.3,
    "keyword": true,
    "use_kg": true,
    "rerank_id": "rerank-model-id"
  }'
```

## Retrieval Request Parameters

### Core Parameters (Basic Retrieval)

- `question` (string, required) - Search query or question
- `dataset_ids` (array, optional) - Specific dataset IDs to search (empty = search all)
- `top_k` (integer, optional) - Maximum chunks to retrieve (default: 1024)
- `similarity_threshold` (float, optional) - Minimum similarity score (0-1, default: 0.2)

### Core Parameters (Retrieval Test)

- `kb_id` (string or array, required) - Dataset ID(s) to search
- `question` (string, required) - Search query
- `page` (integer, optional) - Page number (default: 1)
- `size` (integer, optional) - Results per page (default: 30)
- `top_k` (integer, optional) - Maximum chunks to retrieve (default: 1024)

### Similarity Control

- `vector_similarity_weight` (float, optional) - Weight for vector similarity (default: 0.3)
  - Lower value (e.g., 0.1) favors keyword matching
  - Higher value (e.g., 0.7) favors semantic vector similarity
- `keywords_similarity_weight` (float, optional) - Alternative keyword weight setting
- `similarity_threshold` (float, optional) - Minimum similarity threshold (default: 0.0 for retrieval_test, 0.2 for basic)

### Content Filtering

- `doc_ids` (array, optional) - Limit search to specific document IDs
- `meta_data_filter` (object, optional) - Filter by document metadata with:
  - `method` - Filter method: "manual", "auto", "semi_auto"
  - `conditions` - Filter conditions

### Advanced Features

- `keyword` (boolean, optional) - Extract keywords for better matching (default: false)
- `rerank_id` (string, optional) - Reranking model ID
- `use_kg` (boolean, optional) - Include knowledge graph (default: false)
- `cross_languages` (array, optional) - Languages for cross-language search (e.g., ["en", "zh"])
- `search_id` (string, optional) - Search configuration ID for saved searches

### Retrieval Test Exclusive

- `similarity_threshold` (float, optional) - Defaults to 0.0 in retrieval_test
- Returns additional `labels` field with question labels

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
    ],
    "labels": ["label1", "label2"]
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
- `data.labels` - Question labels (retrieval_test only)

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
    "question_kwd": ["new-question"],
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
    "keywords": "search terms",
    "available_int": 1
  }'
```

### Get Knowledge Graph

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/chunk/knowledge_graph" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -G --data-urlencode "doc_id=DOCUMENT_ID"
```

## Memory Management

### Create Memory

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/memories" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Memory",
    "memory_type": ["longterm", "user"],
    "embd_id": "embedding-model-id",
    "llm_id": "llm-model-id"
  }'
```

**Memory Types**: `longterm`, `user`, `agent`, `session`

### Update Memory

```bash
curl -s -X PUT "${RAGFLOW_API_URL}/api/v1/memories/MEMORY_ID" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Memory Name",
    "memory_size": 1000000,
    "forgetting_policy": "oldest_first",
    "temperature": 0.7,
    "system_prompt": "You are a helpful assistant",
    "user_prompt": "Please assist users"
  }'
```

**Update Parameters**:
- `name` - Memory name
- `permissions` - Permission level: "me_only", "tenant_collaborators"
- `llm_id` - LLM model ID
- `embd_id` - Embedding model ID
- `memory_type` - Memory type array
- `memory_size` - Maximum memory size in bytes (max:MEMORY_SIZE_LIMIT)
- `forgetting_policy` - "oldest_first", "newest_first"
- `temperature` - LLM temperature (0-1)
- `avatar` - Memory avatar URL
- `description` - Memory description
- `system_prompt` - System prompt
- `user_prompt` - User prompt

### Delete Memory

```bash
curl -s -X DELETE "${RAGFLOW_API_URL}/api/v1/memories/MEMORY_ID" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}"
```

### List Memories

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/memories" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -G \
  --data-urlencode "memory_type=longterm" \
  --data-urlencode "page=1" \
  --data-urlencode "page_size=50" \
  --data-urlencode "keywords=search term"
```

**Query Parameters**:
- `memory_type` - Filter by memory type (comma-separated)
- `tenant_id` - Filter by tenant ID (comma-separated)
- `storage_type` - Storage type filter
- `keywords` - Search keywords
- `page` - Page number (default: 1)
- `page_size` - Results per page (default: 50)

### Get Memory Configuration

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/memories/MEMORY_ID/config" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}"
```

### Get Memory Messages

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/memories/MEMORY_ID" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -G \
  --data-urlencode "agent_id=agent-id" \
  --data-urlencode "page=1" \
  --data-urlencode "page_size=50"
```

**Query Parameters**:
- `agent_id` - Filter by agent ID (comma-separated)
- `keywords` - Search keywords
- `page` - Page number
- `page_size` - Results per page

### Add Message to Memory

```bash
curl -s -X POST "${RAGFLOW_API_URL}/api/v1/messages" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "memory_id": ["memory-id-1", "memory-id-2"],
    "agent_id": "agent-id",
    "session_id": "session-id",
    "user_input": "User message",
    "agent_response": "Agent response"
  }'
```

### Forget Message

```bash
curl -s -X DELETE "${RAGFLOW_API_URL}/api/v1/messages/MEMORY_ID:MESSAGE_ID" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}"
```

### Update Message Status

```bash
curl -s -X PUT "${RAGFLOW_API_URL}/api/v1/messages/MEMORY_ID:MESSAGE_ID" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": true
  }'
```

### Search Messages

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/messages/search" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -G \
  --data-urlencode "memory_id=memory-id" \
  --data-urlencode "query=search query" \
  --data-urlencode "similarity_threshold=0.2" \
  --data-urlencode "keywords_similarity_weight=0.7" \
  --data-urlencode "top_n=5" \
  --data-urlencode "agent_id=agent-id" \
  --data-urlencode "session_id=session-id"
```

### Get Recent Messages

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/messages" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -G \
  --data-urlencode "memory_id=memory-id" \
  --data-urlencode "agent_id=agent-id" \
  --data-urlencode "session_id=session-id" \
  --data-urlencode "limit=10"
```

### Get Message Content

```bash
curl -s "${RAGFLOW_API_URL}/api/v1/messages/MEMORY_ID:MESSAGE_ID/content" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}"
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
  curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/retrieval_test" \
    -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"kb_id\": \"dataset-id\",
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
  curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/retrieval_test" \
    -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"kb_id\": \"dataset-id\",
      \"question\": \"${query}\",
      \"use_kg\": true
    }"
}
```

### Memory Search

```bash
memory_search() {
  local memory_id="$1"
  local query="$2"
  curl -s "${RAGFLOW_API_URL}/api/v1/messages/search" \
    -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
    -G \
    --data-urlencode "memory_id=${memory_id}" \
    --data-urlencode "query=${query}" \
    --data-urlencode "top_n=5"
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

### Retrieval Test Login Required

The `/api/v1/chunk/retrieval_test` endpoint requires user authentication. Ensure:
1. You have a valid RAGFlow user account
2. Your API key has proper permissions
3. You're logged in to the RAGFlow web interface

For unauthenticated access, use `/api/v1/retrieval` instead.

## Best Practices

1. **Always provide clear questions** - Full questions work better than keywords
2. **Use similarity_threshold** - Start with 0.2, adjust based on result quality
3. **Leverage vector_similarity_weight** - Increase for semantic queries, decrease for exact matching
4. **Enable keyword extraction** - Use `keyword: true` for technical queries
5. **Use knowledge graphs** - Enable `use_kg: true` for conceptually related content
6. **Specify datasets** - Limit search with `dataset_ids` or `kb_id` for faster, more relevant results
7. **Handle no results** - Try rephrasing or lowering `similarity_threshold`
8. **Use retrieval_test for advanced features** - When you need metadata filtering, reranking, or knowledge graphs
9. **Manage memory size** - Monitor memory usage and set appropriate `memory_size` limits
10. **Use forgetting policies** - Configure `forgetting_policy` to manage memory growth

## API Differences

### Basic Retrieval vs Retrieval Test

| Feature | Basic (`/retrieval`) | Test (`/chunk/retrieval_test`) |
|---------|---------------------|-------------------------------|
| Authentication | Optional | Required (login) |
| Dataset Param | `dataset_ids` | `kb_id` |
| Similarity Default | 0.2 | 0.0 |
| Metadata Filter | Basic object | Advanced with methods |
| Search Config | No | Yes (`search_id`) |
| Returns Labels | No | Yes |
| Knowledge Graph | Basic | Enhanced |

## Related Resources

- RAGFlow Documentation: https://ragflow.io/docs
- HTTP API Reference: https://ragflow.io/docs/dev/http_api_reference
- OpenClaw Skills: https://docs.openclaw.ai/skills
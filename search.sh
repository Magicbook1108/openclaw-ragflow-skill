#!/bin/bash
# RAGFlow Knowledge Search Helper Script
# Supports all RAGFlow retrieval API parameters
#
# Usage: ./search.sh [OPTIONS] "<search query>"
#
# Options:
#   --top-k N               Maximum chunks to retrieve (default: 5)
#   --threshold N           Similarity threshold 0-1 (default: 0.2, 0.0 for test)
#   --vector-weight N       Vector similarity weight 0-1 (default: 0.3)
#   --page N                Page number (default: 1)
#   --size N                Results per page (default: 30)
#   --dataset-ids "id1,id2"  Specific dataset IDs to search (basic retrieval)
#   --kb-id "id"            Dataset ID for retrieval_test (requires login)
#   --doc-ids "id1,id2"      Limit search to specific documents
#   --keyword               Enable keyword extraction
#   --use-kg                Enable knowledge graph retrieval
#   --rerank MODEL          Use reranking model
#   --search-id ID          Use saved search configuration
#   --retrieval-test        Use /api/v1/chunk/retrieval_test (requires login)
#   --json                  Output raw JSON
#   --pretty                Pretty print results (default)
#   --help                  Show this help

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env file if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    # Source only simple variables, skip JSON arrays
    eval "$(grep -E '^[A-Z_]+=' "$SCRIPT_DIR/.env" | grep -v '\[' | sed 's/^/export /')"
fi

# Configuration with defaults
RAGFLOW_API_URL="${RAGFLOW_API_URL:-http://127.0.0.1}"
RAGFLOW_API_KEY="${RAGFLOW_API_KEY:-}"
RAGFLOW_DATASET_IDS="${RAGFLOW_DATASET_IDS:-[]}"
RAGFLOW_TOP_K="${RAGFLOW_TOP_K:-5}"
RAGFLOW_SIMILARITY_THRESHOLD="${RAGFLOW_SIMILARITY_THRESHOLD:-0.2}"

# Parse command line arguments
QUERY=""
TOP_K=""
SIMILARITY_THRESHOLD=""
VECTOR_WEIGHT=""
PAGE=""
SIZE=""
DATASET_IDS=""
KB_ID=""
DOC_IDS=""
KEYWORD=""
USE_KG=""
RERANK_ID=""
SEARCH_ID=""
USE_RETRIEVAL_TEST=""
OUTPUT_JSON=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --top-k)
            TOP_K="$2"
            shift 2
            ;;
        --threshold)
            SIMILARITY_THRESHOLD="$2"
            shift 2
            ;;
        --vector-weight)
            VECTOR_WEIGHT="$2"
            shift 2
            ;;
        --page)
            PAGE="$2"
            shift 2
            ;;
        --size)
            SIZE="$2"
            shift 2
            ;;
        --dataset-ids)
            IFS=',' read -ra IDS <<< "$2"
            DATASET_IDS="[\"$(IFS='","'; echo "${IDS[*]}")\"]"
            shift 2
            ;;
        --doc-ids)
            IFS=',' read -ra IDS <<< "$2"
            DOC_IDS="[\"$(IFS='","'; echo "${IDS[*]}")\"]"
            shift 2
            ;;
        --keyword)
            KEYWORD="true"
            shift
            ;;
        --use-kg)
            USE_KG="true"
            shift
            ;;
        --rerank)
            RERANK_ID="$2"
            shift 2
            ;;
        --kb-id)
            KB_ID="$2"
            shift 2
            ;;
        --search-id)
            SEARCH_ID="$2"
            shift 2
            ;;
        --retrieval-test)
            USE_RETRIEVAL_TEST="true"
            shift
            ;;
        --json)
            OUTPUT_JSON="true"
            shift
            ;;
        --pretty)
            OUTPUT_JSON=""
            shift
            ;;
        --help)
            grep '^#' "$0" | tail -n +2 | sed 's/^# //; s/^#//'
            exit 0
            ;;
        *)
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            else
                QUERY="$QUERY $1"
            fi
            shift
            ;;
    esac
done

# Check if API key is set
if [ -z "$RAGFLOW_API_KEY" ] || [ "$RAGFLOW_API_KEY" = "ragflow-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    echo "Error: RAGFLOW_API_KEY not set!"
    echo ""
    echo "Please set your RAGFlow API key:"
    echo "  1. Copy .env.example to .env"
    echo "  2. Fill in your RAGFLOW_API_KEY"
    echo "  3. Run this script again"
    echo ""
    echo "Or set it as environment variable:"
    echo "  export RAGFLOW_API_KEY='your-api-key-here'"
    exit 1
fi

# Check if query is provided
if [ -z "$QUERY" ]; then
    echo "Error: No search query provided"
    echo ""
    echo "Usage: $0 [OPTIONS] '<search query>'"
    echo ""
    echo "Run '$0 --help' for more options"
    exit 1
fi

# Use defaults if not specified
TOP_K="${TOP_K:-$RAGFLOW_TOP_K}"

# Determine which API to use
if [ -n "$USE_RETRIEVAL_TEST" ]; then
    # Use retrieval_test API
    API_ENDPOINT="${RAGFLOW_API_URL}/api/v1/chunk/retrieval_test"
    # Default similarity for retrieval_test is 0.0
    SIMILARITY_THRESHOLD="${SIMILARITY_THRESHOLD:-0.0}"

    # For retrieval_test, kb_id is required
    if [ -z "$KB_ID" ] && [ -n "$DATASET_IDS" ] && [ "$DATASET_IDS" != "[]" ]; then
        # Extract first dataset ID if no kb_id specified
        KB_ID=$(echo "$DATASET_IDS" | jq -r '.[0]')
    fi

    if [ -z "$KB_ID" ]; then
        echo "Error: --kb-id is required for retrieval_test"
        echo "Usage: $0 --retrieval-test --kb-id <dataset-id> '<query>'"
        exit 1
    fi
else
    # Use basic retrieval API
    API_ENDPOINT="${RAGFLOW_API_URL}/api/v1/retrieval"
    SIMILARITY_THRESHOLD="${SIMILARITY_THRESHOLD:-$RAGFLOW_SIMILARITY_THRESHOLD}"
    DATASET_IDS="${DATASET_IDS:-$RAGFLOW_DATASET_IDS}"
fi

# Escape quotes in query for JSON
ESCAPED_QUERY=$(echo "$QUERY" | sed 's/"/\\"/g')

# Build JSON request body
if [ -n "$USE_RETRIEVAL_TEST" ]; then
    # retrieval_test uses kb_id
    JSON_BODY="{\"kb_id\": \"${KB_ID}\", \"question\": \"${ESCAPED_QUERY}\""
else
    # Basic retrieval uses dataset_ids
    JSON_BODY="{\"question\": \"${ESCAPED_QUERY}\""
    if [ -n "$DATASET_IDS" ] && [ "$DATASET_IDS" != "[]" ]; then
        JSON_BODY="${JSON_BODY}, \"dataset_ids\": ${DATASET_IDS}"
    fi
fi

# Add optional parameters
if [ -n "$TOP_K" ]; then
    JSON_BODY="${JSON_BODY}, \"top_k\": ${TOP_K}"
fi

if [ -n "$SIMILARITY_THRESHOLD" ]; then
    JSON_BODY="${JSON_BODY}, \"similarity_threshold\": ${SIMILARITY_THRESHOLD}"
fi

if [ -n "$VECTOR_WEIGHT" ]; then
    JSON_BODY="${JSON_BODY}, \"vector_similarity_weight\": ${VECTOR_WEIGHT}"
fi

if [ -n "$PAGE" ]; then
    JSON_BODY="${JSON_BODY}, \"page\": ${PAGE}"
fi

if [ -n "$SIZE" ]; then
    JSON_BODY="${JSON_BODY}, \"size\": ${SIZE}"
fi

if [ -n "$DOC_IDS" ]; then
    JSON_BODY="${JSON_BODY}, \"doc_ids\": ${DOC_IDS}"
fi

if [ -n "$KEYWORD" ]; then
    JSON_BODY="${JSON_BODY}, \"keyword\": ${KEYWORD}"
fi

if [ -n "$USE_KG" ]; then
    JSON_BODY="${JSON_BODY}, \"use_kg\": ${USE_KG}"
fi

if [ -n "$RERANK_ID" ]; then
    JSON_BODY="${JSON_BODY}, \"rerank_id\": \"${RERANK_ID}\""
fi

if [ -n "$SEARCH_ID" ]; then
    JSON_BODY="${JSON_BODY}, \"search_id\": \"${SEARCH_ID}\""
fi

JSON_BODY="${JSON_BODY}}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Show search info if not JSON output
if [ -z "$OUTPUT_JSON" ]; then
    echo -e "${BLUE}Searching RAGFlow knowledge base...${NC}"
    echo -e "${BLUE}Query: ${YELLOW}${QUERY}${NC}"
    [ -n "$TOP_K" ] && echo -e "${BLUE}Top K: ${YELLOW}${TOP_K}${NC}"
    [ -n "$SIMILARITY_THRESHOLD" ] && echo -e "${BLUE}Threshold: ${YELLOW}${SIMILARITY_THRESHOLD}${NC}"
    [ -n "$VECTOR_WEIGHT" ] && echo -e "${BLUE}Vector Weight: ${YELLOW}${VECTOR_WEIGHT}${NC}"
    [ -n "$KEYWORD" ] && echo -e "${BLUE}Keyword Extraction: ${YELLOW}enabled${NC}"
    [ -n "$USE_KG" ] && echo -e "${BLUE}Knowledge Graph: ${YELLOW}enabled${NC}"
    echo ""
fi

# Show which API is being used
if [ -z "$OUTPUT_JSON" ] && [ -n "$USE_RETRIEVAL_TEST" ]; then
    echo -e "${BLUE}Using: ${YELLOW}retrieval_test API (requires login)${NC}"
fi

# Make API request
RESPONSE=$(curl -s -X POST "${API_ENDPOINT}" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${JSON_BODY}" 2>&1)

# Check for curl errors
if [[ $RESPONSE == *"curl"* ]] || [[ $RESPONSE == *"Failed to connect"* ]]; then
    echo "Connection Error"
    echo "Could not connect to RAGFlow at: ${RAGFLOW_API_URL}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check if RAGFlow is running"
    echo "  2. Verify RAGFLOW_API_URL is correct"
    echo "  3. Check your network connection"
    exit 1
fi

# Output JSON if requested
if [ -n "$OUTPUT_JSON" ]; then
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    exit 0
fi

# Parse and display results
echo "$RESPONSE" | jq -r '
  if .code == 0 then
    if .data.chunks | length > 0 then
      "Found \(.data.chunks | length) result(s):\n"
    else
      "No results found\n"
    end
  else
    "API Error: \(.code // "unknown")\n"
  end
'

# Display each result
echo "$RESPONSE" | jq -r '
  if .code == 0 then
    .data.chunks[] |
      "📄 [\(.document_keyword)] (相似度: \(.similarity * 100 | floor)%)\n\(.content)\n"
  else
    empty
  end
'

# Show document aggregation if present
if echo "$RESPONSE" | jq -e '.data.doc_aggs' > /dev/null 2>&1; then
    DOC_COUNT=$(echo "$RESPONSE" | jq -r '.data.doc_aggs | length')
    if [ "$DOC_COUNT" -gt 0 ]; then
        echo -e "${BLUE}Document Summary:${NC}"
        echo "$RESPONSE" | jq -r '
            .data.doc_aggs[] |
            "  - \(.doc_name): \(.count) chunk(s)"
        '
    fi
fi

# Show summary
RESULT_COUNT=$(echo "$RESPONSE" | jq -r 'if .code == 0 then .data.chunks | length else 0 end')
echo -e "${BLUE}─────────────────────────────────────${NC}"
echo -e "${GREEN}Search complete! Found $RESULT_COUNT result(s)${NC}"
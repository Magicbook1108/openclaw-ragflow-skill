#!/bin/bash
# RAGFlow Knowledge Search Helper Script
# Usage: ./search.sh "your search query"

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env file if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | grep -v '^[[:space:]]*$' | xargs)
fi

# Configuration with defaults
RAGFLOW_API_URL="${RAGFLOW_API_URL:-http://127.0.0.1}"
RAGFLOW_API_KEY="${RAGFLOW_API_KEY:-}"
RAGFLOW_DATASET_IDS="${RAGFLOW_DATASET_IDS:-[]}"
RAGFLOW_TOP_K="${RAGFLOW_TOP_K:-5}"

# Check if API key is set
if [ -z "$RAGFLOW_API_KEY" ] || [ "$RAGFLOW_API_KEY" = "ragflow-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    echo "❌ Error: RAGFLOW_API_KEY not set!"
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

# Get query from argument
if [ -z "$1" ]; then
    echo "❌ Error: No search query provided"
    echo ""
    echo "Usage: $0 '<search query>'"
    echo ""
    echo "Example: $0 'What is the remote work policy?'"
    exit 1
fi

QUERY="$1"

# Escape quotes in query for JSON
ESCAPED_QUERY=$(echo "$QUERY" | sed 's/"/\\"/g')

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Searching RAGFlow knowledge base...${NC}"
echo -e "${BLUE}📝 Query: ${YELLOW}$QUERY${NC}"
echo ""

# Make API request
RESPONSE=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/retrieval" \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"question\": \"${ESCAPED_QUERY}\",
    \"dataset_ids\": ${RAGFLOW_DATASET_IDS},
    \"top_k\": ${RAGFLOW_TOP_K}
  }" 2>&1)

# Check for curl errors
if [[ $RESPONSE == *"curl"* ]] || [[ $RESPONSE == *"Failed to connect"* ]]; then
    echo -e "${YELLOW}⚠️  Connection Error${NC}"
    echo "Could not connect to RAGFlow at: ${RAGFLOW_API_URL}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check if RAGFlow is running"
    echo "  2. Verify RAGFLOW_API_URL is correct"
    echo "  3. Check your network connection"
    exit 1
fi

# Parse and display results
echo "$RESPONSE" | jq -r '
  if .code == 0 then
    if .data.chunks | length > 0 then
      "✅ Found \(.data.chunks | length) result(s):\n"
    else
      "❌ No results found\n"
    end
  else
    "❌ API Error: \(.code // "unknown")\n"
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

# Show summary
RESULT_COUNT=$(echo "$RESPONSE" | jq -r 'if .code == 0 then .data.chunks | length else 0 end')
echo -e "${BLUE}─────────────────────────────────────${NC}"
echo -e "${GREEN}Search complete! Found $RESULT_COUNT result(s)${NC}"

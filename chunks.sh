#!/bin/bash
# RAGFlow Chunk Management Helper Script
# Manage document chunks in RAGFlow knowledge base
#
# Usage: ./chunks.sh [command] [options]
#
# Commands:
#   list <doc_id>           List chunks in a document
#   get <chunk_id>          Get chunk details
#   create <doc_id> <content>  Create a new chunk
#   update <doc_id> <chunk_id> <content>  Update a chunk
#   enable <doc_id> <chunk_ids>  Enable chunks
#   disable <doc_id> <chunk_ids> Disable chunks
#   delete <doc_id> <chunk_ids>  Delete chunks
#   help                    Show this help

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env file if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    eval "$(grep -E '^[A-Z_]+=' "$SCRIPT_DIR/.env" | grep -v '\[' | sed 's/^/export /')"
fi

# Configuration
RAGFLOW_API_URL="${RAGFLOW_API_URL:-http://127.0.0.1}"
RAGFLOW_API_KEY="${RAGFLOW_API_KEY:-}"

# Check if API key is set
if [ -z "$RAGFLOW_API_KEY" ] || [ "$RAGFLOW_API_KEY" = "ragflow-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    echo "Error: RAGFLOW_API_KEY not set!"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Show help
show_help() {
    cat << EOF
RAGFlow Chunk Management

Usage: ./chunks.sh [command] [options]

Commands:
  list <doc_id> [page] [size]
                        List chunks in a document
  get <chunk_id>         Get chunk details
  create <doc_id> <content>
                        Create a new chunk
  update <doc_id> <chunk_id> <content>
                        Update a chunk
  enable <doc_id> <chunk_ids>
                        Enable chunks (set available_int=1)
  disable <doc_id> <chunk_ids>
                        Disable chunks (set available_int=0)
  delete <doc_id> <chunk_ids>
                        Delete chunks
  help                  Show this help

Examples:
  ./chunks.sh list doc-id-123
  ./chunks.sh list doc-id-123 1 50
  ./chunks.sh get chunk-id-456
  ./chunks.sh create doc-id-123 "This is a new chunk"
  ./chunks.sh update doc-id-123 chunk-id-456 "Updated content"
  ./chunks.sh enable doc-id-123 chunk-id-1,chunk-id-2
  ./chunks.sh delete doc-id-123 chunk-id-1

Environment Variables:
  RAGFLOW_API_URL        RAGFlow server URL (default: http://127.0.0.1)
  RAGFLOW_API_KEY        RAGFlow API key
EOF
}

# List chunks
list_chunks() {
    local doc_id="$1"
    local page="${2:-1}"
    local size="${3:-30}"
    local keywords="${4:-}"

    echo -e "${BLUE}Listing chunks for document: ${doc_id}${NC}"

    local json_body="{\"doc_id\": \"${doc_id}\", \"page\": ${page}, \"size\": ${size}}"

    if [ -n "$keywords" ]; then
        json_body=$(echo "$json_body" | jq --arg kw "$keywords" '. + {keywords: $kw}')
    fi

    local response=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/list" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    echo "$response" | jq -r '
        if .code == 0 then
            "Total: \(.data.total // 0) chunks\n",
            (.data.chunks[]? |
                "\(.chunk_id // "N/A")",
                "  Content: \(.content_with_weight[0:100] // "N/A")...",
                "  Document: \(.docnm_kwd // "N/A")",
                "  Available: \(.available_int // 1)",
                ""
            )
        else
            "Error: \(.code // "unknown")"
        end
    '
}

# Get chunk details
get_chunk() {
    local chunk_id="$1"

    echo -e "${BLUE}Getting chunk: ${chunk_id}${NC}"

    local response=$(curl -s -G "${RAGFLOW_API_URL}/api/v1/chunk/get" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        --data-urlencode "chunk_id=${chunk_id}")

    echo "$response" | jq '.'
}

# Create chunk
create_chunk() {
    local doc_id="$1"
    local content="$2"

    echo -e "${BLUE}Creating chunk in document: ${doc_id}${NC}"

    local json_body=$(jq -n \
        --arg doc_id "$doc_id" \
        --arg content "$content" \
        '{
            doc_id: $doc_id,
            content_with_weight: $content,
            important_kwd: [],
            question_kwd: []
        }')

    local response=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/create" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        local chunk_id=$(echo "$response" | jq -r '.data.chunk_id')
        echo -e "${GREEN}Chunk created successfully!${NC}"
        echo "Chunk ID: $chunk_id"
    else
        echo -e "${RED}Failed to create chunk${NC}"
        echo "$response" | jq '.'
    fi
}

# Update chunk
update_chunk() {
    local doc_id="$1"
    local chunk_id="$2"
    local content="$3"

    echo -e "${BLUE}Updating chunk: ${chunk_id}${NC}"

    local json_body=$(jq -n \
        --arg doc_id "$doc_id" \
        --arg chunk_id "$chunk_id" \
        --arg content "$content" \
        '{
            doc_id: $doc_id,
            chunk_id: $chunk_id,
            content_with_weight: $content,
            important_kwd: [],
            available_int: 1
        }')

    local response=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/set" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Chunk updated successfully!${NC}"
    else
        echo -e "${RED}Failed to update chunk${NC}"
        echo "$response" | jq '.'
    fi
}

# Toggle chunk availability
toggle_chunks() {
    local doc_id="$1"
    local chunk_ids="$2"
    local available="$3"  # 0 or 1

    # Convert comma-separated IDs to JSON array
    local ids_array="[\"$(echo "$chunk_ids" | sed 's/,/","/g')\"]"

    local action=$([ "$available" -eq 1 ] && echo "Enabling" || echo "Disabling")
    echo -e "${BLUE}${action} chunks in document: ${doc_id}${NC}"

    local json_body=$(jq -n \
        --arg doc_id "$doc_id" \
        --argjson chunk_ids "$ids_array" \
        --argjson available "$available" \
        '{
            doc_id: $doc_id,
            chunk_ids: $chunk_ids,
            available_int: $available
        }')

    local response=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/switch" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Chunks ${action}ed successfully!${NC}"
    else
        echo -e "${RED}Failed to ${action} chunks${NC}"
        echo "$response" | jq '.'
    fi
}

# Delete chunks
delete_chunks() {
    local doc_id="$1"
    local chunk_ids="$2"

    # Convert comma-separated IDs to JSON array
    local ids_array="[\"$(echo "$chunk_ids" | sed 's/,/","/g')\"]"

    echo -e "${BLUE}Deleting chunks from document: ${doc_id}${NC}"

    local json_body=$(jq -n \
        --arg doc_id "$doc_id" \
        --argjson chunk_ids "$ids_array" \
        '{
            doc_id: $doc_id,
            chunk_ids: $chunk_ids
        }')

    local response=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/chunk/rm" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Chunks deleted successfully!${NC}"
    else
        echo -e "${RED}Failed to delete chunks${NC}"
        echo "$response" | jq '.'
    fi
}

# Main
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

command="$1"
shift

case "$command" in
    list)
        if [ $# -lt 1 ]; then
            echo "Error: doc_id is required"
            echo "Usage: $0 list <doc_id> [page] [size]"
            exit 1
        fi
        list_chunks "$@"
        ;;
    get)
        if [ $# -lt 1 ]; then
            echo "Error: chunk_id is required"
            echo "Usage: $0 get <chunk_id>"
            exit 1
        fi
        get_chunk "$@"
        ;;
    create)
        if [ $# -lt 2 ]; then
            echo "Error: doc_id and content are required"
            echo "Usage: $0 create <doc_id> <content>"
            exit 1
        fi
        create_chunk "$@"
        ;;
    update)
        if [ $# -lt 3 ]; then
            echo "Error: doc_id, chunk_id, and content are required"
            echo "Usage: $0 update <doc_id> <chunk_id> <content>"
            exit 1
        fi
        update_chunk "$@"
        ;;
    enable)
        if [ $# -lt 2 ]; then
            echo "Error: doc_id and chunk_ids are required"
            echo "Usage: $0 enable <doc_id> <chunk_ids>"
            exit 1
        fi
        toggle_chunks "$1" "$2" 1
        ;;
    disable)
        if [ $# -lt 2 ]; then
            echo "Error: doc_id and chunk_ids are required"
            echo "Usage: $0 disable <doc_id> <chunk_ids>"
            exit 1
        fi
        toggle_chunks "$1" "$2" 0
        ;;
    delete)
        if [ $# -lt 2 ]; then
            echo "Error: doc_id and chunk_ids are required"
            echo "Usage: $0 delete <doc_id> <chunk_ids>"
            exit 1
        fi
        delete_chunks "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$command'"
        echo ""
        show_help
        exit 1
        ;;
esac
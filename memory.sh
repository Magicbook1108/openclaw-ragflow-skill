#!/bin/bash
# RAGFlow Memory Management Helper Script
# Manage memories and messages in RAGFlow
#
# Usage: ./memory.sh [command] [options]
#
# Commands:
#   list                     List all memories
#   create <name> <type>     Create a new memory
#   update <memory_id>       Update memory configuration
#   delete <memory_id>       Delete a memory
#   config <memory_id>       Get memory configuration
#   messages <memory_id>     Get messages from memory
#   add <memory_id>          Add message to memory
#   search <memory_id> <query>  Search messages
#   recent <memory_id>       Get recent messages
#   forget <memory_id> <msg_id>  Forget a message
#   status <memory_id> <msg_id> <status>  Update message status
#   help                     Show this help

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
RAGFlow Memory Management

Usage: ./memory.sh [command] [options]

Commands:
  list [filters]              List all memories
  create <name> <type> <embd_id> <llm_id>
                              Create a new memory
  update <memory_id> [options]  Update memory configuration
  delete <memory_id>          Delete a memory
  config <memory_id>          Get memory configuration
  messages <memory_id>        Get messages from memory
  add <memory_id> <agent_id> <session_id> <user> <agent>
                              Add message to memory
  search <memory_id> <query>  Search messages
  recent <memory_id>          Get recent messages
  forget <memory_id> <msg_id>  Forget a message
  status <memory_id> <msg_id> <true|false>  Update message status
  help                        Show this help

Memory Types:
  longtime, user, agent, session

Examples:
  ./memory.sh list
  ./memory.sh create "My Memory" "longterm" "embd-id" "llm-id"
  ./memory.sh update memory-id --name "New Name" --size 1000000
  ./memory.sh config memory-id
  ./memory.sh messages memory-id
  ./memory.sh add memory-id agent-id session-id "user input" "agent response"
  ./memory.sh search memory-id "search query"
  ./memory.sh recent memory-id
  ./memory.sh forget memory-id 12345

Environment Variables:
  RAGFLOW_API_URL        RAGFlow server URL (default: http://127.0.0.1)
  RAGFLOW_API_KEY        RAGFlow API key
EOF
}

# List memories
list_memories() {
    local keywords=""
    local memory_type=""
    local page="1"
    local page_size="50"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --keywords)
                keywords="$2"
                shift 2
                ;;
            --type)
                memory_type="$2"
                shift 2
                ;;
            --page)
                page="$2"
                shift 2
                ;;
            --size)
                page_size="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    echo -e "${BLUE}Listing memories...${NC}"

    local url="${RAGFLOW_API_URL}/api/v1/memories?page=${page}&page_size=${page_size}"
    [ -n "$keywords" ] && url="${url}&keywords=${keywords}"
    [ -n "$memory_type" ] && url="${url}&memory_type=${memory_type}"

    local response=$(curl -s "${url}" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}")

    echo "$response" | jq -r '
        if .code == 0 then
            "Total: \(.data.total_count // 0) memories\n",
            (.data.memory_list[]? |
                "\(.memory_id // "N/A")",
                "  Name: \(.name // "N/A")",
                "  Type: \(.memory_type | join(", "))",
                "  Size: \(.memory_size // 0) bytes",
                "  Description: \(.description // "N/A")",
                ""
            )
        else
            "Error: \(.code // "unknown")"
        end
    '
}

# Create memory
create_memory() {
    local name="$1"
    local memory_type="$2"
    local embd_id="$3"
    local llm_id="$4"

    if [ -z "$name" ] || [ -z "$memory_type" ] || [ -z "$embd_id" ] || [ -z "$llm_id" ]; then
        echo "Error: name, memory_type, embd_id, and llm_id are required"
        echo "Usage: $0 create <name> <type> <embd_id> <llm_id>"
        exit 1
    fi

    echo -e "${BLUE}Creating memory: ${name}${NC}"

    local json_body=$(jq -n \
        --arg name "$name" \
        --argjson type "[$memory_type]" \
        --arg embd "$embd_id" \
        --arg llm "$llm_id" \
        '{
            name: $name,
            memory_type: $type,
            embd_id: $embd,
            llm_id: $llm
        }')

    local response=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/memories" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Memory created successfully!${NC}"
        echo "$response" | jq '.'
    else
        echo -e "${RED}Failed to create memory${NC}"
        echo "$response" | jq '.'
    fi
}

# Update memory
update_memory() {
    local memory_id="$1"
    shift

    local updates="{}"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                updates=$(echo "$updates" | jq --arg name "$2" '. + {name: $name}')
                shift 2
                ;;
            --description)
                updates=$(echo "$updates" | jq --arg desc "$2" '. + {description: $desc}')
                shift 2
                ;;
            --system-prompt)
                updates=$(echo "$updates" | jq --arg prompt "$2" '. + {system_prompt: $prompt}')
                shift 2
                ;;
            --user-prompt)
                updates=$(echo "$updates" | jq --arg prompt "$2" '. + {user_prompt: $prompt}')
                shift 2
                ;;
            --size)
                updates=$(echo "$updates" | jq --argjson size "$2" '. + {memory_size: $size}')
                shift 2
                ;;
            --policy)
                updates=$(echo "$updates" | jq --arg policy "$2" '. + {forgetting_policy: $policy}')
                shift 2
                ;;
            --temperature)
                updates=$(echo "$updates" | jq --argjson temp "$2" '. + {temperature: $temp}')
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    echo -e "${BLUE}Updating memory: ${memory_id}${NC}"

    local response=$(curl -s -X PUT "${RAGFLOW_API_URL}/api/v1/memories/${memory_id}" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$updates")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Memory updated successfully!${NC}"
        echo "$response" | jq '.'
    else
        echo -e "${RED}Failed to update memory${NC}"
        echo "$response" | jq '.'
    fi
}

# Delete memory
delete_memory() {
    local memory_id="$1"

    echo -e "${BLUE}Deleting memory: ${memory_id}${NC}"

    local response=$(curl -s -X DELETE "${RAGFLOW_API_URL}/api/v1/memories/${memory_id}" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Memory deleted successfully!${NC}"
    else
        echo -e "${RED}Failed to delete memory${NC}"
        echo "$response" | jq '.'
    fi
}

# Get memory config
get_config() {
    local memory_id="$1"

    echo -e "${BLUE}Getting memory config: ${memory_id}${NC}"

    local response=$(curl -s "${RAGFLOW_API_URL}/api/v1/memories/${memory_id}/config" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}")

    echo "$response" | jq '.'
}

# Get messages
get_messages() {
    local memory_id="$1"
    local agent_id=""
    local keywords=""
    local page="1"
    local page_size="50"

    while [[ $# -gt 1 ]]; do
        shift
        case $1 in
            --agent)
                agent_id="$2"
                shift 2
                ;;
            --keywords)
                keywords="$2"
                shift 2
                ;;
            --page)
                page="$2"
                shift 2
                ;;
            --size)
                page_size="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    echo -e "${BLUE}Getting messages from memory: ${memory_id}${NC}"

    local url="${RAGFLOW_API_URL}/api/v1/memories/${memory_id}?page=${page}&page_size=${page_size}"
    [ -n "$agent_id" ] && url="${url}&agent_id=${agent_id}"
    [ -n "$keywords" ] && url="${url}&keywords=${keywords}"

    local response=$(curl -s "$url" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}")

    echo "$response" | jq '.'
}

# Add message
add_message() {
    local memory_id="$1"
    local agent_id="$2"
    local session_id="$3"
    local user_input="$4"
    local agent_response="$5"

    if [ -z "$memory_id" ] || [ -z "$agent_id" ] || [ -z "$session_id" ] || [ -z "$user_input" ] || [ -z "$agent_response" ]; then
        echo "Error: All parameters are required"
        echo "Usage: $0 add <memory_id> <agent_id> <session_id> <user_input> <agent_response>"
        exit 1
    fi

    echo -e "${BLUE}Adding message to memory: ${memory_id}${NC}"

    local json_body=$(jq -n \
        --argjson mems "[$memory_id]" \
        --arg agent "$agent_id" \
        --arg session "$session_id" \
        --arg user "$user_input" \
        --arg response "$agent_response" \
        '{
            memory_id: $mems,
            agent_id: $agent,
            session_id: $session,
            user_input: $user,
            agent_response: $response
        }')

    local result=$(curl -s -X POST "${RAGFLOW_API_URL}/api/v1/messages" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    echo "$result" | jq '.'
}

# Search messages
search_messages() {
    local memory_id="$1"
    local query="$2"
    local threshold="0.2"
    local keyword_weight="0.7"
    local top_n="5"

    echo -e "${BLUE}Searching messages in memory: ${memory_id}${NC}"
    echo -e "${BLUE}Query: ${query}${NC}"

    local response=$(curl -s "${RAGFLOW_API_URL}/api/v1/messages/search" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -G \
        --data-urlencode "memory_id=${memory_id}" \
        --data-urlencode "query=${query}" \
        --data-urlencode "similarity_threshold=${threshold}" \
        --data-urlencode "keywords_similarity_weight=${keyword_weight}" \
        --data-urlencode "top_n=${top_n}")

    echo "$response" | jq '.'
}

# Get recent messages
recent_messages() {
    local memory_id="$1"
    local limit="10"
    local agent_id=""
    local session_id=""

    while [[ $# -gt 1 ]]; do
        shift
        case $1 in
            --limit)
                limit="$2"
                shift 2
                ;;
            --agent)
                agent_id="$2"
                shift 2
                ;;
            --session)
                session_id="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    echo -e "${BLUE}Getting recent messages from memory: ${memory_id}${NC}"

    local url="${RAGFLOW_API_URL}/api/v1/messages?memory_id=${memory_id}&limit=${limit}"
    [ -n "$agent_id" ] && url="${url}&agent_id=${agent_id}"
    [ -n "$session_id" ] && url="${url}&session_id=${session_id}"

    local response=$(curl -s "$url" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}")

    echo "$response" | jq '.'
}

# Forget message
forget_message() {
    local memory_id="$1"
    local message_id="$2"

    echo -e "${BLUE}Forgetting message: ${message_id}${NC}"

    local response=$(curl -s -X DELETE "${RAGFLOW_API_URL}/api/v1/messages/${memory_id}:${message_id}" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Message forgotten successfully!${NC}"
    else
        echo -e "${RED}Failed to forget message${NC}"
        echo "$response" | jq '.'
    fi
}

# Update message status
update_status() {
    local memory_id="$1"
    local message_id="$2"
    local status="$3"

    if [ "$status" != "true" ] && [ "$status" != "false" ]; then
        echo "Error: status must be 'true' or 'false'"
        exit 1
    fi

    echo -e "${BLUE}Updating message status: ${message_id} -> ${status}${NC}"

    local json_body=$(jq -n --argjson status "$status" '{status: $status}')

    local response=$(curl -s -X PUT "${RAGFLOW_API_URL}/api/v1/messages/${memory_id}:${message_id}" \
        -H "Authorization: Bearer ${RAGFLOW_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_body")

    if echo "$response" | jq -e '.code == 0' > /dev/null; then
        echo -e "${GREEN}Message status updated successfully!${NC}"
    else
        echo -e "${RED}Failed to update message status${NC}"
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
        list_memories "$@"
        ;;
    create)
        create_memory "$@"
        ;;
    update)
        if [ $# -lt 1 ]; then
            echo "Error: memory_id is required"
            exit 1
        fi
        update_memory "$@"
        ;;
    delete)
        if [ $# -lt 1 ]; then
            echo "Error: memory_id is required"
            exit 1
        fi
        delete_memory "$@"
        ;;
    config)
        if [ $# -lt 1 ]; then
            echo "Error: memory_id is required"
            exit 1
        fi
        get_config "$@"
        ;;
    messages)
        if [ $# -lt 1 ]; then
            echo "Error: memory_id is required"
            exit 1
        fi
        get_messages "$@"
        ;;
    add)
        add_message "$@"
        ;;
    search)
        if [ $# -lt 2 ]; then
            echo "Error: memory_id and query are required"
            exit 1
        fi
        search_messages "$@"
        ;;
    recent)
        if [ $# -lt 1 ]; then
            echo "Error: memory_id is required"
            exit 1
        fi
        recent_messages "$@"
        ;;
    forget)
        if [ $# -lt 2 ]; then
            echo "Error: memory_id and message_id are required"
            exit 1
        fi
        forget_message "$@"
        ;;
    status)
        if [ $# -lt 3 ]; then
            echo "Error: memory_id, message_id, and status are required"
            exit 1
        fi
        update_status "$@"
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
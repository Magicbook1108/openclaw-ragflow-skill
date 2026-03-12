# OpenClaw RAGFlow Knowledge Skill

🔍 **Connect OpenClaw AI to RAGFlow knowledge bases** with complete retrieval API support.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-2.0.0-green.svg)
![OpenClaw](https://img.shields.io/badge/OpenClaw-compatible-orange.svg)

## ✨ Features

- 🔍 **Complete Retrieval API**: Full support for all RAGFlow retrieval parameters
- 📚 **Dataset Management**: List and inspect available datasets
- 📝 **Chunk Management**: Create, update, delete, and manage document chunks
- 🎯 **Advanced Search**: Similarity thresholds, vector weights, reranking, knowledge graphs
- 🔑 **Keyword Extraction**: Enable automatic keyword extraction for better results
- 🌏 **Multi-Language**: Cross-language retrieval support
- 📄 **Document Filtering**: Search specific documents or use metadata filters
- 🌐 **Knowledge Graph**: Optional knowledge graph-enhanced retrieval
- ⚡ **Fast**: Direct API calls without overhead
- 🛠️ **Easy Setup**: Just configure environment variables
- 🔧 **Helper Scripts**: Bash and Python scripts for manual testing

## 📋 Prerequisites

1. **OpenClaw** installed and running
2. **RAGFlow** server running (local or remote)
3. **RAGFlow API Key** from your RAGFlow console
4. **curl** and **jq** (for helper scripts)

## 🚀 Quick Start

### 1. Install This Skill

```bash
# Clone or download this repository
git clone https://github.com/redredrrred/openclaw-ragflow-skill.git
cd openclaw-ragflow-skill

# Copy to OpenClaw skills directory
cp -r SKILL.md ~/.openclaw/workspace/skills/ragflow-knowledge/
cp -r *.sh ~/.openclaw/workspace/skills/ragflow-knowledge/
cp -r datasets.py ~/.openclaw/workspace/skills/ragflow-knowledge/

# Make scripts executable
chmod +x ~/.openclaw/workspace/skills/ragflow-knowledge/*.sh
```

### 2. Configure RAGFlow Access

Create/Edit `~/.openclaw/workspace/skills/ragflow-knowledge/.env`:

```bash
RAGFLOW_API_URL=http://127.0.0.1
RAGFLOW_API_KEY=ragflow-your-api-key-here
RAGFLOW_DATASET_IDS=["dataset-id-1", "dataset-id-2"]
RAGFLOW_TOP_K=5
RAGFLOW_SIMILARITY_THRESHOLD=0.2
```

### 3. Refresh OpenClaw

```bash
# Restart OpenClaw gateway
openclaw restart

# Or ask AI to "refresh skills" in chat
```

### 4. Start Using!

Just chat with OpenClaw:

```
You: What's our company's remote work policy?
AI: [Searches RAGFlow knowledge base and answers with sources]
```

## 📖 Usage Examples

### Basic Search

```
User: What is the vacation policy?
AI: According to the Employee Handbook, full-time employees are entitled to...
     Source: Employee Handbook 2024 (Similarity: 94%)
```

### Advanced Search with Parameters

```bash
# Using helper script with all options
./search.sh --top-k 10 --threshold 0.3 --vector-weight 0.7 --keyword "your query"
```

### List Datasets

```
User: What datasets do you have?
AI: Found 6 datasets:
     - final paper (27 chunks)
     - overlap (30 chunks)
     - general (51 chunks)
```

### Chunk Management

```bash
# List chunks in a document
./chunks.sh list doc-id-123

# Create a new chunk
./chunks.sh create doc-id-123 "This is a new chunk content"

# Update a chunk
./chunks.sh update doc-id-123 chunk-id-456 "Updated content"

# Enable/disable chunks
./chunks.sh enable doc-id-123 chunk-id-1,chunk-id-2
./chunks.sh disable doc-id-123 chunk-id-1

# Delete chunks
./chunks.sh delete doc-id-123 chunk-id-1,chunk-id-2
```

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RAGFLOW_API_URL` | ✅ Yes | - | RAGFlow server URL (e.g., `http://127.0.0.1`) |
| `RAGFLOW_API_KEY` | ✅ Yes | - | Your RAGFlow API key |
| `RAGFLOW_DATASET_IDS` | ❌ No | `[]` (all) | JSON array of dataset IDs to search |
| `RAGFLOW_TOP_K` | ❌ No | `5` | Maximum results to return |
| `RAGFLOW_SIMILARITY_THRESHOLD` | ❌ No | `0.2` | Minimum similarity score (0-1) |

### Retrieval API Parameters

#### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `question` | string | - | Search query or question (required) |
| `dataset_ids` | array | all | Specific dataset IDs to search |
| `top_k` | integer | 1024 | Maximum chunks to retrieve |
| `similarity_threshold` | float | 0.2 | Minimum similarity score (0-1) |

#### Similarity Control

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `vector_similarity_weight` | float | 0.3 | Weight for vector similarity (0-1) |
| `keywords_similarity_weight` | float | 0.7 | Weight for keyword similarity (0-1) |

#### Pagination

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `size` | integer | 30 | Results per page |

#### Content Filtering

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `doc_ids` | array | all | Limit to specific document IDs |
| `meta_data_filter` | object | - | Filter by document metadata |

#### Advanced Features

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `keyword` | boolean | false | Extract keywords for better matching |
| `rerank_id` | string | - | Reranking model ID |
| `use_kg` | boolean | false | Include knowledge graph |
| `cross_languages` | array | - | Languages for cross-language search |

## 🔧 Helper Scripts

### search.sh - Advanced Search

```bash
# Basic search
./search.sh "your query"

# Advanced options
./search.sh --top-k 10 --threshold 0.3 "your query"
./search.sh --vector-weight 0.7 --keyword "your query"
./search.sh --dataset-ids id1,id2 --use-kg "your query"
./search.sh --json "your query"  # Output raw JSON
./search.sh --help  # Show all options
```

### datasets.py / datasets.sh - Dataset Management

```bash
# List all datasets (Python version - cross-platform)
python datasets.py list

# Get dataset details
python datasets.py info 8b29e240dc8611f0b88e02bd655462b6

# List all datasets (Bash version - requires jq)
./datasets.sh list

# Get dataset details (Bash version)
./datasets.sh info 8b29e240dc8611f0b88e02bd655462b6
```

### chunks.sh - Chunk Management

```bash
# List chunks in a document
./chunks.sh list doc-id-123
./chunks.sh list doc-id-123 1 50  # page 1, 50 results

# Get chunk details
./chunks.sh get chunk-id-456

# Create a new chunk
./chunks.sh create doc-id-123 "New chunk content"

# Update a chunk
./chunks.sh update doc-id-123 chunk-id-456 "Updated content"

# Enable/disable chunks
./chunks.sh enable doc-id-123 chunk-id-1,chunk-id-2
./chunks.sh disable doc-id-123 chunk-id-1

# Delete chunks
./chunks.sh delete doc-id-123 chunk-id-1,chunk-id-2
```

## 📁 File Structure

```
~/.openclaw/workspace/skills/ragflow-knowledge/
├── SKILL.md          # Main skill definition (AI reads this)
├── search.sh         # Advanced search helper script
├── datasets.sh       # Dataset manager (Bash + jq)
├── datasets.py       # Dataset manager (Python - cross-platform)
├── chunks.sh         # Chunk management script
├── .env              # Your local configuration (don't commit!)
├── .env.example      # Example configuration
└── README.md         # This file
```

## 🎯 Search Strategies

### High-Precision Search

For questions requiring exact matches:

```bash
./search.sh --threshold 0.7 --vector-weight 0.7 "exact query"
```

### Broad Exploration

For discovering related content:

```bash
./search.sh --threshold 0.1 --top-k 20 "general topic"
```

### Keyword-Focused Search

For technical queries with specific terms:

```bash
./search.sh --keyword --vector-weight 0.1 "technical term"
```

### Knowledge Graph Enhanced

For conceptual relationships:

```bash
./search.sh --use-kg "conceptual question"
```

## 🐛 Troubleshooting

### Connection Issues

```bash
# Test RAGFlow connectivity
curl ${RAGFLOW_API_URL}/api/v1/datasets \
  -H "Authorization: Bearer ${RAGFLOW_API_KEY}"

# Check if RAGFlow is running
curl http://127.0.0.1
```

### No Results Found

- Lower `similarity_threshold` to 0.1
- Increase `top_k` to 20 or more
- Enable `keyword` extraction
- Try `vector_weight` adjustments

### Script Permission Denied

```bash
chmod +x ~/.openclaw/workspace/skills/ragflow-knowledge/*.sh
```

### jq Not Found

Use the Python version instead:

```bash
python datasets.py list  # Instead of ./datasets.sh list
```

## 🤝 Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- **RAGFlow**: https://ragflow.io
- **RAGFlow Docs**: https://ragflow.io/docs
- **RAGFlow HTTP API**: https://ragflow.io/docs/dev/http_api_reference
- **OpenClaw**: https://openclaw.ai
- **Plugin Version**: https://github.com/redredrrred/openclaw-ragflow

## ⭐ Star This Repository!

If you find this skill useful, please give it a star!

---

Made with ❤️ by [redredrrred](https://github.com/redredrrred)
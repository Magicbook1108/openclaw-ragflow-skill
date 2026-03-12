# 🧪 Testing Guide

How to test the RAGFlow skill before and after installation.

## 🔍 Pre-Installation Testing

### Test RAGFlow API Connection

First, ensure RAGFlow is running and accessible:

```bash
# Test basic connection
curl http://127.0.0.1

# Test API with your key
curl http://127.0.0.1/api/v1/datasets \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Expected response: JSON with dataset list or 401 (if key is invalid).

### Test the Search Script

```bash
# From the skill directory
cd /c/Users/lenovo/Desktop/openclaw-ragflow-skill

# Create .env file
cp .env.example .env
nano .env  # Edit with your credentials

# Make script executable (if not already)
chmod +x search.sh

# Test search
./search.sh "test query"
```

Expected output:
```
🔍 Searching RAGFlow knowledge base...
📝 Query: test query

✅ Found X result(s):

📄 [Document Name] (相似度: XX%)
Content here...

─────────────────────────────────────
Search complete! Found X result(s)
```

## ✅ Post-Installation Testing

### 1. Verify Skill Installation

```bash
# Check skill exists
ls -la ~/.openclaw/workspace/skills/ragflow-knowledge/

# Should see: SKILL.md, search.sh, .env, README.md
```

### 2. Test with OpenClaw

**Method A: Direct Chat**

```bash
# Start OpenClaw agent
openclaw agent

# Then send message:
{
  "message": "search the knowledge base for remote work policy"
}
```

**Method B: Control UI**

1. Open http://127.0.0.1:18789 in browser
2. Send message: "Search knowledge base for [your query]"

**Method C: Feishu/Slack/etc.**

If you have channels configured, send a message:
```
search ragflow for [your query]
```

### 3. Test Search Functionality

Try these test queries:

```
# Simple query
"What documents do you have?"

# Policy query
"What is the vacation policy?"

# Technical query
"How do I configure the API?"

# Chinese query
"公司的远程办公政策是什么？"
```

Expected behavior:
- AI should use the search skill
- Return results from RAGFlow
- Cite source documents

## 🐛 Troubleshooting Tests

### Test Environment Variables

```bash
cd ~/.openclaw/workspace/skills/ragflow-knowledge

# Check if .env exists
cat .env

# Test variables are set
echo $RAGFLOW_API_URL
echo $RAGFLOW_API_KEY
```

### Test Network Connectivity

```bash
# Test RAGFlow is reachable
curl -v http://127.0.0.1 2>&1 | grep "Connected"

# Test API endpoint
curl -v http://127.0.0.1/api/v1/retrieval \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"question":"test","top_k":1}'
```

### Test Skill Loading

```bash
# Restart OpenClaw
openclaw restart

# Check logs for skill loading
tail -f /tmp/openclaw/openclaw-*.log | grep -i "skill\|ragflow"
```

## ✅ Success Criteria

Your skill is working correctly if:

- [ ] RAGFlow API responds to curl requests
- [ ] search.sh returns results from command line
- [ ] Skill is loaded by OpenClaw (check logs)
- [ ] AI uses the skill when asked to search knowledge base
- [ ] Results include document names and similarity scores
- [ ] Chinese queries work correctly

## 📊 Performance Testing

Test response times:

```bash
# Time a search query
time ~/.openclaw/workspace/skills/ragflow-knowledge/search.sh "your query"

# Expected: < 2 seconds for local RAGFlow
```

## 🔄 Regression Testing

After making changes, re-run:

1. Pre-installation API test
2. search.sh manual test
3. OpenClaw integration test
4. Performance test

## 📝 Test Results Template

```markdown
## Test Results - [DATE]

### Environment
- OpenClaw Version: [run `openclaw --version`]
- RAGFlow Version: [check your RAGFlow]
- OS: [Windows/Linux/Mac]

### Test Cases
- [ ] API Connection: PASS/FAIL
- [ ] search.sh Manual Test: PASS/FAIL
- [ ] Skill Installation: PASS/FAIL
- [ ] OpenClaw Integration: PASS/FAIL
- [ ] Chinese Query: PASS/FAIL
- [ ] Performance (< 2s): PASS/FAIL

### Notes
[Add any observations or issues]

### Issues Found
[List any bugs or problems]
```

---

**Happy Testing! 🧪**

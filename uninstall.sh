#!/bin/bash
# OpenClaw RAGFlow Skill Uninstallation Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OpenClaw RAGFlow Skill Uninstaller   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Target directory
TARGET_DIR="$HOME/.openclaw/workspace/skills/ragflow-knowledge"

# Check if skill is installed
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}⚠️  Skill not found at: $TARGET_DIR${NC}"
    exit 0
fi

echo "This will remove the RAGFlow knowledge skill from:"
echo "  $TARGET_DIR"
echo ""
echo -e "${RED}⚠️  This action cannot be undone!${NC}"
echo ""
read -p "Are you sure? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove skill directory
echo "Removing skill directory..."
rm -rf "$TARGET_DIR"

echo ""
echo -e "${GREEN}✓ Uninstallation complete!${NC}"
echo ""
echo "Don't forget to restart OpenClaw:"
echo -e "  ${YELLOW}openclaw restart${NC}"

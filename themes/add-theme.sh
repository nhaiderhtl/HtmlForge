#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   HtmlForge Theme Generator Script    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No theme directory provided${NC}"
    echo ""
    echo "Usage: ./add-theme.sh <theme-directory-name>"
    echo ""
    echo "Example: ./add-theme.sh MyAwesomeTheme"
    echo ""
    echo "This will look for: themes/MyAwesomeTheme/style.css"
    exit 1
fi

THEME_DIR=$1
THEME_NAME=$(echo "$THEME_DIR" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
THEME_PATH="$THEME_DIR"

if [ ! -f "themes.json" ]; then
    echo -e "${YELLOW}Warning: themes.json not found in current directory${NC}"
    echo "Attempting to navigate to themes directory..."

    if [ -d "themes" ]; then
        cd themes
        echo -e "${GREEN} Navigated to themes directory${NC}"
    fi

    if [ ! -f "themes.json" ]; then
        echo -e "${YELLOW}Creating new themes.json file...${NC}"
        cat > themes.json << 'JSONEOF'
{
  "themes": {}
}
JSONEOF
        echo -e "${GREEN}✓ Created themes.json${NC}"
    fi
fi

if [ ! -d "$THEME_PATH" ]; then
    echo -e "${RED}Error: Theme directory '$THEME_PATH' does not exist${NC}"
    echo ""
    echo "Available theme directories:"
    ls -d */ 2>/dev/null | grep -v node_modules || echo "  (none found)"
    exit 1
fi

CSS_FILE="$THEME_PATH/style.css"
if [ ! -f "$CSS_FILE" ]; then
    echo -e "${RED}Error: CSS file not found at '$CSS_FILE'${NC}"
    echo ""
    echo "Please create a style.css file in the $THEME_PATH directory first."
    exit 1
fi

echo -e "${GREEN} Found theme directory: $THEME_PATH${NC}"
echo -e "${GREEN} Found CSS file: $CSS_FILE${NC}"
echo ""

echo -e "${BLUE}Processing CSS file...${NC}"

CSS_CONTENT=$(cat "$CSS_FILE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

if [ -z "$CSS_CONTENT" ]; then
    echo -e "${RED}Error: CSS file is empty${NC}"
    exit 1
fi

echo -e "${GREEN} CSS processed successfully (${#CSS_CONTENT} characters)${NC}"
echo ""

BACKUP_FILE="themes.json.backup.$(date +%Y%m%d_%H%M%S)"
cp themes.json "$BACKUP_FILE"
echo -e "${GREEN} Created backup: $BACKUP_FILE${NC}"

if grep -q "\"$THEME_NAME\":" themes.json; then
    echo -e "${YELLOW}Warning: Theme '$THEME_NAME' already exists in themes.json${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted. Backup preserved at: $BACKUP_FILE${NC}"
        exit 1
    fi

    OVERWRITE=true
else
    OVERWRITE=false
fi

THEME_ENTRY=$(cat <<EOF
    "$THEME_NAME": {
      "name": "$THEME_DIR",
      "description": "TODO: Add a description for your theme",
      "tags": ["TODO", "Add", "Tags"],
      "css": "$CSS_CONTENT"
    }
EOF
)

echo -e "${BLUE}Adding theme to themes.json...${NC}"

python3 - <<PYTHON_SCRIPT
import json
import sys

try:
    # Read existing JSON
    with open('themes.json', 'r') as f:
        data = json.load(f)

    # Add or update theme
    if 'themes' not in data:
        data['themes'] = {}

    data['themes']['$THEME_NAME'] = {
        'name': '$THEME_DIR',
        'description': 'TODO: Add a description for your theme',
        'tags': ['TODO', 'Add', 'Tags'],
        'css': '''$CSS_CONTENT'''
    }

    # Write updated JSON
    with open('themes.json', 'w') as f:
        json.dump(data, f, indent=2)

    print('Successfully updated themes.json')
    sys.exit(0)

except Exception as e:
    print(f'Error updating JSON: {e}', file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Theme Added Successfully!      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}⚠  IMPORTANT: Next Steps${NC}"
    echo ""
    echo "1. Edit themes.json and update your theme's metadata:"
    echo "   - description: Add a meaningful description"
    echo "   - tags: Add relevant tags (e.g., 'Dark', 'Light', 'Minimal')"
    echo ""
    echo "2. Add your theme to the Java enum in:"
    echo "   src/main/java/dev/kxrim/Theme.java"
    echo ""
    echo "   Add this line:"
    echo -e "   ${BLUE}$THEME_NAME(\"$THEME_DIR\")${NC}"
    echo ""
    echo "3. Update themes/index.html with a preview card"
    echo ""
    echo "4. Test your theme locally"
    echo ""
    echo "5. Create a pull request!"
    echo ""
    echo -e "Backup saved at: ${GREEN}$BACKUP_FILE${NC}"
    echo ""
else
    echo -e "${RED}✗ Failed to update themes.json${NC}"
    echo -e "Restoring from backup..."
    mv "$BACKUP_FILE" themes.json
    echo -e "${GREEN} Restored from backup${NC}"
    exit 1
fi


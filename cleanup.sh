#!/bin/bash

# CHATTrace Cleanup Script
# Removes all data and optionally deletes all components

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}[CLEANUP]${NC} CHATTrace Cleanup Utility"
echo -e "${RED}WARNING:${NC} This will remove all data and configurations!"
echo -e "${YELLOW}[ACTION]${NC} What would you like to do?"
echo -e "1) Clean logs and temporary data only"
echo -e "2) Full reset (remove all components and data)"
read -p "Choice (1-2): " choice

case $choice in
    1)
        echo -e "${YELLOW}[CLEANING]${NC} Removing temporary data..."
        rm -rf "$PROJECT_DIR/server/logs/*"
        rm -rf "$PROJECT_DIR/chat_archive_*.log"
        echo -e "${GREEN}[SUCCESS]${NC} Temporary data cleaned"
        ;;
    2)
        echo -e "${RED}[DANGER]${NC} Full reset selected. This will remove everything!"
        read -p "Are you absolutely sure? Type 'CONFIRM' to proceed: " confirm
        
        if [ "$confirm" = "CONFIRM" ]; then
            echo -e "${RED}[DELETING]${NC} Removing all CHATTrace components..."
            rm -rf "$PROJECT_DIR/server/logs/"
            rm -rf "$PROJECT_DIR/bin/"
            rm -rf "$PROJECT_DIR/config.json"
            rm -rf "$PROJECT_DIR/chat_archive_*.log"
            echo -e "${GREEN}[SUCCESS]${NC} All components removed"
        else
            echo -e "${YELLOW}[CANCELLED]${NC} Operation cancelled"
        fi
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Invalid choice. Exiting."
        exit 1
        ;;
esac

echo -e "${GREEN}[COMPLETE]${NC} Cleanup finished"
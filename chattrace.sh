#!/bin/bash

# CHATTrace - Secure Local Chat Application
# Author: Chriz
# Description: Self-hosted chat with global access via Cloudflare tunnel
# Enhanced with virtual environment support and clean terminal output

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
SERVER_DIR="$PROJECT_DIR/server"
BIN_DIR="$PROJECT_DIR/bin"
LOGS_DIR="$PROJECT_DIR/server/logs"
CONFIG_FILE="$PROJECT_DIR/config.json"

# Global variables
SERVER_PID=""
TUNNEL_PID=""
PUBLIC_URL=""
PORT=""

# ASCII Art Banner
show_ascii() {
    clear
    echo -e "${CYAN}"
    cat "$PROJECT_DIR/assets/ascii.txt"
    echo -e "${NC}"
    echo
}

# Check if Python is installed
check_python() {
    echo -ne "${YELLOW}[CHECKING]${NC} Python installation... "
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}NOT FOUND${NC}"
        echo -e "${RED}[ERROR]${NC} Python3 not found. Please install Python3 first."
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}FOUND${NC} ($PYTHON_VERSION)"
}

# Setup virtual environment
setup_venv() {
    echo -ne "${YELLOW}[SETTING UP]${NC} Virtual environment... "
    
    if [ ! -d "$VENV_DIR" ]; then
        python3 -m venv "$VENV_DIR"
        echo -e "${GREEN}CREATED${NC}"
    else
        echo -e "${GREEN}EXISTS${NC}"
    fi
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Verify virtual environment is active
    if [[ "$VIRTUAL_ENV" != "" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} Virtual environment activated: ${CYAN}$(basename $VIRTUAL_ENV)${NC}"
    else
        echo -e "${RED}[ERROR]${NC} Failed to activate virtual environment"
        exit 1
    fi
}

# Check dependencies quietly within virtual environment
check_dependencies() {
    echo -ne "${YELLOW}[CHECKING]${NC} Dependencies in venv... "
    
    # Check Node.js silently
    if ! command -v node &> /dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo -e "${RED}[ERROR]${NC} Node.js not found. Installing..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt install -y nodejs
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install node
        fi
    fi
    
    # Check Cloudflared silently
    if [ ! -f "$BIN_DIR/cloudflared" ]; then
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}[INSTALLING]${NC} Cloudflared..."
        mkdir -p "$BIN_DIR"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [[ $(uname -m) == "x86_64" ]]; then
                CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
            elif [[ $(uname -m) == "aarch64" ]]; then
                CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb"
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if [[ $(uname -m) == "arm64" ]]; then
                CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz"
            else
                CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz"
            fi
        fi
        
        if [ ! -z "$CLOUDFLARED_URL" ]; then
            wget -O "$BIN_DIR/cloudflared_package" "$CLOUDFLARED_URL" 2>/dev/null
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo dpkg -i "$BIN_DIR/cloudflared_package" 2>/dev/null
                sudo cp /usr/local/bin/cloudflared "$BIN_DIR/cloudflared" 2>/dev/null
                sudo rm /usr/local/bin/cloudflared 2>/dev/null
            else
                tar -xzf "$BIN_DIR/cloudflared_package" -C "$BIN_DIR" 2>/dev/null
            fi
            rm "$BIN_DIR/cloudflared_package" 2>/dev/null
        fi
    fi
    
    # Install Python packages with completely suppressed output
    pip install flask flask-socketio requests > /dev/null 2>&1
    echo -e "${GREEN}OK${NC}"
}

# Find an available port
find_available_port() {
    local port=5000
    while netstat -tuln | grep -q ":$port "; do
        ((port++))
        if [ $port -gt 5050 ]; then
            echo "5000"  # Default back to 5000 if many ports are busy
            return
        fi
    done
    echo $port
}

# Setup configuration
setup_config() {
    # Find available port
    PORT=$(find_available_port)
    echo -e "${YELLOW}[INFO]${NC} Using port: $PORT"
    
    # Create directories if they don't exist
    mkdir -p "$SERVER_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$LOGS_DIR"
    
    # Create config file
    cat > "$CONFIG_FILE" << EOF
{
    "port": $PORT,
    "log_file": "$LOGS_DIR/chat.log",
    "cloudflared_path": "$BIN_DIR/cloudflared"
}
EOF
}

# Start Flask server with proper detection
start_server() {
    echo -ne "${GREEN}[STARTING]${NC} Local chat server on port $PORT... "
    
    # Start server with minimal output but capture PID
    cd "$SERVER_DIR"
    python3 "$PROJECT_DIR/server/app.py" >/tmp/server_output.log 2>&1 &
    SERVER_PID=$!
    
    # Wait a moment for server to start
    sleep 3
    
    # Check if server process is running
    if ps -p $SERVER_PID > /dev/null; then
        # Check if the server is actually responding
        if curl -s "http://localhost:$PORT" >/dev/null 2>&1; then
            echo -e "${GREEN}SUCCESS${NC}"
            return 0
        else
            # Server process running but not responding, kill it
            kill $SERVER_PID 2>/dev/null
            echo -e "${RED}FAILED${NC}"
            echo -e "  ${RED}[ERROR]${NC} Server started but not responding"
            return 1
        fi
    else
        echo -e "${RED}FAILED${NC}"
        # Show error if available
        if [ -f /tmp/server_output.log ]; then
            ERROR_MSG=$(tail -n 10 /tmp/server_output.log 2>/dev/null)
            if [ -n "$ERROR_MSG" ]; then
                echo "  Error: $ERROR_MSG"
            fi
        fi
        return 1
    fi
}

# Start Cloudflare tunnel with proper URL capture
start_tunnel() {
    echo -ne "${GREEN}[STARTING]${NC} Cloudflare tunnel... "
    
    # Create a temporary file to capture the output
    TEMP_OUTPUT="/tmp/cloudflared_$(date +%s).txt"
    
    # Start cloudflared tunnel in background with correct port
    "$BIN_DIR/cloudflared" tunnel --url "http://localhost:$PORT" >"$TEMP_OUTPUT" 2>&1 &
    TUNNEL_PID=$!
    
    # Wait for the URL to appear in the output
    local timeout=20
    local count=0
    while [ $count -lt $timeout ]; do
        sleep 1
        # Look for the URL in the output file
        if [ -f "$TEMP_OUTPUT" ]; then
            PUBLIC_URL=$(grep -o 'https://[^[:space:]]*\.trycloudflare\.com' "$TEMP_OUTPUT" | head -n1)
            if [ -n "$PUBLIC_URL" ]; then
                echo -e "${GREEN}SUCCESS${NC}"
                echo -e "  ${CYAN}Public URL:${NC} $PUBLIC_URL"
                echo -e "  ${YELLOW}Share this link to invite participants${NC}"
                
                # Clean up the temporary file
                rm -f "$TEMP_OUTPUT"
                return 0
            fi
        fi
        ((count++))
    done
    
    # If we timed out, try to get any URL that might have appeared
    if [ -f "$TEMP_OUTPUT" ]; then
        PUBLIC_URL=$(grep -o 'https://[^[:space:]]*\.trycloudflare\.com' "$TEMP_OUTPUT" | head -n1)
        if [ -n "$PUBLIC_URL" ]; then
            echo -e "${GREEN}SUCCESS${NC}"
            echo -e "  ${CYAN}Public URL:${NC} $PUBLIC_URL"
            echo -e "  ${YELLOW}Share this link to invite participants${NC}"
            
            rm -f "$TEMP_OUTPUT"
            return 0
        fi
    fi
    
    # Even if we didn't capture the URL, the tunnel might still be running
    # Check if the process is still alive
    if ps -p $TUNNEL_PID > /dev/null; then
        echo -e "${YELLOW}PENDING${NC}"
        echo -e "  ${YELLOW}Tunnel established, URL will appear shortly${NC}"
        # Try to get URL in background
        (
            while true; do
                sleep 2
                if [ -f "$TEMP_OUTPUT" ]; then
                    URL=$(grep -o 'https://[^[:space:]]*\.trycloudflare\.com' "$TEMP_OUTPUT" | head -n1)
                    if [ -n "$URL" ]; then
                        echo -e "\n  ${GREEN}✓${NC} Public URL: ${CYAN}$URL${NC}"
                        echo -e "  ${YELLOW}Share this link to invite participants${NC}"
                        break
                    fi
                fi
            done
        ) &
        BG_URL_CHECK_PID=$!
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        rm -f "$TEMP_OUTPUT"
        return 1
    fi
}

# Monitor chat activity with clean UI (only joins/leaves)
monitor_chat() {
    echo
    echo -e "${YELLOW}[MONITORING]${NC} Live chat activity (Press Ctrl+C to stop):"
    echo -e "${CYAN}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}            REAL-TIME JOIN/LEAVE MONITOR                  ${CYAN}  │${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    # Create the log file if it doesn't exist
    touch "$LOGS_DIR/chat.log"
    
    # Tail the log file with clean formatting - only show joins and leaves
    tail -f "$LOGS_DIR/chat.log" 2>/dev/null | while read line; do
        if [[ $line == *"joined"* ]]; then
            # Extract username from the log entry
            USERNAME=$(echo "$line" | grep -o 'User [^ ]* joined' | cut -d' ' -f2)
            TIMESTAMP=$(echo "$line" | cut -d']' -f1 | sed 's/\[//')
            echo -e "  ${GREEN}┌ JOIN${NC} ── [$TIMESTAMP] User ${CYAN}$USERNAME${NC} joined"
        elif [[ $line == *"left"* ]]; then
            # Extract username from the log entry
            USERNAME=$(echo "$line" | grep -o 'User [^ ]* left' | cut -d' ' -f2)
            TIMESTAMP=$(echo "$line" | cut -d']' -f1 | sed 's/\[//')
            echo -e "  ${RED}└ LEAVE${NC} ── [$TIMESTAMP] User ${CYAN}$USERNAME${NC} left"
        fi
    done
}

# Cleanup function with clean UI
cleanup() {
    echo
    echo -e "${YELLOW}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC}                    CLEANUP PROCESS                       ${YELLOW}  │${NC}"
    echo -e "${YELLOW}└────────────────────────────────────────────────────────────┘${NC}"
    
    # Kill server and tunnel processes
    if [ ! -z "$SERVER_PID" ] && ps -p $SERVER_PID > /dev/null; then
        kill $SERVER_PID 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Flask server stopped (PID: $SERVER_PID)"
    fi
    
    if [ ! -z "$TUNNEL_PID" ] && ps -p $TUNNEL_PID > /dev/null; then
        kill $TUNNEL_PID 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Cloudflare tunnel stopped (PID: $TUNNEL_PID)"
    fi
    
    # Kill background URL checker if running
    if [ ! -z "$BG_URL_CHECK_PID" ] && ps -p $BG_URL_CHECK_PID > /dev/null; then
        kill $BG_URL_CHECK_PID 2>/dev/null
    fi
    
    # Clean up temp files
    rm -f /tmp/server_output.log
    rm -f /tmp/cloudflared_*.txt
    
    # Ask user about logs with clean UI
    echo
    echo -e "${YELLOW}[ACTION]${NC} Choose log management option:"
    echo -e "  ${CYAN}1)${NC} Save logs to archive"
    echo -e "  ${CYAN}2)${NC} Delete logs permanently"
    echo -e "  ${CYAN}3)${NC} View logs before deciding"
    read -p "  Choice (1-3): " log_choice
    
    case $log_choice in
        1)
            ARCHIVE_NAME="chat_archive_$(date +%Y%m%d_%H%M%S).log"
            if [ -f "$LOGS_DIR/chat.log" ]; then
                cp "$LOGS_DIR/chat.log" "$PROJECT_DIR/$ARCHIVE_NAME"
                echo -e "  ${GREEN}✓${NC} Logs saved as: $ARCHIVE_NAME"
            else
                echo -e "  ${YELLOW}-${NC} No log file found to save"
            fi
            ;;
        2)
            if [ -f "$LOGS_DIR/chat.log" ]; then
                rm -f "$LOGS_DIR/chat.log"
                echo -e "  ${RED}✗${NC} Logs permanently deleted"
            fi
            ;;
        3)
            if [ -f "$LOGS_DIR/chat.log" ]; then
                echo -e "  ${YELLOW}Current logs:${NC}"
                cat "$LOGS_DIR/chat.log" | head -n 10
                if [ $(wc -l < "$LOGS_DIR/chat.log") -gt 10 ]; then
                    echo "  ... (showing first 10 lines)"
                fi
            else
                echo -e "  ${YELLOW}-${NC} No log file found"
            fi
            echo
            read -p "  Save logs? (y/N): " final_save
            if [[ $final_save =~ ^[Yy]$ ]]; then
                ARCHIVE_NAME="chat_archive_$(date +%Y%m%d_%H%M%S).log"
                if [ -f "$LOGS_DIR/chat.log" ]; then
                    cp "$LOGS_DIR/chat.log" "$PROJECT_DIR/$ARCHIVE_NAME"
                    echo -e "  ${GREEN}✓${NC} Logs saved as: $ARCHIVE_NAME"
                fi
            else
                if [ -f "$LOGS_DIR/chat.log" ]; then
                    rm -f "$LOGS_DIR/chat.log"
                    echo -e "  ${RED}✗${NC} Logs permanently deleted"
                fi
            fi
            ;;
        *)
            echo -e "  ${YELLOW}-${NC} Deleting logs by default"
            if [ -f "$LOGS_DIR/chat.log" ]; then
                rm -f "$LOGS_DIR/chat.log"
            fi
            ;;
    esac
    
    echo
    echo -e "${GREEN}[SUCCESS]${NC} All processes stopped and cleaned up"
    exit 0
}

# Main execution
main() {
    show_ascii
    check_python
    setup_venv
    check_dependencies
    setup_config
    
    # Ensure directories exist
    mkdir -p "$LOGS_DIR"
    touch "$LOGS_DIR/chat.log"
    
    # Start services
    if start_server; then
        if start_tunnel; then
            # Set up cleanup trap
            trap cleanup SIGINT SIGTERM
            
            # Start monitoring
            monitor_chat
        else
            echo -e "${RED}[FATAL]${NC} Could not start tunnel. Exiting."
            # Kill the server if tunnel failed
            if [ ! -z "$SERVER_PID" ]; then
                kill $SERVER_PID 2>/dev/null
            fi
            exit 1
        fi
    else
        echo -e "${RED}[FATAL]${NC} Could not start server. Exiting."
        exit 1
    fi
}

# Run main function
main "$@"
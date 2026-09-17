#!/bin/bash
# ==============================================================================
# Script: start-beef-lab.sh
# Purpose: Automated orchestration of BeEF in persistent TMUX sessions
# Usage: ./start-beef-lab.sh [optional_session_name]
# ==============================================================================

SESSION="${1:-beef-lab}"

# Check if session already exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "[!] TMUX session '$SESSION' already exists. Skipping startup."
    exit 0
fi

echo "[*] Initializing TMUX session: $SESSION"

# 1. Create detached session with primary window
tmux new-session -d -s "$SESSION" -n beef

# 2. Launch BeEF server
tmux send-keys -t "$SESSION:beef" 'cd ~/beef' C-m
tmux send-keys -t "$SESSION:beef" './beef' C-m

# 3. Create monitoring window
tmux new-window -t "$SESSION" -n monitor
tmux send-keys -t "$SESSION:monitor" 'echo "=== BeEF Lab Monitoring Shell ==="; date; uptime' C-m

echo "[+] BeEF Lab Environment successfully initialized."
echo "    - Session Name : $SESSION"
echo "    - Windows      : beef (Server), monitor (Diagnostics)"
echo "    - Attach with  : tmux attach -t $SESSION"

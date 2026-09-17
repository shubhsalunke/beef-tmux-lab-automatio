# Browser Security & Session Management Lab Guide
**BeEF Framework + TMUX Integration & Automation on Azure VM**

---

## Executive Summary

This document details the end-to-end setup, architecture, and automation of a persistent browser security testing environment using **BeEF (Browser Exploitation Framework)** and **TMUX (Terminal Multiplexer)** on an Azure Linux VM.

> [!NOTE]
> **Academic Scope & Ethics:** All testing, demonstrations, and architecture analysis are strictly conducted within an isolated, authorized sandbox lab environment. Offensive actions, payloads, and unauthorized targeting are out of scope; focus remains on session management, architecture, automation, and defensive detection theory.

---

## Project Execution Roadmap

```text
┌────────────────────────────────────────────────────────┐
│ Phase 1: Environment Diagnostics                       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 2: Ruby Environment Setup (via rbenv)            │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 3: BeEF Repository & Dependencies Setup          │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 4: BeEF Configuration & Security Hardening       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 5: Baseline BeEF Verification                    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 6: TMUX Session Management Architecture          │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 7: Manual TMUX + BeEF Multi-Window Setup         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 8: Automation Script (start-beef-lab.sh)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 9: Comprehensive Integration Testing             │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 10: Reusability & Resource Isolation Check       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 11: Controlled Lab Demonstration                 │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 12: Architectural Presentation & Viva Defense    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ Phase 13: Academic Study: Malware & Rootkit Detection  │
└────────────────────────────────────────────────────────┘
```

---

## Phase 1 — Environment Diagnostics

Connect to your Azure VM via SSH and verify your base Linux environment and installed packages.

### 1. SSH Login
```bash
ssh azureuser@<YOUR-VM-IP>
```

### 2. User & Hostname Verification
```bash
whoami
hostname
pwd
```

### 3. Operating System Info
```bash
cat /etc/os-release
```

### 4. Toolchain Version Check
```bash
ruby --version
tmux -V
git --version
sqlite3 --version
```

---

## Phase 2 — Ruby Setup via rbenv

BeEF modern versions require a recent Ruby release (e.g., Ruby 3.3+ / 3.4.x). Install and configure `rbenv` and `ruby-build`.

### 1. Clone rbenv
```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
```

### 2. Configure Shell Environment
```bash
echo 'export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Install ruby-build Plugin
```bash
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
eval "$(rbenv init - bash)"
ruby-build --version
```

### 4. Install & Set Ruby Version
```bash
# List available Ruby versions
rbenv install -l | grep -E '^3\.[3-9]\.'

# Install Ruby 3.4.10
rbenv install 3.4.10
```

---

## Phase 3 — BeEF Repository & Dependency Setup

### 1. Clone BeEF Repository
```bash
cd ~
git clone https://github.com/beefproject/beef.git
cd ~/beef
```

### 2. Pin Directory Ruby Version
```bash
echo "3.4.10" > ~/beef/.ruby-version
cd ~/beef
ruby --version
rbenv version
```
*Expected Output:* `ruby 3.4.10`

### 3. Inspect Core File Structure
```bash
ls -F
```
Key directories:
* `beef` — Main executable launcher
* `config.yaml` — Core server and extension configurations
* `Gemfile` — Ruby dependency manifests
* `core/`, `extensions/`, `modules/` — Architectural components

### 4. Install Dependencies
```bash
gem install bundler
bundler --version
cd ~/beef
bundle install
```
*Verification:* Confirm output displays `Bundle complete!`.

---

## Phase 4 — Configuration & Security Hardening

> [!WARNING]
> Never expose BeEF listeners directly to the public Internet without Network Security Group (NSG) restrictions, and never push plaintext credentials to public repositories or logs.

### 1. Create Configuration Backup
```bash
cd ~/beef
cp config.yaml config.yaml.backup
ls -lh config.yaml*
```

### 2. Update Configuration
```bash
nano config.yaml
```
Key modifications:
- Update default administrator credentials to strong, lab-specific non-default values.
- Check binding parameters:
```yaml
beef:
  http:
    host: "0.0.0.0"
    port: "3000"
```

---

## Phase 5 — Baseline BeEF Execution Check

Verify that BeEF compiles and boots successfully as a standalone process.

### 1. Start BeEF
```bash
cd ~/beef
./beef
```
*Expected console output:*
```text
BeEF 0.6.0.0
300+ modules enabled
BeEF server started
```

### 2. Check Listening Port (from another terminal)
```bash
ss -ltnp | grep ':3000'
```
*Expected Output:*
```text
LISTEN 0 1024 0.0.0.0:3000 0.0.0.0:* users:(("ruby",pid=...,fd=...))
```

---

## Phase 6 — TMUX Session Architecture

TMUX acts as the **session persistence and management layer**. It decouples the running BeEF server process and monitoring commands from SSH disconnects.

```text
┌─────────────────────────────────────────────────────────┐
│                    TMUX Session: beef-lab               │
│                                                         │
│   ┌───────────────────────────┬─────────────────────┐   │
│   │  Window 0: "beef"         │ Window 1: "monitor" │   │
│   │  - BeEF Web Server        │ - Server Health     │   │
│   │  - Port 3000 listener     │ - Resource Monitor  │   │
│   │  - Ruby Execution Engine  │ - Shell Commands    │   │
│   └───────────────────────────┴─────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### TMUX Basic Commands Cheat Sheet

| Command | Action |
|---|---|
| `tmux new -s beef-lab` | Create and attach to a new session named `beef-lab` |
| `tmux ls` | List active TMUX sessions |
| `Ctrl+B` then `D` | Detach safely from current session via keyboard shortcut |
| `tmux detach-client -s beef-lab` | Detach session from another SSH terminal |
| `tmux attach -t beef-lab` | Reattach to session `beef-lab` |
| `tmux kill-session -t beef-lab` | Terminate specific session |

---

## Phase 7 — Manual Multi-Window Setup

Before automating, test creating the headless multi-window setup manually:

```bash
# 1. Create detached session with 'beef' window
tmux new-session -d -s beef-lab -n beef

# 2. Start BeEF in the beef window
tmux send-keys -t beef-lab:beef 'cd ~/beef' C-m
tmux send-keys -t beef-lab:beef './beef' C-m

# 3. Create 'monitor' window
tmux new-window -t beef-lab -n monitor

# 4. Launch diagnostic banner in monitor window
tmux send-keys -t beef-lab:monitor 'echo "=== BeEF Lab Monitor ==="; date; uptime' C-m

# 5. Verify window hierarchy
tmux list-windows -t beef-lab
```

---

## Phase 8 — Automation Script (start-beef-lab.sh)

Automate environment orchestration using a reusable, parameter-driven Bash script.

### 1. Script Implementation
Create `~/start-beef-lab.sh`:

```bash
cat << 'EOF' > ~/start-beef-lab.sh
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
EOF
```

### 2. Permissions & Syntax Check
```bash
chmod +x ~/start-beef-lab.sh
bash -n ~/start-beef-lab.sh
```

### 3. Execute Script
```bash
~/start-beef-lab.sh
```

---

## Phase 9 — Comprehensive Integration Testing

Run systematic tests to ensure both session persistence and network services are functioning.

### Test 1: Verify Active Sessions
```bash
tmux ls
```
*Expected:* `beef-lab: 2 windows (created ...)`

### Test 2: Verify Window Hierarchy
```bash
tmux list-windows -t beef-lab
```
*Expected:*
```text
0: beef* (1 panes)
1: monitor (1 panes)
```

### Test 3: Verify Running Process
```bash
tmux display-message -p -t beef-lab:beef '#{pane_current_command}'
```
*Expected:* `ruby`

### Test 4: Socket & Port Binding
```bash
ss -ltnp | grep ':3000'
```
*Expected:* Active `LISTEN` state on port `3000`.

### Test 5: Local HTTP Health Probe
```bash
curl -I http://127.0.0.1:3000/
```
*Expected:* HTTP 200 / 302 response headers from BeEF.

---

## Phase 10 — Reusability & Resource Isolation Check

Verify that the automation script properly handles custom session names and port conflicts.

```bash
# Default session invocation (creates 'beef-lab')
~/start-beef-lab.sh

# Custom session invocation (e.g., 'my-lab' or 'beef-lab-test')
~/start-beef-lab.sh my-lab

# List active sessions to verify creation
tmux ls

# Terminate test session after validation
tmux kill-session -t my-lab
```

> [!NOTE]
> Running multiple concurrent BeEF sessions on the same default port (`3000`) will cause a port binding collision. This is expected behavior demonstrating port exclusivity.

---

## Phase 11 — Controlled Lab Demonstration

Demonstrate the setup using an authorized, isolated browser client within the private subnet:

```text
┌──────────────────────┐          HTTP GET /hook.js          ┌──────────────────────┐
│  Lab Browser Client  │ ──────────────────────────────────> │  BeEF Server (:3000) │
└──────────────────────┘                                     └──────────┬───────────┘
                                                                        │
                                                                        ▼ Session Telemetry
┌──────────────────────┐             tmux attach             ┌──────────────────────┐
│      Admin SSH       │ ──────────────────────────────────> │    BeEF Admin UI     │
└──────────────────────┘                                     │ (beef-lab in TMUX)   │
                                                             └──────────────────────┘
```

### Safe Demo Checkpoints:
1. Access BeEF Admin panel via authorized local/VPN browser.
2. Review connected browser session telemetry (OS, user-agent, browser plugins).
3. Demonstrate module inspection (showing modular category structure).
4. Review access logs in the TMUX `monitor` pane.

---

## Phase 12 — Architectural Explanation & Viva Defense

### 1. Multi-Tier System Architecture

The deployed solution is designed as a **decoupled, three-tier operational architecture** where session management, application execution, and diagnostic monitoring operate independently yet synchronously.

```text
═══════════════════════════════════════════════════════════════════════════════════
                         TIER 1: ACCESS & MANAGEMENT LAYER
═══════════════════════════════════════════════════════════════════════════════════
                                  ┌───────────────────┐
                                  │   Lab Operator    │
                                  └─────────┬─────────┘
                                            │ SSH (Port 22 / Key Auth)
                                            ▼
                                  ┌───────────────────┐
                                  │  Azure Linux VM   │
                                  └─────────┬─────────┘
                                            │ Launches / Attaches
                                            ▼
═══════════════════════════════════════════════════════════════════════════════════
                   TIER 2: TMUX PERSISTENT ORCHESTRATION LAYER
═══════════════════════════════════════════════════════════════════════════════════
                      ┌───────────────────────────────────────┐
                      │    TMUX Multiplexer: "beef-lab"       │
                      └───────────────────┬───────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
     ┌────────────────────────┐                      ┌────────────────────────┐
     │  Window 0: [beef]      │                      │  Window 1: [monitor]   │
     │  - Active Ruby Process │                      │  - Diagnostic Shell    │
     │  - REST API Engine     │                      │  - Socket Health Check │
     │  - Event Hook Broker   │                      │  - Resource Telemetry  │
     └────────────┬───────────┘                      └────────────────────────┘
                  │
═══════════════════════════════════════════════════════════════════════════════════
                      TIER 3: CORE APPLICATION & NETWORK LAYER
═══════════════════════════════════════════════════════════════════════════════════
                  ▼
     ┌────────────────────────┐
     │   BeEF Server Core     │
     │   (Port 3000 / HTTP)   │
     └────────────┬───────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
┌───────────────┐   ┌───────────────┐
│ Extensions    │   │ Modules Engine│
│ - REST API    │   │ - Browser Info│
│ - Admin Web UI│   │ - DOM Analysis│
│ - SQLite DB   │   │ - Lab Probes  │
└───────┬───────┘   └───────────────┘
        │
        │ HTTP /hook.js
        ▼
┌───────────────────────────────┐
│ Authorized Lab Target Browser │
└───────────────────────────────┘
═══════════════════════════════════════════════════════════════════════════════════
```

---

### 2. Component Responsibility Matrix

| Component Layer | Technology | Operational Role | Engineering Benefit |
|---|---|---|---|
| **Orchestration Layer** | TMUX (`tmux`) | Persistent pseudo-terminal multiplexing | Decouples process lifecycle from SSH connection dropouts |
| **Automation Layer** | POSIX Bash (`start-beef-lab.sh`) | Idempotent session bootstrap & configuration | Eliminates human setup error; ensures reproducible lab spin-up |
| **Runtime Environment** | Ruby 3.4.x via `rbenv` | Isolated runtime sandbox | Version-pinned gem dependency isolation without root pollution |
| **Core Framework** | BeEF (Browser Exploitation Framework) | Client-side security testing & hook broker | Modular, extensible framework for DOM & browser telemetry |
| **Persistence / Storage** | SQLite3 | Embedded datastore | Lightweight transaction logging of hooked browser sessions |
| **Diagnostic Layer** | Multi-window bash pane | Live telemetry & socket inspection | Real-time monitoring without interrupting main server stdout |

---

### 3. Execution & Data Flow Mechanics

#### A. Automated Initialization & Orchestration Flow

The execution workflow is strictly deterministic and divided into two independent planes: the **Orchestration Control Plane** (Script & Multiplexer) and the **Application Data Plane** (BeEF Server, Database, & Hook Broker).

```text
┌───────────────────────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATION CONTROL FLOW                                 │
└───────────────────────────────────────────────────────────────────────────────────┘

 [User / Admin] ───> Executes: ./start-beef-lab.sh [optional_session_name]
                                │
                                ▼
                   ┌───────────────────────────┐
                   │  Parse Session Argument   │ ───> Defaults to "beef-lab"
                   └────────────┬──────────────┘
                                │
                                ▼
                   ┌───────────────────────────┐
                   │   tmux has-session Check  │
                   └────────────┬──────────────┘
                                │
               ┌────────────────┴────────────────┐
               │                                 │
      [Session Exists]                    [Session Absent]
               │                                 │
               ▼                                 ▼
    Prints Notice & Exits (0)           ┌─────────────────────────────┐
    (Idempotent Guard)                  │ tmux new-session (Detached) │
                                        │ Window 0: "beef"            │
                                        └──────────────┬──────────────┘
                                                       │
                                                       ▼
                                        ┌─────────────────────────────┐
                                        │ Send Keys: cd ~/beef        │
                                        │ Send Keys: ./beef           │
                                        └──────────────┬──────────────┘
                                                       │
                                                       ▼
                                        ┌─────────────────────────────┐
                                        │ tmux new-window             │
                                        │ Window 1: "monitor"         │
                                        └──────────────┬──────────────┘
                                                       │
                                                       ▼
                                        ┌─────────────────────────────┐
                                        │ Send Keys: Diagnostic Probes│
                                        │ (echo banner; date; uptime) │
                                        └──────────────┬──────────────┘
                                                       │
                                                       ▼
                                        ┌─────────────────────────────┐
                                        │ Confirmation Banner Output  │
                                        │ Ready for 'tmux attach'     │
                                        └─────────────────────────────┘
```

---

#### B. Step-by-Step Execution Sequence

1. **Parameter Resolution & Shell Guard:**
   - The shell script executes with positional parameter evaluation: `SESSION="${1:-beef-lab}"`.
   - `tmux has-session -t "$SESSION"` checks the active TMUX socket server. If active, it exits cleanly without disrupting the existing process.

2. **Headless Session Initialization:**
   - `tmux new-session -d -s "$SESSION" -n beef` requests the TMUX daemon to allocate a pseudo-terminal (pty) and create the primary window labeled `beef` in background mode.

3. **Injected Process Bootstrapping:**
   - `tmux send-keys -t "$SESSION:beef" 'cd ~/beef' C-m` navigates to the application directory.
   - `tmux send-keys -t "$SESSION:beef" './beef' C-m` triggers the Ruby interpreter, initiating the Rails/Sinatra core, mounting SQLite database schemas, and binding HTTP socket `0.0.0.0:3000`.

4. **Dedicated Telemetry Plane Allocation:**
   - `tmux new-window -t "$SESSION" -n monitor` forks a secondary window within the same session.
   - System diagnostics (`date`, `uptime`, socket checks) are triggered on Window 1 to provide isolated health telemetry without polluting the BeEF server stdout.

---

#### C. Bidirectional Telemetry & Network Data Flow

Once initialized, communication between the operator, BeEF framework, and the authorized lab target browser follows a structured request-response cycle:

```text
┌───────────────────────────────────────────────────────────────────────────────────┐
│                        RUNTIME APPLICATION DATA FLOW                              │
└───────────────────────────────────────────────────────────────────────────────────┘

   Target Client                          BeEF Framework Server                     Admin Interface
 (Lab Target Browser)                     (Azure VM : Port 3000)                   (SSH / Web Browser)
         │                                          │                                       │
         │ 1. Initial Page Load (includes hook.js) │                                       │
         │─────────────────────────────────────────>│                                       │
         │                                          │                                       │
         │ 2. HTTP 200 OK (Returns JS Payload)      │                                       │
         │<─────────────────────────────────────────│                                       │
         │                                          │                                       │
         │ 3. Asynchronous Telemetry & Fingerprint  │                                       │
         │    (OS, Browser Engine, Cookies, DOM)    │                                       │
         │─────────────────────────────────────────>│                                       │
         │                                          │ 4. Transact Record                    │
         │                                          │───┐                                   │
         │                                          │   │ SQLite DB                         │
         │                                          │<──┘ Persistence                       │
         │                                          │                                       │
         │                                          │ 5. Session State Update (WebSocket)   │
         │                                          │──────────────────────────────────────>│
         │                                          │                                       │
         │ 6. Periodic Polling / Command Heartbeat  │                                       │
         │<════════════════════════════════════════>│                                       │
         │                                          │                                       │
         │                                          │ 7. Out-of-Band Diagnostic Stream      │
         │                                          │    (Window 1: TMUX Monitor)           │
         │                                          │──────────────────────────────────────>│
```

---

#### D. Protocol & Communication Channel Specifications

| Channel | Source | Destination | Protocol / Port | Data Payload |
|---|---|---|---|---|
| **Operator Access** | Admin Workstation | Azure Linux VM | SSH (TCP 22) | Encrypted shell session & TMUX control |
| **Hook Delivery** | BeEF Core Server | Lab Browser | HTTP (TCP 3000) | `hook.js` JavaScript payload |
| **Telemetry Ingestion** | Lab Browser | BeEF REST Engine | HTTP POST / JSON | Client environment info, DOM tree, events |
| **Command Polling** | Lab Browser | BeEF Hook Broker | HTTP / WebSockets | Asynchronous command queue & execution results |
| **Local Diagnostics** | TMUX Monitor Pane | Linux Kernel / OS | Unix Sockets / IPC | Process PID status, socket bindings (`ss`), uptime |

---

### 4. Comprehensive Viva Defense & Professor Q&A Matrix

#### 30-Second Elevator Pitch
> *"This project demonstrates a robust, automated browser security testing architecture. By encapsulating the modular BeEF framework inside a persistent TMUX session orchestration layer and automating it via an idempotent Bash script, we achieve high availability, session persistence across network disruptions, and isolated real-time diagnostic monitoring—all within a strictly contained and secure academic lab environment."*

---

#### Q1: Why did you introduce TMUX instead of running BeEF as a background daemon (nohup / `&`) or systemd service?
* **Core Answer:** While `nohup` or `&` can background a process, they discard interactive control and make terminal redirection clunky. A `systemd` unit is viable for static services, but TMUX provides **interactive multi-window multiplexing**.
* **Key Defense Points:**
  1. **Dual Context:** Allows running the active interactive BeEF terminal on Window 0 while maintaining an active diagnostic monitoring shell on Window 1.
  2. **Session Attachment:** The administrator can detach, disconnect from SSH, reconnect from another machine, and reattach (`tmux attach -t beef-lab`) with the exact visual state intact.
  3. **Non-destructive Logging:** Standard output and interactive BeEF console messages remain accessible without parsing log files.

---

#### Q2: Did you modify BeEF's internal core source code? How do you justify your technical contribution?
* **Core Answer:** No source code inside `core/` or `modules/` was altered, which adheres to the **Open-Closed Principle (SOLID)** and industry standard wrapper architecture.
* **Key Defense Points:**
  1. **Stability & Upstream Compatibility:** Leaving the core untouched ensures the framework can receive upstream updates without merge conflicts.
  2. **Architectural Wrapper Pattern:** The contribution is an **Operational Orchestration Layer**—integrating version isolation (rbenv), process multiplexing (TMUX), automated bootstrapping (`start-beef-lab.sh`), and diagnostic verification.

---

#### Q3: What makes your automation script (`start-beef-lab.sh`) robust and production-grade?
* **Core Answer:** The script implements **idempotency**, **parameterization**, and **defensive execution**.
* **Key Defense Points:**
  1. **Idempotency Check:** `tmux has-session -t "$SESSION" 2>/dev/null` ensures the script does not accidentally spawn duplicate conflicting sessions if run multiple times.
  2. **Parameter Defaulting:** `SESSION="${1:-beef-lab}"` allows flexible session naming for multi-lab scenarios while maintaining an intuitive default.
  3. **Deterministic Orchestration:** `tmux send-keys` sends keystrokes with carriage returns (`C-m`) to initialize each window in a predictable, non-blocking sequence.

---

#### Q4: How is security handled regarding BeEF listening on `0.0.0.0:3000`?
* **Core Answer:** While BeEF binds to `0.0.0.0` inside the Linux guest OS to accept connections from the lab subnet, **perimeter defense and defense-in-depth are enforced at the cloud network layer**.
* **Key Defense Points:**
  1. **Azure NSG Filtering:** Inbound traffic to port 3000 is strictly filtered to authorized lab IP ranges or local VPN tunnels.
  2. **Credential Rotation:** Default credentials in `config.yaml` are rotated to high-entropy secrets to prevent unauthorized web UI access.
  3. **Safe Academic Boundary:** No payloads, persistence mechanisms, or external hosts are targeted.

---

#### Q5: What happens if two BeEF sessions are launched concurrently?
* **Core Answer:** A **TCP port collision (EADDRINUSE)** occurs because the second instance attempts to bind to `0.0.0.0:3000` which is already held by the first instance.
* **Key Defense Points:**
  1. This was validated during our integration test when verifying script parameterization (`beef-lab-test`).
  2. Resolving this for multi-tenancy would require passing custom `--port` arguments or modifying `config.yaml` port bindings per session.

---

#### Q6: How does BeEF client-side hooking differ from traditional binary exploitation?
* **Core Answer:** Traditional exploits often target memory corruption (e.g., buffer overflows, ROP chains) in compiled software. In contrast, BeEF operates at the **Application & DOM layer via JavaScript execution context**.
* **Key Defense Points:**
  1. BeEF leverages authorized browser capabilities (XHR/Fetch, DOM manipulation, WebSockets) through an executed `hook.js`.
  2. It demonstrates the risk of Cross-Site Scripting (XSS) and client-side trust vulnerabilities rather than OS-level memory compromise.

---

## Phase 13 — Academic Study: Malware & Rootkit Detection

| Domain | Key Concepts | Detection & Defense Mechanisms |
|---|---|---|
| **Malware Analysis** | - Static/Dynamic Analysis<br>- Behavioral sandboxing<br>- Command & Control (C2) heuristics | - Host-based Intrusion Detection (HIDS)<br>- Signature & heuristic file hashing<br>- Egress network traffic anomaly filtering |
| **Rootkit Detection** | - Kernel vs User space hooks<br>- Syscall table modification<br>- Process / File hiding | - Kernel integrity checks (`sysdig`, `chkrootkit`, `rkhunter`)<br>- Memory dump forensics (Volatility)<br>- Secure Boot & kernel module signing enforcement |

---

## Final File System Layout

```text
/home/azureuser/
│
├── beef/                              # BeEF Project Directory
│   ├── beef                           # Main Ruby executable
│   ├── config.yaml                    # Hardened configuration
│   ├── config.yaml.backup             # Pristine backup configuration
│   ├── Gemfile                        # Gem dependency specifications
│   ├── extensions/                    # Core extension modules
│   └── modules/                       # Security analysis modules
│
└── start-beef-lab.sh                  # Lab automation & TMUX orchestration script
```

---
*Created for Academic Lab Evaluation & Documentation.*

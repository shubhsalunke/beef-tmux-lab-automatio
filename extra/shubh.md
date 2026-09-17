```
# Complete Task Structure

PHASE 1
Environment Preparation
        ↓
PHASE 2
BeEF Installation
        ↓
PHASE 3
BeEF Configuration
        ↓
PHASE 4
BeEF Verification
        ↓
PHASE 5
TMUX Installation & Study
        ↓
PHASE 6
Existing BeEF Architecture
        ↓
PHASE 7
TMUX Integration
        ↓
PHASE 8
Automation Script
        ↓
PHASE 9
Integration Testing
        ↓
PHASE 10
Safe BeEF Lab Demonstration
        ↓
PHASE 11
Architecture + Workflow Documentation
        ↓
PHASE 12
Malware / Rootkit Academic Study
```

---

 # PHASE 1 — Environment Check

 Login to your Azure VM:

```
ssh azureuser@<YOUR-VM>
```

 Check:

```
whoami
hostname
pwd
```

 Check OS:

```
cat /etc/os-release
```

 Check tools:

```
ruby --version
tmux -V
git --version
sqlite3 --version
```

 In your case, Ruby was initially old, so Ruby was upgraded.

---

 # PHASE 2 — BeEF Download

 BeEF directory:

```
cd ~
git clone https://github.com/beefproject/beef.git
cd ~/beef
```

 Check:

```
ls
```

 Important files:

```
beef
config.yaml
Gemfile
install
extensions/
modules/
core/
```

 Tell the professor:

 > "BeEF is the existing Browser Exploitation Framework architecture that I am extending with a terminal/session management layer."

---

 # PHASE 3 — Ruby Setup

 Your BeEF dependencies required a newer Ruby version.

 rbenv setup:

```
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
```

 PATH:

```
echo 'export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

 Ruby-build:

```
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
```

 Initialize:

```
eval "$(rbenv init - bash)"
```

 Check:

```
ruby-build --version
```

 Available Ruby:

```
rbenv install -l | grep -E '^3\.[3-9]\.'
```

 You installed:

```
rbenv install 3.4.10
```

 Set Ruby:

```
echo "3.4.10" > ~/beef/.ruby-version
```

 Check:

```
cd ~/beef
ruby --version
rbenv version
```

 Expected:

```
ruby 3.4.10
```

---

 # PHASE 4 — Bundler / BeEF Dependencies

 Check:

```
bundler --version
```

 Then:

```
cd ~/beef
bundle install
```

 If successfully completed:

```
Bundle complete
```

 then dependencies are ready.

---

 # PHASE 5 — BeEF Configuration

 Backup:

```
cd ~/beef
cp config.yaml config.yaml.backup
```

 Check:

```
ls -lh config.yaml*
```

 Edit:

```
nano config.yaml
```

 Change the default credentials to lab-specific non-default credentials.

 **Important:** Do not expose credentials/API keys in chat, GitHub, or the report.

 Also, do not expose BeEF to the public Internet. Your config has:

```
host: "0.0.0.0"
```

 which can listen on all interfaces.

 For the lab, it is better to keep the firewall/NSG appropriately restricted.

---

 # PHASE 6 — BeEF Start

 BeEF directory:

```
cd ~/beef
```

 Start:

```
./beef
```

 Successful output will look something like:

```
BeEF 0.6.0.0
304 modules enabled
BeEF server started
```

 Local verification:

```
ss -ltnp | grep ':3000'
```

 In your current setup, the output already showed:

```
0.0.0.0:3000
ruby
```

 So BeEF is running.

---

 # PHASE 7 — TMUX Study

 Check:

```
tmux -V
```

 TMUX concept:

```
TMUX Session
     │
     ├── Window 1
     ├── Window 2
     └── Window 3
```

 In your project:

```
beef-lab
   │
   ├── beef
   │    └── BeEF server
   │
   └── monitor
        └── Monitoring shell
```

 Create session:

```
tmux new -s beef-lab
```

 List:

```
tmux ls
```

 Detach:

```
Ctrl + B
then
D
```

 If the shortcut is difficult, from another SSH terminal:

```
tmux detach-client -s beef-lab
```

 Reattach:

```
tmux attach -t beef-lab
```

---

 # PHASE 8 — BeEF + TMUX Integration

 This is where your actual assignment implementation starts.

 Do not change the existing BeEF.

 Architecture:

```
              EXISTING BeEF
                   │
       ┌───────────┼───────────┐
       │           │           │
      Core     Extensions    Modules
                   │
                   │
              TMUX Layer
                   │
          ┌────────┴────────┐
          │                 │
        beef             monitor
          │                 │
       BeEF server       monitoring
```

 Important:

 **TMUX is not a BeEF exploitation module.**

 TMUX is a:

 > Terminal/session management layer.

---

 # PHASE 9 — TMUX Windows Create

 Session:

```
tmux new-session -d -s beef-lab -n beef
```

 BeEF directory:

```
tmux send-keys -t beef-lab:beef 'cd ~/beef' C-m
```

 Start BeEF:

```
tmux send-keys -t beef-lab:beef './beef' C-m
```

 Create monitor:

```
tmux new-window -t beef-lab -n monitor
```

 Monitor:

```
tmux send-keys -t beef-lab:monitor 'echo "=== BeEF Lab Monitor ==="; date; uptime' C-m
```

 Check:

```
tmux list-windows -t beef-lab
```

 Expected:

```
0: beef
1: monitor
```

---

 # PHASE 10 — Automation Script

 You already created this file:

```
~/start-beef-lab.sh
```

 Current version:

```
#!/bin/bash

SESSION="${1:-beef-lab}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "TMUX session '$SESSION' already exists."
    exit 0
fi

tmux new-session -d -s "$SESSION" -n beef

tmux send-keys -t "$SESSION:beef" 'cd ~/beef' C-m

tmux send-keys -t "$SESSION:beef" './beef' C-m

tmux new-window -t "$SESSION" -n monitor

tmux send-keys -t "$SESSION:monitor" \
'echo "=== BeEF Lab Monitor ==="; date; uptime' C-m

echo "BeEF lab session created."
echo "Session: $SESSION"
echo "Windows: beef, monitor"
```

 Permission:

```
chmod +x ~/start-beef-lab.sh
```

 Syntax test:

```
bash -n ~/start-beef-lab.sh
```

 No output = syntax is okay.

 Run:

```
~/start-beef-lab.sh
```

 Check:

```
tmux ls
```

---

 # PHASE 11 — Integration Testing

 ### Test 1 — Session

```
tmux ls
```

 Expected:

```
beef-lab: 2 windows
```

 ### Test 2 — Windows

```
tmux list-windows -t beef-lab
```

 Expected:

```
beef
monitor
```

 ### Test 3 — BeEF process

```
tmux display-message -p -t beef-lab:beef '#{pane_current_command}'
```

 Expected generally:

```
ruby
```

 ### Test 4 — Port

```
ss -ltnp | grep ':3000'
```

 Expected:

```
LISTEN ... :3000 ... ruby
```

 ### Test 5 — Local HTTP

 Safe local check:

```
curl -I http://127.0.0.1:3000/
```

 You should get an HTTP response.

---

 # PHASE 12 — Script Reusability Test

 Your line:

```
SESSION="${1:-beef-lab}"
```

 means:

 Normal:

```
~/start-beef-lab.sh
```

 creates:

```
beef-lab
```

 Custom:

```
~/start-beef-lab.sh my-lab
```

 creates:

```
my-lab
```

 You already tested this.

 A test session had a BeEF port conflict because the original BeEF was already using port `3000`.

 Therefore, the test session was removed:

```
tmux kill-session -t beef-lab-test
```

 This was **expected behavior**; a second BeEF instance cannot start on the same port.

---

 # PHASE 13 — Safe BeEF Demonstration

 Be careful here.

 For the demonstration, use **only your own authorized lab browser/VM**.

 You can demonstrate to the professor:

```
Browser
   ↓
Authorized Lab Page
   ↓
BeEF Hook
   ↓
BeEF Server
   ↓
BeEF UI
```

 Safe concepts:

 - BeEF UI navigation
- Module structure
- Extensions
- Browser/session information
- Request/response concepts
- Lab-only benign demonstrations

 Do not target real users, public websites, or third-party browsers.

---

 # PHASE 14 — Explain Architecture to the Professor

 You can draw this architecture:

```
                    USER / LAB ADMIN
                           │
                           ▼
                    SSH CONNECTION
                           │
                           ▼
                    TMUX SESSION
                      "beef-lab"
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
        BEEF WINDOW                MONITOR WINDOW
              │                         │
              ▼                         ▼
       ./beef process              Monitoring
              │
              ▼
       BeEF Server :3000
              │
       ┌──────┴──────┐
       │             │
       ▼             ▼
   Extensions      Modules
```

---

 # PHASE 15 — Actual Benefit

 If the professor asks:

 ### "Why did you use TMUX?"

 Say:

 > "TMUX is used as a persistent terminal and session management layer. It allows the BeEF process and monitoring shell to be maintained in separate windows within the same server-side session."

 If they ask:

 ### "What modification did you make in BeEF?"

 Say:

 > "I did not modify the core BeEF architecture. I added TMUX-based session management and a startup automation script around the existing BeEF deployment."

 If they ask:

 ### "What is the benefit of automation?"

 Say:

 > "Instead of manually creating the TMUX session, BeEF window and monitoring window every time, the Bash script creates the lab environment consistently."

---

 # PHASE 16 — Malware / Rootkit Part

 Keep this part separate:

```
BeEF
 ↓
Browser Security Study

TMUX
 ↓
Session Management

Malware
 ↓
Academic Study + Detection

Rootkit
 ↓
Academic Study + Detection
```

 There is no need to deploy actual malware/rootkits.

 The report can cover:

 - What is malware
- What is a rootkit
- Malware lifecycle
- Rootkit types
- Detection techniques
- Indicators of compromise
- Defensive monitoring
- Why persistence/stealth is dangerous

---

 # Final Project Structure

 Eventually, your VM will have:

```
/home/azureuser/
│
├── beef/
│   ├── beef
│   ├── config.yaml
│   ├── config.yaml.backup
│   ├── Gemfile
│   ├── extensions/
│   └── modules/
│
└── start-beef-lab.sh
```

 Runtime:

```
TMUX
└── beef-lab
    │
    ├── beef
    │    └── BeEF :3000
    │
    └── monitor
         └── Monitoring
```

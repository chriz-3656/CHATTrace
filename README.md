
# CHATTrace 🗨️⚡  
### Ephemeral • Session-Based • Anonymous Chat Tool

<p align="center">
  <img src="https://i.ibb.co/XHQ6Pgw/chat5.png" alt="CHATTrace Banner" width="800">
</p>

> **CHATTrace is not a service. It is a session.**  
> When the terminal closes, the chat disappears — completely.

---

## 🧠 Backstory

CHATTrace was born after multiple failed attempts to build a traditional anonymous chat service.  
Those failures revealed an important truth:

> **Long‑running services attract traceability.  
> Short‑lived tools disappear naturally.**

Instead of fighting platforms or forcing persistence, CHATTrace embraces **ephemerality** as a design principle.  
The result is a chat system that exists *only while the operator is present* — inspired by the lifecycle philosophy of tools like LENSTrace and NEXUSTrace.

---

## ✨ Core Features

- 🕒 Session‑based lifecycle (operator‑controlled)
- 🧠 Memory‑only chat (no DB, no disk storage)
- 👤 No accounts, no authentication
- 🌍 Temporary public URL
- 🧹 Clean shutdown with optional log deletion
- 🖥️ Terminal‑first tool UX
- ⚙️ Fully automated setup (no manual installs)

---

## 🔐 Anonymity Model (Honest & Clear)

CHATTrace provides **application‑layer anonymity**, not network‑layer anonymity.

### What CHATTrace DOES:
- No persistent identities
- No message history after shutdown
- No cookies / localStorage
- No database
- No background daemons
- No auto‑restart
- Operator‑controlled exposure

### What CHATTrace DOES NOT claim:
- ❌ Tor‑level anonymity
- ❌ IP address hiding
- ❌ Traffic obfuscation
- ❌ End‑to‑end encryption (yet)

> CHATTrace minimizes **data existence**, not network visibility.

---

## 🧠 Architecture Overview

```
User Browser
    ↓
Flask Web Server (Local)
    ↓
In‑Memory Chat State
    ↓
Temporary Tunnel (Session‑Scoped)
```

- **Backend**: Python (Flask)
- **Frontend**: HTML + CSS (Jinja templates)
- **Control**: Bash scripts
- **Exposure**: Temporary tunnel
- **Storage**: RAM only

---

## 📁 Project Structure

```
CHATTrace/
├── venv/                    # Auto‑created virtual environment
│
├── assets/
│   ├── ascii.txt            # ASCII banner
│   └── style.css            # UI styles
│
├── bin/
│   └── cloudflared          # Local tunnel binary
│
├── server/
│   ├── app.py               # Flask backend (memory‑only)
│   ├── logs/                # Runtime logs (optional)
│   └── templates/
│       └── index.html       # Chat UI
│
├── config.json              # Runtime configuration
├── chattrace.sh             # Main launcher (does everything)
└── cleanup.sh               # Safe cleanup script
```

---

## 🧩 Requirements

### Required
- Linux
- Python 3
- Bash
- curl
- Internet connection

### Auto‑Handled by Script
- Python virtual environment
- pip dependency installation
- Flask installation
- Tunnel setup
- Session cleanup

> You do **not** need to install pip or create a venv manually.

---

## 🚀 Installation & Usage

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/chriz-3656/CHATTrace.git
```

### 2️⃣ Enter the Directory

```bash
cd CHATTrace
```

### 3️⃣ Make Scripts Executable

```bash
chmod +x chattrace.sh cleanup.sh
```

### 4️⃣ Start CHATTrace

```bash
./chattrace.sh
```

That’s it.  
The script handles everything else.

---

## 🖥️ What Happens When You Run It

1. ASCII banner is displayed
2. System & dependency checks
3. Virtual environment is created (if missing)
4. Dependencies are installed automatically
5. Old sessions are cleaned
6. Flask server starts locally
7. Temporary public URL is generated
8. URL is printed in terminal
9. Chat exists only while the terminal is open

---

## ⛔ Stopping the Session

Press:

```text
CTRL + C
```

On shutdown:
- Server stops
- Tunnel closes
- Memory is wiped
- You are prompted to save or delete logs

No background processes remain.

---

## 🎨 Frontend Details

- Minimal HTML (Jinja template)
- Terminal‑style CSS
- No heavy frameworks
- No background workers
- No persistent browser storage

The UI is intentionally simple to avoid fingerprinting and reduce complexity.

---

## 📜 Logs

- Stored in: `server/logs/`
- Session‑scoped only
- Never persisted unless you choose to keep them

To force cleanup:

```bash
./cleanup.sh
```

---

## ⚠️ Usage Disclaimer

CHATTrace is intended for:
- Temporary chat sessions
- Demos & testing
- Educational use
- Tool‑style communication

It is **not** intended to be:
- A permanent chat service
- A public anonymous platform
- A secure messenger replacement

---

## 🧠 Design Philosophy

> **If a system must live forever, it becomes traceable.  
> If a system exists only when needed, it becomes forgettable.**

CHATTrace treats ephemerality as a **feature**, not a limitation.

---

## 👤 Author

**Chris (chriz‑3656)**  
GitHub: https://github.com/chriz-3656

---

## ⭐ Final Note

CHATTrace is a tool, not a service.  
If you run it like a tool, it behaves like one.

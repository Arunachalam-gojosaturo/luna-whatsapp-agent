<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0a0015,40:1a0a3e,70:2d1b69,100:0a0015&height=220&section=header&text=🌙%20LUNA%20AI&fontSize=72&fontColor=c084fc&fontAlignY=50&animation=fadeIn&desc=WhatsApp%20AI%20Agent%20%7C%20Powered%20by%20Groq%20%2B%20Edge%20TTS&descSize=16&descAlignY=72&descColor=9ca3af"/>

</div>

<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=600&size=15&pause=1000&color=C084FC&center=true&vCenter=true&width=780&lines=🌙+Luna+AI+is+awake+and+listening...;Connecting+to+WhatsApp+Web...+✓;Loading+Groq+LLM+Engine...+✓;Edge+TTS+Voice+Module...+✓;Telegram+Control+Bot...+✓;Ntfy+Push+Notifications...+✓;%5B+ALL+SYSTEMS+ONLINE+%5D+Luna+is+ready." alt="Typing SVG"/>

</div>

<br/>

<div align="center">

![Node.js](https://img.shields.io/badge/Node.js-whatsapp--web.js-c084fc?style=flat-square&logo=node.js&logoColor=white&labelColor=0a0015)
![Python](https://img.shields.io/badge/Python-FastAPI-c084fc?style=flat-square&logo=python&logoColor=white&labelColor=0a0015)
![Groq](https://img.shields.io/badge/LLM-Groq%20API-c084fc?style=flat-square&labelColor=0a0015)
![TTS](https://img.shields.io/badge/Voice-Edge%20TTS-a855f7?style=flat-square&labelColor=0a0015)
![PM2](https://img.shields.io/badge/Process-PM2-a855f7?style=flat-square&labelColor=0a0015)
![License](https://img.shields.io/badge/License-MIT%202026-7c3aed?style=flat-square&labelColor=0a0015)

</div>

---

## `>> WHAT IS LUNA?`

```
Luna is not a chatbot.

She is an autonomous AI agent that lives inside WhatsApp —
replying to DMs with personality, speaking in voice notes,
and controlled entirely through a Telegram bot interface.

Built from scratch. Running on Arch Linux. Powered by Groq.
```

---

## `>> CORE CAPABILITIES`

<div align="center">
<table>
<tr>
<td width="50%" valign="top">

### 🧠 Intelligence
```yaml
engine       : Groq API (LLM)
personality  : Luna AI — custom system prompt
context      : conversation memory per user
scope        : WhatsApp DMs only
group_ignore : true  # stays silent in groups
response     : text + optional voice note
```

</td>
<td width="50%" valign="top">

### 🎙️ Voice Notes
```yaml
module   : Edge TTS (Microsoft)
format   : .ogg / .opus (WhatsApp native)
trigger  : auto or on request
language : multi-language support
quality  : natural neural voice
status   : ONLINE ✓
```

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 📲 Telegram Control
```yaml
bot_commands:
  /start   → activate Luna
  /stop    → pause responses
  /status  → show runtime info
  /logs    → fetch recent logs
access     : admin-only token
transport  : Telegram Bot API
```

</td>
<td width="50%" valign="top">

### 🔔 Push Notifications
```yaml
service  : Ntfy (self-hostable)
triggers : new DM received
          agent reply sent
          error / crash alert
delivery : instant push to device
platform : Android / iOS / web
```

</td>
</tr>
</table>
</div>

---

## `>> ARCHITECTURE`

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                        LUNA AI AGENT                            │
  │                                                                  │
  │   WhatsApp DM                                                    │
  │       │                                                          │
  │       ▼                                                          │
  │  [whatsapp-web.js]  ←── QR Auth / Web Session                   │
  │       │                                                          │
  │       ▼                                                          │
  │  [Message Filter]  ── group? → IGNORE                           │
  │       │                                                          │
  │       ▼                                                          │
  │  [Groq LLM API]  ── generate Luna personality response           │
  │       │                                                          │
  │       ├──── Text Reply ──────────────────→ WhatsApp DM          │
  │       │                                                          │
  │       └──── [Edge TTS] → voice.ogg ────→ WhatsApp Voice Note    │
  │                                                                  │
  │  [Ntfy]  ←── notify on every interaction                        │
  │  [PM2]   ←── process manager / auto-restart                     │
  │  [Telegram Bot] ←── remote control from anywhere                │
  └─────────────────────────────────────────────────────────────────┘
```

---

## `>> STACK`

<div align="center">

| `MODULE` | `TECHNOLOGY` | `PURPOSE` |
|---|---|---|
| 📱 WhatsApp Bridge | `whatsapp-web.js` | WA Web automation via Puppeteer |
| 🧠 Language Model | `Groq API` | Fast LLM inference (LLaMA / Mixtral) |
| 🎙️ Voice Synthesis | `Edge TTS` | Microsoft neural text-to-speech |
| ⚡ API Server | `FastAPI (Python)` | Backend control interface |
| 🔁 Process Manager | `PM2` | Auto-restart, logs, daemon mode |
| 🤖 Remote Control | `Telegram Bot API` | Start / stop / monitor from phone |
| 🔔 Notifications | `Ntfy` | Push alerts to any device |

</div>

---

## `>> QUICK START`

```bash
# ─── 1. CLONE ──────────────────────────────────────────
git clone https://github.com/Arunachalam-gojosaturo/luna-ai
cd luna-ai

# ─── 2. INSTALL DEPENDENCIES ───────────────────────────
npm install          # Node packages (whatsapp-web.js etc.)
pip install -r requirements.txt   # Python packages (FastAPI etc.)

# ─── 3. CONFIGURE ──────────────────────────────────────
cp .env.example .env
nano .env
# Fill in:
#   GROQ_API_KEY=your_key
#   TELEGRAM_BOT_TOKEN=your_token
#   TELEGRAM_ADMIN_ID=your_id
#   NTFY_TOPIC=your_topic

# ─── 4. LAUNCH ─────────────────────────────────────────
pm2 start ecosystem.config.js    # start all services
pm2 logs luna-ai                 # watch logs

# Scan QR code in terminal → WhatsApp linked ✓
# Open Telegram → /status → Luna is ONLINE ✓
```

---

## `>> ENV CONFIGURATION`

```ini
# ── GROQ ──────────────────────────────────────────
GROQ_API_KEY       = your_groq_api_key_here
GROQ_MODEL         = llama3-70b-8192        # or mixtral-8x7b

# ── TELEGRAM CONTROL ──────────────────────────────
TELEGRAM_BOT_TOKEN = your_telegram_bot_token
TELEGRAM_ADMIN_ID  = your_telegram_user_id

# ── NOTIFICATIONS ─────────────────────────────────
NTFY_SERVER        = https://ntfy.sh         # or self-hosted
NTFY_TOPIC         = luna-ai-alerts

# ── AGENT SETTINGS ────────────────────────────────
VOICE_ENABLED      = true
DM_ONLY            = true
LUNA_NAME          = Luna
```

---

## `>> PM2 ECOSYSTEM`

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name     : "luna-ai",
      script   : "index.js",
      watch    : false,
      restart_delay : 3000,
      env: {
        NODE_ENV : "production"
      }
    },
    {
      name     : "luna-api",
      script   : "uvicorn",
      args     : "api.main:app --host 0.0.0.0 --port 8000",
      interpreter : "python3"
    }
  ]
}
```

---

## `>> TELEGRAM COMMANDS`

```
/start    →  Wake Luna, begin replying to DMs
/stop     →  Pause Luna, hold all responses
/status   →  Show uptime, message count, health
/logs     →  Fetch last 20 lines of runtime logs
```

---

## `>> UPGRADE ROADMAP`

```
v1.0  [✓]  WhatsApp DM replies with Groq LLM
v1.1  [✓]  Edge TTS voice note responses
v1.2  [✓]  Telegram bot remote control
v1.3  [✓]  Ntfy push notification on every DM
─────────────────────────────────────────────────
v2.0  [ ]  Per-user conversation memory (Redis)
v2.1  [ ]  Image understanding (vision model)
v2.2  [ ]  Schedule messages / reminders
v2.3  [ ]  Web dashboard (React UI)
v2.4  [ ]  Self-hosted Ntfy server
v3.0  [ ]  Multi-platform (Instagram DM, Telegram)
```

---

## `>> CREATOR`

<div align="center">

```
  BUILT BY   : ARUNACHALAM
  ALIAS      : gojosaturo
  BASE       : Vellore, Tamil Nadu 🇮🇳
  OS         : Arch Linux + Hyprland
  STACK      : Python · Node.js · Linux · AI · Cybersecurity
               React · TypeScript · Android GSI
  MOTIVATION : Build the things that don't exist yet.
```

[![GitHub](https://img.shields.io/badge/GITHUB-Arunachalam--gojosaturo-c084fc?style=for-the-badge&logo=github&logoColor=white&labelColor=0a0015)](https://github.com/Arunachalam-gojosaturo)
[![Instagram](https://img.shields.io/badge/INSTAGRAM-@saturogojo__ac-c084fc?style=for-the-badge&logo=instagram&logoColor=white&labelColor=0a0015)](https://instagram.com/saturogojo_ac)

</div>

---

<div align="center">

*Luna runs best at 2AM — just like her creator.*

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0a0015,40:1a0a3e,70:2d1b69,100:0a0015&height=100&section=footer&text=🌙%20Luna%20AI%20%7C%20MIT%20License%202026%20%7C%20Arunachalam&fontSize=14&fontColor=c084fc&animation=fadeIn"/>

</div>

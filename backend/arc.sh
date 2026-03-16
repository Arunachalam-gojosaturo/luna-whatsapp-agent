#!/bin/bash

# ╔═══════════════════════════════════════════════════════╗
# ║         WhatsAgent — One Click Setup & Launch         ║
# ║     Luna AI + Groq + Edge TTS + Ntfy + n8n           ║
# ╚═══════════════════════════════════════════════════════╝

set -e

# ── Colors ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Banner ────────────────────────────────────────────────
clear
echo -e "${PURPLE}"
echo "  ██╗    ██╗██╗  ██╗ █████╗ ████████╗███████╗"
echo "  ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██╔════╝"
echo "  ██║ █╗ ██║███████║███████║   ██║   ███████╗"
echo "  ██║███╗██║██╔══██║██╔══██║   ██║   ╚════██║"
echo "  ╚███╔███╔╝██║  ██║██║  ██║   ██║   ███████║"
echo "   ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝"
echo -e "${CYAN}         AI WhatsApp Agent — One Click Setup${NC}"
echo ""

# ── Check mode ────────────────────────────────────────────
MODE=${1:-"setup"}

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
info()   { echo -e "${BLUE}[→]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; }
header() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

# ═══════════════════════════════════════════════════════════
# SETUP MODE — runs once to create all files
# ═══════════════════════════════════════════════════════════
setup() {
  header "1/7 — Reading Config"

  # ── Load existing .env if present ─────────────────────
  if [ -f ~/.whatsagent.env ]; then
    source ~/.whatsagent.env
    log "Loaded saved config from ~/.whatsagent.env"
  fi

  # ── Ask for missing values ─────────────────────────────
  if [ -z "$GROQ_API_KEY" ]; then
    echo -e "${YELLOW}Enter your Groq API key (get free at console.groq.com):${NC}"
    read -r GROQ_API_KEY
  fi

  if [ -z "$NTFY_TOPIC" ]; then
    echo -e "${YELLOW}Enter your ntfy topic name (e.g. whatsagent-arun2024):${NC}"
    read -r NTFY_TOPIC
  fi

  # ── Save config ────────────────────────────────────────
  cat > ~/.whatsagent.env << EOF
GROQ_API_KEY=$GROQ_API_KEY
NTFY_TOPIC=$NTFY_TOPIC
LUNA_PATH=~/.local/share/luna-ai
EOF
  log "Config saved to ~/.whatsagent.env"

  # ═══════════════════════════════════════════════════════
  header "2/7 — Creating Project Structure"
  # ═══════════════════════════════════════════════════════
  mkdir -p ~/whatsagent/{bot,backend,audio}
  log "Folders created"

  # ── .env ──────────────────────────────────────────────
  cat > ~/whatsagent/.env << EOF
GROQ_API_KEY=$GROQ_API_KEY
NTFY_TOPIC=$NTFY_TOPIC
LUNA_PATH=~/.local/share/luna-ai
EOF
  log ".env written"

  # ═══════════════════════════════════════════════════════
  header "3/7 — Installing Python Packages"
  # ═══════════════════════════════════════════════════════

  # Find pip
  PIP=""
  for p in pip pip3 /usr/bin/pip /usr/bin/pip3; do
    if command -v $p &>/dev/null; then PIP=$p; break; fi
  done

  if [ -z "$PIP" ]; then
    error "pip not found! Install python-pip first."
    exit 1
  fi

  $PIP install -q edge-tts groq fastapi uvicorn \
               aiofiles requests python-dotenv 2>&1 | tail -3
  log "Python packages installed"

  # Find uvicorn path
  UVICORN=$(python3 -c "import uvicorn, os; print(os.path.dirname(uvicorn.__file__).replace('uvicorn','') + '../bin/uvicorn')" 2>/dev/null || which uvicorn 2>/dev/null || find ~ -name uvicorn -type f 2>/dev/null | head -1)
  if [ -z "$UVICORN" ]; then
    UVICORN=$(find ~/whatsagent -name uvicorn 2>/dev/null | head -1)
  fi
  log "uvicorn found at: $UVICORN"
  echo "UVICORN_PATH=$UVICORN" >> ~/.whatsagent.env

  # ═══════════════════════════════════════════════════════
  header "4/7 — Writing Backend Files"
  # ═══════════════════════════════════════════════════════

  # groq_ai.py
  cat > ~/whatsagent/backend/groq_ai.py << 'PYEOF'
import os
from groq import Groq
from dotenv import load_dotenv
load_dotenv(os.path.expanduser("~/whatsagent/.env"))

client = Groq(api_key=os.getenv("GROQ_API_KEY"))
SYSTEM_PROMPT = "You are Luna, a helpful WhatsApp assistant. Keep replies short, friendly, max 3 sentences."

def ask_groq(message: str) -> str:
    try:
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user",   "content": message}
            ],
            max_tokens=200
        )
        reply = response.choices[0].message.content
        print(f"[Luna AI] {reply}")
        return reply
    except Exception as e:
        return f"Sorry, AI error: {str(e)}"
PYEOF

  # ai_engine.py
  cat > ~/whatsagent/backend/ai_engine.py << 'PYEOF'
import os, sys
from dotenv import load_dotenv
load_dotenv(os.path.expanduser("~/whatsagent/.env"))

LUNA_PATH = os.path.expanduser(os.getenv("LUNA_PATH", "~/.local/share/luna-ai"))
LUNA_AVAILABLE = False
SYSTEM_PROMPT = "You are Luna, a helpful WhatsApp assistant. Keep replies short, friendly, max 3 sentences."

try:
    sys.path.insert(0, LUNA_PATH)
    from core.ai_engine import AIEngine
    from core.memory import Memory
    luna_engine  = AIEngine()
    luna_memory  = Memory()
    LUNA_AVAILABLE = True
    print("✅ Luna AI core loaded!")
except Exception as e:
    print(f"⚠️ Luna AI not loaded: {e} → Using Groq only")

from groq_ai import ask_groq

def ask_luna(message: str, sender: str):
    if not LUNA_AVAILABLE:
        return None
    try:
        context = luna_memory.get_context(sender) if hasattr(luna_memory, 'get_context') else ""
        reply = luna_engine.generate_response(message, context=context, system_prompt=SYSTEM_PROMPT)
        if hasattr(luna_memory, 'save'):
            luna_memory.save(sender, message, reply)
        print(f"[Luna AI 🌙] {reply}")
        return reply
    except Exception as e:
        print(f"[Luna AI 🌙] Failed: {e}")
        return None

def ask_ai(message: str, sender: str = "unknown") -> dict:
    luna_reply = ask_luna(message, sender)
    if luna_reply:
        return {"reply": luna_reply, "source": "Luna AI 🌙"}
    groq_reply = ask_groq(message)
    return {"reply": groq_reply, "source": "Luna AI 🌙"}
PYEOF

  # tts.py
  cat > ~/whatsagent/backend/tts.py << 'PYEOF'
import edge_tts, os

AUDIO_PATH = os.path.expanduser("~/whatsagent/audio/reply.mp3")
VOICE      = "en-US-AriaNeural"

async def text_to_speech(text: str) -> str:
    tts = edge_tts.Communicate(text, voice=VOICE)
    await tts.save(AUDIO_PATH)
    print(f"[Edge TTS 🔊] Voice saved!")
    return AUDIO_PATH
PYEOF

  # notify.py
  cat > ~/whatsagent/backend/notify.py << 'PYEOF'
import requests, os
from dotenv import load_dotenv
load_dotenv(os.path.expanduser("~/whatsagent/.env"))

NTFY_TOPIC = os.getenv("NTFY_TOPIC", "whatsagent")

def send_ntfy_alert(sender: str, message: str):
    try:
        requests.post(
            f"https://ntfy.sh/{NTFY_TOPIC}",
            data=f"From: {sender}\n\n{message[:200]}".encode("utf-8"),
            headers={"Title": "New WhatsApp Message", "Priority": "high", "Tags": "whatsapp"},
            timeout=5
        )
        print(f"[Ntfy 🔔] Alert sent!")
    except Exception as e:
        print(f"[Ntfy 🔔] Failed: {e}")
PYEOF

  # main.py
  cat > ~/whatsagent/backend/main.py << 'PYEOF'
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
import os
load_dotenv(os.path.expanduser("~/whatsagent/.env"))

from ai_engine import ask_ai
from tts import text_to_speech
from notify import send_ntfy_alert

app = FastAPI()

class Message(BaseModel):
    sender:   str
    message:  str
    pushname: str = "Unknown"

@app.get("/")
def root():
    return {"status": "✅ WhatsAgent Running", "ai": "Luna AI 🌙", "tts": "Edge TTS 🔊", "alerts": "Ntfy 🔔"}

@app.post("/process")
async def process_message(data: Message):
    print(f"\n{'='*50}")
    print(f"📨 From : {data.pushname} ({data.sender})")
    print(f"💬 Msg  : {data.message}")
    result    = ask_ai(data.message, data.sender)
    ai_reply  = result["reply"]
    ai_source = result["source"]
    audio_path = await text_to_speech(ai_reply)
    send_ntfy_alert(data.pushname, data.message)
    print(f"✅ Replied via {ai_source}")
    print(f"{'='*50}\n")
    return {"reply": ai_reply, "audio_path": audio_path, "ai_used": ai_source}
PYEOF

  log "Backend files written"

  # ═══════════════════════════════════════════════════════
  header "5/7 — Setting Up WhatsApp Bot"
  # ═══════════════════════════════════════════════════════

  cd ~/whatsagent/bot
  npm init -y > /dev/null 2>&1
  npm install --save whatsapp-web.js qrcode-terminal axios > /dev/null 2>&1

  cat > ~/whatsagent/bot/index.js << 'JSEOF'
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const axios  = require('axios');
const path   = require('path');

const BACKEND_URL = 'http://localhost:8000/process';
const AUDIO_PATH  = path.join(__dirname, '../audio/reply.mp3');

const client = new Client({
    authStrategy: new LocalAuth(),
    puppeteer: { headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox'] }
});

client.on('qr', (qr) => {
    console.log('\n[Luna] Scan this QR code with WhatsApp:\n');
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log('\n✅ Luna WhatsApp Bot Ready!\n');
});

client.on('message', async (msg) => {
    if (msg.isGroupMsg) return;
    if (msg.from === 'status@broadcast') return;
    const payload = { sender: msg.from, message: msg.body, pushname: msg.notifyName || 'Unknown' };
    console.log(`\n📨 ${payload.pushname}: ${payload.message}`);
    try {
        const res = await axios.post(BACKEND_URL, payload);
        const reply = res.data.reply;
        await msg.reply(reply);
        console.log('✅ Text reply sent');
        try {
            const media = MessageMedia.fromFilePath(AUDIO_PATH);
            await client.sendMessage(msg.from, media, { sendAudioAsVoice: true });
            console.log('✅ Voice note sent');
        } catch (e) {
            console.log('⚠️ Voice note skipped:', e.message);
        }
    } catch (err) {
        console.error('❌ Error:', err.message);
        await msg.reply("Sorry, having trouble. Try again!");
    }
});

client.initialize();
JSEOF

  log "WhatsApp bot files written"
  cd ~

  # ═══════════════════════════════════════════════════════
  header "6/7 — Installing PM2"
  # ═══════════════════════════════════════════════════════

  if ! command -v pm2 &>/dev/null; then
    npm install -g pm2 > /dev/null 2>&1
    log "PM2 installed"
  else
    log "PM2 already installed"
  fi

  # ═══════════════════════════════════════════════════════
  header "7/7 — Creating Launch Script"
  # ═══════════════════════════════════════════════════════

  # Save uvicorn path to env
  source ~/.whatsagent.env

  cat > ~/whatsagent/launch.sh << LAUNCHEOF
#!/bin/bash
source ~/.whatsagent.env

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; PURPLE='\033[0;35m'; NC='\033[0m'

clear
echo -e "\${PURPLE}"
echo "  ██╗    ██╗██╗  ██╗ █████╗ ████████╗███████╗"
echo "  ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██╔════╝"
echo "  ██║ █╗ ██║███████║███████║   ██║   ███████╗"
echo "  ██║███╗██║██╔══██║██╔══██║   ██║   ╚════██║"
echo "  ╚███╔███╔╝██║  ██║██║  ██║   ██║   ███████║"
echo "   ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝"
echo -e "\${CYAN}              Starting Luna AI Agent...${NC}"
echo ""

# Stop any old processes
pm2 delete all 2>/dev/null || true
sleep 1

# Start backend
echo -e "\${GREEN}▶ Starting Luna AI backend...${NC}"
pm2 start "\$UVICORN_PATH main:app --host 0.0.0.0 --port 8000" \\
    --name "luna-backend" \\
    --cwd ~/whatsagent/backend \\
    --max-memory-restart 200M 2>/dev/null
sleep 3

# Test backend
if curl -s http://localhost:8000/ > /dev/null 2>&1; then
    echo -e "\${GREEN}✅ Backend online → http://localhost:8000${NC}"
else
    echo -e "\${RED}❌ Backend failed — check: pm2 logs luna-backend${NC}"
fi

# Start WhatsApp bot
echo -e "\${GREEN}▶ Starting WhatsApp bot...${NC}"
pm2 start ~/whatsagent/bot/index.js \\
    --name "luna-bot" \\
    --max-memory-restart 300M 2>/dev/null
sleep 2

echo ""
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\${GREEN}✅ Luna AI Agent is running!${NC}"
echo ""
echo -e "  📱 Scan QR code with WhatsApp:"
echo -e "     \${CYAN}pm2 logs luna-bot${NC}"
echo ""
echo -e "  📊 Monitor all services:"
echo -e "     \${CYAN}pm2 status${NC}"
echo ""
echo -e "  📋 View live logs:"
echo -e "     \${CYAN}pm2 logs --lines 20${NC}"
echo ""
echo -e "  🔴 Stop everything:"
echo -e "     \${CYAN}pm2 stop all${NC}"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Show QR code
pm2 logs luna-bot --lines 40 --nostream
LAUNCHEOF

  chmod +x ~/whatsagent/launch.sh
  log "Launch script created at ~/whatsagent/launch.sh"

  # ── Final summary ──────────────────────────────────────
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}🎉 Setup Complete!${NC}"
  echo ""
  echo -e "  ${YELLOW}To start Luna AI Agent, run:${NC}"
  echo -e "  ${CYAN}bash ~/whatsagent/launch.sh${NC}"
  echo ""
  echo -e "  ${YELLOW}Or add this alias to ~/.bashrc / ~/.config/fish/config.fish:${NC}"
  echo -e "  ${CYAN}alias luna='bash ~/whatsagent/launch.sh'${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ═══════════════════════════════════════════════════════════
# LAUNCH MODE — just start services
# ═══════════════════════════════════════════════════════════
launch() {
  bash ~/whatsagent/launch.sh
}

# ── Run based on argument ──────────────────────────────────
case "$MODE" in
  setup)   setup ;;
  launch)  launch ;;
  *)       setup ;;
esac

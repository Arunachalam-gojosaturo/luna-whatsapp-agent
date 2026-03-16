#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║         Luna AI — One Click Railway Deploy                   ║
# ║         Creates all files + pushes to GitHub                 ║
# ║         Built by Arunachalam                                 ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "  ██╗     ██╗   ██╗███╗   ██╗ █████╗ "
echo "  ██║     ██║   ██║████╗  ██║██╔══██╗"
echo "  ██║     ██║   ██║██╔██╗ ██║███████║"
echo "  ██║     ██║   ██║██║╚██╗██║██╔══██║"
echo "  ███████╗╚██████╔╝██║ ╚████║██║  ██║"
echo "  ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝"
echo -e "${GREEN}     Luna AI — Railway Deploy Script${NC}"
echo -e "${YELLOW}     Built by Arunachalam${NC}"
echo ""

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
info()   { echo -e "${CYAN}[→]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
header() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

cd ~/whatsagent

# ═══════════════════════════════════════════════════════════════
header "1/7 — Creating Dockerfile for Backend"
# ═══════════════════════════════════════════════════════════════

cat > Dockerfile.backend << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
log "Dockerfile.backend created"

# ═══════════════════════════════════════════════════════════════
header "2/7 — Creating Dockerfile for WhatsApp Bot"
# ═══════════════════════════════════════════════════════════════

cat > Dockerfile.bot << 'EOF'
FROM node:20-slim

RUN apt-get update && apt-get install -y \
    chromium \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgdk-pixbuf2.0-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    wget \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app
COPY bot/package*.json ./
RUN npm install
COPY bot/ .

EXPOSE 3000
CMD ["node", "index.js"]
EOF
log "Dockerfile.bot created"

# ═══════════════════════════════════════════════════════════════
header "3/7 — Creating Dockerfile for Telegram Bot"
# ═══════════════════════════════════════════════════════════════

cat > Dockerfile.telegram << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/telegram_control.py .
COPY backend/groq_ai.py .
COPY backend/notify.py .
CMD ["python3", "telegram_control.py"]
EOF
log "Dockerfile.telegram created"

# ═══════════════════════════════════════════════════════════════
header "4/7 — Creating backend/requirements.txt"
# ═══════════════════════════════════════════════════════════════

cat > backend/requirements.txt << 'EOF'
fastapi==0.115.0
uvicorn==0.30.6
groq==0.11.0
edge-tts==6.1.12
requests==2.32.3
python-dotenv==1.0.1
aiofiles==24.1.0
python-telegram-bot==22.6
EOF
log "requirements.txt created"

# ═══════════════════════════════════════════════════════════════
header "5/7 — Updating bot/index.js for Railway"
# ═══════════════════════════════════════════════════════════════

cat > bot/index.js << 'EOF'
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const axios  = require('axios');
const path   = require('path');
const fs     = require('fs');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8000/process';
const AUDIO_PATH  = path.join('/tmp', 'reply.mp3');

const client = new Client({
    authStrategy: new LocalAuth({ dataPath: '/tmp/.wwebjs_auth' }),
    puppeteer: {
        headless: true,
        executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium',
        protocolTimeout: 120000,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu'
        ]
    }
});

client.on('qr', (qr) => {
    console.log('\n[Luna] QR Code — scan with WhatsApp:\n');
    qrcode.generate(qr, { small: true });
    // Save QR so backend can serve it
    try { fs.writeFileSync('/tmp/qr.txt', qr); } catch(e) {}
});

client.on('ready', () => {
    console.log('\n✅ Luna WhatsApp Bot Ready!\n');
    try { fs.unlinkSync('/tmp/qr.txt'); } catch(e) {}
});

client.on('disconnected', (reason) => {
    console.log('[Luna] Disconnected:', reason);
    setTimeout(() => client.initialize(), 5000);
});

client.on('message', async (msg) => {
    if (msg.isGroupMsg) return;
    if (msg.from === 'status@broadcast') return;
    if (!msg.body || msg.body.trim() === '') return;

    const payload = {
        sender:   msg.from,
        message:  msg.body,
        pushname: msg.notifyName || 'Unknown'
    };

    console.log(`\n📨 ${payload.pushname}: ${payload.message}`);

    try {
        const res = await axios.post(BACKEND_URL, payload, { timeout: 30000 });

        if (!res.data.active || !res.data.reply) {
            console.log('[Luna] Agent stopped — not replying');
            return;
        }

        await msg.reply(res.data.reply);
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
    }
});

client.initialize();
EOF
log "bot/index.js updated for Railway"

# ═══════════════════════════════════════════════════════════════
header "6/7 — Updating backend/main.py with QR endpoint"
# ═══════════════════════════════════════════════════════════════

cat > backend/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from dotenv import load_dotenv
import os, json
load_dotenv()

from ai_engine import ask_ai
from tts import text_to_speech
from notify import send_ntfy_alert

app = FastAPI(title="Luna AI Backend", description="Built by Arunachalam")
STATE_FILE = "/tmp/state.json"

def get_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except:
        return {"active": True}

def set_state(active: bool):
    with open(STATE_FILE, "w") as f:
        json.dump({"active": active}, f)

class Message(BaseModel):
    sender:   str
    message:  str
    pushname: str = "Unknown"

@app.get("/")
def root():
    state = get_state()
    return {
        "name":    "Luna AI",
        "status":  "running",
        "active":  state["active"],
        "creator": "Arunachalam",
        "version": "1.0.0"
    }

@app.get("/status")
def status():
    return get_state()

@app.post("/start")
def start_agent():
    set_state(True)
    return {"status": "Luna is now active", "active": True}

@app.post("/stop")
def stop_agent():
    set_state(False)
    return {"status": "Luna is now stopped", "active": False}

@app.get("/qr", response_class=HTMLResponse)
def get_qr():
    try:
        with open("/tmp/qr.txt") as f:
            qr_data = f.read().strip()
        return f"""
        <html>
        <head><title>Luna AI — Scan QR</title></head>
        <body style='background:#111;color:#0f0;font-family:monospace;padding:20px'>
        <h2 style='color:#0ff'>Luna AI — WhatsApp QR Code</h2>
        <p>Scan with WhatsApp → Linked Devices</p>
        <div id='qr'></div>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js'></script>
        <script>
        new QRCode(document.getElementById('qr'), {{
            text: "{qr_data}",
            width: 300, height: 300,
            colorDark: "#000000", colorLight: "#ffffff"
        }});
        </script>
        <p style='color:#888'>Refresh this page if QR expired</p>
        </body></html>
        """
    except:
        return "<html><body style='background:#111;color:#f00;padding:20px'><h2>No QR available</h2><p>Bot is already connected or still starting...</p></body></html>"

@app.post("/process")
async def process_message(data: Message):
    if not get_state()["active"]:
        print(f"[Luna] Stopped — ignoring {data.pushname}")
        return {"reply": None, "active": False}

    print(f"\n{'='*50}")
    print(f"From : {data.pushname} ({data.sender})")
    print(f"Msg  : {data.message}")

    result    = ask_ai(data.message, data.sender)
    ai_reply  = result["reply"]
    ai_source = result["source"]
    audio_path = await text_to_speech(ai_reply)
    send_ntfy_alert(data.pushname, data.message)

    print(f"Replied via {ai_source}")
    print(f"{'='*50}\n")

    return {"reply": ai_reply, "audio_path": audio_path, "ai_used": ai_source, "active": True}
EOF
log "main.py updated with /qr endpoint"

# ═══════════════════════════════════════════════════════════════
header "7/7 — Creating Railway config files"
# ═══════════════════════════════════════════════════════════════

# railway.json for backend
cat > railway.json << 'EOF'
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile.backend"
  },
  "deploy": {
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
EOF

# .railwayignore
cat > .railwayignore << 'EOF'
.wwebjs_auth/
.wwebjs_cache/
audio/
node_modules/
__pycache__/
*.pyc
venv/
*.log
state.json
.env
EOF

log "Railway config files created"

# ── Push to GitHub ────────────────────────────────────────
echo ""
info "Pushing all changes to GitHub..."
git add .
git commit -m "feat: Railway deployment — Luna AI by Arunachalam

- Dockerfile.backend  (FastAPI)
- Dockerfile.bot      (WhatsApp + Chromium)
- Dockerfile.telegram (Telegram control)
- /qr endpoint to scan QR from browser
- BACKEND_URL env support
- /tmp paths for Railway filesystem"

git push
log "Pushed to GitHub!"

# ── Done — Print Railway Instructions ────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ All files created and pushed to GitHub!${NC}"
echo ""
echo -e "${YELLOW}Now follow these steps on Railway:${NC}"
echo ""
echo -e "${CYAN}1. Go to https://railway.app/new${NC}"
echo ""
echo -e "   SERVICE 1 — Backend (deploy first):"
echo -e "   • Deploy from GitHub → luna-whatsapp-agent"
echo -e "   • Settings → Dockerfile: ${YELLOW}Dockerfile.backend${NC}"
echo -e "   • Add variables:"
echo -e "     ${GREEN}GROQ_API_KEY${NC}       = your_groq_key"
echo -e "     ${GREEN}NTFY_TOPIC${NC}         = your_ntfy_topic"
echo -e "     ${GREEN}TELEGRAM_BOT_TOKEN${NC} = your_telegram_token"
echo -e "     ${GREEN}TELEGRAM_CHAT_ID${NC}   = your_chat_id"
echo ""
echo -e "   SERVICE 2 — WhatsApp Bot:"
echo -e "   • Same repo"
echo -e "   • Dockerfile: ${YELLOW}Dockerfile.bot${NC}"
echo -e "   • Add variable:"
echo -e "     ${GREEN}BACKEND_URL${NC} = https://your-backend.railway.app/process"
echo -e "   • Add Volume: Mount at ${YELLOW}/tmp/.wwebjs_auth${NC}"
echo ""
echo -e "   SERVICE 3 — Telegram Bot:"
echo -e "   • Same repo"
echo -e "   • Dockerfile: ${YELLOW}Dockerfile.telegram${NC}"
echo -e "   • Same variables as backend"
echo ""
echo -e "${CYAN}2. After deploy — get QR code:${NC}"
echo -e "   Open: ${YELLOW}https://your-backend.railway.app/qr${NC}"
echo -e "   Scan the QR with WhatsApp!"
echo ""
echo -e "${CYAN}3. Test Telegram bot:${NC}"
echo -e "   Send ${YELLOW}/status${NC} to your bot"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Your repo: https://github.com/Arunachalam-gojosaturo/luna-whatsapp-agent${NC}"
echo ""

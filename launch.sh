#!/bin/bash
source ~/.whatsagent.env

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; PURPLE='\033[0;35m'; NC='\033[0m'

clear
echo -e "${PURPLE}"
echo "  ██╗    ██╗██╗  ██╗ █████╗ ████████╗███████╗"
echo "  ██║    ██║██║  ██║██╔══██╗╚══██╔══╝██╔════╝"
echo "  ██║ █╗ ██║███████║███████║   ██║   ███████╗"
echo "  ██║███╗██║██╔══██║██╔══██║   ██║   ╚════██║"
echo "  ╚███╔███╔╝██║  ██║██║  ██║   ██║   ███████║"
echo "   ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝"
echo -e "${CYAN}              Starting Luna AI Agent...\033[0m"
echo ""

# Stop any old processes
pm2 delete all 2>/dev/null || true
sleep 1

# Start backend
echo -e "${GREEN}▶ Starting Luna AI backend...\033[0m"
pm2 start "$UVICORN_PATH main:app --host 0.0.0.0 --port 8000" \
    --name "luna-backend" \
    --cwd ~/whatsagent/backend \
    --max-memory-restart 200M 2>/dev/null
sleep 3

# Test backend
if curl -s http://localhost:8000/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend online → http://localhost:8000\033[0m"
else
    echo -e "${RED}❌ Backend failed — check: pm2 logs luna-backend\033[0m"
fi

# Start WhatsApp bot
echo -e "${GREEN}▶ Starting WhatsApp bot...\033[0m"
pm2 start ~/whatsagent/bot/index.js \
    --name "luna-bot" \
    --max-memory-restart 300M 2>/dev/null
sleep 2

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${GREEN}✅ Luna AI Agent is running!\033[0m"
echo ""
echo -e "  📱 Scan QR code with WhatsApp:"
echo -e "     ${CYAN}pm2 logs luna-bot\033[0m"
echo ""
echo -e "  📊 Monitor all services:"
echo -e "     ${CYAN}pm2 status\033[0m"
echo ""
echo -e "  📋 View live logs:"
echo -e "     ${CYAN}pm2 logs --lines 20\033[0m"
echo ""
echo -e "  🔴 Stop everything:"
echo -e "     ${CYAN}pm2 stop all\033[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Show QR code
pm2 logs luna-bot --lines 40 --nostream

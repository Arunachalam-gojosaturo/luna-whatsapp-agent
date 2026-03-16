"""
Luna AI — Telegram Control Bot
Commands:
  /start   - Start the WhatsApp AI agent
  /stop    - Stop the WhatsApp AI agent
  /status  - Check if agent is running
  /qr      - Get WhatsApp QR code instructions
  /logs    - Show last 10 log lines
  /restart - Restart everything
  /help    - Show all commands
"""

import os, requests, subprocess
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
from dotenv import load_dotenv
load_dotenv(os.path.expanduser("~/whatsagent/.env"))

TELEGRAM_TOKEN   = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")
BACKEND_URL      = "http://localhost:8000"

def is_authorized(update: Update) -> bool:
    return str(update.effective_chat.id) == str(TELEGRAM_CHAT_ID)

async def start(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if not is_authorized(update):
        await update.message.reply_text("Unauthorized.")
        return
    try:
        requests.post(f"{BACKEND_URL}/start", timeout=5)
        await update.message.reply_text(
            "Luna AI Agent Started!\n\n"
            "Luna is now active and will reply to WhatsApp DMs.\n\n"
            "Creator: Arunachalam — Linux Dev & AI Experimenter"
        )
    except Exception as e:
        await update.message.reply_text(f"Failed to start: {e}")

async def stop(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if not is_authorized(update):
        await update.message.reply_text("Unauthorized.")
        return
    try:
        requests.post(f"{BACKEND_URL}/stop", timeout=5)
        await update.message.reply_text(
            "Luna AI Agent Stopped!\n\n"
            "Luna will no longer reply to WhatsApp messages.\n"
            "Send /start to activate again."
        )
    except Exception as e:
        await update.message.reply_text(f"Failed to stop: {e}")

async def status(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if not is_authorized(update):
        return
    try:
        r = requests.get(f"{BACKEND_URL}/status", timeout=5)
        state = r.json()
        active = state.get("active", False)
        emoji = "Active - replying to messages" if active else "Stopped - not replying"
        await update.message.reply_text(
            f"Luna AI Status\n\n"
            f"Status: {emoji}\n"
            f"Backend: Online\n"
            f"Creator: Arunachalam"
        )
    except Exception as e:
        await update.message.reply_text(f"Backend offline: {e}")

async def qr(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if not is_authorized(update):
        return
    await update.message.reply_text(
        "Get WhatsApp QR Code\n\n"
        "Run this on your PC:\n"
        "pm2 logs luna-bot --lines 50\n\n"
        "The QR code will appear in the terminal.\n"
        "Scan it with WhatsApp -> Linked Devices"
    )

async def logs(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if not is_authorized(update):
        return
    try:
        result = subprocess.run(
            ["pm2", "logs", "--nostream", "--lines", "10"],
            capture_output=True, text=True, timeout=10
        )
        log_text = result.stdout[-3000:] if result.stdout else "No logs found"
        await update.message.reply_text(f"Recent Logs:\n\n{log_text}")
    except Exception as e:
        await update.message.reply_text(f"Error getting logs: {e}")

async def restart(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if not is_authorized(update):
        return
    await update.message.reply_text("Restarting Luna AI Agent...")
    try:
        subprocess.run(["pm2", "restart", "all"], timeout=15)
        await update.message.reply_text("Restarted! Luna is coming back online...")
    except Exception as e:
        await update.message.reply_text(f"Restart failed: {e}")

async def help_cmd(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if not is_authorized(update):
        return
    await update.message.reply_text(
        "Luna AI — Telegram Control\n\n"
        "Commands:\n"
        "/start — Start WhatsApp AI agent\n"
        "/stop — Stop WhatsApp AI agent\n"
        "/status — Check agent status\n"
        "/qr — How to get QR code\n"
        "/logs — View recent logs\n"
        "/restart — Restart all services\n"
        "/help — Show this message\n\n"
        "Built by Arunachalam\n"
        "Linux Dev | AI Experimenter | Arch Linux"
    )

def main():
    if not TELEGRAM_TOKEN:
        print("TELEGRAM_BOT_TOKEN not set in .env!")
        return

    print("Luna Telegram Control Bot starting...")
    app = Application.builder().token(TELEGRAM_TOKEN).build()

    app.add_handler(CommandHandler("start",   start))
    app.add_handler(CommandHandler("stop",    stop))
    app.add_handler(CommandHandler("status",  status))
    app.add_handler(CommandHandler("qr",      qr))
    app.add_handler(CommandHandler("logs",    logs))
    app.add_handler(CommandHandler("restart", restart))
    app.add_handler(CommandHandler("help",    help_cmd))

    print("Telegram bot ready! Send /help to your bot.")
    app.run_polling()

if __name__ == "__main__":
    main()

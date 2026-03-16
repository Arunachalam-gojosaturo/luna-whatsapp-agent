from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from dotenv import load_dotenv
import os, json
load_dotenv()

from ai_engine import ask_ai
from tts import text_to_speech
from notify import send_ntfy_alert

app = FastAPI(title="Luna AI", description="Built by Arunachalam")
STATE_FILE = "/tmp/state.json"

def get_state():
    try:
        with open(STATE_FILE) as f: return json.load(f)
    except: return {"active": True}

def set_state(active: bool):
    with open(STATE_FILE, "w") as f: json.dump({"active": active}, f)

class Message(BaseModel):
    sender: str
    message: str
    pushname: str = "Unknown"

@app.get("/")
def root():
    return {"name": "Luna AI", "status": "running", "active": get_state()["active"], "creator": "Arunachalam"}

@app.get("/status")
def status(): return get_state()

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
        with open("/tmp/qr.txt") as f: qr_data = f.read().strip()
        return f"""<html><head><title>Luna AI QR</title></head>
        <body style='background:#111;color:#0f0;font-family:monospace;padding:20px;text-align:center'>
        <h2 style='color:#0ff'>Luna AI — Scan QR Code</h2>
        <p>Open WhatsApp → Linked Devices → Link a Device</p>
        <div id='qr' style='margin:20px auto;display:inline-block'></div>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js'></script>
        <script>new QRCode(document.getElementById('qr'),{{text:"{qr_data}",width:280,height:280}});</script>
        <p style='color:#555'>Refresh if expired</p></body></html>"""
    except:
        return "<html><body style='background:#111;color:#f00;padding:20px'><h2>Bot already connected or still starting</h2></body></html>"

@app.post("/process")
async def process_message(data: Message):
    if not get_state()["active"]:
        return {"reply": None, "active": False}
    print(f"\n{'='*40}\nFrom: {data.pushname}\nMsg: {data.message}")
    result = ask_ai(data.message, data.sender)
    ai_reply = result["reply"]
    audio_path = await text_to_speech(ai_reply)
    send_ntfy_alert(data.pushname, data.message)
    print(f"Replied via {result['source']}\n{'='*40}")
    return {"reply": ai_reply, "audio_path": audio_path, "ai_used": result["source"], "active": True}

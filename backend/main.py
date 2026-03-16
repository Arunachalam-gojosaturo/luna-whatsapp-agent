from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
import os, json
load_dotenv(os.path.expanduser("~/whatsagent/.env"))

from ai_engine import ask_ai
from tts import text_to_speech
from notify import send_ntfy_alert

app = FastAPI()
STATE_FILE = os.path.expanduser("~/whatsagent/state.json")

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
        "status": "Luna AI Agent Running",
        "active": state["active"],
        "ai":     "Luna AI",
        "tts":    "Edge TTS",
        "creator": "Arunachalam"
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

@app.post("/process")
async def process_message(data: Message):
    if not get_state()["active"]:
        print(f"[Luna] Agent stopped — ignoring message from {data.pushname}")
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

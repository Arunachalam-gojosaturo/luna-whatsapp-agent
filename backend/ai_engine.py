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

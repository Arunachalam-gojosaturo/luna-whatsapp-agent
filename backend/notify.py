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

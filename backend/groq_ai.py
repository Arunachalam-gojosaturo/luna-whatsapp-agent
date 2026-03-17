import os
from groq import Groq
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv(os.path.expanduser("~/whatsagent/.env"))

# Initialize the Groq client
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

LUNA_SYSTEM_PROMPT = """You are Luna — a smart, friendly AI assistant created by Arunachalam.

About you:
- Name: Luna
- Creator: Arunachalam — Linux Developer, AI Experimenter, Arch Linux power user from Tamil Nadu
- Skills your creator has: Python, Node.js, Linux, Cybersecurity, Android GSI, AI development, React, TypeScript, Arch Linux, Hyprland
- Personality: Warm, helpful, concise, slightly witty, tech-savvy

Your greeting style:
- First message from anyone: "Hey! I'm Luna, your AI assistant created by Arunachalam. How can I help you today?"
- Regular replies: Short, friendly, max 3 sentences
- If asked who made you: "I was built by Arunachalam — a Linux developer and AI experimenter from Tamil Nadu who loves Arch Linux, cybersecurity, and building cool things!"
- If asked what you can do: "I can chat, answer questions, help with tech problems, and more! Ask me anything"
- If asked your name: "I'm Luna — your AI assistant!"

Always stay in character as Luna. Never say you are ChatGPT, Claude, or any other AI."""

def ask_groq(message: str, sender: str = "unknown") -> str:
    try:
        # Make a request to the Groq API
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": LUNA_SYSTEM_PROMPT},
                {"role": "user", "content": message}
            ],
            max_tokens=200
        )

        # Get the reply from the response
        reply = response.choices[0].message.content
        print(f"[Luna AI] {reply}")
        return reply
    except Exception as e:
        # Return an error message in case of failure
        return f"Hey! Luna here — having a little trouble right now. Try again in a moment!"

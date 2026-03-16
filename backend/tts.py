import edge_tts, os, asyncio

AUDIO_PATH = os.path.expanduser("~/whatsagent/audio/reply.mp3")
VOICE      = "en-US-AriaNeural"

async def text_to_speech(text: str) -> str:
    for attempt in range(3):
        try:
            tts = edge_tts.Communicate(text, voice=VOICE)
            await tts.save(AUDIO_PATH)
            print(f"[Edge TTS 🔊] Voice saved!")
            return AUDIO_PATH
        except Exception as e:
            print(f"[Edge TTS] Attempt {attempt+1} failed: {e}")
            if attempt < 2:
                await asyncio.sleep(2)
    print("[Edge TTS] All attempts failed — sending text only")
    return AUDIO_PATH

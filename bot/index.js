const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const axios  = require('axios');
const path   = require('path');

const BACKEND_URL = 'http://localhost:8000/process';
const AUDIO_PATH  = path.join(__dirname, '../audio/reply.mp3');

const client = new Client({
    authStrategy: new LocalAuth(),
    puppeteer: {
        headless: true,
        protocolTimeout: 120000,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--single-process',
            '--disable-gpu'
        ]
    }
});

client.on('qr', (qr) => {
    console.log('\n[Luna] Scan this QR code with WhatsApp:\n');
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log('\n✅ Luna WhatsApp Bot Ready!\n');
});

client.on('disconnected', (reason) => {
    console.log('[Luna] Disconnected:', reason);
    setTimeout(() => client.initialize(), 5000);
});

client.on('message', async (msg) => {
    // Only reply to DMs
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

        // Agent is stopped — don't reply
        if (!res.data.active || !res.data.reply) {
            console.log('[Luna] Agent is stopped — not replying');
            return;
        }

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
    }
});

client.initialize();

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

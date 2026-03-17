module.exports = {
  apps: [
    {
      name: 'luna-bot',
      script: './bot/index.js',
      cwd: process.env.HOME + '/whatsagent',
      env_file: '.env',
      restart_delay: 5000,
      max_restarts: 10,
      watch: false,
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      out_file: './logs/bot.log',
      error_file: './logs/bot-error.log',
    },
    {
      name: 'luna-telegram',
      script: './backend/telegram_control.py',
      cwd: process.env.HOME + '/whatsagent',
      interpreter: './venv/bin/python3',
      env_file: '.env',
      restart_delay: 5000,
      max_restarts: 10,
      watch: false,
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      out_file: './logs/telegram.log',
      error_file: './logs/telegram-error.log',
    },
  ],
};

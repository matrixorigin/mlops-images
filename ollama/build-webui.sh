#!/bin/bash

# Clone Open WebUI
git clone https://github.com/open-webui/open-webui.git /open-webui
cd /open-webui

# Copy required .env file
cp -RPp .env.example .env

# Build Frontend
npm install
npm run build

# Set up backend
cd ./backend
pip install -r requirements.txt -U

# Make start script executable
chmod +x start.sh

# Create a script to start Ollama and Open WebUI
cat << EOF > /usr/local/bin/start_services.sh
#!/bin/bash
/usr/local/bin/ollama serve &
cd /open-webui/backend && ./start.sh
EOF

chmod +x /usr/local/bin/start_services.sh
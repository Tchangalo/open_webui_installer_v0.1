#/bin/bash

# Uninstall Docker
sudo apt-get update -y
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
sudo apt-get autoremove -y || true
sudo rm -rf /var/lib/docker /var/lib/containerd || true
sudo rm -f /usr/local/bin/docker-compose /usr/bin/docker-compose || true

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg lsb-release

# Install Docker
CHANNEL=stable
curl -fsSL https://get.docker.com -o get-docker.sh
sudo CHANNEL=$CHANNEL sh get-docker.sh
rm get-docker.sh

# Enable/start Docker
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker <username>

# Install Docker Compose
sudo rm -f /usr/local/bin/docker-compose
LATEST_URL=$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/docker/compose/releases/latest)
LATEST_TAG=${LATEST_URL##*/}
DOWNLOAD_URL="https://github.com/docker/compose/releases/download/${LATEST_TAG}/docker-compose-$(uname -s)-$(uname -m)"
curl -fSL "${DOWNLOAD_URL}" -o /tmp/docker-compose.$$
sudo mv /tmp/docker-compose.$$ /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo /usr/local/bin/docker-compose version

# Fix for Portainer on Docker 29
sudo mkdir -p /etc/systemd/system/docker.service.d
TMP=$(mktemp)
cat > "${TMP}" <<'EOF'
[Service]
Environment=DOCKER_MIN_API_VERSION=1.24
EOF
sudo mv "${TMP}" /etc/systemd/system/docker.service.d/override.conf
sudo chmod 644 /etc/systemd/system/docker.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart docker

# Set up Portainer
sudo docker rm -f portainer || true
docker volume rm 'portainer_data' || true
sudo docker volume create portainer_data >/dev/null
sudo docker run -d -p 8000:8000 -p 9000:9000 --name "portainer" --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v "portainer_data:/data" "portainer/portainer-ce"

# Set up Open WebUI
sudo docker rm -f open-webui || true
docker volume rm 'ollama' || true
docker volume rm 'open-webui' || true
sudo docker volume create ollama >/dev/null || true
sudo docker volume create open-webui >/dev/null || true
sudo docker run -d -p 3000:8080 -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama

# Reboot
sudo reboot


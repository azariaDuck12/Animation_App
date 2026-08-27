#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.47.0"
FLUTTER_DIR="/opt/flutter"

apt-get update
apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa

if [ ! -d "${FLUTTER_DIR}" ]; then
  curl -L \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz

  mkdir -p /opt
  tar -xf /tmp/flutter.tar.xz -C /opt
  rm /tmp/flutter.tar.xz
fi

chown -R vscode:vscode "${FLUTTER_DIR}"

cat > /etc/profile.d/flutter.sh <<'EOF'
export PATH="/opt/flutter/bin:$PATH"
EOF

chmod 644 /etc/profile.d/flutter.sh

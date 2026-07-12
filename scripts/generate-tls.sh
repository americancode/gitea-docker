#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${ROOT_DIR}/config"
CERT_FILE="${CONFIG_DIR}/server.crt"
KEY_FILE="${CONFIG_DIR}/server.key"
HOSTNAME="gitea.127.0.0.1.nip.io"

mkdir -p "${CONFIG_DIR}"
if [[ -s "${CERT_FILE}" && -s "${KEY_FILE}" ]]; then
  echo "TLS certificate already exists: ${CERT_FILE}"
  exit 0
fi

umask 077
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 825 \
  -keyout "${KEY_FILE}" -out "${CERT_FILE}" \
  -subj "/CN=${HOSTNAME}" \
  -addext "subjectAltName=DNS:${HOSTNAME},IP:127.0.0.1"
chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"
echo "Generated self-signed TLS certificate for ${HOSTNAME}"

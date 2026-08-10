#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'run this smoke test as root\n' >&2
  exit 20
fi

services=(
  echo-prime-family.service
  echo-convai-tts.service
  echo-titlehound.service
)
health_urls=(
  http://127.0.0.1:18420/health
  http://127.0.0.1:7800/health
  http://127.0.0.1:18991/health
)
token=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
released=false

cleanup() {
  status=$?
  trap - EXIT
  if [[ "$released" != true ]]; then
    /usr/local/sbin/qcoder-gpu-lease release --token "$token" >/dev/null || true
  fi
  exit "$status"
}
trap cleanup EXIT

for index in "${!services[@]}"; do
  systemctl is-active --quiet "${services[$index]}"
  curl --fail --silent --show-error --max-time 5 "${health_urls[$index]}" >/dev/null
done

/usr/local/sbin/qcoder-gpu-lease acquire \
  --token "$token" \
  --holder qcoder-runtime-mask-smoke \
  --ttl 600 >/dev/null

for service in "${services[@]}"; do
  [[ $(systemctl show "$service" -p RefuseManualStart --value) == yes ]]
  [[ $(systemctl show "$service" -p ActiveState --value) == inactive ]]
done

ollama_processes=$(curl --fail --silent --show-error --max-time 5 \
  http://127.0.0.1:11434/api/ps)
if printf '%s' "$ollama_processes" | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
models = payload.get("models", []) if isinstance(payload, dict) else []
names = [str(item.get("name") or item.get("model") or "") for item in models if isinstance(item, dict)]
raise SystemExit(0 if any("c3po-code" in name for name in names) else 1)
'; then
  printf 'qcoder model unexpectedly remained loaded after acquisition\n' >&2
  exit 21
fi

/usr/local/sbin/qcoder-gpu-lease release --token "$token" >/dev/null
released=true

for index in "${!services[@]}"; do
  systemctl is-active --quiet "${services[$index]}"
  [[ $(systemctl show "${services[$index]}" -p RefuseManualStart --value) == no ]]
  curl --fail --silent --show-error --max-time 5 "${health_urls[$index]}" >/dev/null
done

printf 'QCODER_GPU_LEASE_SMOKE_OK services=%s restart_guard=verified restoration=healthy\n' "${#services[@]}"

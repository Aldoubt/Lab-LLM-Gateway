#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:4000}"
MODEL="${MODEL:-lab-local-code}"

if [[ -z "${LITELLM_MASTER_KEY:-}" && -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

: "${LITELLM_MASTER_KEY:?Set LITELLM_MASTER_KEY or create .env}"

echo "[1/2] Listing models..."
curl -fsS "${BASE_URL}/v1/models"   -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" >/dev/null

echo "[2/2] Sending completion to ${MODEL}..."
curl -fsS "${BASE_URL}/v1/chat/completions"   -H "Authorization: Bearer ${LITELLM_MASTER_KEY}"   -H "Content-Type: application/json"   -d "$(jq -nc --arg model "$MODEL" '{
    model: $model,
    messages: [{role:"user", content:"Reply with exactly: gateway-ok"}],
    max_tokens: 32,
    temperature: 0
  }')" | jq .

echo "Smoke test completed."

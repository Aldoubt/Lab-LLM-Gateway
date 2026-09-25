#!/usr/bin/env bash
set -euo pipefail

USER_ID="${1:-}"
if [[ -z "$USER_ID" ]]; then
  echo "Usage: $0 <user-id> [models_csv]" >&2
  exit 2
fi

MODELS_CSV="${2:-lab-local-code}"
ADMIN_BASE="${ADMIN_BASE:-http://127.0.0.1:4000}"

if [[ -z "${LITELLM_MASTER_KEY:-}" && -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

: "${LITELLM_MASTER_KEY:?Set LITELLM_MASTER_KEY or create .env}"

MODELS_JSON="$(printf '%s' "$MODELS_CSV" | jq -Rc 'split(",") | map(select(length > 0))')"

echo "Creating internal user identity: $USER_ID"
curl -fsS -X POST "${ADMIN_BASE}/user/new"   -H "Authorization: Bearer ${LITELLM_MASTER_KEY}"   -H "Content-Type: application/json"   -d "$(jq -nc --arg user "$USER_ID" '{user_id:$user}')" >/dev/null

echo "Generating virtual key..."
RESPONSE="$(curl -fsS -X POST "${ADMIN_BASE}/key/generate"   -H "Authorization: Bearer ${LITELLM_MASTER_KEY}"   -H "Content-Type: application/json"   -d "$(jq -nc     --arg user "$USER_ID"     --argjson models "$MODELS_JSON"     '{
      user_id:$user,
      models:$models,
      rpm_limit:60,
      tpm_limit:200000,
      max_parallel_requests:4,
      metadata:{source:"Lab-LLM-Gateway bootstrap"}
    }')")"

echo "$RESPONSE" | jq '{key, user_id, models, rpm_limit, tpm_limit, max_parallel_requests}'
echo
echo "Store the returned key securely. Never give users the LiteLLM master key."

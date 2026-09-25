# Deployment Runbook

## Recommended host

Baseline for the intended lab node:

- Ubuntu 22.04 or 24.04 LTS
- 2 x RTX 4090, 24 GB each
- 128 GB system RAM as a comfortable starting point
- 256 GB system RAM if CPU offload, larger models, quantization work, datasets or heavy builds are expected
- NVMe storage: 2 TB minimum; 4 TB or more is preferable for model/cache growth
- PSU, connectors and cooling sized for simultaneous dual-GPU compute
- wired LAN

Each RTX 4090 has 24 GB VRAM. Treat them as two independent 24 GB devices rather than one transparent 48 GB GPU.

## Host prerequisites

Install:

- NVIDIA driver
- Docker Engine
- Docker Compose plugin
- NVIDIA Container Toolkit
- git, curl, jq

Validate:

~~~bash
nvidia-smi
docker version
docker compose version
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
~~~

If the example CUDA image becomes unavailable, use a currently supported runtime compatible with the installed driver.

## Clone and configure

~~~bash
git clone https://github.com/Aldoubt/Lab-LLM-Gateway.git
cd Lab-LLM-Gateway
cp .env.example .env
~~~

Generate strong secrets:

~~~bash
openssl rand -hex 32
openssl rand -hex 32
openssl rand -hex 32
~~~

Set them in .env for:

- LITELLM_MASTER_KEY, with sk- prefix
- LITELLM_SALT_KEY, with sk- prefix
- POSTGRES_PASSWORD

Never commit .env. Treat the LiteLLM salt as persistent production state once encrypted data depends on it.

## Start gateway services

~~~bash
docker compose pull
docker compose up -d postgres litellm caddy
docker compose ps
~~~

Administrative endpoint on the server:

~~~text
http://127.0.0.1:4000
~~~

Bootstrap user endpoint on LAN:

~~~text
http://SERVER_IP:8080/v1
~~~

PostgreSQL is mandatory for the intended user/key/budget deployment.

## Start local GPU inference

The repository starts from a quantized Qwen3-Coder-30B-A3B candidate intended for a 24 GB-class GPU. It is a starting point, not a permanent model choice.

~~~bash
docker compose --profile gpu up -d vllm-code-a vllm-code-b
docker compose logs -f vllm-code-a
~~~

Local debug endpoints:

~~~text
GPU0: http://127.0.0.1:8001/v1
GPU1: http://127.0.0.1:8002/v1
~~~

Lab members should not call these ports directly.

## End-to-end test

~~~bash
chmod +x scripts/*.sh
./scripts/smoke_test.sh
~~~

## Add Arena official API

Arena already exposes an OpenAI-compatible API. A browser-session-to-API converter is not required in the production path.

1. Create an Arena API key.
2. List model IDs currently available to the account:

~~~bash
curl https://api.preview.arena.ai/v1/models   -H "Authorization: Bearer $ARENA_API_KEY"
~~~

3. Test the chosen Arena model directly before adding it to the gateway.
4. In LiteLLM, add an OpenAI-compatible deployment:
   - API base: https://api.preview.arena.ai/v1
   - API key: server-side Arena key
   - model ID: exact ID returned by the Arena models endpoint
5. Give it a stable lab alias only after it passes smoke tests.

Arena itself supports fallback chains on provider-side failures. Keep lab-level routing and resolved-model observability as well.

## Add OpenAI, Anthropic or other providers

Prefer organization/project API credentials or a controlled BYOK design. Do not expose or proxy a personal ChatGPT/Codex login session for other users.

Validate the upstream directly first, then place it behind a lab alias.

## Create a lab-member key

On the server:

~~~bash
set -a
source .env
set +a
chmod +x scripts/create_user_key.sh
./scripts/create_user_key.sh alice
~~~

Give the user only:

~~~text
Base URL: http(s)://gateway/v1
API Key:  sk-...
Model:    lab-local-code
~~~

Never distribute the LiteLLM master key.

## Remote administration

Keep port 4000 loopback-only. From an admin workstation:

~~~bash
ssh -L 4000:127.0.0.1:4000 USER@SERVER
~~~

Then use http://127.0.0.1:4000 locally.

## Internet exposure

Preferred order:

1. LAN or Tailscale/VPN.
2. Public domain + TLS only if needed.
3. Keep port 4000 loopback-only.
4. Keep vLLM and PostgreSQL private.
5. Expose only the Caddy inference endpoint.

For automatic HTTPS, change the Caddy site address and publish/firewall 80/443 appropriately. Review the Caddy configuration before Internet exposure.

## Pin versions after validation

The bootstrap favors easy first deployment. After a known-good test:

- pin LiteLLM image version
- pin vLLM image version
- pin model revision/quantization
- record NVIDIA driver/CUDA compatibility
- tag a gateway release

Reproducibility is more important than always running latest.

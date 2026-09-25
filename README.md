# Lab-LLM-Gateway

实验室内部统一 LLM Gateway：把本地 GPU 推理、Arena 官方 API、云端模型 API 和 Coding Agent 客户端统一到一个 OpenAI-compatible endpoint。

> Status: bootstrap / MVP. 当前目标是先把“统一入口 + 用户 key + 配额 + 双 4090 本地推理 + Arena/云端接入”跑稳，再做自动智能路由。

## Goals

- 一个入口：`https://ai.<lab-domain>/v1`
- 每个成员独立 Virtual Key，不共享上游 provider 密钥
- 本地双 RTX 4090 作为默认低成本推理池
- Arena 官方 API / OpenAI / Anthropic 等作为 frontier 与弹性溢出
- 用户、团队、RPM/TPM、并发和付费 API 预算可控
- Provider 故障时可 fallback，不让单个模型拖垮所有用户
- Codex / Claude Code / OpenCode / Python SDK 等客户端可直接接入
- 保留可观测性，为后续模型路由、Agent benchmark 与实验室使用分析提供数据

## Non-goals (MVP)

- 不 fork LiteLLM。
- 不依赖 Arena 网页 cookie/session 的“转 API”方案。
- 不共享个人 ChatGPT / Codex 登录凭据或个人订阅额度。
- 不在公网直接暴露 vLLM、PostgreSQL 或 LiteLLM 管理接口。
- 不追求一开始就自动判断“哪个模型最聪明”；先把稳定性、权限和可观测性做好。

## Architecture

```text
Codex / Claude Code / OpenCode / SDK / Lab Apps
                         |
                  Virtual API Key
                         |
                         v
                  Caddy / TLS / ACL
                         |
                         v
                  LiteLLM Gateway
                   /      |       \
                  /       |        \
             Local vLLM  Arena    Cloud APIs
                 |        API       |
          +------+------+
          |             |
       RTX 4090       RTX 4090
        replica A      replica B

PostgreSQL: users / keys / budgets / spend metadata
```

The default local mode is **two single-GPU replicas of the same coding model**, optimized for laboratory concurrency. Large TP=2 models are a separate “max quality” operating mode, not the default.

## Repository layout

```text
.
├── config/
│   ├── Caddyfile
│   └── litellm.yaml
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── OPERATIONS.md
│   ├── ROUTING_AND_QUOTA.md
│   ├── SECURITY.md
│   └── SERVER_GUIDE.md
├── scripts/
│   ├── create_user_key.sh
│   └── smoke_test.sh
├── .env.example
├── .gitignore
└── docker-compose.yml
```

## Quick start

1. Prepare an Ubuntu GPU server with Docker, Docker Compose, NVIDIA driver and NVIDIA Container Toolkit.
2. Clone this repository.
3. Copy `.env.example` to `.env` and generate strong secrets.
4. Start the gateway core:

```bash
docker compose up -d postgres litellm caddy
```

5. Start the two local GPU workers when the model is ready:

```bash
docker compose --profile gpu up -d vllm-code-a vllm-code-b
```

6. Run:

```bash
./scripts/smoke_test.sh
```

7. Create a lab member key from the server:

```bash
./scripts/create_user_key.sh alice
```

Detailed setup: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

## Recommended rollout

- **Phase 0 — Single admin:** gateway + one local model; validate reliability.
- **Phase 1 — Lab beta:** per-user keys, local rate limits, Arena/cloud controlled access.
- **Phase 2 — Routing:** `lab-fast`, `lab-code`, `lab-frontier`, fallback and load-aware spillover.
- **Phase 3 — Agent pool:** Explorer / Coder / Reviewer model roles, benchmark-driven routing.
- **Phase 4 — Platform:** dashboard, quotas/credits, usage analytics and research datasets.

## Security

This repository is public. Never commit provider API keys, LiteLLM master keys, database passwords, tokens, cookies, SSH keys, or user credentials. Production management access should be through the server itself, VPN/Tailscale, or an SSH tunnel.

See [docs/SECURITY.md](docs/SECURITY.md).

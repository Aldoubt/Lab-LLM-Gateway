# Operations Runbook

## Daily checks

~~~bash
cd Lab-LLM-Gateway
docker compose ps
nvidia-smi
docker compose logs --tail=100 litellm
docker compose logs --tail=100 vllm-code-a
docker compose logs --tail=100 vllm-code-b
./scripts/smoke_test.sh
~~~

## Start

Gateway only:

~~~bash
docker compose up -d postgres litellm caddy
~~~

Gateway plus local GPU pool:

~~~bash
docker compose --profile gpu up -d
~~~

## Stop

~~~bash
docker compose --profile gpu down
~~~

Named volumes remain unless explicitly deleted.

## Update

Do not blindly update production.

1. Record current image/model revisions.
2. Pull during a maintenance window.
3. Validate one local replica.
4. Test tool calling and structured output needed by agents.
5. Validate both replicas.
6. Test virtual-key enforcement and routing.
7. Roll back if latency, memory or agent compatibility regresses.

## User onboarding

~~~bash
set -a
source .env
set +a
./scripts/create_user_key.sh USER_ID
~~~

Give the user only their endpoint, virtual key and allowed aliases.

## Incident: local overload

Symptoms:

- TTFT rises sharply
- queues grow
- GPU memory remains near limit
- OOM/restarts appear

Actions:

1. stop or throttle new heavy jobs
2. identify high-concurrency users/agents
3. reduce context/concurrency
4. spill authorized traffic to remote capacity
5. do not silently grant everyone unlimited frontier access

## Incident: one GPU worker fails

The other deployment should remain available through the shared model group.

~~~bash
docker compose ps
docker compose logs vllm-code-a
docker compose restart vllm-code-a
~~~

## Incident: paid-provider spend spike

1. identify key/user/team
2. revoke or reduce limits
3. check for an agent loop/retry storm
4. rotate upstream credentials only if compromise is suspected
5. retain enough metadata for a postmortem

## Backups

Back up:

- PostgreSQL
- production config
- secret material in a secure secret store
- model/image/revision manifest

Git is not a secret backup.

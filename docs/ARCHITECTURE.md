# Architecture

## Product boundary

Lab-LLM-Gateway is an internal AI infrastructure layer. It is not a model and it is not a coding agent.

Its responsibilities are:

1. Identity and policy: identify the lab member or service and enforce model access, RPM/TPM, concurrency and paid-provider budgets.
2. Routing: expose stable lab-owned model names while allowing the backend deployment/provider to change.
3. Inference aggregation: connect local vLLM, Arena official API and approved cloud APIs.
4. Observability: record usage, latency, provider/model resolution and failures without exposing provider credentials to users.

The agent harness stays separate: Codex, Claude Code, OpenCode, IDE plugins, ROS agents and custom scripts are clients of this gateway.

## Data plane

~~~text
Client
  |
  | OpenAI-compatible request + Lab Virtual Key
  v
Caddy
  |
  v
LiteLLM Gateway ---------------- PostgreSQL
  |                                  |
  |                                  +-- users
  |                                  +-- teams
  |                                  +-- virtual keys
  |                                  +-- spend metadata
  |
  +-------- Local model group --------+
  |           |                       |
  |       vLLM GPU0               vLLM GPU1
  |
  +-------- Arena official API
  |
  +-------- Approved cloud providers
~~~

## Control plane

Administration is separated from inference traffic.

- User inference: Caddy -> LiteLLM inference routes.
- Admin interface: server loopback 127.0.0.1:4000.
- Remote admin: SSH tunnel, VPN/Tailscale, or a dedicated trusted admin network.
- Provider secrets live only on the gateway server.

## Stable model aliases

Applications should use lab-owned names instead of provider model IDs.

Initial contract:

- lab-local-code: local coding model group, two RTX 4090 replicas.
- lab-code: future policy route, normally local first with authorized spillover.
- lab-frontier: future explicitly expensive/high-capability route.
- lab-review: future cross-provider reviewer route.
- lab-auto: future task/load-aware router.

Only expose aliases that have actually passed validation.

## Dual-4090 operating modes

### Shared-throughput mode: default

~~~text
4090 #0 -> same quantized coding model -> replica A
4090 #1 -> same quantized coding model -> replica B
                  |
             LiteLLM group
~~~

This mode favors multi-user throughput and fault isolation.

### Mixed mode: later

GPU0 runs a coding model; GPU1 runs a general/reasoning model. Use this only when actual usage data justifies keeping two different weights resident.

### Max-quality mode: later

Both GPUs serve one larger model using tensor parallelism. This increases model-size headroom but reduces independent-request capacity and introduces cross-GPU traffic. RTX 4090 has no NVLink, so this mode must be benchmark-driven.

## Failure domains

- Local vLLM failure: cool down/remove the unhealthy replica.
- One GPU failure: the other replica can remain available.
- Arena/provider 429 or 5xx: use an explicit permitted fallback chain.
- Database failure: do not assume virtual-key budgets or policy enforcement remain valid.
- Gateway failure: inference stops; keep database/config backup and a tested restore procedure.

## Design rules

- No raw provider keys on ordinary client machines when a lab-managed route exists.
- No Arena browser-cookie/session proxy as a production dependency.
- No personal ChatGPT/Codex credential sharing.
- No silent switch from cheap/local to paid frontier if the user/team policy does not allow it.
- Every fallback should be observable.
- A lab model alias is a contract; its implementation may change only after validation.

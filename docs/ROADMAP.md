# Roadmap

## M0 Bootstrap

- [x] repository structure
- [x] LiteLLM + PostgreSQL + Caddy skeleton
- [x] dual single-GPU vLLM replica profile
- [x] security and deployment documentation
- [ ] validate on real dual-4090 server
- [ ] pin known-good image versions

Exit: one administrator can make an end-to-end local request.

## M1 Lab beta

- [ ] create users/teams/virtual keys
- [ ] define Student / Researcher / Admin policies
- [ ] benchmark local model at 1/2/4/8+ concurrency
- [ ] validate 32k context capacity
- [ ] add Arena official API
- [ ] add cloud route if needed
- [ ] document Codex / Claude Code / OpenCode setup

Exit: several lab members can share the service without provider-key sharing.

## M2 Reliability

- [ ] health/cooldown/fallback policy
- [ ] metrics for TTFT, latency, tokens/s, errors, 429 and spend
- [ ] resolved provider/model logging
- [ ] PostgreSQL backup/restore test
- [ ] load test and failure injection

Exit: one failed backend does not take down normal inference.

## M3 Smart routing

- [ ] collect workload/outcome data
- [ ] deterministic local-vs-frontier rules
- [ ] load-aware spillover
- [ ] cross-model review route
- [ ] optional learned router only after enough data exists

Exit: routing beats simple always-local/always-frontier baselines on measured cost, latency and task success.

## M4 Lab AI platform

- [ ] internal Lab Credits
- [ ] self-service dashboard
- [ ] BYOK
- [ ] agent concurrency policy
- [ ] experiment/benchmark registry
- [ ] MCP/tool access policy
- [ ] privacy-aware research export

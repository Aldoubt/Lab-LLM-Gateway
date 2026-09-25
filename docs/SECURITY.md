# Security Model

The gateway may hold provider credentials, virtual keys, usage metadata and expensive inference capacity. Treat it as production infrastructure.

## Rules

1. Never commit .env, provider keys, cookies, SSH credentials or master keys.
2. Never distribute LITELLM_MASTER_KEY to normal users.
3. Keep LiteLLM administration on loopback or a trusted admin network.
4. Keep PostgreSQL and vLLM private.
5. Use per-user or per-service virtual keys.
6. Revoke keys when users leave the project/lab.
7. Prefer organization/project API credentials over shared personal credentials.
8. Do not share personal ChatGPT/Codex accounts.
9. Do not make browser-cookie/session reverse proxies a production dependency.
10. Back up database and required secret material securely.

## Network boundary

~~~text
Internet/LAN
    |
 Caddy/TLS
    |
 inference routes only
    |
 LiteLLM
    |
 private Docker network
~~~

Admin access:

~~~bash
ssh -L 4000:127.0.0.1:4000 user@lab-server
~~~

## Public repository warning

This GitHub repository is public. Assume committed secrets become permanently observable even after deletion.

Before config commits:

~~~bash
git diff --cached
git grep -nE '(sk-|api[_-]?key|token|password|secret)' -- .
~~~

## Logging and privacy

Decide explicitly whether prompts/responses are logged. Full content may contain unpublished research, source code or personal information.

Default recommendation:

- retain operational metadata needed for capacity/cost analysis
- avoid full prompt/response retention unless an experiment requires it
- define retention periods
- document who can access logs

# Routing and Quota Policy

## Separate resource classes

### Local GPU

Scarce resources:

- VRAM and KV cache
- GPU compute
- active sequences
- queue length
- time-to-first-token

Primary controls:

- maximum parallel requests
- RPM and TPM
- local context limit
- queue/load-aware routing

### Arena and paid cloud API

Scarce resources:

- money
- provider RPM/TPM
- account/provider capacity

Primary controls:

- monetary budget
- RPM/TPM
- model allow-list
- explicit fallback

### Personal or BYOK

The user owns the upstream cost, but the lab can still enforce concurrency and security policy.

## MVP roles

Student:

- lab-local-code allowed
- paid/frontier denied by default or given a small explicit budget
- conservative concurrency

Researcher:

- local routes allowed
- selected Arena/cloud routes allowed
- larger budget/concurrency

Admin/service:

- explicit operational permissions
- never use the master key as a normal user credential

## Local quota is not a dollar budget

A local vLLM deployment may have zero/unknown monetary cost in gateway accounting. Therefore a monthly dollar budget is not enough to protect shared GPUs.

For local routes enforce at least:

- rpm_limit
- tpm_limit
- max_parallel_requests
- context ceiling in the inference service

For paid routes add budget limits.

## Model aliases

Phase 1:

- lab-local-code: two local replicas

Phase 2:

- lab-code: explicit local-first coding policy
- lab-frontier: intentionally expensive route
- lab-review: reviewer route, preferably a different model/provider family
- lab-auto: only after routing telemetry exists

## Routing policy

Start deterministic, not opaque.

~~~text
request
  |
  +-- explicitly lab-frontier --> frontier policy
  |
  +-- context exceeds local ceiling --> approved remote route
  |
  +-- local healthy and queue acceptable --> local
  |
  +-- local overloaded/unhealthy --> approved spillover
  |
  +-- no permitted spillover --> capacity error
~~~

Never silently route a user into a paid model they are not authorized to use.

## Arena layering

~~~text
Lab alias
  |
  +-- local deployment
  |
  +-- Arena route
       |
       +-- Arena primary
       +-- Arena fallback #1
       +-- Arena fallback #2
~~~

Record the resolved model/fallback state.

## Future Lab Credits

A later version may normalize:

- local GPU usage
- cloud token cost
- long-context premium
- frontier premium

Do not invent permanent credit multipliers before measuring real workloads.

## Capacity metrics

Track:

- TTFT p50/p95
- inter-token latency
- output tokens/s
- queue time
- GPU memory/KV utilization
- request success/error/429
- active sequences
- per-user concurrency

Change routing thresholds from measurement, not a fixed guessed number of users.

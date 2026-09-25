# Practical Dual-4090 Server Guide

## Treat the machine as an inference appliance

Normal students should not SSH into the GPU host to launch random model processes.

~~~text
student laptop/workstation
        |
        | HTTPS + Lab Virtual Key
        v
Lab-LLM-Gateway
        |
        +-- LiteLLM
        +-- PostgreSQL
        +-- vLLM GPU workers
~~~

They configure their coding/chat client to the gateway and do not need shell access to the server.

## Default GPU layout

Start shared mode as:

~~~text
GPU0 RTX 4090 -> vLLM replica A -> local-code
GPU1 RTX 4090 -> vLLM replica B -> local-code
~~~

The bootstrap model is a 4-bit Qwen3-Coder-30B-A3B candidate intended to fit one 24 GB GPU. Benchmark it on the real host before declaring it the lab standard.

## Why not one huge model by default

Two 4090s provide 48 GB total physical VRAM but remain separate devices. RTX 4090 does not have NVLink.

TP=2 can serve a larger model, but:

- both GPUs are occupied by one model instance
- cross-GPU traffic is introduced
- fewer independent requests are served
- KV-cache headroom remains important

Use TP=2 as an explicit local-max experiment after benchmarking.

## Host RAM

Practical recommendation:

- 128 GB: strong baseline for gateway + Docker + model loading/caches + development
- 256 GB: better for CPU offload, quantization, larger model experiments, datasets or heavy builds

RAM does not magically combine VRAM. CPU offload can expand capacity but increases latency and PCIe traffic.

## Storage

Use NVMe. A practical target is:

~~~text
system/docker        about 1 TB
model/cache/data     2-4 TB or more
~~~

Model variants and caches grow quickly.

## Power and cooling

A reference RTX 4090 is rated up to 450 W graphics power. Two cards can therefore approach 900 W GPU-only before CPU/platform load.

Choose PSU capacity, connectors, chassis spacing and sustained airflow for simultaneous compute. Validate the exact board-partner cards and motherboard topology.

## Context policy

Do not expose theoretical maximum context as the default.

Start at 32k local context. Long context consumes KV cache and can degrade concurrency/TTFT for all users.

Possible future service classes:

- lab-local-code: 32k, shared
- lab-local-long: 64k, lower concurrency after benchmark
- lab-frontier: remote long-context path when policy allows

## Daily user workflow

Student:

1. receives a Lab Virtual Key
2. sets API base to the lab endpoint
3. selects lab-local-code
4. uses Codex/OpenCode/IDE/SDK normally
5. requests frontier access only when needed

Administrator:

1. watches gateway/GPU health
2. provisions/revokes keys
3. manages provider routes
4. watches latency, OOM, 429 and spend
5. benchmarks model changes before rollout

Research workload:

Reserve a maintenance or experiment window for large TP=2/model experiments rather than replacing the shared production service during active use.

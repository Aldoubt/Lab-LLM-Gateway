# References

These are the upstream sources that define the current bootstrap architecture. Re-check them before major upgrades because APIs and deployment flags can change.

## LiteLLM

- Gateway overview: https://docs.litellm.ai/
- Docker quickstart: https://docs.litellm.ai/docs/proxy/docker_quick_start
- Virtual keys: https://docs.litellm.ai/docs/proxy/virtual_keys
- Budgets and rate limits: https://docs.litellm.ai/docs/proxy/users
- Client setup: https://docs.litellm.ai/docs/proxy/client_setup/overview

Key design dependency: virtual-key budgets and user/team accounting require PostgreSQL-backed state.

## vLLM

- OpenAI-compatible server: https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html
- Serve CLI: https://docs.vllm.ai/en/latest/cli/serve/
- Data parallel deployment: https://docs.vllm.ai/en/latest/serving/data_parallel_deployment/

Key design dependency: vLLM provides an OpenAI-compatible inference server and supports multi-GPU parallelism. The bootstrap uses independent single-GPU replicas for shared throughput.

## Arena API

- API reference: https://portal.api.preview.arena.ai/docs/api-reference
- Routing/fallback: https://portal.api.preview.arena.ai/docs/routing
- Rate limits: https://portal.api.preview.arena.ai/docs/rate-limits

Key design dependency: Arena already provides an official OpenAI-compatible API and fallback support. Production does not require a browser-session conversion proxy.

## Hardware

- RTX 4090 specifications: https://www.nvidia.com/en-us/geforce/graphics-cards/40-series/rtx-4090/

Each reference RTX 4090 has 24 GB GDDR6X, up to 450 W graphics power, PCIe Gen4 and no NVLink.

## Initial local-model candidate

- Qwen3-Coder-30B-A3B family: https://huggingface.co/Qwen/Qwen3-Coder-30B-A3B-Instruct
- 24 GB-oriented AWQ candidate used by the bootstrap:
  https://huggingface.co/dark-side-of-the-code/Qwen3-Coder-30B-A3B-Instruct-AWQ

The quantized checkpoint is a bootstrap candidate only. Pin and standardize a model only after testing quality, context length, tool calling, TTFT, throughput and memory use on the real server.

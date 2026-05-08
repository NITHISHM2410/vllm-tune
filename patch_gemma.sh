python3 - <<'PY'
from pathlib import Path

p = Path("/tmp/vllm-bench/benchmarks/kernels/benchmark_moe.py")
s = p.read_text()

old = """    E = config.num_local_experts
    topk = config.num_experts_per_tok
    intermediate_size = config.intermediate_size
    hidden_size = config.hidden_size
    return E, topk, intermediate_size, hidden_size
"""

new = """    # Gemma4 MoE stores text MoE fields under config.text_config.
    if hasattr(config, "text_config") and getattr(config.text_config, "model_type", None) == "gemma4_text":
        text_config = config.text_config
        E = text_config.num_experts
        topk = text_config.top_k_experts
        intermediate_size = text_config.moe_intermediate_size
        hidden_size = text_config.hidden_size
        return E, topk, intermediate_size, hidden_size

    E = config.num_local_experts
    topk = config.num_experts_per_tok
    intermediate_size = config.intermediate_size
    hidden_size = config.hidden_size
    return E, topk, intermediate_size, hidden_size
"""

if old not in s:
    raise SystemExit("Could not find expected fallback block. Open the file and patch get_model_params manually.")

p.write_text(s.replace(old, new))
print("patched", p)
PY
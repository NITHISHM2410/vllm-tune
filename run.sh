mkdir -p /tmp/vllm-tune-shim

cat > /tmp/vllm-tune-shim/docker <<'SH'
#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${VLLM_TUNE_FAKE_CONTAINER:-vllm_node}"

case "${1:-}" in
  ps)
    # Support: docker ps --format '{{.Names}}'
    if [[ "${2:-}" == "--format" ]]; then
      echo "$CONTAINER_NAME"
    else
      echo "CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES"
      echo "fake           local   local     now       Up       -       $CONTAINER_NAME"
    fi
    ;;

  exec)
    shift
    # drop container name
    if [[ "${1:-}" == "$CONTAINER_NAME" ]]; then
      shift
    else
      shift
    fi
    exec "$@"
    ;;

  cp)
    src="$2"
    dst="$3"

    # docker cp container:/path /dest  -> cp -a /path /dest
    if [[ "$src" == *:* ]]; then
      src_path="${src#*:}"
      cp -a "$src_path" "$dst"
      exit 0
    fi

    # docker cp /src container:/path  -> cp -a /src /path
    if [[ "$dst" == *:* ]]; then
      dst_path="${dst#*:}"
      mkdir -p "$(dirname "$dst_path")"
      cp -a "$src" "$dst_path"
      exit 0
    fi

    cp -a "$src" "$dst"
    ;;

  inspect)
    # Used only for zombie counting. Return PID 1.
    if [[ "${2:-}" == "--format" ]]; then
      echo 1
    else
      echo "{}"
    fi
    ;;

  restart)
    echo "fake docker restart: no-op"
    ;;

  *)
    echo "fake docker: unsupported command: $*" >&2
    exit 1
    ;;
esac
SH

chmod +x /tmp/vllm-tune-shim/docker
export PATH="/tmp/vllm-tune-shim:$PATH"

docker ps

export MODEL=/models/load_quant/merged-100
export TP=1

./vllm-tune.sh "$MODEL" \
  --tp "$TP" \
  --mode all \
  --foreground


        #   # Default: Mixtral.
        # E = config.num_experts
        # topk = config.top_k_experts
        # intermediate_size = config.moe_intermediate_size
        # hidden_size = config.hidden_size
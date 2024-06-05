#!/bin/bash
set -o errexit -o nounset -o pipefail
[[ "${TRACE:-0}" == "1" ]] && set -o xtrace

shepherd config location       "${API_ENDPOINT:?}"
shepherd login service-account "${API_TOKEN:?}"

if [[ -n "${RUN:-}" ]]; then
  echo "Running: ${RUN}"
  eval "${RUN}" # eval will always exit with whatever RUN returns, so the rest of main.sh won't execute if RUN is defined
fi

if [[ -n "${ENV_ID:-}" ]]; then
  echo "ENV_ID:    ${ENV_ID}"
  echo "NAMESPACE: ${NAMESPACE}"
  shepherd delete lease "${ENV_ID:?}" \
    --namespace "${NAMESPACE:?}"
fi

if [[ -n "${POOL_NAME:-}" ]]; then
  echo "POOL_NAME:      ${POOL_NAME}"
  echo "POOL_NAMESPACE: ${POOL_NAMESPACE}"

  create_lease() {
    shepherd create lease \
      --duration       "${DURATION:?}" \
      --pool           "${POOL_NAME:?}" \
      --pool-namespace "${POOL_NAMESPACE:?}" \
      --namespace      "${NAMESPACE:?}" \
      --description    "${DESCRIPTION:?}" \
      --json \
      | jq -r .id
  }

  get_lease() {
    shepherd get lease "${lease_id:?}" \
      --namespace "${NAMESPACE:?}" \
      --json \
      | jq -r \
          --sort-keys \
          --compact-output
  }

  get_lease_status() {
    get_lease \
      | jq -r .status
  }

  get_lease_output() {
    get_lease \
      | jq -r .output \
           --sort-keys \
           --compact-output
  }

  wait_until_env_is_ready() {
    set -x
    echo "::group::Lease readiness"
    while lease_json=$(get_lease); do
      status=$(printf "%s" "${lease_json}" | jq -r .status)
      echo "[$(date -u +%Y-%m-%dT%H:%M:%S%Z)] Lease status: ${status:?}"
      # echo "[$(date -u +%Y-%m-%dT%H:%M:%S%Z)] Lease output: $( get_lease_output )"
      echo "[$(date -u +%Y-%m-%dT%H:%M:%S%Z)] Lease status_message: $( printf "%s" "${lease_json}"  | jq -r .status_message --sort-keys )"
      case ${status} in
        LEASED)
          exit 0
          ;;
        FAILED | EXPIRED)
          exit 1
          ;;
        *)
          sleep 30
          ;;
      esac
    done
    echo "::endgroup::"
    set +x
  }

  # lease_id="966e8ad2-ff7f-4611-b053-4cd2299927d7" # LEASED

  lease_id=${lease_id:-$(create_lease)}
  echo "env-id=$lease_id" >> "${GITHUB_OUTPUT}"

  time wait_until_env_is_ready

  get_lease > lease.json
fi
#!/usr/bin/env bash
set -u

export KUBECONFIG="${KUBECONFIG:-/mnt/c/Users/richa/Projects/capstone-phoenix/infra/ansible/kubeconfig}"

evidence_dir="${1:-/mnt/c/Users/richa/Projects/capstone-phoenix/docs/EVIDENCE}"
node="${2:-ip-10-20-2-143}"
url="${3:-https://taskapp.18.225.218.179.sslip.io/api/health}"
log_file="${evidence_dir}/failover-demo.log"

mkdir -p "$evidence_dir"

{
  echo "Failover demo captured at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Target drained worker: $node"
  echo "Health URL: $url"
  echo
  echo "== Before drain: nodes =="
  kubectl get nodes -o wide
  echo
  echo "== Before drain: pods =="
  kubectl -n taskapp get pods -o wide
  echo
  echo "== Starting request loop during drain =="
} > "$log_file"

(
  for i in $(seq 1 45); do
    printf "%s request_%02d " "$(date -u +%H:%M:%S)" "$i" >> "$log_file"
    curl -sk -o /dev/null -w "http=%{http_code} time=%{time_total}\n" --max-time 10 "$url" >> "$log_file" 2>&1
    sleep 2
  done
) &
loop_pid=$!

{
  echo
  echo "== Drain command =="
  kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force --timeout=240s
  drain_rc=$?
  echo "drain_exit=$drain_rc"
  echo
  echo "== After drain: nodes =="
  kubectl get nodes -o wide
  echo
  echo "== After drain: pods =="
  kubectl -n taskapp get pods -o wide
  echo
  echo "== Wait for backend rollout after drain =="
  kubectl -n taskapp rollout status deployment/backend --timeout=240s
  echo
  echo "== Health after drain =="
  curl -sk "$url"
  echo
  echo
  echo "== Uncordon command =="
  kubectl uncordon "$node"
  echo
  echo "== After uncordon: nodes =="
  kubectl get nodes -o wide
} >> "$log_file" 2>&1

wait "$loop_pid"

{
  echo
  echo "== Final app status =="
  kubectl -n taskapp get pods -o wide
  echo
  echo "== Final request =="
  curl -sk "$url"
  echo
} >> "$log_file" 2>&1

tail -80 "$log_file"

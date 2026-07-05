# EVIDENCE

Drop screenshots/logs here, named so a grader knows what each proves:

- `nodes-ready.png` - multi-node `kubectl get nodes -o wide`
- `pods-spread.png` - frontend/backend replicas on different nodes
- `tls-valid.png` - valid Let's Encrypt certificate from `curl -vI`
- `pvc-persist.log` - data survives deleting `postgres-0`
- `zero-downtime.log` - unbroken 200s during a rollout
- `hpa-scale.png` - backend replicas climbing under load
- `argocd-synced.png` - Argo CD app is Synced and Healthy
- `failover.png` - app stays up after a worker drain

Recommended commands:

```bash
kubectl get nodes -o wide
kubectl -n taskapp get pods -o wide
kubectl -n taskapp get certificate taskapp-tls
curl -vI https://taskapp.18.225.218.179.sslip.io
curl https://taskapp.18.225.218.179.sslip.io/api/health
kubectl -n argocd get application taskapp
```

Live verification on 2026-07-05:

- App URL: https://taskapp.18.225.218.179.sslip.io
- `kubectl get nodes -o wide`: 1 control-plane and 2 workers Ready.
- `kubectl -n taskapp get certificate taskapp-tls`: Ready=True with a Let's Encrypt certificate.
- `curl https://taskapp.18.225.218.179.sslip.io/api/health`: returned `{"database":"connected","status":"healthy",...}`.

# Architecture

## 1. Topology Diagram

Replace `taskapp.example.com` with the real domain before deployment.

```text
Internet
  |
  | DNS A/AAAA: taskapp.example.com -> node public IPs / load balancer
  v
ingress-nginx on k3s nodes, port 80/443
  |
  | TLS certificate issued by cert-manager + Let's Encrypt
  v
Ingress taskapp
  |-- /      -> Service frontend:80  -> frontend Pods, 2+ replicas, spread by hostname
  `-- /api   -> Service backend:5000 -> backend Pods, 2+ replicas, spread by hostname
                                      |
                                      v
                              Service postgres:5432
                                      |
                                      v
                          StatefulSet postgres-0 + PVC
```

## 2. Node And Network

Terraform provisions three AWS EC2 nodes by default:

| Node | Role | Default size | Placement |
|---|---|---|---|
| `cp1` | k3s server/control-plane | `t3.small` | public subnet 1 |
| `worker1` | k3s agent | `t3.small` | public subnet 2 |
| `worker2` | k3s agent | `t3.small` | public subnet 3 |

The default VPC CIDR is `10.20.0.0/16`, with three public subnets. This intentionally avoids k3s/flannel's default Pod CIDR, `10.42.0.0/16`, so node-private networking and Pod networking do not overlap. Public subnets keep the project cheap and simple for the capstone, while security groups still restrict access. The only world-open ports are `80` and `443`. SSH `22` is restricted to `allowed_ssh_cidr`. Kubernetes API `6443` is only reachable inside the VPC security group, so it is not exposed to `0.0.0.0/0`.

## 3. Request Flow

A browser resolves `taskapp.example.com` and connects to the ingress controller over HTTPS on `443`. cert-manager obtains and renews the public Let's Encrypt certificate through the `letsencrypt-prod` ClusterIssuer. The Kubernetes Ingress routes `/` to the `frontend` Service on port `80` and `/api` to the `backend` Service on port `5000`. Backend Pods read non-secret settings from `taskapp-config`, secret values from `taskapp-secret`, and connect to Postgres through the stable `postgres` headless Service on port `5432`.

## 4. Single-Server Assumptions Fixed

| Single-server assumption | Why it breaks at scale | How it is fixed here |
|---|---|---|
| Migrate-on-boot in the backend entrypoint | Two or more backend replicas can race on `alembic upgrade head` | `manifests/migration-job.yaml` runs migrations once as a Kubernetes Job |
| A named Docker volume is tied to one host | Pods may reschedule to another node and lose local data | Postgres runs as a StatefulSet with a PVC in `manifests/postgres.yaml` |
| Published host ports are enough | Multi-node clusters need one stable front door | ingress-nginx + Ingress routes `taskapp.example.com` paths to Services |
| One process restart is acceptable downtime | Rolling multiple replicas can drop requests if pods disappear too early | Deployments use `maxUnavailable: 0`, readiness probes, and PDBs |
| Secrets can live in local Portainer variables | GitOps repos must not contain plaintext secrets | `taskapp-secret` is created out-of-band from `secret.example.yaml`; plaintext real secrets stay out of git |
| One backend container can handle all traffic | Traffic and failures spread across nodes | Backend and frontend use 2 replicas plus hostname topology spread constraints |
| Manual deploy commands are the source of truth | Final state must be reconciled continuously | Argo CD Application in `gitops/taskapp-application.yaml` syncs `manifests/` |

## 5. Choices And Trade-Offs

- Raw YAML with Kustomize metadata: simple for grading, easy to inspect, and no chart abstraction hiding required objects.
- ingress-nginx instead of bundled k3s Traefik: the Ansible role disables Traefik so there is one documented ingress path.
- NetworkPolicy: k3s includes a NetworkPolicy controller; manifests use default-deny plus explicit app traffic rules.
- Secrets: the repo includes `manifests/secret.example.yaml` only. For the base submission, create `taskapp-secret` out-of-band and keep it out of git. Stretch improvement: replace this with Sealed Secrets or External Secrets.
- Domain: same-origin `/api` routing is used instead of a separate `api.` host to avoid CORS complexity and keep the demo focused on Kubernetes HA.

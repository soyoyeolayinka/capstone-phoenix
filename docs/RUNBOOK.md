# Runbook

This runbook assumes AWS, k3s, ingress-nginx, cert-manager, metrics-server, Argo CD, and raw manifests under `manifests/`.

## 0. Local Tools

Install these before provisioning:

```bash
terraform version
ansible --version
kubectl version --client=true
helm version
aws sts get-caller-identity
```

On Windows, use WSL Ubuntu if the tools are not installed natively.

## 1. Prepare Terraform State

Create an S3 bucket and DynamoDB table for state locking. Do this once, then copy the backend example:

```bash
cd infra/terraform
cp backend.tf.example backend.tf
# edit backend.tf with the real bucket, key, region, and lock table
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with allowed_ssh_cidr and key_name
```

Never commit `backend.tf`, `terraform.tfvars`, `.terraform/`, or `*.tfstate`.

## 2. Provision Infrastructure

```bash
cd infra/terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output -raw ansible_inventory > ../ansible/inventory.ini
```

Acceptance:

```bash
ssh ubuntu@$(terraform output -raw control_plane_public_ip)
terraform plan
```

The second `terraform plan` should show no drift.

## 3. Bring Up k3s

```bash
cd ../ansible
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook -i inventory.ini site.yml
ansible-playbook -i inventory.ini site.yml
```

The second run should report `changed=0` or only harmless facts/checks. Then verify:

```bash
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes -o wide
```

Save evidence as `docs/EVIDENCE/nodes-ready.png`.

## 4. Install Platform Components

Install ingress-nginx:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```

Install cert-manager:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
```

Install metrics-server:

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  --repo https://kubernetes-sigs.github.io/metrics-server/ \
  --namespace kube-system
```

Install Argo CD:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server
```

## 5. Configure Domain And Secrets

Replace placeholders before syncing the app:

```bash
# replace taskapp.example.com in manifests/configmap.yaml and manifests/ingress.yaml
# replace ops@example.com in manifests/platform/clusterissuer.yaml
```

Create the runtime Secret without committing it:

```bash
kubectl create namespace taskapp --dry-run=client -o yaml | kubectl apply -f -
kubectl -n taskapp create secret generic taskapp-secret \
  --from-literal=DB_USER=taskapp \
  --from-literal=DB_PASSWORD='REPLACE_WITH_STRONG_PASSWORD' \
  --from-literal=SECRET_KEY='REPLACE_WITH_RANDOM_SECRET' \
  --from-literal=DATABASE_URL='postgresql://taskapp:REPLACE_WITH_STRONG_PASSWORD@postgres:5432/taskapp'
```

## 6. Let GitOps Take Over

Commit and push any domain/email changes, then bootstrap the Argo CD Application once:

```bash
kubectl apply -f gitops/taskapp-application.yaml
kubectl -n argocd get applications.argoproj.io taskapp
```

After this point, change app state by git commit, not by manual `kubectl apply`.

Acceptance:

```bash
kubectl -n taskapp get pods -o wide
kubectl -n taskapp get ingress
kubectl -n argocd get application taskapp
```

Capture `pods-spread.png`, `tls-valid.png`, and `argocd-synced.png`.

## Day-2 Operations

Scale a tier:

```bash
# edit manifests/frontend.yaml replicas: 2 -> 3
git add manifests/frontend.yaml
git commit -m "Scale frontend replicas"
git push
kubectl -n taskapp rollout status deploy/frontend
```

Roll back a bad deploy:

```bash
git revert <bad_commit_sha>
git push
kubectl -n taskapp rollout status deploy/backend
```

Run a new migration safely:

```bash
# bump backend image tag in manifests/migration-job.yaml and manifests/backend.yaml
# delete the old completed Job only after the new manifest is committed
kubectl -n taskapp delete job taskapp-migrate
git add manifests
git commit -m "Run backend migration for release <tag>"
git push
```

Rotate a secret:

```bash
kubectl -n taskapp create secret generic taskapp-secret \
  --from-literal=DB_USER=taskapp \
  --from-literal=DB_PASSWORD='NEW_STRONG_PASSWORD' \
  --from-literal=SECRET_KEY='NEW_RANDOM_SECRET' \
  --from-literal=DATABASE_URL='postgresql://taskapp:NEW_STRONG_PASSWORD@postgres:5432/taskapp' \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n taskapp rollout restart deploy/backend
```

## Failure Recovery

Worker node dies or is drained:

```bash
kubectl get nodes
kubectl drain <worker-node> --ignore-daemonsets --delete-emptydir-data
kubectl -n taskapp get pods -o wide --watch
curl -k -I https://taskapp.example.com
kubectl uncordon <worker-node>
```

Backend Pod crashloops:

```bash
kubectl -n taskapp get pods
kubectl -n taskapp describe pod <backend-pod>
kubectl -n taskapp logs <backend-pod> --previous
kubectl -n taskapp get events --sort-by=.lastTimestamp
```

Bad migration:

```bash
kubectl -n taskapp logs job/taskapp-migrate
git revert <migration_commit>
git push
# restore Postgres from backup if schema/data was changed destructively
```

Postgres Pod rescheduled:

```bash
kubectl -n taskapp exec statefulset/postgres -- psql -U taskapp -d taskapp -c "select now();"
kubectl -n taskapp delete pod postgres-0
kubectl -n taskapp rollout status statefulset/postgres
kubectl -n taskapp exec statefulset/postgres -- psql -U taskapp -d taskapp -c "select now();"
```

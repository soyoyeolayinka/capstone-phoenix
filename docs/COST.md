# Cost

Estimates use AWS `us-east-2` on-demand pricing for the deployed student/demo environment.

## Monthly Itemized Cost

| Item | Spec | Qty | Estimated $/mo |
|---|---|---:|---:|
| control-plane VM | EC2 `t3.micro` Linux | 1 | 7.49 |
| worker VMs | EC2 `t3.micro` Linux | 2 | 14.98 |
| root block storage | 30 GiB gp3 per node | 3 | 7.20 |
| Postgres PVC | 10 GiB gp3 | 1 | 0.80 |
| load balancer / ingress | k3s ServiceLB on nodes | 0 | 0.00 |
| object storage for Terraform state | S3 small usage | 1 | 0.25 |
| DynamoDB lock table | on-demand minimal usage | 1 | 0.25 |
| DNS / domain | existing domain, Route 53 hosted zone estimate | 1 | 0.50 |
| **Total** | | | **31.47** |

## Compared To Single-Server Compose + Portainer

The single-server stack can run on one small VM, roughly $8 to $16/month depending on provider. This Kubernetes cluster is closer to $31/month because it pays for three nodes and extra storage. The extra spend buys real scheduling across machines, self-healing after a worker drain, rolling updates with no unavailable replicas, HPA-driven scaling, public TLS automation, and GitOps reconciliation. It is not worth it for a tiny app with low traffic, no uptime target, and no team operating requirements.

## How I Would Halve This

For a cheaper student/demo environment, I would move workers to spot instances or a lower-cost provider, reduce root volumes after measuring actual disk usage, and keep the control plane single-node as the brief allows. If production requirements allowed it, a two-node k3s cluster would lower cost further, but that would not satisfy this capstone because the instructor requires one control-plane plus two or more real worker nodes.

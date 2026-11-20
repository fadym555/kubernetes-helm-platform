# kubernetes-helm-platform

[![CI](https://github.com/fadym555/kubernetes-helm-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/fadym555/kubernetes-helm-platform/actions/workflows/ci.yml)

A Helm chart built the way I'd ship a service to a production cluster, plus a pipeline that actually deploys it to a real 3-node Kubernetes cluster on every push and proves it behaves: it scales, it serves traffic through ingress, it updates without dropping requests, and it rolls back cleanly.

The sample workload is [podinfo](https://github.com/stefanprodan/podinfo), a small Go web app that's common for this kind of demo. Swap the image and you have a chart for your own service.

## What the chart gives you

| Concern | How it's handled |
|---|---|
| Availability | HPA (CPU based), PodDisruptionBudget, topology spread across nodes, `maxUnavailable: 0` rolling updates |
| Graceful shutdown | preStop delay so the ingress stops sending traffic before the pod exits |
| Health | Separate readiness and liveness probes |
| Security | Non-root, read-only root filesystem, all capabilities dropped, seccomp RuntimeDefault, no service account token |
| Network | Default-deny NetworkPolicy: only the ingress controller and labelled clients can reach the pods |
| Config | ConfigMap with a checksum annotation, so config changes roll the pods automatically |
| Environments | `environments/staging.yaml` and `environments/production.yaml` (TLS, more replicas, higher limits) |

## What CI does

**Lint, render & policy scan**
- `helm lint --strict` with every environment's values
- Renders the manifests and validates them against the Kubernetes API schemas with kubeconform
- Trivy policy scan of the rendered manifests, failing on any high or critical finding

**Deploy to a 3-node cluster & verify** (kind: 1 control plane + 2 workers)
1. Installs ingress-nginx and metrics-server
2. Installs the chart with staging values and waits for the HPA to bring it to its minimum replicas
3. Runs `helm test` (readiness and the configured response, through the Service)
4. Calls the app through the ingress
5. **Zero-downtime check:** sends a request every 100ms through the ingress while upgrading to a new image. The job fails if a single request fails
6. **Rollback:** `helm rollback` to the first release and confirms the original image is back

## Use it

```bash
helm upgrade --install webapp charts/webapp \
  -f environments/production.yaml \
  -n production --create-namespace --wait
```

Run the same checks locally:

```bash
kind create cluster --config kind/cluster.yaml
# then follow the steps in .github/workflows/ci.yml
```

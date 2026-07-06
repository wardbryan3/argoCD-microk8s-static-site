# GitOps Static Site — Learn ArgoCD on MicroK8s

A GitOps-deployed static site on MicroK8s using ArgoCD.

## Stack

- **Kubernetes** – MicroK8s (Deployments, Services, ConfigMaps)
- **GitOps** – ArgoCD (auto-sync, self-healing)
- **Kustomize** – ConfigMap generation, multi-resource management
- **Web Server** – nginx:alpine
- **Networking** – NodePort exposure

## Architecture

```
Developer → Git Push (GitHub) → ArgoCD Syncs → MicroK8s → Browser
```

## Project Structure

| File | Purpose |
|------|---------|
| `index.html` | Static site content |
| `deployment.yaml` | Deployment + NodePort Service |
| `kustomization.yaml` | Kustomize build config |
| `service-nodeport.yaml` | Standalone NodePort service |

## Key Insight

`kustomization.yaml` uses `configMapGenerator` to inject `index.html` into pods, keeping the deployment clean and updates simple.

## Access

```
http://<host-ip>:31234
```

## What I Learned

- **Kubernetes fundamentals**: Deployments, Services (ClusterIP vs NodePort), ConfigMaps, Pods
- **ArgoCD**: Application CRD, sync policies, self-healing, Git as source of truth
- **Kustomize**: ConfigMap generation, resource composition
- **Containerization**: Building and pushing Docker images to a local registry
- **GitOps pipeline**: `git push` → ArgoCD detects → cluster reconciles automatically
- **Troubleshooting**: Drift correction, pod debugging, networking issues

---

For a hands-on walkthrough, see [TUTORIAL.md](./TUTORIAL.md).

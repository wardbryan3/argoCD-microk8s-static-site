# Tutorial — Deploy a Static Site with ArgoCD on MicroK8s

A step-by-step walkthrough of the full GitOps workflow — from Docker build to auto-syncing cluster deployment.

> For a conceptual overview, see [README.md](./README.md).

## Prerequisites

- A Kubernetes cluster (recommended: **MicroK8s** — `sudo snap install microk8s --classic`)
- `docker` installed
- A GitHub account

## 1. Fork & Clone

```bash
git clone https://github.com/<your-username>/<your-fork>.git
cd <your-fork>
```

## 2. Set Up Your Kubernetes Cluster

Enable the registry add-on (for local image pushing):

```bash
microk8s enable registry
```

Verify `microk8s kubectl` is configured:

```bash
microk8s kubectl get nodes
```

## 3. Build & Push the Docker Image

```bash
docker build -t localhost:32000/my-static-site:v1.0.1 .
docker push localhost:32000/my-static-site:v1.0.1
```

This packages `index.html` into an nginx:alpine image and pushes it to your local registry.

> If using a cloud registry (Docker Hub, GHCR), tag accordingly and update `deployment.yaml`.

## 4. Install ArgoCD

```bash
microk8s kubectl create namespace argocd
microk8s kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
microk8s kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
microk8s kubectl get pods -n argocd
```

## 5. Access ArgoCD

```bash
# Port-forward the ArgoCD server
microk8s kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get the admin password
microk8s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login via CLI
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure
```

Open `https://localhost:8080` in your browser (username: `admin`, password: from above).

## 6. Deploy the Application

**Option A: ArgoCD CLI**

```bash
argocd app create static-site \
  --repo https://github.com/<your-username>/<your-fork> \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy auto \
  --auto-prune \
  --self-heal

argocd app sync static-site
argocd app get static-site
```

**Option B: Declarative (recommended for GitOps)**

Create `argocd-application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: static-site
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<your-username>/<your-fork>
    targetRevision: main
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

Apply it:

```bash
microk8s kubectl apply -f argocd-application.yaml
```

## 7. Access Your Site

```bash
# Runs in background
microk8s kubectl port-forward svc/static-site-service 8080:80 &
```

Or via NodePort (port **31234**):

```
http://<host-ip>:31234
```

## The GitOps Workflow — Try It Yourself

This is the core lesson. Once deployed, ArgoCD continuously monitors your fork.

1. **Edit the site:**
   ```bash
   vim index.html
   ```

2. **Rebuild and push the image:**
   ```bash
   docker build -t localhost:32000/my-static-site:v2 .
   docker push localhost:32000/my-static-site:v2
   ```
   Then update the image tag in `deployment.yaml`.

3. **Commit and push:**
   ```bash
   git add .
   git commit -m "Update site content"
   git push origin main
   ```

4. **Watch ArgoCD reconcile:**
   ```bash
   argocd app get static-site --watch
   ```

Within minutes (3min default sync interval), ArgoCD detects the drift and your site updates automatically. That's GitOps.

## Troubleshooting

**ArgoCD Not Syncing:**

```bash
argocd app refresh static-site
argocd app sync static-site
argocd app logs static-site
```

**Pods Not Starting:**

```bash
microk8s kubectl get pods
microk8s kubectl describe pod <pod-name>
microk8s kubectl logs <pod-name>
```

**Connection Refused:**

```bash
ps aux | grep "port-forward"
microk8s kubectl port-forward svc/static-site-service 8080:80 &
```

## Monitoring

**CLI:**

```bash
argocd app get static-site
argocd app get static-site --watch
argocd app history static-site
argocd app manifests static-site
```

**UI:** Open `https://localhost:8080`, click `static-site`, and explore the visual deployment tree.

## Extending the Project

### Customize the Dockerfile

The existing `Dockerfile` is minimal nginx:

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Try swapping the web server, adding assets, or using multi-stage builds:

```dockerfile
FROM caddy:alpine
COPY . /usr/share/caddy/
EXPOSE 80
```

After editing, rebuild and push:

```bash
docker build -t localhost:32000/my-static-site:v2 .
docker push localhost:32000/my-static-site:v2
```

Then update the image tag in `deployment.yaml` and push to let ArgoCD roll out the new version.

### Try More Advanced Patterns

- Switch to a cloud registry (Docker Hub, GHCR) instead of local MicroK8s registry
- Use `configMapGenerator` in `kustomization.yaml` to inject `index.html` without rebuilding the image
- Add Ingress for domain-based routing
- Set up notifications (Slack, email) for sync events

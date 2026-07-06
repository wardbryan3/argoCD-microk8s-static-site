# ArgoCD MicroK8s Static Site

A GitOps-deployed static site on MicroK8s using ArgoCD.

## Stack

- **Kubernetes** – MicroK8s (Deployments, Services, ConfigMaps)
- **GitOps** – ArgoCD (auto-sync, self-healing)
- **Kustomize** – ConfigMap generation, multi-resource management
- **Web Server** – nginx:alpine
- **Networking** – NodePort exposure

## Architecture

```
Your Local Machine/VM
    ↓
1. Build Docker Image
    ↓
2. Push to Registry (Docker Hub / Local)
    ↓
3. Update deployment.yaml with new image
    ↓
4. Git Push to GitHub
    ↓
5. ArgoCD Detects Change
    ↓
6. ArgoCD Pulls New Image
    ↓
7. MicroK8s Deploys Updated Containers
    ↓
8. Your Site Updates Automatically! 🎉
```

## Project Structure

| File | Purpose |
|------|---------|
| `index.html` | Static site content |
| `Dockerfile` | Container image build config (nginx:alpine) |
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
- **Troubleshooting**: YAML indentation, networking (firewall, NodePort), ArgoCD drift correction
- **GitOps pipeline**: Git push → ArgoCD detects → cluster reconciles

## How to Deploy

### 1. Build & push the Docker image

```bash
docker build -t localhost:32000/my-static-site:v1 .
docker push localhost:32000/my-static-site:v1
```

This uses the included `Dockerfile` to package `index.html` into an nginx:alpine image, then pushes it to the local MicroK8s registry.

### 2. Deploy to Kubernetes

**Using Kustomize (manually):**

```bash
kubectl apply -k .
```

This applies the Deployment (2 replicas running the nginx image) and the NodePort Service (port 31234) defined in `deployment.yaml`.

**Using ArgoCD (GitOps):**

```bash
argocd app create static-site \
  --repo https://github.com/your-org/your-repo.git \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

ArgoCD will detect changes on every `git push` and reconcile the cluster automatically.

### 3. Access the site

```
http://<host-ip>:31234
```

Replace `<host-ip>` with the IP of your MicroK8s node.

---

## Creating Your Own Dockerfile

The existing `Dockerfile` is a minimal nginx setup:

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

You can customize it freely:

- **Swap the web server** – replace nginx with Caddy, Apache, or a Node.js server (express, serve).
- **Add more assets** – copy a `css/`, `js/`, or `images/` directory.
- **Multi-stage builds** – build a frontend app (React, Vue, etc.) in one stage and serve it in the final stage.
- **Custom nginx config** – copy an `nginx.conf` for advanced routing or caching.

Example with Caddy:

```dockerfile
FROM caddy:alpine
COPY . /usr/share/caddy/
EXPOSE 80
```

After editing `Dockerfile`, rebuild and push:

```bash
docker build -t localhost:32000/my-static-site:v2 .
docker push localhost:32000/my-static-site:v2
```

Then update the image tag in `deployment.yaml` and let ArgoCD (or `kubectl apply -k .`) roll out the new version.

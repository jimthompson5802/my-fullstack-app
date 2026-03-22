# Kubernetes Deployment Guide

This guide explains how to deploy the fullstack application to a local Kubernetes cluster (minikube, kind, or Docker Desktop).

## Network Architecture

The application uses **NodePort services** for local development:

- **Frontend**: Accessible at `http://localhost:30300` (NodePort 30300)
- **Backend**: Accessible at `http://localhost:30800` (NodePort 30800)

### Why NodePort?

The frontend's JavaScript runs **in the browser**, not in the Kubernetes cluster. Therefore:
- The browser cannot resolve Kubernetes internal DNS names (like `http://backend-service:8000`)
- The frontend must use `http://localhost:30800` to reach the backend API
- This URL is baked into the JavaScript bundle at build time via webpack's DefinePlugin
- CORS is configured to allow requests from `http://localhost:30300`

## Prerequisites

Before deploying, ensure you have:

1. **Docker** installed and running
2. **kubectl** installed
3. A **local Kubernetes cluster** running:
   - **Docker Desktop**: Enable Kubernetes in Docker Desktop settings
   - **minikube**: Run `minikube start`
   - **kind**: Run `kind create cluster`

Verify your cluster is ready:
```bash
kubectl cluster-info
kubectl get nodes
```

## Build Docker Images

Build both images with the correct configuration:

### 1. Build Backend Image

The backend installs dependencies from `pyproject.toml`:

```bash
docker build -t my-fullstack-backend:latest ./backend
```

### 2. Build Frontend Image

**CRITICAL**: The frontend must be built with the NodePort URL for the backend:

```bash
docker build \
  --build-arg API_BASE_URL=http://localhost:30800 \
  -t my-fullstack-frontend:latest \
  ./frontend
```

This `API_BASE_URL` is injected into the JavaScript bundle and determines where the browser sends API requests.

### Verify Images

```bash
docker images | grep my-fullstack
```

You should see both `my-fullstack-backend:latest` and `my-fullstack-frontend:latest`.

## Deploy to Kubernetes

### Create Namespace

First, create the dedicated namespace for the application:

```bash
kubectl create namespace my-fullstack-app
```

Verify the namespace was created:

```bash
kubectl get namespaces
```

### Deploy Application

Apply all manifests from the `k8s/` directory:

```bash
# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

Or apply all at once:

```bash
kubectl apply -f k8s/
```

## Verify Deployment

### Check Pod Status

```bash
kubectl get pods -n my-fullstack-app
```

Wait until both pods show `STATUS: Running`:
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxxxxxxxxx-xxxxx    1/1     Running   0          30s
frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

### Check Services

```bash
kubectl get services -n my-fullstack-app
```

You should see:
```
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
backend-service    NodePort    10.x.x.x        <none>        8000:30800/TCP   1m
frontend-service   NodePort    10.x.x.x        <none>        80:30300/TCP     1m
```

### View Logs

```bash
# Backend logs
kubectl logs -l app=backend -n my-fullstack-app -f

# Frontend logs
kubectl logs -l app=frontend -n my-fullstack-app -f
```

## Access the Application

Open your browser and navigate to:

**Frontend**: http://localhost:30300

The calculator UI should load and be able to communicate with the backend at `http://localhost:30800`.

### Test Backend API Directly

```bash
curl http://localhost:30800/
# Should return: {"message":"Welcome to the calculator backend API!"}

curl -X POST http://localhost:30800/api/compute \
  -H "Content-Type: application/json" \
  -d '{"x": "10", "y": "5", "op": "add"}'
# Should return: {"result":"15"}
```

## Troubleshooting

### Pods Not Starting

Check pod details:
```bash
kubectl describe pod <pod-name> -n my-fullstack-app
```

Common issues:
- **ImagePullBackOff**: Ensure `imagePullPolicy: Never` is set in deployments (for local images)
- **CrashLoopBackOff**: Check logs with `kubectl logs <pod-name>`

### CORS Errors

If the frontend shows CORS errors in the browser console:
1. Verify the backend pod has the `CORS_ORIGINS` environment variable set:
   ```bash
   kubectl exec -it <backend-pod-name> -n my-fullstack-app -- env | grep CORS
   ```
   Should show: `CORS_ORIGINS=http://localhost:30300`

2. Check backend logs for CORS-related messages

### Cannot Access Services

Verify NodePort services are exposed:
```bash
kubectl get svc -n my-fullstack-app
```

For **minikube**, you may need to use `minikube service` commands:
```bash
minikube service frontend-service --url
minikube service backend-service --url
```

## Update Deployment

To update after code changes:

1. Rebuild the Docker image(s)
2. Restart the deployment:
   ```bash
   kubectl rollout restart deployment/backend -n my-fullstack-app
   kubectl rollout restart deployment/frontend -n my-fullstack-app
   ```

## Clean Up

Remove all Kubernetes resources:

```bash
kubectl delete -f k8s/
```

Or delete the entire namespace (removes all resources in it):
```bash
kubectl delete namespace my-fullstack-app
```

Or delete individually:
```bash
kubectl delete deployment backend frontend -n my-fullstack-app
kubectl delete service backend-service frontend-service -n my-fullstack-app
```

## Local Development vs Kubernetes

### Local Development (Existing Workflow)

```bash
# Backend (terminal 1)
cd backend
uv run uvicorn src.main:app --reload

# Frontend (terminal 2)
cd frontend
npm start
```

- Frontend runs at `http://localhost:3000`
- Backend runs at `http://localhost:8000`
- No Docker or Kubernetes required

### Kubernetes Deployment (This Guide)

```bash
# Build images
docker build -t my-fullstack-backend:latest ./backend
docker build --build-arg API_BASE_URL=http://localhost:30800 -t my-fullstack-frontend:latest ./frontend

# Deploy
kubectl apply -f k8s/
```

- Frontend accessible at `http://localhost:30300`
- Backend accessible at `http://localhost:30800`
- Runs in containerized Kubernetes environment

Both workflows are fully supported and independent.

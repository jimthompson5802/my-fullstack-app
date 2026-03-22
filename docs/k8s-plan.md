## Plan: Add Kubernetes Deployment Support

Adding Kubernetes deployment capabilities for local k8s clusters (minikube/kind/Docker Desktop) while preserving the existing local development workflow. The solution uses Dockerfiles and plain YAML manifests with NodePort services for local access.

**Key decisions:**
- Multi-stage Docker builds for optimized frontend images
- **NodePort services**: Frontend accessible at `http://localhost:30300`, backend at `http://localhost:30800`
- **Critical**: Frontend JavaScript runs in browser, so `API_BASE_URL` must use localhost NodePort URL, NOT k8s internal service names
- CORS configured to allow frontend NodePort origin (`http://localhost:30300`)
- **Backend dependencies**: Install from `backend/pyproject.toml` (NOT requirements.txt, which contains outdated Flask dependencies)
- Separate commands documented for each workflow

**Steps**

1. **Create backend Dockerfile** at `backend/Dockerfile`
   - Use Python 3.14+ base image (e.g., `python:3.14-slim`)
   - Set working directory to `/app`
   - Copy `backend/pyproject.toml` **only** (not requirements.txt)
   - **Install dependencies**: `pip install .` to install from pyproject.toml
   - Copy entire `backend/src/` application code
   - Expose port 8000
   - CMD to run uvicorn: `["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]`
   - Add `.dockerignore` to exclude `__pycache__/`, `*.egg-info/`, `venv/`, `.venv/`, `dist/`, `*.pyc`

2. **Create frontend Dockerfile** at `frontend/Dockerfile`
   - Multi-stage build:
     - **Stage 1 (builder)**: Node image (e.g., `node:20`)
       - Set working directory
       - Copy `package.json` and `package-lock.json`
       - Run `npm install`
       - Copy `tsconfig.json`, `webpack.config.js`, `src/`, `public/`
       - Build arg `API_BASE_URL` (defaults to `http://localhost:8000`)
       - **Run**: `API_BASE_URL=${API_BASE_URL} npm run build` (webpack DefinePlugin will inject it)
     - **Stage 2 (runtime)**: `nginx:alpine`
       - Copy built assets from Stage 1: `/dist/bundle.js` → `/usr/share/nginx/html/bundle.js`
       - Copy `public/index.html` → `/usr/share/nginx/html/index.html`
       - Configure nginx to serve static files on port 80
       - Add nginx.conf to serve index.html as fallback
   - Add `.dockerignore` to exclude `node_modules/`, `dist/`

3. **Create Kubernetes manifests** in new `k8s/` directory at project root
   
   **Backend manifests:**
   - `k8s/backend-deployment.yaml`:
     - Deployment with 1 replica
     - Health/liveness probes on root endpoint (`/`)
     - **Environment variable**: `CORS_ORIGINS=http://localhost:30300` (allows browser requests from frontend)
     - Container port 8000
   
   - `k8s/backend-service.yaml`:
     - **NodePort service** exposing port 8000
     - **NodePort: 30800** (browser will access backend at `http://localhost:30800`)
     - Service type: NodePort (not ClusterIP)
   
   **Frontend manifests:**
   - `k8s/frontend-deployment.yaml`:
     - Deployment with 1 replica
     - Container port 80 (nginx)
     - Image contains pre-built JavaScript with `API_BASE_URL=http://localhost:30800`
   
   - `k8s/frontend-service.yaml`:
     - **NodePort service** exposing port 80
     - **NodePort: 30300** (browser accesses frontend at `http://localhost:30300`)
     - Service type: NodePort (not ClusterIP)

4. **Update backend for environment-aware CORS** in `backend/src/main.py`
   - Read environment variable `CORS_ORIGINS` (default: `["*"]` for local dev)
   - Parse as comma-separated list if string, or use list directly
   - Pass to FastAPI CORS middleware `allow_origins` parameter
   - **Why needed**: Browser makes cross-origin requests from `http://localhost:30300` to `http://localhost:30800`

5. **Create deployment documentation** at `k8s/README.md`
   
   **Network architecture explanation:**
   - Frontend static files served from pod via NodePort 30300
   - Browser runs JavaScript that calls backend via NodePort 30800
   - **Cannot use k8s service DNS names** (`http://backend-service:8000`) because browser doesn't resolve k8s internal DNS
   - NodePort exposes services on host machine's localhost
   
   **Prerequisites:** 
   - Docker installed
   - kubectl installed
   - Local k8s cluster running (minikube/kind/Docker Desktop k8s)
   
   **Build images with correct API URL:**
   ```bash
   # Backend - install from pyproject.toml
   docker build -t my-fullstack-backend:latest ./backend
   
   # Frontend - CRITICAL: Use NodePort URL for backend
   # This URL is baked into the JavaScript bundle via webpack DefinePlugin
   docker build --build-arg API_BASE_URL=http://localhost:30800 \
     -t my-fullstack-frontend:latest ./frontend
# Calculator Full-Stack Application

A simple calculator web application with a React/TypeScript frontend and FastAPI/Python backend that performs precise decimal arithmetic.

## Features

- Perform basic arithmetic operations: add, subtract, multiply, divide
- Precise decimal arithmetic using Python's Decimal class
- Clean UI with input validation
- Comprehensive error handling

## Deployment Options

This application supports two deployment modes:

1. **Local Development** - Run the frontend and backend directly on your machine using Node.js and Python
2. **Kubernetes Deployment** - Deploy to a local or remote Kubernetes cluster using Docker containers and NodePort services

Choose the appropriate setup section below based on your needs.

---

## Local Development Setup

### Prerequisites

- Python 3.14+ with uv package manager
- Node.js and npm

### Backend Setup

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```

2. Install dependencies using uv:
   ```bash
   uv pip install -e .
   ```

3. Run the development server:
   ```bash
   uv run uvicorn src.main:app --reload --port 8000
   ```

The backend API will be available at `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`

### Frontend Setup

1. Navigate to the `frontend` directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm start
   ```

The frontend will be available at `http://localhost:3000`

### Testing the Local Development Setup

1. Start the backend server (see Backend Setup above)
2. Start the frontend server (see Frontend Setup above)
3. Navigate to `http://localhost:3000`
4. Enter values in the X and Y fields
5. Select an operation
6. Click "Compute"
7. View the result in the Answer field

---

## Kubernetes Deployment

The application can be deployed to a local Kubernetes cluster (Docker Desktop, minikube, kind) or a remote cluster.

### Prerequisites

- Docker installed and running
- kubectl installed
- A Kubernetes cluster running (Docker Desktop with Kubernetes enabled, minikube, or kind)

### Quick Start

1. **Build Docker images:**

   ```bash
   # Build backend image
   docker build -t my-fullstack-backend:latest ./backend

   # Build frontend image with NodePort URL for local k8s
   docker build --build-arg API_BASE_URL=http://localhost:30800 \
     -t my-fullstack-frontend:latest ./frontend
   ```

2. **Create namespace:**

   ```bash
   kubectl create namespace my-fullstack-app
   ```

3. **Deploy to cluster:**

   ```bash
   kubectl apply -f k8s/
   ```

4. **Access the application:**

   - Frontend: `http://localhost:30300`
   - Backend API: `http://localhost:30800`
   - API Docs: `http://localhost:30800/docs`

### Detailed Instructions

For complete Kubernetes deployment instructions, including:
- Network architecture details
- NodePort service configuration
- Troubleshooting steps
- Verification commands
- Cleanup instructions

See the [k8s/README.md](k8s/README.md) deployment guide.

---

## Project Structure

```
my-fullstack-app/
├── backend/
│   ├── src/
│   │   ├── main.py          # FastAPI application and /api/compute endpoint
│   │   ├── models/          # Pydantic models for request/response
│   │   └── services/        # Business logic (compute function)
│   ├── pyproject.toml       # Python dependencies
│   ├── requirements.txt
│   └── Dockerfile           # Backend container image
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── App.tsx      # Main app component
│   │   │   └── Calculator.tsx  # Calculator UI component
│   │   ├── types/
│   │   │   └── api.ts       # TypeScript type definitions
│   │   └── index.ts         # Entry point
│   ├── public/
│   │   └── index.html       # HTML template
│   ├── package.json         # Node dependencies
│   ├── tsconfig.json        # TypeScript configuration
│   ├── webpack.config.js    # Webpack configuration
│   └── Dockerfile           # Frontend container image
├── k8s/
│   ├── backend-deployment.yaml   # Backend Kubernetes deployment
│   ├── backend-service.yaml      # Backend NodePort service
│   ├── frontend-deployment.yaml  # Frontend Kubernetes deployment
│   ├── frontend-service.yaml     # Frontend NodePort service
│   └── README.md            # Detailed K8s deployment guide
└── docs/
    └── system-spec.md       # Full system specification
```

## API Endpoint

### POST /api/compute

Request:
```json
{
  "x": "12.5",
  "y": "3.25",
  "op": "add"
}
```

Response (success):
```json
{
  "result": "15.75"
}
```

Response (error):
```json
{
  "error": "Division by zero",
  "code": "DIVIDE_BY_ZERO"
}
```

Supported operations: `add`, `subtract`, `multiply`, `divide`

## Error Handling

The application handles:

- Invalid input (non-numeric values)
- Division by zero
- Network errors
- Server errors

All errors are displayed as user-friendly messages in the Answer field.

## Implementation Details

See [docs/system-spec.md](docs/system-spec.md) for the complete system specification including:
- Detailed API contract
- Request/response schemas
- Error codes and status mappings
- Frontend validation requirements
- Backend implementation notes
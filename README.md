# kubernetes-demo

A minimal Node.js API containerized with Docker and deployed to Kubernetes. Built as a hands-on reference for learning container orchestration basics — image builds, deployments, services, health checks, and resource limits.

## What it does

The app is a single Express server that returns JSON identifying the pod it's running on:

```json
{
  "message": "Hello from a container",
  "service": "hello-node",
  "pod": "kubernetes-demo-api-6f8b9c7d5-x4k2m",
  "time": "2026-08-11T13:00:00.000Z"
}
```

It also exposes `/ready` and `/health` endpoints used by Kubernetes probes.

## Prerequisites

| Tool              | Purpose                        |
| ----------------- | ------------------------------ |
| **Node.js** ≥ 18  | Run the app locally            |
| **Docker**        | Build and push container image |
| **kubectl**       | Interact with the cluster      |
| **Minikube** *(or any K8s cluster)* | Run Kubernetes locally |

## Project structure

```
.
├── index.js                 # Express server (entry point)
├── package.json
├── Dockerfile               # Multi-stage production image
├── docker-compose.yaml      # Local dev with hot-reload
├── deploy.sh                # Build → push → apply manifests
└── k8s/
    ├── deployment.yaml      # 2-replica Deployment with probes & resource limits
    └── service.yaml         # NodePort Service
```

## Getting started

### Run locally (no containers)

```bash
npm install
npm run dev        # starts with --watch for auto-reload
```

The server listens on **http://localhost:6789** by default.

### Run with Docker Compose

```bash
docker compose up --build
```

This mounts the source directory and runs `npm run dev` inside the container, so file changes are picked up automatically.

### Deploy to Kubernetes

The included `deploy.sh` script handles the full workflow:

```bash
npm run deploy
```

Under the hood it:

1. Builds the Docker image as `s1r15h/kubernetes-demo-api:latest`
2. Pushes it to Docker Hub
3. Applies `k8s/deployment.yaml` and `k8s/service.yaml`
4. Prints the resulting pods and services

> **Note:** Update the `USERNAME` variable in `deploy.sh` and the `image` field in `k8s/deployment.yaml` if you're pushing to a different Docker Hub account.

#### Manual deployment

```bash
# Build & push
docker build -t <your-dockerhub-user>/kubernetes-demo-api:latest .
docker push <your-dockerhub-user>/kubernetes-demo-api:latest

# Apply manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Verify
kubectl get pods
kubectl get services
```

#### Access the service (Minikube)

```bash
minikube service kubernetes-demo-api-service
```

This opens a browser pointing to the NodePort. If running on a cloud provider, change `type: NodePort` to `type: LoadBalancer` in `k8s/service.yaml`.

## API reference

| Method | Path      | Description                              |
| ------ | --------- | ---------------------------------------- |
| GET    | `/`       | Returns JSON with pod name and timestamp |
| GET    | `/ready`  | Readiness probe — returns `200 ready`    |
| GET    | `/health` | Liveness probe — returns `200 healthy`   |

## Kubernetes configuration

The deployment is configured with:

- **2 replicas** for basic availability
- **Resource requests/limits** — 100m–500m CPU, 128Mi–512Mi memory
- **Readiness probe** — `GET /ready` every 10 s (initial delay 5 s)
- **Liveness probe** — `GET /health` every 20 s (initial delay 10 s)
- **`POD_NAME` env var** — injected via the Downward API so each pod can identify itself in responses

## Environment variables

| Variable   | Default | Description              |
| ---------- | ------- | ------------------------ |
| `PORT`     | `6789`  | Server listening port    |
| `NODE_ENV` | —       | Set to `production` in K8s |
| `POD_NAME` | `unknown` | Injected by the Downward API |

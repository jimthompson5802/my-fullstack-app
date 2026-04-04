# Generating K8s Manifests from CALM Architecture

This directory contains everything needed to generate Kubernetes deployment manifests from the CALM architecture file using the `calm template` command.

## Overview

The CALM architecture file ([my-fullstack-k8s.architecture.json](./my-fullstack-k8s.architecture.json)) stores all K8s deployment configuration in node metadata under the `k8s` property. Handlebars templates transform this metadata into actual K8s YAML manifests.

## Architecture Metadata Structure

Each service node contains K8s-specific metadata:

```json
{
  "unique-id": "frontend-web-app",
  "node-type": "service",
  "metadata": {
    "k8s": {
      "image": "my-fullstack-frontend:latest",
      "namespace": "my-fullstack-app",
      "replicas": 1,
      "containerPort": 80,
      "servicePort": 80,
      "nodePort": 30300,
      "imagePullPolicy": "IfNotPresent",
      "serviceName": "frontend-service",
      "deploymentName": "frontend",
      "appLabel": "frontend"
    }
  }
}
```

Backend nodes can include additional configuration like environment variables and health probes.

## Available Templates

- **`k8s-manifests.yaml.hbs`** - Combined template (generates all Deployments + Services in one file)
- **`k8s-deployment.yaml.hbs`** - Generates only Deployment manifests
- **`k8s-service.yaml.hbs`** - Generates only Service manifests
- **`dc-compose.yaml.hbs`** - Generates a `docker-compose` stack for local development

## Usage

### Generate All K8s Manifests

Generate complete K8s manifests (Deployments + Services) for all services:

```bash
calm template \
  -a docs/calm/my-fullstack-k8s.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o calm-generated-k8s/all-manifests.yaml
```

### Generate Deployments Only

```bash
calm template \
  -a docs/calm/my-fullstack-k8s.architecture.json \
  --template docs/calm/templates/k8s-deployment.yaml.hbs \
  -o calm-generated-k8s/deployments.yaml
```

### Generate Services Only

```bash
calm template \
  -a docs/calm/my-fullstack-k8s.architecture.json \
  --template docs/calm/templates/k8s-service.yaml.hbs \
  -o calm-generated-k8s/services.yaml
```

### Generate Docker Compose

Generate a `docker-compose` file representing the architecture for local testing:

```bash
calm template \
  -a docs/calm/my-fullstack-k8s.architecture.json \
  --template docs/calm/templates/dc-compose.yaml.hbs \
  -o calm-generated-dc/docker-compose.yml
```

Validate and run locally:

```bash
# Validate generated compose
docker compose -f calm-generated-dc/docker-compose.yml config

# Run the stack
docker compose -f calm-generated-dc/docker-compose.yml up -d

# Tear down
docker compose -f calm-generated-dc/docker-compose.yml down
```

## Validate Generated Manifests (Dry Run)

Before deploying, validate the generated manifests:

```bash
# Client-side validation (no cluster connection needed)
kubectl apply -f calm-generated-k8s/all-manifests.yaml --dry-run=client

# Server-side validation (requires cluster connection, more thorough)
kubectl apply -f calm-generated-k8s/all-manifests.yaml --dry-run=server

# Show what would be created without applying
kubectl diff -f calm-generated-k8s/all-manifests.yaml
```

## Deploy Generated Manifests

After validating manifests, deploy to your K8s cluster:

```bash
# Create namespace if it doesn't exist
kubectl create namespace my-fullstack-app

# Apply generated manifests
kubectl apply -f calm-generated-k8s/all-manifests.yaml

# Verify deployment
kubectl get all -n my-fullstack-app
```

## Benefits of This Approach

1. **Single Source of Truth**: Architecture file is the canonical source for deployment configuration
2. **Consistency**: All K8s manifests generated from same source ensure consistency
3. **Versioning**: Changes to deployment config are tracked in architecture file
4. **Documentation**: K8s configuration is self-documenting in the architecture model
5. **Validation**: CALM validation ensures architecture integrity before generating manifests
6. **DRY Principle**: Don't repeat deployment configuration across multiple files

## Updating Deployment Configuration

To change deployment settings (e.g., update image, change replica count):

1. Edit `docs/calm/my-fullstack-k8s.architecture.json`
2. Validate: `calm validate -a docs/calm/my-fullstack-k8s.architecture.json`
3. Regenerate: `calm template -a docs/calm/my-fullstack-k8s.architecture.json --template docs/calm/templates/k8s-manifests.yaml.hbs -o calm-generated-k8s/all-manifests.yaml`
4. Dry run: `kubectl apply -f calm-generated-k8s/all-manifests.yaml --dry-run=client`
5. Deploy: `kubectl apply -f calm-generated-k8s/all-manifests.yaml`

## Comparison with Static Manifests

| Aspect | Static YAML (k8s/) | Generated from CALM |
|--------|-------------------|---------------------|
| **Source of Truth** | Multiple YAML files | Architecture file |
| **Updates** | Update each file manually | Update architecture once |
| **Consistency** | Manual sync required | Automatically consistent |
| **Documentation** | Separate docs needed | Architecture is documentation |
| **Validation** | K8s validates at apply-time | CALM validates before generation |
| **Reusability** | Copy-paste pattern | Template-based generation |

## Example: Adding a New Service

To add a new microservice to the deployment:

1. Add node to architecture file with `metadata.k8s` properties
2. Run `calm template` command
3. Generated manifests automatically include the new service

No need to create and maintain separate YAML files!

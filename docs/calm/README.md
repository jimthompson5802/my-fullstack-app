# CALM Template Quick Start

## ✅ YES! This approach works perfectly with `calm template`

Your K8s manifests can now be generated from the CALM architecture file where image names and all deployment configuration are sourced from node metadata.

## What You Have Now

### 📋 Architecture File
[docs/calm/my-fullstack.architecture.json](./my-fullstack.architecture.json)
- Contains all K8s configuration in `metadata.k8s` for each service node
- Single source of truth for deployment settings
- CALM-validated before generation

### 🎨 Handlebars Templates  
[docs/calm/templates/](./templates/)
- `k8s-manifests.yaml.hbs` - Generates complete K8s manifests
- `k8s-deployment.yaml.hbs` - Deployment manifests only
- `k8s-service.yaml.hbs` - Service manifests only

### 📦 Generated Manifests
[k8s-calm-generated/all-manifests.yaml](../k8s-calm-generated/all-manifests.yaml)
- Auto-generated from architecture + template
- Ready to deploy: `kubectl apply -f k8s-calm-generated/all-manifests.yaml`

### 📏 K8s Metadata Standard
[docs/calm/standards/my-fullstack.standard.json](./standards/my-fullstack.standard.json)
- JSON Schema standard enforcing k8s metadata structure
- Validates presence of required properties: image, namespace, replicas, serviceName, deploymentName, appLabel
- Constrains optional properties: ports, environment variables, health probes
- Referenced via [url-mapping.json](./url-mapping.json) for validation

## Quick Commands

```bash
# 1. Validate architecture (with standard enforcement)
calm validate -a docs/calm/my-fullstack.architecture.json -u docs/calm/url-mapping.json

# 2. Generate K8s manifests
calm template \
  -a docs/calm/my-fullstack.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o k8s-calm-generated/all-manifests.yaml

# 3. Validate generated manifests (dry run)
kubectl apply -f k8s-calm-generated/all-manifests.yaml --dry-run=client

# 4. Deploy to K8s
kubectl apply -f k8s-calm-generated/all-manifests.yaml
```

## Example: Change Backend Image

Edit the architecture file:

```json
{
  "unique-id": "backend-api-service",
  "metadata": {
    "k8s": {
      "image": "my-fullstack-backend:v2.0",  // Changed!
      "replicas": 3,                          // Changed!
      // ... rest stays the same
    }
  }
}
```

Then regenerate:

```bash
calm template -a docs/calm/my-fullstack.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o k8s-calm-generated/all-manifests.yaml

kubectl apply -f k8s-calm-generated/all-manifests.yaml
```

## Key Benefits
✅ **Standard Enforcement** - K8s metadata structure validated via JSON Schema standard

## Standard Validation

The architecture uses a CALM standard to enforce proper k8s metadata structure on all service nodes.

### How It Works

1. **Standard Definition**: [standards/my-fullstack.standard.json](./standards/my-fullstack.standard.json) defines the required k8s metadata schema
2. **URL Mapping**: [url-mapping.json](./url-mapping.json) maps the canonical standard URL to the local file
3. **Architecture Reference**: Service nodes reference the standard via `$schema` in their metadata
4. **Validation**: The `-u` flag tells CALM CLI to use the URL mapping during validation

### Required Properties

All service nodes MUST include these k8s properties:
- `image` - Docker image name and tag
- `namespace` - Kubernetes namespace
- `replicas` - Number of pod replicas
- `serviceName` - Kubernetes service name
- `deploymentName` - Kubernetes deployment name
- `appLabel` - Application label for pod selection

### Optional Properties

These properties are validated but not required:
- `containerPort`, `servicePort`, `nodePort` - Port configurations
- `imagePullPolicy` - Must be "Always", "IfNotPresent", or "Never"
- `env` - Environment variables array
- `livenessProbe`, `readinessProbe` - Health check configurations

### Validation Command

Always validate with the URL mapping to enforce the standard:

```bash
calm validate -a docs/calm/my-fullstack.architecture.json -u docs/calm/url-mapping.json
```

**Expected output:**
```json
{
    "jsonSchemaValidationOutputs": [],
    "spectralSchemaValidationOutputs": [],
    "hasErrors": false,
    "hasWarnings": false
}
```

If a service node is missing required k8s properties or has invalid values, validation will fail with specific error messages.

✅ **Single Source of Truth** - Architecture file contains deployment config  
✅ **Version Controlled** - All changes tracked in architecture file  
✅ **Validated** - CALM validates before generation  
✅ **DRY** - Don't repeat yourself across multiple manifest files  
✅ **Self-Documenting** - K8s config is part of architecture model  
✅ **Template Reusability** - Same template works for any CALM architecture  

## Multi-Environment Support

You can create different architecture files for each environment:

```bash
docs/calm/
├── my-fullstack.dev.architecture.json      # Dev config
├── my-fullstack.staging.architecture.json  # Staging config
├── my-fullstack.prod.architecture.json     # Prod config
└── templates/
    └── k8s-manifests.yaml.hbs              # Shared template!
```

Generate for different environments:

```bash
# Development
calm template -a docs/calm/my-fullstack.dev.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o k8s-calm-generated/dev.yaml

# Production
calm template -a docs/calm/my-fullstack.prod.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o k8s-calm-generated/prod.yaml
```

## Next Steps

1. **Add more services**: Just add nodes with `metadata.k8s` to the architecture
2. **Customize templates**: Modify templates for ConfigMaps, Secrets, Ingress, etc.
3. **CI/CD Integration**: Automate manifest generation in your pipeline
4. **Pattern Creation**: Create a CALM pattern for reusable architecture templates

See [TEMPLATE-USAGE.md](./TEMPLATE-USAGE.md) for detailed documentation.

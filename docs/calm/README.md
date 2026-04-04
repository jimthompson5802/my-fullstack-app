# CALM Template Quick Start

## ✅ YES! This approach works perfectly with `calm template`

Your K8s manifests can now be generated from the CALM architecture file where image names and all deployment configuration are sourced from node metadata.

## What You Have Now

### 📋 Architecture File
[docs/calm/my-fullstack-k8s.architecture.json](./my-fullstack-k8s.architecture.json)
- Contains all K8s configuration in `metadata.k8s` for each service node
- Single source of truth for deployment settings
- CALM-validated before generation

### 🎨 Handlebars Templates  
[docs/calm/templates/](./templates/)
- `k8s-manifests.yaml.hbs` - Generates complete K8s manifests
- `k8s-deployment.yaml.hbs` - Deployment manifests only
- `k8s-service.yaml.hbs` - Service manifests only
- `dc-compose.yaml.hbs` - Generates a docker-compose stack for local testing

### 📦 Generated Manifests
- [calm-generated-k8s/all-manifests.yaml](../calm-generated-k8s/all-manifests.yaml)
  - Auto-generated from architecture + template
  - Ready to deploy: `kubectl apply -f calm-generated-k8s/all-manifests.yaml`
- [calm-generated-dc/docker-compose.yml](../calm-generated-dc/docker-compose.yml)
  - Generated docker-compose file for local development and testing
  - Ready to run: `docker compose -f calm-generated-dc/docker-compose.yml up -d`

### 📏 K8s Metadata Standard
[docs/calm/standards/my-fullstack.standard.json](./standards/my-fullstack.standard.json)
- JSON Schema standard enforcing k8s metadata structure
- Validates presence of required properties: image, namespace, replicas, serviceName, deploymentName, appLabel
- Constrains optional properties: ports, environment variables, health probes
- **Reused by pattern** - Pattern references this standard via `$ref` for centralized maintenance

### 🎯 Architecture Pattern
[docs/calm/patterns/my-fullstack.pattern.json](./patterns/my-fullstack.pattern.json)
- Validates complete architecture structure (nodes, relationships)
- References the k8s metadata standard for service nodes
- Enforces that service nodes have proper k8s metadata
- Referenced via [url-mapping.json](./url-mapping.json) for validation

## Quick Commands

```bash
# 1. Validate architecture (pattern + standard enforcement)
calm validate -p docs/calm/patterns/my-fullstack.pattern.json \
              -a docs/calm/my-fullstack-k8s.architecture.json \
              -u docs/calm/url-mapping.json

# 2. Generate K8s manifests
calm template \
  -a docs/calm/my-fullstack-k8s.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o calm-generated-k8s/all-manifests.yaml

# 3. Validate generated manifests (dry run)
kubectl apply -f calm-generated-k8s/all-manifests.yaml --dry-run=client

# 4. Deploy to K8s
kubectl apply -f calm-generated-k8s/all-manifests.yaml
```

### Docker Compose (local)

```bash
# 1. Generate docker-compose file from the architecture
calm template \
  -a docs/calm/my-fullstack-k8s.architecture.json \
  --template docs/calm/templates/dc-compose.yaml.hbs \
  -o calm-generated-dc/docker-compose.yml

# 2. Validate generated compose file
docker compose -f calm-generated-dc/docker-compose.yml config

# 3. Run the stack locally
docker compose -f calm-generated-dc/docker-compose.yml up -d

# 4. Tear down
docker compose -f calm-generated-dc/docker-compose.yml down
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
calm template -a docs/calm/my-fullstack-k8s.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o calm-generated-k8s/all-manifests.yaml

kubectl apply -f calm-generated-k8s/all-manifests.yaml
```

✅ **Centralized Standards** - Pattern reuses standard file via `$ref` for DRY principle

## Pattern & Standard Validation

The architecture uses **both** a pattern and a standard for comprehensive validation:

### Pattern-Based Validation
[patterns/my-fullstack.pattern.json](./patterns/my-fullstack.pattern.json) validates:
- Architecture structure (minimum 2 nodes, relationships)
- Service nodes must have metadata
- Service nodes metadata must conform to the k8s standard (via `$ref`)

### Standard-Based Validation
[standards/my-fullstack.standard.json](./standards/my-fullstack.standard.json) defines:
- Required k8s properties: image, namespace, replicas, serviceName, deploymentName, appLabel
- Optional properties with constraints: ports (ranges), imagePullPolicy (enum), env, probes
- **Reused by the pattern** - Single source of truth for k8s metadata structure

### Composition Architecture

```
Pattern (structure)
  └─> References Standard (metadata)
        └─> Defines k8s schema

URL Mapping resolves both references to local files
```

### How It Works

1. **Pattern defines structure**: The pattern specifies that service nodes must have metadata
2. **Pattern references standard**: Instead of duplicating the k8s schema, the pattern uses `$ref` to reference the standard
3. **Standard defines metadata**: The standard file contains the actual k8s metadata schema with all constraints
4. **URL mapping resolves both**: The url-mapping.json file resolves both the pattern's standard reference and any other URLs to local files
Validate with both pattern and standard enforcement:

```bash
calm validate -p docs/calm/patterns/my-fullstack.pattern.json \
              -a docs/calm/my-fullstack-k8s.architecture.json \
              -u docs/calm/url-mapping.json
```

**What gets validated:**
- ✅ Pattern validates architecture structure
- ✅ Pattern enforces service nodes have metadata
- ✅ Standard (via pattern `$ref`) validates k8s metadata properties
- ✅ All required k8s properties present
- ✅ All optional properties have correct types/ranges Required Properties

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
calm validate -a docs/calm/my-fullstack-k8s.architecture.json -u docs/calm/url-mapping.json
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
  -o calm-generated-k8s/dev.yaml

# Production
calm template -a docs/calm/my-fullstack.prod.architecture.json \
  --template docs/calm/templates/k8s-manifests.yaml.hbs \
  -o calm-generated-k8s/prod.yaml
```

## Next Steps

1. **Add more services**: Just add nodes with `metadata.k8s` to the architecture
2. **Customize templates**: Modify templates for ConfigMaps, Secrets, Ingress, etc.
3. **CI/CD Integration**: Automate manifest generation in your pipeline
4. **Pattern Creation**: Create a CALM pattern for reusable architecture templates

See [TEMPLATE-USAGE.md](./TEMPLATE-USAGE.md) for detailed documentation.

## PDF Generation

Pandoc 3.x can emit an `alt={...}` option on `\includegraphics` for images; LaTeX's `graphicx`/`keyval` parser doesn't recognize `alt` and will error with "Package keyval Error: alt undefined." Use the `mermaid-filter` together with the `add-image-alt.lua` filter to define `alt` as a no-op at the LaTeX level and generate PDFs reliably.

Example command:

```bash
pandoc docs/calm/ci-cd-pipeline-architecture.md \
  --filter mermaid-filter \
  --lua-filter docs/calm/add-image-alt.lua \
  -o docs/calm/ci-cd-pipeline-architecture.pdf
```

Notes:
- The `add-image-alt.lua` filter injects a raw LaTeX header that declares `alt` as a no-op key for the Gin (graphicx) key family.
- This approach is reusable for other docs that include images produced by filters (e.g., mermaid).

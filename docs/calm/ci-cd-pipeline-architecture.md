---
architecture: ci-cd-process.architecture.json
---

## Architecture Overview
```mermaid
---
config:
  theme: base
  themeVariables:
    fontFamily: -apple-system, BlinkMacSystemFont, 'Segoe WPC', 'Segoe UI', system-ui, 'Ubuntu', sans-serif
    darkMode: false
    fontSize: 14px
    edgeLabelBackground: '#d5d7e1'
    lineColor: '#000000'
---
%%{init: {"layout": "elk", "flowchart": {"htmlLabels": false}}}%%
flowchart TB
classDef boundary fill:#e1e4f0,stroke:#204485,stroke-dasharray: 5 4,stroke-width:1px,color:#000000;
classDef node fill:#eef1ff,stroke:#007dff,stroke-width:1px,color:#000000;
classDef iface fill:#f0f0f0,stroke:#b6b6b6,stroke-width:1px,font-size:10px,color:#000000;
classDef highlight fill:#fdf7ec,stroke:#f0c060,stroke-width:1px,color:#000000;
classDef actor fill:#eef1ff,stroke:#007dff,stroke-width:1px,color:#000000;
classDef database fill:#eef1ff,stroke:#2052a2,stroke-width:1px,color:#000000;
classDef webclient fill:#eef1ff,stroke:#156edf,stroke-width:1px,color:#000000;
classDef service fill:#eef1ff,stroke:#1c60c0,stroke-width:1px,color:#000000;
classDef messagebus fill:#eef1ff,stroke:#1c60c0,stroke-width:1px,color:#000000;
classDef system fill:#eef1ff,stroke:#204485,stroke-width:1px,color:#000000;

        subgraph application-system["Application System"]
        direction TB
            architecture-file["Architecture File"]:::node
        end
        class application-system boundary
        subgraph approved-architecture-patterns-standards-controls["Approved Architecture Patterns/Standards/Controls"]
        direction TB
            approved-controls["Approved Controls"]:::node
            approved-standards["Approved Standards"]:::node
            pattern-file["Pattern File"]:::node
        end
        class approved-architecture-patterns-standards-controls boundary
        subgraph ci-cd-pipeline["CI/CD Pipeline"]
        direction TB
            dc-template["Docker Compose Template"]:::node
            dc-compose-output["Generated Docker Compose File"]:::node
            k8s-manifest-output["Generated Kubernetes Manifests"]:::node
            k8s-template["Kubernetes Manifest Template"]:::node
            pipeline-orchestrator[/"⚙️ Pipeline Orchestrator"/]:::service
            url-mapping["URL Mapping"]:::node
                subgraph application-deployment["Application Deployment"]
                direction TB
                    deployer[/"⚙️ Deployer"/]:::service
                end
                class application-deployment boundary
                subgraph architecture-validation["Architecture Validation"]
                direction TB
                    calm-cli-validation[/"⚙️ CALM CLI Validation"/]:::service
                end
                class architecture-validation boundary
                subgraph deployment-generation["Deployment Generation"]
                direction TB
                    calm-cli-templating[/"⚙️ CALM CLI Templating"/]:::service
                end
                class deployment-generation boundary
        end
        class ci-cd-pipeline boundary

    deployment-operator([👤 Deployment Operator]):::actor
    docker-engine[🏢 Docker Engine]:::system
    kubernetes-cluster[🏢 Kubernetes Cluster]:::system

    deployment-operator -->|Deployment Operator interacts with the Pipeline Orchestrator to initiate pipeline execution| pipeline-orchestrator
    pipeline-orchestrator -->|Pipeline Orchestrator delegates deployment of generated artifacts to the Deployer| deployer
    pipeline-orchestrator -->|Pipeline Orchestrator delegates deployment artifact generation to the Deployment Generation system| calm-cli-templating
    pipeline-orchestrator -->|Pipeline Orchestrator invokes the CALM CLI to perform architecture validation| calm-cli-validation
    calm-cli-templating -->|CALM CLI uses its templating engine to render the architecture into Kubernetes manifests via the Generate Kubernetes Deployment service| k8s-manifest-output
    calm-cli-templating -->|CALM CLI uses its templating engine to render the architecture into a Docker Compose file via the Generate Docker-Compose Deployment service| dc-compose-output
    architecture-file -->|Reads and validates the architecture from| calm-cli-validation
    pattern-file -->|Reads the structural pattern constraints from| calm-cli-validation
    url-mapping -->|Resolves schema $ref URLs using| calm-cli-validation
    k8s-template -->|Reads the Kubernetes manifest Handlebars template from| calm-cli-templating
    dc-template -->|Reads the Docker Compose Handlebars template from| calm-cli-templating
    deployer -->|Deployer reads the generated Kubernetes manifests to apply to the cluster| k8s-manifest-output
    deployer -->|Deployer reads the generated Docker Compose file to start services on the Docker engine| dc-compose-output
    deployer -->|Applies generated manifests to| kubernetes-cluster
    deployer -->|Starts services defined in the generated compose file on| docker-engine



```

## Nodes
### Name: Deployment Operator  Type: actor

Developer or CI runner that invokes the validate-and-deploy script

---
### Name: CI/CD Pipeline  Type: system

System that packages the CALM CLI, template data assets, and URL mapping used for architecture validation and rendering

---
### Name: Approved Architecture Patterns/Standards/Controls  Type: system

System that groups the approved architecture and pattern artifacts used as the source of truth for validation

---
### Name: Application System  Type: system

System representing the application architecture definition that is validated and deployed by the CI/CD process

---
### Name: Pipeline Orchestrator  Type: service

Service that orchestrates the validate-and-deploy pipeline steps on behalf of the Deployment Operator

---
### Name: Deployer  Type: service

Service responsible for applying generated deployment artifacts to the target infrastructure

---
### Name: CALM CLI Validation  Type: service

FINOS CALM CLI tool that validates architectures against approved patterns and renders architecture templates into deployment manifests

---
### Name: Architecture File  Type: data-asset

CALM architecture JSON file describing the system to be deployed (e.g. my-fullstack-k8s.architecture.json)

---
### Name: Pattern File  Type: data-asset

CALM pattern JSON file defining the structural constraints the architecture must conform to (docs/calm/patterns/my-fullstack.pattern.json)

---
### Name: Approved Standards  Type: data-asset

Approved standards artifacts used as part of the source of truth for architecture validation

---
### Name: Approved Controls  Type: data-asset

Approved control artifacts used as part of the source of truth for architecture validation

---
### Name: URL Mapping  Type: data-asset

JSON file mapping schema $ref URLs to local file paths, used during validation (docs/calm/url-mapping.json)

---
### Name: Kubernetes Manifest Template  Type: data-asset

Handlebars template rendered by the CALM CLI into a Kubernetes manifest file (docs/calm/templates/k8s-manifests.yaml.hbs)

---
### Name: Docker Compose Template  Type: data-asset

Handlebars template rendered by the CALM CLI into a Docker Compose file (docs/calm/templates/dc-compose.yaml.hbs)

---
### Name: Generated Kubernetes Manifests  Type: data-asset

Kubernetes manifest YAML file generated from the architecture by the CALM CLI (calm-generated-k8s/all-manifests.yaml)

---
### Name: Generated Docker Compose File  Type: data-asset

Docker Compose YAML file generated from the architecture by the CALM CLI (calm-generated-dc/docker-compose.yml)

---
### Name: Architecture Validation  Type: system

System responsible for validating CALM architecture files against approved patterns and standards using the CALM CLI

---
### Name: Deployment Generation  Type: system

System responsible for generating deployment artifacts (Kubernetes manifests and Docker Compose files) from validated CALM architectures using the CALM CLI

---
### Name: Kubernetes Cluster  Type: system

Target Kubernetes cluster to which manifests are applied via kubectl

---
### Name: Docker Engine  Type: system

Target Docker host on which services are started via docker compose

---
### Name: CALM CLI Templating  Type: service

FINOS CALM CLI templating service that renders architecture definitions into deployment artifacts using Handlebars templates

---
### Name: Application Deployment  Type: system

System responsible for applying generated deployment artifacts to the target infrastructure

---

## Flows

### Deploy to Kubernetes
```mermaid
sequenceDiagram
    Deployment Operator ->> Pipeline Orchestrator: Deployment Operator initiates the pipeline via the Pipeline Orchestrator
    Pipeline Orchestrator ->> CALM CLI Validation: Pipeline Orchestrator invokes CALM CLI to validate the architecture against the pattern
    Architecture File ->> CALM CLI Validation: CALM CLI reads the architecture file for validation
    Pattern File ->> CALM CLI Validation: CALM CLI reads the pattern file to validate architecture against
    URL Mapping ->> CALM CLI Validation: CALM CLI resolves schema $ref URLs using the URL mapping
    Pipeline Orchestrator ->> CALM CLI Templating: Pipeline Orchestrator invokes CALM CLI Templating to generate Kubernetes deployment artifacts
    Kubernetes Manifest Template ->> CALM CLI Templating: CALM CLI reads the Kubernetes Handlebars template
    CALM CLI Templating ->> Generated Kubernetes Manifests: CALM CLI uses its templating engine to render the architecture into Kubernetes manifests
    Pipeline Orchestrator ->> Deployer: Pipeline Orchestrator delegates deployment of generated artifacts to the Deployer
    Deployer ->> Generated Kubernetes Manifests: Deployer reads the generated Kubernetes manifests
    Deployer ->> Kubernetes Cluster: Deployer applies the manifests to the Kubernetes cluster via kubectl
```



---
### Deploy to Docker Compose
```mermaid
sequenceDiagram
    Deployment Operator ->> Pipeline Orchestrator: Deployment Operator initiates the pipeline via the Pipeline Orchestrator
    Pipeline Orchestrator ->> CALM CLI Validation: Pipeline Orchestrator invokes CALM CLI to validate the architecture against the pattern
    Architecture File ->> CALM CLI Validation: CALM CLI reads the architecture file for validation
    Pattern File ->> CALM CLI Validation: CALM CLI reads the pattern file to validate architecture against
    URL Mapping ->> CALM CLI Validation: CALM CLI resolves schema $ref URLs using the URL mapping
    Pipeline Orchestrator ->> CALM CLI Templating: Pipeline Orchestrator invokes CALM CLI Templating to generate Docker Compose deployment artifacts
    Docker Compose Template ->> CALM CLI Templating: CALM CLI reads the Docker Compose Handlebars template
    CALM CLI Templating ->> Generated Docker Compose File: CALM CLI uses its templating engine to render the architecture into a Docker Compose file
    Pipeline Orchestrator ->> Deployer: Pipeline Orchestrator delegates deployment of generated artifacts to the Deployer
    Deployer ->> Generated Docker Compose File: Deployer reads the generated Docker Compose file
    Deployer ->> Docker Engine: Deployer starts services on the Docker engine via docker compose up
```



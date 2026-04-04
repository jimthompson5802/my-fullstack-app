Create the ability, within the Calm architecture, to deploy the application either to Kubernetes (k8s) or as Docker containers using Docker Compose.

Current state
- The k8s deployment is working; no changes are required for existing `k8s` metadata.

Overview of required Docker Compose support
The repository will add a node-level Calm metadata property to describe Docker Compose deployment details and the tooling will render Handlebars templates into a `docker-compose.yml` placed under a generated output directory. The high-level tasks are:
- Add a node-level metadata key for compose configuration (see recommendation below).
- Add a copy of the architecture file using compose metadata: `docs/calm/my-fullstack-dc.architecture.json`.
- Update the standards file to validate the new metadata.
- Add Handlebars templates named with the `dc-` prefix into `docs/calm/templates/`.
- Update the `calm-validate-and-deploy.sh` script to generate compose output under `calm-generated-dc/` and run Compose when `docker-compose` metadata is present.

Metadata key
- Use the hyphenated metadata key `docker-compose` at the node level. Hyphenated keys are valid JSON but require tooling and templates to access the key using quoted lookup (examples below). Document this access pattern so code and templates remain consistent.

Example `docker-compose` node metadata (copyable)
{
  "unique-id": "frontend-web-app",
  "node-type": "service",
  "name": "Calculator Web UI",
  "metadata": {
    "docker-compose": {
      "service-name": "frontend",
      "image": "my-fullstack-frontend:latest",
      "ports": ["30300:80"],
      "depends-on": ["backend"]
    }
  }
}

Notes on the example fields
- `service-name` (string): logical service name used in the generated Compose file.
- `image` (string): container image to run for the service.
- `ports` (array of strings): host-to-container port mappings in the form "HOST:CONTAINER".
- `depends-on` (array of strings): list of other service names this service depends on.

Standards / validation guidance
- Update `docs/calm/standards/my-fullstack.standard.json` to add a JSON Schema definition for the new `docker-compose` metadata. At minimum validate:
  - `service-name`: required string
  - `image`: required string
  - `ports`: optional array of strings matching `^\\d{1,5}:\\d{1,5}$`
  - `depends-on`: optional array of strings

Architecture copy
-- Add `docs/calm/my-fullstack-dc.architecture.json` as a copy of `docs/calm/my-fullstack-k8s.architecture.json` with each node's `k8s` metadata replaced by `docker-compose` metadata conforming to the schema above.

Templates: naming and example
- Put templates in `docs/calm/templates/` and prefix filenames with `dc-`. Use the `.yaml.hbs` extension for Handlebars YAML templates (for example: `dc-compose.yaml.hbs` or `dc-service-{{serviceName}}.yaml.hbs`).

Example minimal Handlebars template (`dc-compose.yaml.hbs`)
version: "3.8"
services:
  {{!-- Access hyphenated metadata keys via the Handlebars `lookup` helper --}}
  {{#with (lookup metadata "docker-compose")}}
  {{!-- Service name (kebab-case key) --}}
  {{lookup . "service-name"}}:
    image: {{lookup . "image"}}
    {{#if (lookup . "ports")}}
    ports:
    {{#each (lookup . "ports")}}
      - "{{this}}"
    {{/each}}
    {{/if}}
    {{#if (lookup . "depends-on")}}
    depends_on:
    {{#each (lookup . "depends-on")}}
      - {{this}}
    {{/each}}
    {{/if}}
  {{/with}}

Generated output location
- Place generated Docker Compose output in `calm-generated-dc/` with the primary file named `docker-compose.yml`.

`calm-validate-and-deploy.sh` behavior (clarified)
- Selection: the script should determine the deployment target by inspecting the provided Calm architecture JSON for node-level metadata. If the file contains any node with a `docker-compose` metadata property the script should select Docker Compose; if it contains any node with `k8s` metadata it should select Kubernetes. If both `docker-compose` and `k8s` metadata are present in the same architecture, the script should fail with an explanatory error and require an explicit `--target` flag from the user to disambiguate.

  Example detection snippet (use `jq`):

  ```bash
  ARCH=file.architecture.json
  if jq -e '.nodes[] | select(.metadata["docker-compose"])' "$ARCH" >/dev/null; then
    TARGET=dc
  elif jq -e '.nodes[] | select(.metadata.k8s)' "$ARCH" >/dev/null; then
    TARGET=k8s
  else
    echo "No deployment metadata found in $ARCH" >&2
    exit 1
  fi
  # If both exist, require explicit flag:
  if jq -e '.nodes[] | select(.metadata["docker-compose"])' "$ARCH" >/dev/null && jq -e '.nodes[] | select(.metadata.k8s)' "$ARCH" >/dev/null; then
    echo "Architecture contains both docker-compose and k8s metadata; pass --target k8s|dc to disambiguate" >&2
    exit 2
  fi
  ```

 - Generation: render templates into either the existing k8s output or `calm-generated-dc/docker-compose.yml` for compose.
 - Validation step (recommended): run `docker compose -f calm-generated-dc/docker-compose.yml config` to validate the generated file before deploying.
- Deploy commands (examples to document):

```bash
docker compose -f calm-generated-dc/docker-compose.yml up -d
```

or legacy:

```bash
docker-compose -f calm-generated-dc/docker-compose.yml up -d
```

 - When the selected target is Docker Compose the script MUST run the generated compose file (`docker compose -f calm-generated-dc/docker-compose.yml up -d`) after validation; there is no dry-run option for Docker Compose deployments.

Mapping guidance (k8s -> docker-compose)
- `metadata.k8s.image` -> `docker-compose.image`
- `containerPort` / `servicePort` -> `ports` entry `HOST:CONTAINER` (use `nodePort` for HOST when appropriate for local testing)

Editorial structure suggestions
- Convert the implementation steps into numbered tasks with exact filenames and example commands for clarity.
- Add a short "Quick test" section showing generation + validation + run commands.

Quick test (example commands to document)

  ```bash

./calm-validate-and-deploy.sh --target dc

# Validate generated compose
docker compose -f calm-generated-dc/docker-compose.yml config

# Start services
docker compose -f calm-generated-dc/docker-compose.yml up -d
```


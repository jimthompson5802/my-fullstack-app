#!/bin/bash

#############################################################################
# CALM Validate and Deploy Script
#############################################################################
#
# This script automates the CALM architecture validation and deployment
# workflow for either Kubernetes (k8s) or Docker Compose (dc) targets.
#
#   1. Validates architecture against pattern using CALM CLI
#   2. Detects (or uses explicit) deployment target: k8s or dc
#   3. Generates manifests / compose file from architecture using templates
#   4. Deploys to the selected target
#
# USAGE:
#   ./calm-validate-and-deploy.sh [--target k8s|dc] <architecture-file>
#
# EXAMPLES:
#   ./calm-validate-and-deploy.sh docs/calm/my-fullstack.architecture.json
#   ./calm-validate-and-deploy.sh docs/calm/my-fullstack-dc.architecture.json
#   ./calm-validate-and-deploy.sh --target dc docs/calm/my-fullstack-dc.architecture.json
#   ./calm-validate-and-deploy.sh --target k8s docs/calm/my-fullstack.architecture.json
#
# PREREQUISITES:
#   - calm-cli installed (npm install -g @finos/calm-cli)
#   - jq installed (brew install jq)
#   - For k8s: kubectl configured for target cluster
#   - For dc: docker (with compose plugin) or docker-compose installed
#   - Pattern file: docs/calm/patterns/my-fullstack.pattern.json
#   - URL mapping: docs/calm/url-mapping.json
#   - K8s template: docs/calm/templates/k8s-manifests.yaml.hbs
#   - Compose template: docs/calm/templates/dc-compose.yaml.hbs
#
# EXIT CODES:
#   0 - Success
#   1 - General failure (validation failed, file not found, deployment error)
#   2 - Ambiguous target (both k8s and docker-compose metadata present)
#
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PATTERN_FILE="docs/calm/patterns/my-fullstack.pattern.json"
URL_MAPPING="docs/calm/url-mapping.json"
K8S_TEMPLATE_FILE="docs/calm/templates/k8s-manifests.yaml.hbs"
DC_TEMPLATE_FILE="docs/calm/templates/dc-compose.yaml.hbs"
K8S_OUTPUT_DIR="k8s-calm-generated"
K8S_OUTPUT_FILE="${K8S_OUTPUT_DIR}/all-manifests.yaml"
DC_OUTPUT_DIR="dc-calm-generated"
DC_OUTPUT_FILE="${DC_OUTPUT_DIR}/docker-compose.yml"

# ---------------------------------------------------------------------------
# Argument parsing: optional --target flag followed by architecture file
# ---------------------------------------------------------------------------
TARGET=""
ARCHITECTURE_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo -e "${RED}Error: --target requires a value: k8s or dc${NC}"
                exit 1
            fi
            TARGET="$2"
            shift 2
            ;;
        *)
            if [[ -z "$ARCHITECTURE_FILE" ]]; then
                ARCHITECTURE_FILE="$1"
            else
                echo -e "${RED}Error: unexpected argument '$1'${NC}"
                echo "Usage: $0 [--target k8s|dc] <architecture-file>"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$ARCHITECTURE_FILE" ]]; then
    echo -e "${RED}Error: Architecture file not provided${NC}"
    echo "Usage: $0 [--target k8s|dc] <architecture-file>"
    echo "Example: $0 docs/calm/my-fullstack.architecture.json"
    exit 1
fi

if [[ -n "$TARGET" && "$TARGET" != "k8s" && "$TARGET" != "dc" ]]; then
    echo -e "${RED}Error: --target must be 'k8s' or 'dc', got '$TARGET'${NC}"
    exit 1
fi

# Check files exist
if [[ ! -f "$ARCHITECTURE_FILE" ]]; then
    echo -e "${RED}Error: Architecture file not found: $ARCHITECTURE_FILE${NC}"
    exit 1
fi
if [[ ! -f "$PATTERN_FILE" ]]; then
    echo -e "${RED}Error: Pattern file not found: $PATTERN_FILE${NC}"
    exit 1
fi
if [[ ! -f "$URL_MAPPING" ]]; then
    echo -e "${RED}Error: URL mapping file not found: $URL_MAPPING${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 1: Validate the architecture
# ---------------------------------------------------------------------------
echo -e "${YELLOW}==> Validating architecture against pattern...${NC}"
echo "Architecture: $ARCHITECTURE_FILE"
echo "Pattern:      $PATTERN_FILE"
echo "URL Mapping:  $URL_MAPPING"
echo ""

set +e
VALIDATION_OUTPUT=$(calm validate \
    -p "$PATTERN_FILE" \
    -a "$ARCHITECTURE_FILE" \
    -u "$URL_MAPPING" \
    -f json 2>&1)
VALIDATION_EXIT_CODE=$?
set -e

if [[ $VALIDATION_EXIT_CODE -ne 0 ]]; then
    echo -e "${RED}✗ CALM validation command failed!${NC}"
    echo ""
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

HAS_ERRORS=$(echo "$VALIDATION_OUTPUT" | grep -o '"hasErrors":[^,}]*' | cut -d':' -f2 | tr -d ' ' || echo "true")
if [[ "$HAS_ERRORS" == "true" ]]; then
    echo -e "${RED}✗ CALM validation failed with errors!${NC}"
    echo ""
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✓ CALM validation passed!${NC}"
echo ""

# ---------------------------------------------------------------------------
# Step 2: Auto-detect deployment target if --target not provided
# ---------------------------------------------------------------------------
if [[ -z "$TARGET" ]]; then
    set +e
    jq -e '[.nodes[] | select(.metadata["docker-compose"])] | length > 0' "$ARCHITECTURE_FILE" >/dev/null 2>&1
    HAS_DC_EXIT=$?
    jq -e '[.nodes[] | select(.metadata.k8s)] | length > 0' "$ARCHITECTURE_FILE" >/dev/null 2>&1
    HAS_K8S_EXIT=$?
    set -e

    if [[ $HAS_DC_EXIT -eq 0 && $HAS_K8S_EXIT -eq 0 ]]; then
        echo -e "${RED}Error: Architecture contains both docker-compose and k8s metadata.${NC}"
        echo "Pass --target k8s or --target dc to disambiguate."
        exit 2
    elif [[ $HAS_DC_EXIT -eq 0 ]]; then
        TARGET="dc"
        echo -e "${YELLOW}Auto-detected deployment target: Docker Compose${NC}"
    elif [[ $HAS_K8S_EXIT -eq 0 ]]; then
        TARGET="k8s"
        echo -e "${YELLOW}Auto-detected deployment target: Kubernetes${NC}"
    else
        echo -e "${RED}Error: No deployment metadata (k8s or docker-compose) found in $ARCHITECTURE_FILE${NC}"
        exit 1
    fi
    echo ""
fi

# ---------------------------------------------------------------------------
# Step 3a: Kubernetes path
# ---------------------------------------------------------------------------
if [[ "$TARGET" == "k8s" ]]; then
    if [[ ! -f "$K8S_TEMPLATE_FILE" ]]; then
        echo -e "${RED}Error: K8s template not found: $K8S_TEMPLATE_FILE${NC}"
        exit 1
    fi

    echo -e "${YELLOW}==> Generating Kubernetes manifests...${NC}"
    echo "Template: $K8S_TEMPLATE_FILE"
    echo "Output:   $K8S_OUTPUT_FILE"
    echo ""

    mkdir -p "$K8S_OUTPUT_DIR"

    calm template \
        -a "$ARCHITECTURE_FILE" \
        --template "$K8S_TEMPLATE_FILE" \
        -o "$K8S_OUTPUT_FILE"

    echo -e "${GREEN}✓ Kubernetes manifests generated successfully!${NC}"
    echo ""

    echo -e "${YELLOW}==> Applying Kubernetes manifests...${NC}"
    echo "Running: kubectl apply -f $K8S_OUTPUT_FILE"
    echo ""

    kubectl apply -f "$K8S_OUTPUT_FILE"

    echo ""
    echo -e "${GREEN}✓ Deployment successful!${NC}"
    echo ""
    echo "Summary:"
    echo "  • Architecture validated: $ARCHITECTURE_FILE"
    echo "  • Manifests generated:    $K8S_OUTPUT_FILE"
    echo "  • Kubernetes resources applied"
    echo ""
    kubectl get deployments,services -n my-fullstack-app
fi

# ---------------------------------------------------------------------------
# Step 3b: Docker Compose path
# ---------------------------------------------------------------------------
if [[ "$TARGET" == "dc" ]]; then
    if [[ ! -f "$DC_TEMPLATE_FILE" ]]; then
        echo -e "${RED}Error: Docker Compose template not found: $DC_TEMPLATE_FILE${NC}"
        exit 1
    fi

    echo -e "${YELLOW}==> Generating Docker Compose file...${NC}"
    echo "Template: $DC_TEMPLATE_FILE"
    echo "Output:   $DC_OUTPUT_FILE"
    echo ""

    mkdir -p "$DC_OUTPUT_DIR"

    calm template \
        -a "$ARCHITECTURE_FILE" \
        --template "$DC_TEMPLATE_FILE" \
        -o "$DC_OUTPUT_FILE"

    echo -e "${GREEN}✓ Docker Compose file generated successfully!${NC}"
    echo ""

    echo -e "${YELLOW}==> Validating generated Docker Compose file...${NC}"
    if command -v docker &>/dev/null && docker compose version &>/dev/null 2>&1; then
        docker compose -f "$DC_OUTPUT_FILE" config
        echo -e "${GREEN}✓ Docker Compose file is valid!${NC}"
        echo ""

        echo -e "${YELLOW}==> Starting services with Docker Compose...${NC}"
        echo "Running: docker compose -f $DC_OUTPUT_FILE up -d"
        echo ""
        docker compose -f "$DC_OUTPUT_FILE" up -d
    elif command -v docker-compose &>/dev/null; then
        docker-compose -f "$DC_OUTPUT_FILE" config
        echo -e "${GREEN}✓ Docker Compose file is valid!${NC}"
        echo ""

        echo -e "${YELLOW}==> Starting services with Docker Compose...${NC}"
        echo "Running: docker-compose -f $DC_OUTPUT_FILE up -d"
        echo ""
        docker-compose -f "$DC_OUTPUT_FILE" up -d
    else
        echo -e "${RED}Error: docker compose or docker-compose not found${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}✓ Deployment successful!${NC}"
    echo ""
    echo "Summary:"
    echo "  • Architecture validated: $ARCHITECTURE_FILE"
    echo "  • Compose file generated: $DC_OUTPUT_FILE"
    echo "  • Services started via Docker Compose"
fi

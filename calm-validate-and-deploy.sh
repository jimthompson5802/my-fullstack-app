#!/bin/bash

#############################################################################
# CALM Validate and Deploy Script
#############################################################################
#
# This script automates the CALM architecture validation and Kubernetes
# deployment workflow:
#
#   1. Validates architecture against pattern using CALM CLI
#   2. Generates Kubernetes manifests from architecture using templates
#   3. Applies manifests to Kubernetes cluster
#
# USAGE:
#   ./calm-validate-and-deploy.sh <architecture-file>
#
# EXAMPLE:
#   ./calm-validate-and-deploy.sh docs/calm/my-fullstack.architecture.json
#
# PREREQUISITES:
#   - calm-cli installed (npm install -g @finos/calm-cli)
#   - kubectl configured for target cluster
#   - Pattern file: docs/calm/patterns/my-fullstack.pattern.json
#   - URL mapping: docs/calm/url-mapping.json
#   - Template: docs/calm/templates/k8s-manifests.yaml.hbs
#
# EXIT CODES:
#   0 - Success (validation passed, manifests generated and applied)
#   1 - Failure (validation failed, file not found, or deployment error)
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
TEMPLATE_FILE="docs/calm/templates/k8s-manifests.yaml.hbs"
OUTPUT_DIR="k8s-calm-generated"
OUTPUT_FILE="${OUTPUT_DIR}/all-manifests.yaml"

# Check if architecture file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Architecture file not provided${NC}"
    echo "Usage: $0 <architecture-file>"
    echo "Example: $0 docs/calm/my-fullstack.architecture.json"
    exit 1
fi

ARCHITECTURE_FILE="$1"

# Check if architecture file exists
if [ ! -f "$ARCHITECTURE_FILE" ]; then
    echo -e "${RED}Error: Architecture file not found: $ARCHITECTURE_FILE${NC}"
    exit 1
fi

# Check if required files exist
if [ ! -f "$PATTERN_FILE" ]; then
    echo -e "${RED}Error: Pattern file not found: $PATTERN_FILE${NC}"
    exit 1
fi

if [ ! -f "$URL_MAPPING" ]; then
    echo -e "${RED}Error: URL mapping file not found: $URL_MAPPING${NC}"
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Error: Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Step 1: Validate the architecture
echo -e "${YELLOW}==> Validating architecture against pattern...${NC}"
echo "Architecture: $ARCHITECTURE_FILE"
echo "Pattern: $PATTERN_FILE"
echo "URL Mapping: $URL_MAPPING"
echo ""

# Run validation and capture output
set +e  # Temporarily disable exit on error
VALIDATION_OUTPUT=$(calm validate \
    -p "$PATTERN_FILE" \
    -a "$ARCHITECTURE_FILE" \
    -u "$URL_MAPPING" \
    -f json 2>&1)
VALIDATION_EXIT_CODE=$?
set -e  # Re-enable exit on error

# Check if validation command failed
if [ $VALIDATION_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}✗ CALM validation command failed!${NC}"
    echo ""
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

# Parse validation output to check for errors
HAS_ERRORS=$(echo "$VALIDATION_OUTPUT" | grep -o '"hasErrors":[^,}]*' | cut -d':' -f2 | tr -d ' ' || echo "true")

if [ "$HAS_ERRORS" = "true" ]; then
    echo -e "${RED}✗ CALM validation failed with errors!${NC}"
    echo ""
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✓ CALM validation passed!${NC}"
echo ""

# Step 2: Generate Kubernetes manifests
echo -e "${YELLOW}==> Generating Kubernetes manifests...${NC}"
echo "Template: $TEMPLATE_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

calm template \
    -a "$ARCHITECTURE_FILE" \
    --template "$TEMPLATE_FILE" \
    -o "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate Kubernetes manifests${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Kubernetes manifests generated successfully!${NC}"
echo ""

# Step 3: Apply Kubernetes manifests
echo -e "${YELLOW}==> Applying Kubernetes manifests...${NC}"
echo "Running: kubectl apply -f $OUTPUT_FILE"
echo ""

kubectl apply -f "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to apply Kubernetes manifests${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Deployment successful!${NC}"
echo ""
echo "Summary:"
echo "  • Architecture validated: $ARCHITECTURE_FILE"
echo "  • Manifests generated: $OUTPUT_FILE"
echo "  • Kubernetes resources applied"

# display deployments and services in the my-fullstack-app namespace
kubectl get deployments,services -n my-fullstack-app

#!/bin/bash
# =============================================================================
# Upload Singularity Containers to GitHub Container Registry
# Organization: LIVR-VUB
# Repository: https://github.com/orgs/LIVR-VUB/packages
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION - Modify these settings as needed
# =============================================================================
GITHUB_ORG="livr-vub"           # GitHub organization (must be lowercase)
CONTAINER_DIR="./containers"     # Directory containing .sif files to upload

# =============================================================================
# Script - No modifications needed below
# =============================================================================

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║     LIVR-VUB Singularity Container Upload Script           ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_header

# Step 0: Check/Install ORAS
echo -e "${YELLOW}[Step 0] Checking for ORAS CLI...${NC}"
if ! command -v oras &> /dev/null; then
    echo -e "${CYAN}ORAS not found. Installing...${NC}"
    
    VERSION="1.1.0"
    curl -LO "https://github.com/oras-project/oras/releases/download/v${VERSION}/oras_${VERSION}_linux_amd64.tar.gz"
    mkdir -p oras-install/
    tar -zxf oras_${VERSION}_*.tar.gz -C oras-install/
    sudo mv oras-install/oras /usr/local/bin/
    rm -rf oras_${VERSION}_*.tar.gz oras-install/
    
    echo -e "${GREEN}✓ ORAS installed successfully${NC}"
else
    echo -e "${GREEN}✓ ORAS found: $(oras version | head -1)${NC}"
fi
echo ""

# Step 1: Login to GHCR
echo -e "${YELLOW}[Step 1] GitHub Container Registry Login${NC}"
echo ""
echo -e "${CYAN}You need a GitHub Personal Access Token (PAT) with these permissions:${NC}"
echo "  - write:packages"
echo "  - read:packages"
echo "  - delete:packages (optional)"
echo ""
echo "Create one at: https://github.com/settings/tokens/new"
echo ""

read -p "Enter your GitHub username: " GITHUB_USERNAME
echo "Enter your GitHub Personal Access Token:"
read -rs GITHUB_TOKEN
echo ""

echo "$GITHUB_TOKEN" | oras login ghcr.io --username "$GITHUB_USERNAME" --password-stdin

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully logged in to ghcr.io${NC}"
else
    echo -e "${RED}✗ Login failed. Check your credentials.${NC}"
    exit 1
fi
echo ""

# Step 2: Find containers
echo -e "${YELLOW}[Step 2] Finding containers to upload...${NC}"

if [ ! -d "$CONTAINER_DIR" ]; then
    echo -e "${RED}Container directory not found: ${CONTAINER_DIR}${NC}"
    read -p "Enter path to container directory: " CONTAINER_DIR
fi

cd "$CONTAINER_DIR"
sif_files=(*.sif)

if [ ${#sif_files[@]} -eq 0 ] || [ ! -f "${sif_files[0]}" ]; then
    echo -e "${RED}No .sif files found in ${CONTAINER_DIR}${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}Found containers:${NC}"
i=1
for sif in "${sif_files[@]}"; do
    size=$(du -h "$sif" | cut -f1)
    printf "  ${YELLOW}%d)${NC} %-30s %s\n" "$i" "$sif" "($size)"
    ((i++))
done
echo ""

# Step 3: Select containers
echo -e "${BOLD}Upload Options:${NC}"
echo "  a) Upload ALL containers"
echo "  s) Select specific containers"
echo "  q) Quit"
echo ""
read -p "Enter choice [a/s/q]: " choice

selected=()
case $choice in
    a|A)
        selected=("${sif_files[@]}")
        ;;
    s|S)
        echo ""
        echo "Enter container numbers separated by spaces (e.g., 1 3 4):"
        read -p "> " numbers
        for num in $numbers; do
            idx=$((num - 1))
            if [[ $idx -ge 0 && $idx -lt ${#sif_files[@]} ]]; then
                selected+=("${sif_files[$idx]}")
            fi
        done
        ;;
    q|Q)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

if [ ${#selected[@]} -eq 0 ]; then
    echo -e "${RED}No containers selected${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[Step 3] Uploading ${#selected[@]} container(s)...${NC}"
echo ""

# Step 4: Upload
success_count=0
fail_count=0

for sif in "${selected[@]}"; do
    # Convert name to lowercase (GHCR requirement)
    container_name=$(echo "${sif%.sif}" | tr '[:upper:]' '[:lower:]')
    registry_path="ghcr.io/${GITHUB_ORG}/${container_name}:latest"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Uploading: ${sif}${NC}"
    echo "  Target: ${registry_path}"
    echo ""
    
    if oras push "$registry_path" \
        --artifact-type application/vnd.sylabs.sif.layer.v1.sif \
        "${sif}:application/vnd.sylabs.sif.layer.v1.sif"; then
        echo -e "${GREEN}✓ Success: ${container_name}${NC}"
        ((success_count++))
    else
        echo -e "${RED}✗ Failed: ${container_name}${NC}"
        ((fail_count++))
    fi
    echo ""
done

# Summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Upload Summary:${NC}"
echo -e "  ${GREEN}Succeeded: ${success_count}${NC}"
echo -e "  ${RED}Failed: ${fail_count}${NC}"
echo ""

if [ $success_count -gt 0 ]; then
    echo -e "${BOLD}Uploaded to:${NC}"
    echo "  https://github.com/orgs/${GITHUB_ORG}/packages"
    echo ""
    echo -e "${YELLOW}To make containers PUBLIC:${NC}"
    echo "  1. Go to the packages page above"
    echo "  2. Click on each package"
    echo "  3. Package settings → Change visibility → Public"
    echo ""
    echo -e "${CYAN}Pull commands for uploaded containers:${NC}"
    for sif in "${selected[@]}"; do
        container_name=$(echo "${sif%.sif}" | tr '[:upper:]' '[:lower:]')
        echo "  singularity pull oras://ghcr.io/${GITHUB_ORG}/${container_name}:latest"
    done
fi

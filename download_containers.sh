#!/bin/bash
# =============================================================================
# Download Singularity Containers from GitHub Container Registry
# Organization: LIVR-VUB
# Repository: https://github.com/orgs/LIVR-VUB/packages
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION - Modify these settings as needed
# =============================================================================
GITHUB_ORG="livr-vub"
OUTPUT_DIR="./containers"

# Available containers - Add new containers here
declare -A CONTAINERS=(
    ["cellprofiler"]="CellProfiler v4.2.x - Cell image analysis"
    ["cellprofiler_426"]="CellProfiler v4.2.6 - Cell image analysis (pinned version)"
    ["cp2m_quant"]="CellProfiler + Custom quantification pipeline"
    ["svetlana"]="Cellpose - Deep learning cell segmentation"
)

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
    echo -e "${BOLD}║     LIVR-VUB Singularity Container Download Script         ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_header

# Check for singularity or apptainer
if command -v singularity &> /dev/null; then
    CONTAINER_CMD="singularity"
elif command -v apptainer &> /dev/null; then
    CONTAINER_CMD="apptainer"
else
    echo -e "${RED}Error: Neither singularity nor apptainer found!${NC}"
    echo "Please install one of them first."
    echo "  - Singularity: https://sylabs.io/singularity"
    echo "  - Apptainer: https://apptainer.org"
    exit 1
fi

echo -e "${GREEN}Using: ${CONTAINER_CMD}${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Show available containers
echo -e "${CYAN}${BOLD}Available Containers:${NC}"
echo ""
i=1
container_list=()
for name in "${!CONTAINERS[@]}"; do
    container_list+=("$name")
    printf "  ${YELLOW}%d)${NC} %-20s %s\n" "$i" "$name" "${CONTAINERS[$name]}"
    ((i++))
done
echo ""

# Menu
echo -e "${BOLD}Download Options:${NC}"
echo "  a) Download ALL containers"
echo "  s) Select specific containers"
echo "  q) Quit"
echo ""
read -p "Enter choice [a/s/q]: " choice

selected=()
case $choice in
    a|A)
        selected=("${container_list[@]}")
        ;;
    s|S)
        echo ""
        echo "Enter container numbers separated by spaces (e.g., 1 3 4):"
        read -p "> " numbers
        for num in $numbers; do
            idx=$((num - 1))
            if [[ $idx -ge 0 && $idx -lt ${#container_list[@]} ]]; then
                selected+=("${container_list[$idx]}")
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
echo -e "${YELLOW}Downloading ${#selected[@]} container(s) to ${OUTPUT_DIR}/...${NC}"
echo ""

# Download containers
success_count=0
fail_count=0

for container in "${selected[@]}"; do
    registry_path="oras://ghcr.io/${GITHUB_ORG}/${container}:latest"
    output_file="${OUTPUT_DIR}/${container}.sif"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Downloading: ${container}${NC}"
    echo "  Source: ${registry_path}"
    echo "  Target: ${output_file}"
    echo ""
    
    if $CONTAINER_CMD pull --force "$output_file" "$registry_path"; then
        echo -e "${GREEN}✓ Success: ${container}.sif${NC}"
        ((success_count++))
    else
        echo -e "${RED}✗ Failed: ${container}${NC}"
        ((fail_count++))
    fi
    echo ""
done

# Summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Download Summary:${NC}"
echo -e "  ${GREEN}Succeeded: ${success_count}${NC}"
echo -e "  ${RED}Failed: ${fail_count}${NC}"
echo ""

if [ $success_count -gt 0 ]; then
    echo -e "${BOLD}Downloaded containers:${NC}"
    ls -lh "${OUTPUT_DIR}"/*.sif 2>/dev/null | awk '{print "  " $NF " (" $5 ")"}'
    echo ""
    echo -e "${CYAN}Usage example:${NC}"
    first_sif=$(ls "${OUTPUT_DIR}"/*.sif 2>/dev/null | head -1)
    if [ -n "$first_sif" ]; then
        echo "  $CONTAINER_CMD exec $first_sif <command>"
    fi
fi

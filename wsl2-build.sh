#!/bin/bash
# WSL2 Build Script for OrcaSlicer
# Run this in WSL2 Ubuntu after restart

set -e  # Exit on error

echo "================================================"
echo "OrcaSlicer WSL2 Build Script"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="/mnt/j/github orca/OrcaSlicer"

echo -e "${CYAN}Project directory: ${PROJECT_DIR}${NC}"
echo ""

# Check if directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}ERROR: Project directory not found!${NC}"
    echo "Expected: $PROJECT_DIR"
    echo ""
    echo "Available drives:"
    ls -la /mnt/
    exit 1
fi

cd "$PROJECT_DIR"
echo -e "${GREEN}✓ Changed to project directory${NC}"
echo ""

# Step 1: Update package list
echo -e "${CYAN}Step 1: Updating package list...${NC}"
sudo apt-get update
echo -e "${GREEN}✓ Package list updated${NC}"
echo ""

# Step 2: Install build dependencies
echo -e "${CYAN}Step 2: Installing build dependencies...${NC}"
echo "This will take 5-10 minutes..."
echo ""

sudo apt-get install -y \
  build-essential \
  cmake \
  ninja-build \
  git \
  gettext \
  libgtk-3-dev \
  libwxgtk3.0-gtk3-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  libglu1-mesa-dev \
  libdbus-1-dev \
  extra-cmake-modules \
  pkgconf \
  libudev-dev \
  libglew-dev \
  libhidapi-dev

echo ""
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 3: Build dependencies
echo -e "${CYAN}Step 3: Building dependencies (30-45 minutes)...${NC}"
echo "Building: Boost, wxWidgets, OpenCV, OpenSSL, and more"
echo ""

cd deps
mkdir -p build
cd build

cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja

echo ""
echo -e "${GREEN}✓ Dependencies built successfully${NC}"
echo ""

# Step 4: Build OrcaSlicer
echo -e "${CYAN}Step 4: Building OrcaSlicer (20-30 minutes)...${NC}"
echo ""

cd "$PROJECT_DIR"
mkdir -p build
cd build

cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSLIC3R_STATIC=ON \
  -DSLIC3R_GUI=ON \
  -DSLIC3R_PCH=OFF

ninja

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}BUILD COMPLETE! 🎉${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check if executable exists
if [ -f "src/orcaslicer" ]; then
    echo -e "${GREEN}Executable: $(pwd)/src/orcaslicer${NC}"
    echo ""

    # Test executable
    echo -e "${CYAN}Testing executable...${NC}"
    ./src/orcaslicer --help

    echo ""
    echo -e "${GREEN}✓ Executable works!${NC}"
    echo ""

    # Show features
    echo -e "${CYAN}Your 6 custom features are included:${NC}"
    echo "  1. Per-Filament Retraction Override"
    echo "  2. Per-Plate Printer/Filament Settings"
    echo "  3. Prime Tower Material Selection"
    echo "  4. Support & Infill Flush Selection"
    echo "  5. Hierarchical Object Grouping"
    echo "  6. Cutting Plane Size Adjustability"
    echo ""

    # Next steps
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Test features: ./src/orcaslicer"
    echo "  2. Package: tar -czf orcaslicer-custom.tar.gz src/orcaslicer ../resources"
    echo "  3. Read testing guide: .claude/CREATIVE-TESTING-PLAYBOOK.md"
    echo ""
else
    echo -e "${RED}ERROR: Executable not found!${NC}"
    echo "Build may have failed. Check logs above."
    exit 1
fi

echo -e "${GREEN}All done! 🚀${NC}"

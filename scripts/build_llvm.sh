#!/bin/bash
# Build LLVM/MLIR from source for TileTaskStencil development.
#
# Prerequisites:
#   - conda activate stencil-mlir  (or equivalent env with cmake, ninja, python, pybind11, nanobind)
#   - GCC >= 11 (C++17 required)
#
# Usage:
#   ./scripts/build_llvm.sh [LLVM_SRC_DIR] [LLVM_BUILD_DIR] [INSTALL_DIR]
#
# Defaults:
#   LLVM_SRC_DIR   = ../llvm-project
#   LLVM_BUILD_DIR = ../llvm-project/build
#   INSTALL_DIR    = (none — use build tree directly)

set -euo pipefail

LLVM_VERSION="llvmorg-20.1.0"

LLVM_SRC_DIR="${1:-../llvm-project}"
LLVM_BUILD_DIR="${2:-${LLVM_SRC_DIR}/build}"
INSTALL_DIR="${3:-}"

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 8)
# Use 90% of cores to avoid starving the system
BUILD_JOBS=$(( NPROC * 9 / 10 ))
[ "$BUILD_JOBS" -lt 1 ] && BUILD_JOBS=1

echo "=== TileTaskStencil LLVM/MLIR Build ==="
echo "  LLVM version:  ${LLVM_VERSION}"
echo "  Source dir:    ${LLVM_SRC_DIR}"
echo "  Build dir:     ${LLVM_BUILD_DIR}"
echo "  Install dir:   ${INSTALL_DIR:-<use build tree>}"
echo "  Build jobs:    ${BUILD_JOBS}"
echo ""

# --- Step 1: Clone if needed ---
if [ ! -d "${LLVM_SRC_DIR}/llvm" ]; then
    echo ">>> Cloning llvm-project at ${LLVM_VERSION}..."
    git clone --depth 1 --branch "${LLVM_VERSION}" \
        https://github.com/llvm/llvm-project.git "${LLVM_SRC_DIR}"
else
    echo ">>> LLVM source found at ${LLVM_SRC_DIR}"
    CURRENT_TAG=$(git -C "${LLVM_SRC_DIR}" describe --tags 2>/dev/null || echo "unknown")
    echo "    Current tag: ${CURRENT_TAG}"
fi

# --- Step 2: Configure ---
echo ">>> Configuring LLVM+MLIR..."

CMAKE_ARGS=(
    -G Ninja
    -S "${LLVM_SRC_DIR}/llvm"
    -B "${LLVM_BUILD_DIR}"
    -DCMAKE_BUILD_TYPE=Release
    -DLLVM_ENABLE_ASSERTIONS=ON
    -DLLVM_ENABLE_PROJECTS="mlir"
    -DLLVM_TARGETS_TO_BUILD="host;NVPTX"
    -DMLIR_ENABLE_BINDINGS_PYTHON=ON
    -DLLVM_INSTALL_UTILS=ON
    -DLLVM_BUILD_EXAMPLES=OFF
    -DLLVM_ENABLE_OCAMLDOC=OFF
    -DLLVM_ENABLE_BINDINGS=OFF
)

# Use conda python if available
if command -v python3 &>/dev/null; then
    CMAKE_ARGS+=(-DPython3_EXECUTABLE="$(which python3)")
fi

if [ -n "${INSTALL_DIR}" ]; then
    CMAKE_ARGS+=(-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}")
fi

cmake "${CMAKE_ARGS[@]}"

# --- Step 3: Build ---
echo ">>> Building with ${BUILD_JOBS} jobs..."
ninja -C "${LLVM_BUILD_DIR}" -j"${BUILD_JOBS}"

# --- Step 4: Optionally install ---
if [ -n "${INSTALL_DIR}" ]; then
    echo ">>> Installing to ${INSTALL_DIR}..."
    ninja -C "${LLVM_BUILD_DIR}" install
fi

# --- Done ---
echo ""
echo "=== Build complete ==="
echo "  MLIR_DIR=${LLVM_BUILD_DIR}/lib/cmake/mlir"
echo "  LLVM_DIR=${LLVM_BUILD_DIR}/lib/cmake/llvm"
echo ""
echo "To build TileTaskStencil:"
echo "  cmake -G Ninja -S . -B build \\"
echo "    -DMLIR_DIR=${LLVM_BUILD_DIR}/lib/cmake/mlir \\"
echo "    -DLLVM_DIR=${LLVM_BUILD_DIR}/lib/cmake/llvm \\"
echo "    -DCMAKE_BUILD_TYPE=Release"
echo "  ninja -C build"

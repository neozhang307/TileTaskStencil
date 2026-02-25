# TileTaskStencil

An MLIR-based stencil compiler targeting NVIDIA Hopper (SM90) and Blackwell (SM100) GPUs.

Compiles high-level stencil descriptions into optimized GPU code with automatic temporal blocking, async pipeline (TMA + mbarrier), hierarchical compute mapping, cluster support, and load-balanced execution.

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| **LLVM/MLIR** | 20.1.0 | Built from source with NVPTX target and MLIR Python bindings |
| **CMake** | >= 3.20 | |
| **Ninja** | >= 1.10 | |
| **GCC** | >= 11 | C++17 required |
| **Python** | 3.11 | For MLIR Python bindings and cost model |
| **CUDA Toolkit** | >= 12.4 | For GPU code generation and runtime |
| **GPU** | SM90+ | Hopper (SM90) or Blackwell (SM100) |

### Python packages

| Package | Version | Purpose |
|---------|---------|---------|
| numpy | | Numerical tests and cost model |
| pybind11 | >= 2.13 | MLIR Python bindings (legacy) |
| nanobind | >= 2.4 | MLIR Python bindings (LLVM 20+) |
| lit | | LLVM Integrated Tester for running tests |

## Environment Setup

### 1. Create conda environment

```bash
conda env create -f environment.yml
conda activate stencil-mlir
```

Or manually:

```bash
conda create -n stencil-mlir python=3.11 cmake ninja numpy pybind11 -y
conda activate stencil-mlir
pip install "nanobind>=2.4" lit
```

### 2. Build LLVM/MLIR

Use the provided helper script:

```bash
./scripts/build_llvm.sh ../llvm-project
```

This clones LLVM 20.1.0 (if not already present), configures with NVPTX target + MLIR Python bindings, and builds. The script prints `MLIR_DIR` and `LLVM_DIR` paths on completion.

Or build manually:

```bash
git clone --depth 1 --branch llvmorg-20.1.0 \
    https://github.com/llvm/llvm-project.git ../llvm-project

cmake -G Ninja -S ../llvm-project/llvm -B ../llvm-project/build \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_ENABLE_PROJECTS="mlir" \
  -DLLVM_TARGETS_TO_BUILD="host;NVPTX" \
  -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
  -DPython3_EXECUTABLE=$(which python3) \
  -DLLVM_INSTALL_UTILS=ON \
  -DLLVM_BUILD_EXAMPLES=OFF \
  -DLLVM_ENABLE_OCAMLDOC=OFF \
  -DLLVM_ENABLE_BINDINGS=OFF

ninja -C ../llvm-project/build
```

### 3. Build TileTaskStencil

```bash
cmake -G Ninja -S . -B build \
  -DMLIR_DIR=../llvm-project/build/lib/cmake/mlir \
  -DLLVM_DIR=../llvm-project/build/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=Release
ninja -C build
```

### 4. Run tests

```bash
ninja -C build check-stencil-task
```

## LLVM Build Configuration

The following CMake flags are required when building LLVM for this project:

| Flag | Value | Why |
|------|-------|-----|
| `LLVM_ENABLE_PROJECTS` | `"mlir"` | MLIR is the foundation |
| `LLVM_TARGETS_TO_BUILD` | `"host;NVPTX"` | Host for testing, NVPTX for GPU codegen |
| `MLIR_ENABLE_BINDINGS_PYTHON` | `ON` | Python frontend and cost model |
| `LLVM_ENABLE_ASSERTIONS` | `ON` | Catches IR validity issues during development |
| `LLVM_INSTALL_UTILS` | `ON` | Installs FileCheck, count, not (needed for lit tests) |

## Project Structure

```
include/StencilTask/Dialect/   - MLIR dialect ODS definitions + C++ headers
lib/Dialect/                   - Dialect implementations
lib/CostModel/                 - Cost model (schedule generation)
lib/Transforms/                - Cross-dialect transformation passes
python/stencil_task/           - Python frontend
runtime/                       - CUDA runtime (TMA setup, work queue)
test/                          - Lit tests
scripts/                       - Build and environment helper scripts
```

## Dialect Hierarchy

```
StencilDialect -> TileDialect -> TaskDialect -> PipelineDialect -> GPU/NVGPU/NVVM
```

## License

Apache 2.0 with LLVM Exceptions. See [LICENSE](LICENSE).

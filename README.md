# TileTaskStencil

An MLIR-based stencil compiler targeting NVIDIA Hopper (SM90) and Blackwell (SM100) GPUs.

Compiles high-level stencil descriptions into optimized GPU code with automatic temporal blocking, async pipeline (TMA + mbarrier), hierarchical compute mapping, cluster support, and load-balanced execution.

## Building

TileTaskStencil is an out-of-tree MLIR project. You need a built LLVM/MLIR installation.

```bash
mkdir build && cd build
cmake .. -G Ninja \
  -DMLIR_DIR=/path/to/llvm-project/build/lib/cmake/mlir \
  -DLLVM_DIR=/path/to/llvm-project/build/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=Release
ninja
```

## Project Structure

```
include/StencilTask/Dialect/   - MLIR dialect ODS definitions + C++ headers
lib/Dialect/                   - Dialect implementations
lib/CostModel/                 - Cost model (schedule generation)
lib/Transforms/                - Cross-dialect transformation passes
python/stencil_task/           - Python frontend
runtime/                       - CUDA runtime (TMA setup, work queue)
test/                          - Lit tests
```

## Dialect Hierarchy

```
StencilDialect -> TileDialect -> TaskDialect -> PipelineDialect -> GPU/NVGPU/NVVM
```

## License

Apache 2.0 with LLVM Exceptions. See [LICENSE](LICENSE).

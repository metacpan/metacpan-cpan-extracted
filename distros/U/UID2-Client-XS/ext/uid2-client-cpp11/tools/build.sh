#!/bin/bash -xe

BUILD_PRESET=${1:-debug-clang14}
BUILD_OPTIONS=

cmake --preset $BUILD_PRESET $BUILD_OPTIONS -DCMAKE_CXX_COMPILER_LAUNCHER="" .
cmake --build build/$BUILD_PRESET -v -j
CTEST_OUTPUT_ON_FAILURE=1 cmake --build build/$BUILD_PRESET -v -t test
cmake --build build/$BUILD_PRESET -v -t install

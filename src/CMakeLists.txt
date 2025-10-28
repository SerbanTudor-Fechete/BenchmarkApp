# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(benchmark_core_library VERSION 0.0.1 LANGUAGES C)

add_library(benchmark_core SHARED
  "benchmark_core.c"
)

set_target_properties(benchmark_core PROPERTIES
  PUBLIC_HEADER benchmark_core.h
  OUTPUT_NAME "benchmark_core"
)

target_compile_definitions(benchmark_core PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(benchmark_core PRIVATE "-Wl,-z,max-page-size=16384")
endif()

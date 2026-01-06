#pragma once
#include <stdint.h>

#if defined(__GNUC__) && __GNUC__ >= 4
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT double run_offscreen_render_benchmark(double duration_seconds);

#ifdef __cplusplus
}
#endif
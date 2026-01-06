#pragma once 

#include <stdint.h>

#if defined(__GNUC__) && __GNUC__ >= 4
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FFI_PLUGIN_EXPORT
#endif

typedef struct {
    double elapsed_ms;   
    double bandwidth_mb;  
} MemoryBandwidthResult;

typedef struct {
    double avg_ns;
    int steps;
} MemoryLatencyResult;

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT MemoryBandwidthResult run_memory_bandwidth_test(int size_in_mb);
FFI_PLUGIN_EXPORT MemoryLatencyResult run_memory_latency_test(int steps);

#ifdef __cplusplus
}
#endif


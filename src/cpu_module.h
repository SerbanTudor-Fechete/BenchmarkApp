#pragma once 

#include <stdint.h>

#if defined(__GNUC__) && __GNUC__ >= 4
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FFI_PLUGIN_EXPORT
#endif

typedef struct 
{
    double elapsed_ms;
    double score;   
} RawBenchmarkResult;


#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT RawBenchmarkResult run_fibonacci_test(int target_n);

FFI_PLUGIN_EXPORT RawBenchmarkResult run_matrix_test_singlethreaded(int target_n);

FFI_PLUGIN_EXPORT RawBenchmarkResult run_matrix_test_multithreaded(int size);


#ifdef __cplusplus
}
#endif


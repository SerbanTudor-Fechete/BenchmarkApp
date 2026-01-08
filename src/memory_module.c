#include "memory_module.h"
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h> 

double get_time_in_ms() {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000.0 + t.tv_nsec / 1000000.0;
}

uint64_t get_time_in_ns() {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (uint64_t)t.tv_sec * 1000000000 + (uint64_t)t.tv_nsec;
}

FFI_PLUGIN_EXPORT MemoryBandwidthResult run_memory_bandwidth_test(int mb) {
    MemoryBandwidthResult res;
    res.bandwidth_mb = 0;
    res.elapsed_ms = 0;

    long long total_bytes = (long long)mb * 1024 * 1024;
    
    uint64_t *arr = (uint64_t*)malloc(total_bytes);
    
    if (arr == NULL) return res;

    long long count = total_bytes / sizeof(uint64_t);

    for (long long i = 0; i < count; i++) {
        arr[i] = (uint64_t)i;
    }

    volatile uint64_t dummy_sink = 0; 

    double start_time = get_time_in_ms();
    int loops = 50;

    for (int k = 0; k < loops; k++) {
        for (long long i = 0; i < count; i++) {
            dummy_sink = arr[i]; 
        }
    }

    double end_time = get_time_in_ms();
    
    res.elapsed_ms = end_time - start_time;
    double total_data_mb = (double)(total_bytes * loops) / (1024.0 * 1024.0);
    
    if (res.elapsed_ms > 0) {
        res.bandwidth_mb = total_data_mb / (res.elapsed_ms / 1000.0);
    }

    free(arr);
    return res;
}

FFI_PLUGIN_EXPORT MemoryLatencyResult run_memory_latency_test(int steps) {
    MemoryLatencyResult res;
    res.avg_ns = 0;
    res.steps = steps;

    if (steps <= 0) return res;

    int *arr = (int *)malloc(sizeof(int) * steps);
    if (!arr) return res;

    int *indices = (int *)malloc(sizeof(int) * steps);
    if (!indices) {
        free(arr);
        return res;
    }

    for (int i = 0; i < steps; i++) {
        indices[i] = i;
    }

    srand(time(NULL)); 
    for (int i = steps - 1; i > 0; i--) {
        int j = rand() % (i + 1);
        int temp = indices[i];
        indices[i] = indices[j];
        indices[j] = temp;
    }

    for (int i = 0; i < steps - 1; i++) {
        arr[indices[i]] = indices[i + 1];
    }
    arr[indices[steps - 1]] = indices[0];

    free(indices);

    volatile int index = 0;

    uint64_t start_ns = get_time_in_ns();

    for (int i = 0; i < steps; i++) {
        index = arr[index];
    }

    uint64_t end_ns = get_time_in_ns();

    free(arr);

    res.avg_ns = (double)(end_ns - start_ns) / steps;

    return res;
}
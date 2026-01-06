#pragma once 

#include <stdint.h>

#if defined(__GNUC__) && __GNUC__ >= 4
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FFI_PLUGIN_EXPORT
#endif

typedef struct {
    char manufacturer[128];
    char model[128];
    char chipset_model[64];
    char android_version[64];
    uint64_t total_ram;
    uint64_t cpu_cores;
} SystemSpecs; 


#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT SystemSpecs display_system_specs();


#ifdef __cplusplus
}
#endif


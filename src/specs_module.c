#include "specs_module.h";

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>

#include <pthread.h>
#include <unistd.h>
#include <sys/system_properties.h>

static void read_prop(const char* key, char* out, size_t size) {
    char tmp[PROP_VALUE_MAX] = {0};
    int len = __system_property_get(key, tmp);

    if (len > 0) {
        strncpy(out, tmp, size - 1);
        out[size - 1] = '\0';
    } else {
        snprintf(out, size, "unknown");
    }
}

static uint64_t read_total_ram() {
    FILE* f = fopen("/proc/meminfo", "r");
    if (!f) return 0;

    char label[64];
    uint64_t value_kb = 0;
    char unit[32];

    while (fscanf(f, "%63s %lu %31s", label, &value_kb, unit) == 3) {
        if (strcmp(label, "MemTotal:") == 0) {
            fclose(f);
            return value_kb * 1024;
        }
    }

    fclose(f);
    return 0;
}

static uint64_t count_cpu_cores() {
    uint64_t count = 0;
    char path[128];

    while (1) {
        snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%lu", count);
        if (access(path, F_OK) != 0) {
            break;
        }
        count++;
    }

    return count > 0 ? count : 1;
}

SystemSpecs display_system_specs()
{
    SystemSpecs specs;
    memset(&specs, 0, sizeof(SystemSpecs));
    read_prop("ro.product.manufacturer", specs.manufacturer, sizeof(specs.manufacturer));
    read_prop("ro.product.model",        specs.model, sizeof(specs.model));
    read_prop("ro.board.platform",       specs.chipset_model, sizeof(specs.chipset_model));
    read_prop("ro.build.version.release", specs.android_version, sizeof(specs.android_version));
    specs.total_ram = read_total_ram();
    specs.cpu_cores = count_cpu_cores();

    return specs;

}
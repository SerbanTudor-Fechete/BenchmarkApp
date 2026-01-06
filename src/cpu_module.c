
#include "cpu_module.h"
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#include <pthread.h>
#include <unistd.h>
#include <android/log.h>

#define TIMESPEC_TO_MS(start, end) \
    (((double)((end).tv_sec - (start).tv_sec) * 1000.0) + \
    ((double)((end).tv_nsec - (start).tv_nsec) / 1000000.0))

static int64_t run_fibonacci(int n) {
    if (n<=1) return n;
    return run_fibonacci(n-1) + run_fibonacci(n-2);
}

void matrix_worker(double* A, double* B, double* C, int size, int start_row, int end_row) {
    for (int i = start_row; i < end_row; i++) {
        for (int k = 0; k < size; k++) {
            for (int j = 0; j < size; j++) {
                C[i * size + j] += A[i * size + k] * B[k * size + j];
            }
        }
    }
}

int setup_matrices(double** A_ptr, double** B_ptr, double** C_ptr, int size) {
    size_t n_elements = (size_t)size * size;
    *A_ptr = (double*)calloc(n_elements, sizeof(double));
    *B_ptr = (double*)calloc(n_elements, sizeof(double));
    *C_ptr = (double*)calloc(n_elements, sizeof(double));

    if (*A_ptr == NULL || *B_ptr == NULL || *C_ptr == NULL) {
        free(*A_ptr);
        free(*B_ptr);
        free(*C_ptr);
        return 0; 
    }
    double* A = *A_ptr;
    double* B = *B_ptr;
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            A[i * size + j] = (double)i + 1.0;
            B[i * size + j] = (double)j + 1.0;
        }
    }
    return 1; 
}

void cleanup_matrices(double* A, double* B, double* C) {
    free(A);
    free(B);
    free(C);
}

double calculate_gflops(int size, double elapsed_ms) {
    double operations = 2.0 * pow((double)size, 3);
    double gflops = operations / (elapsed_ms / 1000.0) / 1e9;
    return gflops;
}



FFI_PLUGIN_EXPORT RawBenchmarkResult run_fibonacci_test(int target_n){
    
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    int64_t fib_result =  run_fibonacci(target_n);
    clock_gettime(CLOCK_MONOTONIC, &end);

    double elapsed_ms = TIMESPEC_TO_MS(start, end);
    RawBenchmarkResult result;
    result.elapsed_ms = elapsed_ms;
    result.score =  (1.0 / elapsed_ms) * 1000.0; 
    
    return result;
}


FFI_PLUGIN_EXPORT RawBenchmarkResult run_matrix_test_singlethreaded(int size) {
    double *A = NULL, *B = NULL, *C = NULL;
    if (!setup_matrices(&A, &B, &C, size)) {
        return (RawBenchmarkResult){0.0, -1.0}; 
    }
    
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    matrix_worker(A, B, C, size, 0, size);
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_ms = TIMESPEC_TO_MS(start, end);
    
    cleanup_matrices(A, B, C);
    
    RawBenchmarkResult res;
    res.elapsed_ms = elapsed_ms;
    res.score = calculate_gflops(size, elapsed_ms);
    return res;
}

int number_of_threads() {
    long n = sysconf(_SC_NPROCESSORS_ONLN);
    return (int)(n > 0 ? n : 1);
}

typedef struct {
    double* A;
    double* B;
    double* C;
    int size;
    int start_row;
    int end_row;
    double elapsed_ms;
} MatrixWorkerArgs;

void* matrix_worker_pthread(void* arg) {
    MatrixWorkerArgs* data = (MatrixWorkerArgs*)arg;
    for (int i = data->start_row; i < data->end_row; i++) {
        double* Ci = data->C + i * data->size;
        for (int k = 0; k < data->size; k++) {
            double Aik = data->A[i * data->size + k];
            double* Bk = data->B + k * data->size;
            for (int j = 0; j < data->size; j++) {
                Ci[j] += Aik * Bk[j];
            }
        }
    }
    return NULL;
}

FFI_PLUGIN_EXPORT RawBenchmarkResult run_matrix_test_multithreaded(int size) {
    double *A = NULL, *B = NULL, *C = NULL;
    if (!setup_matrices(&A, &B, &C, size)) {
        return (RawBenchmarkResult){0.0, -1.0};
    }

    int num_threads = number_of_threads();
    if (num_threads <= 0) num_threads = 1;

    pthread_t* threads = malloc(num_threads * sizeof(pthread_t));
    MatrixWorkerArgs* args = malloc(num_threads * sizeof(MatrixWorkerArgs));

    if (!threads || !args) {
        cleanup_matrices(A, B, C);
        free(threads);
        free(args);
        return (RawBenchmarkResult){0.0, -2.0};
    }

    int rows_per_thread = size / num_threads;
    int start_row = 0;

    struct timespec start_total, end_total;
    clock_gettime(CLOCK_MONOTONIC, &start_total);

    for (int t = 0; t < num_threads; t++) {
        int end_row = (t == num_threads - 1) ? size : start_row + rows_per_thread;
        args[t] = (MatrixWorkerArgs){A, B, C, size, start_row, end_row, 0.0};
        pthread_create(&threads[t], NULL, matrix_worker_pthread, &args[t]);
        start_row = end_row;
    }

    for (int t = 0; t < num_threads; t++) {
        pthread_join(threads[t], NULL);
    }

    clock_gettime(CLOCK_MONOTONIC, &end_total);
    double elapsed_ms = TIMESPEC_TO_MS(start_total, end_total);
    double gflops = calculate_gflops(size, elapsed_ms);

    cleanup_matrices(A, B, C);
    free(threads);
    free(args);

    RawBenchmarkResult res;
    res.elapsed_ms = elapsed_ms;
    res.score = gflops;
    return res;
}

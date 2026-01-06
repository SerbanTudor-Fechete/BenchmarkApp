#include "gpu_module.h"
#include <EGL/egl.h>
#include <GLES3/gl31.h>
#include <time.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h> 
#define WIDTH 1920
#define HEIGHT 1080
#define GRID_SIZE 35        
#define FRAG_LOOP 750     
#define STR(x) #x
#define XSTR(x) STR(x)

typedef struct { float m[16]; } Mat4;

static void mat4_identity(Mat4* mat) {
    for (int i = 0; i < 16; i++) mat->m[i] = 0.0f;
    mat->m[0] = mat->m[5] = mat->m[10] = mat->m[15] = 1.0f;
}

static void mat4_multiply(Mat4* res, const Mat4* a, const Mat4* b) {
    Mat4 temp;
    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            float sum = 0;
            for (int k = 0; k < 4; k++) sum += a->m[k * 4 + r] * b->m[c * 4 + k];
            temp.m[c * 4 + r] = sum;
        }
    }
    *res = temp;
}

static void mat4_perspective(Mat4* m, float fov, float aspect, float znear, float zfar) {
    float f = 1.0f / tanf(fov / 2.0f);
    mat4_identity(m);
    m->m[0] = f / aspect;
    m->m[5] = f;
    m->m[10] = (zfar + znear) / (znear - zfar);
    m->m[11] = -1.0f;
    m->m[14] = (2.0f * zfar * znear) / (znear - zfar);
    m->m[15] = 0.0f;
}

static void mat4_translate_rotate(Mat4* m, float tx, float ty, float tz, float angle) {
    float c = cosf(angle);
    float s = sinf(angle);
    m->m[0] = c;   m->m[4] = 0; m->m[8] = s;   m->m[12] = tx;
    m->m[1] = 0;   m->m[5] = 1; m->m[9] = 0;   m->m[13] = ty;
    m->m[2] = -s;  m->m[6] = 0; m->m[10] = c;  m->m[14] = tz;
    m->m[3] = 0;   m->m[7] = 0; m->m[11] = 0;  m->m[15] = 1;
}

static double now_in_seconds() {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}


static const char* vert_src =
    "#version 300 es\n"
    "layout(location = 0) in vec3 vPosition;\n"
    "layout(location = 1) in vec3 vColor;\n"
    "uniform mat4 uMVP;\n"
    "out vec3 fColor;\n"
    "void main() {\n"
    "   gl_Position = uMVP * vec4(vPosition, 1.0);\n"
    "   fColor = vColor;\n"
    "}\n";

static const char* frag_src =
    "#version 300 es\n"
    "precision highp float;\n"
    "in vec3 fColor;\n"
    "out vec4 fragColor;\n"
    "void main() {\n"
    "   float v = 0.5;\n"
    "   float offset = gl_FragCoord.x * 0.001;\n" 
    "   for (int i = 0; i < " XSTR(FRAG_LOOP) "; i++) {\n"
    "       v += sin(float(i)*0.05 + offset) * cos(fColor.r);\n"
    "   }\n"
    "   fragColor = vec4(fract(v) * fColor, 0.1);\n" 
    "}\n";

static GLuint load_program(const char* vert, const char* frag) {
    GLuint vs = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vs, 1, &vert, NULL);
    glCompileShader(vs);
    GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fs, 1, &frag, NULL);
    glCompileShader(fs);
    GLuint program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    return program;
}

static const float cube_verts[] = {
    -0.4f,-0.4f, 0.4f,  0.4f,-0.4f, 0.4f,  0.4f, 0.4f, 0.4f,
    -0.4f,-0.4f, 0.4f,  0.4f, 0.4f, 0.4f, -0.4f, 0.4f, 0.4f, 
    -0.4f,-0.4f,-0.4f, -0.4f, 0.4f,-0.4f,  0.4f, 0.4f,-0.4f,
    -0.4f,-0.4f,-0.4f,  0.4f, 0.4f,-0.4f,  0.4f,-0.4f,-0.4f, 
    -0.4f, 0.4f,-0.4f, -0.4f, 0.4f, 0.4f,  0.4f, 0.4f, 0.4f,
    -0.4f, 0.4f,-0.4f,  0.4f, 0.4f, 0.4f,  0.4f, 0.4f,-0.4f, 
    -0.4f,-0.4f,-0.4f,  0.4f,-0.4f,-0.4f,  0.4f,-0.4f, 0.4f,
    -0.4f,-0.4f,-0.4f,  0.4f,-0.4f, 0.4f, -0.4f,-0.4f, 0.4f, 
     0.4f,-0.4f,-0.4f,  0.4f, 0.4f,-0.4f,  0.4f, 0.4f, 0.4f,
     0.4f,-0.4f,-0.4f,  0.4f, 0.4f, 0.4f,  0.4f,-0.4f, 0.4f, 
    -0.4f,-0.4f,-0.4f, -0.4f,-0.4f, 0.4f, -0.4f, 0.4f, 0.4f,
    -0.4f,-0.4f,-0.4f, -0.4f, 0.4f, 0.4f, -0.4f, 0.4f,-0.4f  
};

static float cube_colors[36 * 3]; 


FFI_PLUGIN_EXPORT double run_offscreen_render_benchmark(double duration_seconds) {
    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    eglInitialize(display, NULL, NULL);
    const EGLint config_attribs[] = { EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT, EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_NONE };
    EGLConfig config; EGLint num_configs;
    eglChooseConfig(display, config_attribs, &config, 1, &num_configs);
    const EGLint pbuf_attribs[] = { EGL_WIDTH, WIDTH, EGL_HEIGHT, HEIGHT, EGL_NONE };
    EGLSurface surface = eglCreatePbufferSurface(display, config, pbuf_attribs);
    const EGLint ctx_attribs[] = { EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE };
    EGLContext ctx = eglCreateContext(display, config, EGL_NO_CONTEXT, ctx_attribs);
    eglMakeCurrent(display, surface, surface, ctx);

    GLuint fbo, tex, depth;
    glGenFramebuffers(1, &fbo);
    glGenTextures(1, &tex);
    glGenRenderbuffers(1, &depth);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindRenderbuffer(GL_RENDERBUFFER, depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, WIDTH, HEIGHT);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depth);

    GLuint program = load_program(vert_src, frag_src);
    glUseProgram(program);
    glViewport(0, 0, WIDTH, HEIGHT);
    glDisable(GL_DEPTH_TEST);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    for(int i=0; i<36*3; i++) cube_colors[i] = (float)(i%10)/10.0f;

    GLuint vbo[2];
    glGenBuffers(2, vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cube_verts), cube_verts, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cube_colors), cube_colors, GL_STATIC_DRAW);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(1);

    GLint mvpLoc = glGetUniformLocation(program, "uMVP");

    long frames = 0;
    double start = now_in_seconds();
    double now = start;

    Mat4 proj, model, mvp;
    mat4_perspective(&proj, 1.04f, (float)WIDTH/HEIGHT, 0.1f, 100.0f);

    while ((now - start) < duration_seconds) {
        glClearColor(0.1, 0.1, 0.1, 1.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        float time = (float)(now - start);
        float base_rot = time * 2.0f;

        for (int x = 0; x < GRID_SIZE; x++) {
            for (int y = 0; y < GRID_SIZE; y++) {
                float wx = (x - GRID_SIZE/2.0f) * 1.2f; 
                float wy = (y - GRID_SIZE/2.0f) * 1.2f;
                float wz = -40.0f; 

                mat4_translate_rotate(&model, wx, wy, wz, base_rot + x*0.1f);
                
                mat4_multiply(&mvp, &proj, &model);
                
                glUniformMatrix4fv(mvpLoc, 1, GL_FALSE, mvp.m);
                glDrawArrays(GL_TRIANGLES, 0, 36);
            }
        }

        unsigned char pixel[4];
        glReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);

        
        frames++;
        now = now_in_seconds();
    }

    glDeleteFramebuffers(1, &fbo);
    glDeleteTextures(1, &tex);
    glDeleteRenderbuffers(1, &depth);
    glDeleteBuffers(2, vbo);
    glDeleteProgram(program);
    eglTerminate(display);

    return (double)frames / (now - start);
}
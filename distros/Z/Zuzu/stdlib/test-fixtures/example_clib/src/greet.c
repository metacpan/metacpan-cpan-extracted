#include "greet.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int64_t greet_free_calls = 0;

static char *dup_cstr(const char *s) {
    size_t len = strlen(s);
    char *out = (char *)malloc(len + 1);
    if (out == NULL) {
        return NULL;
    }
    memcpy(out, s, len + 1);
    return out;
}

char *greet(void) {
    return dup_cstr("Hello, world!");
}

char *greet_person(const char *name) {
    const char *actual_name =
        (name != NULL && name[0] != '\0') ? name : "world";
    int needed = snprintf(NULL, 0, "Hello, %s!", actual_name);
    if (needed < 0) {
        return NULL;
    }

    char *out = (char *)malloc((size_t)needed + 1);
    if (out == NULL) {
        return NULL;
    }

    int written = snprintf(out, (size_t)needed + 1, "Hello, %s!", actual_name);
    if (written < 0 || written != needed) {
        free(out);
        return NULL;
    }

    return out;
}

void greet_free(char *s) {
    greet_free_calls++;
    free(s);
}

int64_t greet_free_count(void) {
    return greet_free_calls;
}

void greet_reset_free_count(void) {
    greet_free_calls = 0;
}

int64_t greet_add_i64(int64_t left, int64_t right) {
    return left + right;
}

double greet_add_f64(double left, double right) {
    return left + right;
}

bool greet_not(bool value) {
    return !value;
}

void greet_noop(void) {
}

char *greet_return_null(void) {
    return NULL;
}

char *greet_copy_bytes(const char *bytes, int64_t len) {
    if (len < 0) {
        return NULL;
    }

    if (bytes == NULL && len > 0) {
        return NULL;
    }

    size_t size = (size_t)len;
    char *out = (char *)malloc(size > 0 ? size : 1);
    if (out == NULL) {
        return NULL;
    }

    if (size > 0) {
        memcpy(out, bytes, size);
    }

    return out;
}

int64_t greet_count_bytes(const char *bytes, int64_t len) {
    if (len < 0) {
        return -1;
    }

    if (bytes == NULL && len > 0) {
        return -1;
    }

    return len;
}

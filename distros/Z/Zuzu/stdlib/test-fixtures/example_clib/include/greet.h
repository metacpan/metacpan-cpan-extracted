#ifndef GREET_H
#define GREET_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

char *greet(void);
char *greet_person(const char *name);
void greet_free(char *s);
int64_t greet_free_count(void);
void greet_reset_free_count(void);
int64_t greet_add_i64(int64_t left, int64_t right);
double greet_add_f64(double left, double right);
bool greet_not(bool value);
void greet_noop(void);
char *greet_return_null(void);
char *greet_copy_bytes(const char *bytes, int64_t len);
int64_t greet_count_bytes(const char *bytes, int64_t len);

#ifdef __cplusplus
}
#endif

#endif

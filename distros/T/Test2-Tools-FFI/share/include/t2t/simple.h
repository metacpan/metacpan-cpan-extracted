#ifndef T2T_SIMPLE_H
#define T2T_SIMPLE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*t2t_simple_message_cb)(const char *, const char *, const char *, int, const char *);

void t2t_simple_note(const char *, const char *, int, const char *, const char *);
void t2t_simple_notef(const char *, const char *, int, const char *, const char *, ...);
void t2t_simple_diag(const char *, const char *, int, const char *, const char *);
void t2t_simple_diagf(const char *, const char *, int, const char *, const char *, ...);
int t2t_simple_pass(const char *, const char *, int, const char *, const char *);
int t2t_simple_fail(const char *, const char *, int, const char *, const char *);

#ifndef T2T_SIMPLE_API_ONLY
#define note(message) t2t_simple_note("c", __FILE__, __LINE__, __func__, message)
#define notef(format, ...) t2t_simple_notef("c", __FILE__, __LINE__, __func__, format, __VA_ARGS__)
#define diag(message) t2t_simple_diag("c", __FILE__, __LINE__, __func__, message)
#define diagf(format, ...) t2t_simple_diagf("c", __FILE__, __LINE__, __func__, format, __VA_ARGS__)
#define pass(message) t2t_simple_pass("c", __FILE__, __LINE__, __func__, message)
#define fail(message) t2t_simple_fail("c", __FILE__, __LINE__, __func__, message)
#define ok(expression, message) expression ? t2t_simple_pass("c", __FILE__, __LINE__, __func__, message) : t2t_simple_fail("c", __FILE__, __LINE__, __func__, message)
#endif

void t2t_simple_init(t2t_simple_message_cb, t2t_simple_message_cb, t2t_simple_message_cb, t2t_simple_message_cb);
void t2t_simple_deinit();

#ifdef __cplusplus
}
#endif

#endif

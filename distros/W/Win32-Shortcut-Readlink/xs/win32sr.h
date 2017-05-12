#ifndef WIN32SR_H
#define WIN32SR_H

#if defined(__cplusplus)
extern "C" {
#endif

typedef const char *maybe_string;
const char *resolve(const char *link_name);

#if defined(__cplusplus)
}
#endif

#endif

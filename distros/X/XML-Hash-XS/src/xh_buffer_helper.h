#ifndef _XH_BUFFER_HELPER_H_
#define _XH_BUFFER_HELPER_H_

#include "xh_config.h"
#include "xh_core.h"

#define XH_BUFFER_WRITE_LONG_STRING(b, s, l)                           \
    memcpy(b->cur, s, l);                                              \
    b->cur += l;
#define XH_BUFFER_WRITE_SHORT_STRING(b, s, l)                          \
    while (l--) {                                                      \
        *b->cur++ = *s++;                                              \
    }
#define XH_BUFFER_WRITE_STRING(b, s, l)                                \
    if (l < 17) {                                                      \
        XH_BUFFER_WRITE_SHORT_STRING(b, s, l)                          \
    }                                                                  \
    else {                                                             \
        XH_BUFFER_WRITE_LONG_STRING(b, s, l)                           \
    }
#define XH_BUFFER_WRITE_CHAR(b, c)                                     \
    *b->cur++ = c;
#define XH_BUFFER_WRITE_CHAR2(b, s)                                    \
    *((uint16_t *) b->cur) = *((uint16_t *) (s));                      \
    b->cur += 2;
#define XH_BUFFER_WRITE_CHAR3(b, s)                                    \
    XH_BUFFER_WRITE_CHAR2(b, s)                                        \
    XH_BUFFER_WRITE_CHAR(b, s[2])
#define XH_BUFFER_WRITE_CHAR4(b, s)                                    \
    *((uint32_t *) b->cur) = *((uint32_t *) (s));                      \
    b->cur += 4;
#define XH_BUFFER_WRITE_CHAR5(b, s)                                    \
    XH_BUFFER_WRITE_CHAR4(b, s)                                        \
    XH_BUFFER_WRITE_CHAR(b, s[4])
#define XH_BUFFER_WRITE_CHAR6(b, s)                                    \
    XH_BUFFER_WRITE_CHAR4(b, s)                                        \
    XH_BUFFER_WRITE_CHAR2(b, s + 4)
#define XH_BUFFER_WRITE_CHAR7(b, s)                                    \
    XH_BUFFER_WRITE_CHAR6(b, s)                                        \
    XH_BUFFER_WRITE_CHAR(b, s[6])
#define XH_BUFFER_WRITE_CHAR8(b, s)                                    \
    XH_BUFFER_WRITE_CHAR4(b, s)                                        \
    XH_BUFFER_WRITE_CHAR4(b, s + 4)
#define XH_BUFFER_WRITE_CHAR9(b, s)                                    \
    XH_BUFFER_WRITE_CHAR8(b, s)                                        \
    XH_BUFFER_WRITE_CHAR(b, s[8])
#define XH_BUFFER_WRITE_ESCAPE_STRING(b, s, l)                         \
    while (l--) {                                                      \
        switch (*b->cur = *s++) {                                      \
            case '\r':                                                 \
                XH_BUFFER_WRITE_CHAR5(b, "&#13;")                      \
                break;                                                 \
            case '<':                                                  \
                XH_BUFFER_WRITE_CHAR4(b, "&lt;")                       \
                break;                                                 \
            case '>':                                                  \
                XH_BUFFER_WRITE_CHAR4(b, "&gt;")                       \
                break;                                                 \
            case '&':                                                  \
                XH_BUFFER_WRITE_CHAR5(b, "&amp;")                      \
                break;                                                 \
            default:                                                   \
                b->cur++;                                              \
        }                                                              \
    }
#define XH_BUFFER_WRITE_ESCAPE_ATTR(b, s, l)                           \
    while (l--) {                                                      \
        switch (*b->cur = *s++) {                                      \
            case '\n':                                                 \
                XH_BUFFER_WRITE_CHAR5(b, "&#10;")                      \
                break;                                                 \
            case '\r':                                                 \
                XH_BUFFER_WRITE_CHAR5(b, "&#13;")                      \
                break;                                                 \
            case '\t':                                                 \
                XH_BUFFER_WRITE_CHAR4(b, "&#9;")                       \
                break;                                                 \
            case '<':                                                  \
                XH_BUFFER_WRITE_CHAR4(b, "&lt;")                       \
                break;                                                 \
            case '>':                                                  \
                XH_BUFFER_WRITE_CHAR4(b, "&gt;")                       \
                break;                                                 \
            case '&':                                                  \
                XH_BUFFER_WRITE_CHAR5(b, "&amp;")                      \
                break;                                                 \
            case '"':                                                  \
                XH_BUFFER_WRITE_CHAR6(b, "&quot;")                     \
                break;                                                 \
            default:                                                   \
                b->cur++;                                              \
        }                                                              \
    }
#define XH_BUFFER_WRITE_CONSTANT(b, s)                                 \
    XH_BUFFER_WRITE_LONG_STRING(b, s, sizeof(s) - 1)

#endif /* _XH_BUFFER_HELPER_H_ */

#ifndef _XH_STRING_H_
#define _XH_STRING_H_

#include "xh_config.h"
#include "xh_core.h"

#define xh_str_equal2(p, c0, c1)                                        \
    ((((uint32_t *) (p))[0] & 0xffff) == ((c1 << 8) | c0))

#define xh_str_equal3(p, c0, c1, c2)                                    \
    ((((uint32_t *) (p))[0]  & 0xffffff) == ((c2 << 16) | (c1 << 8) | c0))

#define xh_str_equal4(p, c0, c1, c2, c3)                                \
    (*(uint32_t *) (p) == ((c3 << 24) | (c2 << 16) | (c1 << 8) | c0))

#define xh_str_equal5(p, c0, c1, c2, c3, c4)                            \
    (xh_str_equal4(p, c0, c1, c2, c3) && (p)[4] == c4)

#define xh_str_equal6(p, c0, c1, c2, c3, c4, c5)                        \
    (xh_str_equal4(p, c0, c1, c2, c3) && xh_str_equal2(&p[4], c4, c5))

#define xh_str_equal7(p, c0, c1, c2, c3, c4, c5, c6)                    \
    (xh_str_equal4(p, c0, c1, c2, c3) && xh_str_equal3(&p[4], c4, c5, c6))

#define xh_str_equal8(p, c0, c1, c2, c3, c4, c5, c6, c7)                \
    (xh_str_equal4(p, c0, c1, c2, c3) && xh_str_equal4(&p[4], c4, c5, c6, c7))

#define xh_str_equal9(p, c0, c1, c2, c3, c4, c5, c6, c7, c8)            \
    (xh_str_equal8(p, c0, c1, c2, c3, c4, c5, c6, c7) && (p)[8] == c8)

#define xh_str_equal10(p, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)       \
    (xh_str_equal8(p, c0, c1, c2, c3, c4, c5, c6, c7) && xh_str_equal2(&p[8], c8, c9))

#define xh_str_equal11(p, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10)  \
    (xh_str_equal8(p, c0, c1, c2, c3, c4, c5, c6, c7) && xh_str_equal3(&p[8], c8, c9, c10))

#define xh_str_equal12(p, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11)\
    (xh_str_equal8(p, c0, c1, c2, c3, c4, c5, c6, c7) && xh_str_equal4(&p[8], c8, c9, c10, c11))

#define xh_str_equal13(p, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12)\
    (xh_str_equal8(p, c0, c1, c2, c3, c4, c5, c6, c7) && xh_str_equal5(&p[8], c8, c9, c10, c11, c12))


#define xh_strcmp(s1, s2)       strcmp((const char *) (s1), (const char *) (s2))
#define xh_strcasecmp(s1, s2)   strcasecmp((const char *) (s1), (const char *) (s2))
#define xh_strncmp(s1, s2, n)   strncmp((const char *) (s1), (const char *) (s2), (n))
#define xh_strlen(s)            strlen((const char *) (s))
#define xh_strcpy(d, s)         strcpy((char *) (d), (const char *) (s))
#define xh_strncpy(d, s, n)     strncpy((char *) (d), (const char *) (s), (n))

XH_INLINE xh_char_t *
xh_str_trim(xh_char_t *s, size_t *len)
{
    xh_char_t *end, ch;

    end = s + *len;

    while ((ch = *s++) == ' ' || ch == '\t' || ch == '\n' || ch == '\r');
    if (ch == '\0') {
        *len = 0;
        return s - 1;
    }

    s--;

    while (--end != s && ((ch = *end) == ' ' || ch == '\t' || ch == '\n' || ch == '\r'));

    *len = end - s + 1;

    return s;
}

XH_INLINE xh_char_t *
xh_str_copy(xh_char_t *dest, const xh_char_t *src, size_t n)
{
    dest[--n] = '\0';
    return XH_CHAR_CAST strncpy((char *) dest, (const char *) src, n);
}

XH_INLINE xh_char_t *
xh_str_range_copy(xh_char_t *dest, const xh_char_t *src, size_t l, size_t n)
{
    if (l < n) n = l + 1;
    dest[--n] = '\0';
    return XH_CHAR_CAST strncpy((char *) dest, (const char *) src, n);
}

XH_INLINE void
xh_memmove(xh_char_t *dest, const xh_char_t *src, size_t n)
{
    while (n--) *dest++ = *src++;
}

XH_INLINE xh_bool_t
xh_str_is_xml(xh_char_t *s)
{
    xh_char_t ch;

    while ((ch = *s++) == ' ' || ch =='\t' || ch == '\n' || ch == '\r');
    if (ch == '<') return TRUE;

    return FALSE;
}

#endif /* _XH_STRING_H_ */

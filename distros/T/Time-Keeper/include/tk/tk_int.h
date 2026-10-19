#ifndef TK_INT_H
#define TK_INT_H

/* Instants are 64-bit seconds on every perl, 32-bit ones included: refuse
 * to build where int64_t is not eight bytes. */
typedef char tk_int64_is_eight_bytes[sizeof(int64_t) == 8 ? 1 : -1];


/* What a day past a shorter month's end does: runs on, is cut to the
 * month's last, or, when it was its month's last, is the last again. */
#define TK_EOM_WRAP     0
#define TK_EOM_LIMIT    1
#define TK_EOM_PRESERVE 2

#endif

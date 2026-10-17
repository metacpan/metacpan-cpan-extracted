#ifndef TK_INT_H
#define TK_INT_H

/* Instants are 64-bit seconds on every perl, 32-bit ones included: refuse
 * to build where int64_t is not eight bytes. */
typedef char tk_int64_is_eight_bytes[sizeof(int64_t) == 8 ? 1 : -1];

#endif

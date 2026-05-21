#if defined(_WIN32)

LONG cmpxchg(LONG *ptr, LONG old, LONG new);
LONG xchg(LONG *ptr, LONG new);
LONG xdec(LONG *ptr);

/*****************************************************************************/
#else  /* ! _WIN32 */
/*****************************************************************************/

extern void __compiletime_error(char *s);

#define UU_cmpxchg_wrong_size(void) __compiletime_error("Bad argument size for cmpxchg")
#define UU_xadd_wrong_size(void)    __compiletime_error("Bad argument size for xadd")
#define UU_xchg_wrong_size(void)    __compiletime_error("Bad argument size for xchg")

#define __X86_CASE_B    1
#define __X86_CASE_W    2
#define __X86_CASE_L    4
#define __X86_CASE_Q    8

/*
 * An exchange-type operation, which takes a value and a pointer, and
 * returns the old value.
 */
#define UU_xchg_op(ptr, arg, op)                 \
    ({                                            \
        __typeof__ (*(ptr)) _ret = (arg);          \
        switch (sizeof(*(ptr))) {                   \
        case __X86_CASE_B:                           \
            asm volatile ("lock; " #op "b %b0, %1\n"  \
                      : "+q" (_ret), "+m" (*(ptr))    \
                      : : "memory", "cc");            \
            break;                                    \
        case __X86_CASE_W:                            \
            asm volatile ("lock; " #op "w %w0, %1\n"  \
                      : "+r" (_ret), "+m" (*(ptr))    \
                      : : "memory", "cc");            \
            break;                                    \
        case __X86_CASE_L:                            \
            asm volatile ("lock; " #op "l %0, %1\n"   \
                      : "+r" (_ret), "+m" (*(ptr))    \
                      : : "memory", "cc");            \
            break;                                    \
        case __X86_CASE_Q:                            \
            asm volatile ("lock; " #op "q %q0, %1\n"  \
                      : "+r" (_ret), "+m" (*(ptr))    \
                      : : "memory", "cc");           \
            break;                                  \
        default:                                   \
            UU_ ## op ## _wrong_size();           \
        }                                        \
        _ret;                                   \
    })

/*
 * xadd() adds "inc" to "*ptr" and atomically returns the previous
 * value of "*ptr".
 */
#define xadd(ptr, inc)    UU_xchg_op((ptr), (inc), xadd)
#define xchg(ptr, val)    UU_xchg_op((ptr), (val), xchg)

#define xinc(ptr)   xadd((ptr),  1)
#define xdec(ptr)   xadd((ptr), -1)

typedef unsigned char          u8;
typedef unsigned int           u16;
typedef unsigned long int      u32;
typedef unsigned long long int u64;

/*
 * Atomic compare and exchange.  Compare OLD with MEM, if identical,
 * store NEW in MEM.  Return the initial value in MEM.  Success is
 * indicated by comparing RETURN with OLD.
 */
#define cmpxchg(ptr, old, new)             \
({                                          \
    __typeof__ (*(ptr)) _ret;                \
    __typeof__ (*(ptr)) _old = (old);         \
    __typeof__ (*(ptr)) _new = (new);          \
    switch (sizeof(*(ptr))) {                   \
    case __X86_CASE_B:                           \
    {                                             \
        volatile u8 *_ptr = (volatile u8 *)(ptr);  \
        asm volatile("lock; cmpxchgb %2,%1"         \
                 : "=a" (_ret), "+m" (*_ptr)         \
                 : "q" (_new), "0" (_old)            \
                 : "memory");                        \
        break;                                       \
    }                                                \
    case __X86_CASE_W:                               \
    {                                                \
        volatile u16 *_ptr = (volatile u16 *)(ptr);  \
        asm volatile("lock; cmpxchgw %2,%1"          \
                 : "=a" (_ret), "+m" (*_ptr)         \
                 : "r" (_new), "0" (_old)            \
                 : "memory");                        \
        break;                                       \
    }                                                \
    case __X86_CASE_L:                               \
    {                                                \
        volatile u32 *_ptr = (volatile u32 *)(ptr);  \
        asm volatile("lock; cmpxchgl %2,%1"          \
                 : "=a" (_ret), "+m" (*_ptr)         \
                 : "r" (_new), "0" (_old)            \
                 : "memory");                        \
        break;                                       \
    }                                                \
    case __X86_CASE_Q:                               \
    {                                                \
        volatile u64 *_ptr = (volatile u64 *)(ptr);  \
        asm volatile("lock; cmpxchgq %2,%1"          \
                 : "=a" (_ret), "+m" (*_ptr)        \
                 : "r" (_new), "0" (_old)          \
                 : "memory");                     \
        break;                                   \
    }                                           \
    default:                                   \
        UU_cmpxchg_wrong_size();              \
    }                                        \
    _ret;                                   \
})

#endif  /* _WIN32 */
/* ex:set ts=2 sw=2 itab=spaces: */

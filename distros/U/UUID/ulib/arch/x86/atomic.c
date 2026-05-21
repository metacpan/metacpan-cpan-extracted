#if defined(_WIN32)

LONG cmpxchg(LONG *ptr, LONG old, LONG new) {
    volatile LONG *_ptr = (volatile LONG *)(ptr);
    return _InterlockedCompareExchange(_ptr, new, old);
}

LONG xchg(LONG *ptr, LONG new) {
    volatile LONG *_ptr = (volatile LONG *)(ptr);
    return _InterlockedExchange(_ptr, new);
}

/* _InterlockedDecrement() returns *ptr AFTER the decrement. *
 * we need value BEFORE decrement.                           *
 *
LONG xdec(LONG *ptr) {
    return _InterlockedDecrement(ptr);
}
*/
LONG xdec(LONG *ptr) {
    LONG r, old;
    do {
        old = *ptr;
        r   = cmpxchg(ptr, old, old-1);
    } while (r != old);
    return r;
}

/*****************************************************************************/
#else  /* ! _WIN32 */
/*****************************************************************************/


#endif  /* _WIN32 */
/* ex:set ts=2 sw=2 itab=spaces: */

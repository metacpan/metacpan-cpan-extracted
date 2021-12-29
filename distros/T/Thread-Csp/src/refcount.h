#include <stdatomic.h>

typedef atomic_size_t Refcount;

#define refcount_inited(counter) (refcount_load(counter) != 0)
#define refcount_load(counter) atomic_load(counter)
#define refcount_init(counter, value) atomic_init(counter, value)
#define refcount_inc(counter) atomic_fetch_add_explicit(counter, 1, memory_order_relaxed)
#define refcount_dec(counter) atomic_fetch_sub_explicit(counter, 1, memory_order_acq_rel)
#define refcount_destroy(count) ((void)0)

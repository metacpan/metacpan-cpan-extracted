/* This is a pointer table implementation essentially copied from the ptr_table
 * implementation in perl's sv.c, except that it has been modified to use memory
 * shared across threads.
 * Copyright goes to the original authors, bug reports to me. */

/* This header is designed to be included several times with different
 * definitions for PTABLE_NAME and PTABLE_VAL_ALLOC/FREE(). */

#include "util.h" /* XSH_ASSERT() */
#include "mem.h"  /* xPMS, XSH_SHARED_*() */

/* --- Configuration ------------------------------------------------------- */

#ifndef PTABLE_USE_DEFAULT
# define PTABLE_USE_DEFAULT 0
#endif

#if PTABLE_USE_DEFAULT
# if defined(PTABLE_VAL_ALLOC) || defined(PTABLE_VAL_FREE)
#  error the default ptable is only available when PTABLE_VAL_ALLOC/FREE are unset
# endif
# undef  PTABLE_NAME
# define PTABLE_NAME ptable_default
# undef  PTABLE_VAL_NEED_CONTEXT
# define PTABLE_VAL_NEED_CONTEXT 0
#else
# ifndef PTABLE_NAME
#  error PTABLE_NAME must be defined
# endif
# ifndef PTABLE_VAL_NEED_CONTEXT
#  define PTABLE_VAL_NEED_CONTEXT 1
# endif
#endif

#ifndef PTABLE_JOIN
# define PTABLE_PASTE(A, B) A ## B
# define PTABLE_JOIN(A, B)  PTABLE_PASTE(A, B)
#endif

#ifndef PTABLE_PREFIX
# define PTABLE_PREFIX(X) PTABLE_JOIN(PTABLE_NAME, X)
#endif

#ifndef PTABLE_NEED_SPLICE
# define PTABLE_NEED_SPLICE 0
#endif

#ifndef PTABLE_NEED_WALK
# define PTABLE_NEED_WALK 0
#endif

#ifndef PTABLE_NEED_STORE
# define PTABLE_NEED_STORE 1
#endif

#ifndef PTABLE_NEED_VIVIFY
# define PTABLE_NEED_VIVIFY 0
#elif PTABLE_NEED_VIVIFY
# undef  PTABLE_NEED_VIVIFY
# ifndef PTABLE_VAL_ALLOC
#  error need to define PTABLE_VAL_ALLOC() to use ptable_vivify()
# endif
# define PTABLE_NEED_VIVIFY 1
#endif

#ifndef PTABLE_NEED_DELETE
# define PTABLE_NEED_DELETE 1
#endif

#ifndef PTABLE_NEED_CLEAR
# define PTABLE_NEED_CLEAR 1
#endif

#undef PTABLE_NEED_ENT_VIVIFY
#if PTABLE_NEED_SPLICE || PTABLE_NEED_STORE || PTABLE_NEED_VIVIFY
# define PTABLE_NEED_ENT_VIVIFY 1
#else
# define PTABLE_NEED_ENT_VIVIFY 0
#endif

#undef PTABLE_NEED_ENT_DETACH
#if PTABLE_NEED_SPLICE || PTABLE_NEED_DELETE
# define PTABLE_NEED_ENT_DETACH 1
#else
# define PTABLE_NEED_ENT_DETACH 0
#endif

/* ... Context for ptable_*() functions calling PTABLE_VAL_ALLOC/FREE() .... */

#undef pPTBL
#undef pPTBL_
#undef aPTBL
#undef aPTBL_

#if PTABLE_VAL_NEED_CONTEXT
# define pPTBL  pTHX
# define pPTBL_ pTHX_
# define aPTBL  aTHX
# define aPTBL_ aTHX_
#else
# define pPTBL  pPMS
# define pPTBL_ pPMS_
# define aPTBL  aPMS
# define aPTBL_ aPMS_
#endif

/* --- <ptable> struct ----------------------------------------------------- */

#ifndef ptable_ent
typedef struct ptable_ent {
 struct ptable_ent *next;
 const void *       key;
 void *             val;
} ptable_ent;
#define ptable_ent ptable_ent
#endif /* !ptable_ent */

#ifndef ptable
typedef struct ptable {
 ptable_ent **ary;
 size_t       max;
 size_t       items;
} ptable;
#define ptable ptable
#endif /* !ptable */

/* --- Private interface --------------------------------------------------- */

#ifndef PTABLE_HASH
# define PTABLE_HASH(ptr) \
     ((PTR2UV(ptr) >> 3) ^ (PTR2UV(ptr) >> (3 + 7)) ^ (PTR2UV(ptr) >> (3 + 17)))
#endif

#ifndef ptable_bucket
# define ptable_bucket(T, K) (PTABLE_HASH(K) & (T)->max)
#endif

#ifndef ptable_ent_find
static ptable_ent *ptable_ent_find(const ptable *t, const void *key) {
#define ptable_ent_find ptable_ent_find
 ptable_ent  *ent;
 const size_t idx = ptable_bucket(t, key);

 ent = t->ary[idx];
 for (; ent; ent = ent->next) {
  if (ent->key == key)
   return ent;
 }

 return NULL;
}
#endif /* !ptable_ent_find */

#if PTABLE_NEED_ENT_VIVIFY

#ifndef ptable_split
static void ptable_split(pPMS_ ptable *t) {
#define ptable_split(T) ptable_split(aPMS_ (T))
 ptable_ent      **ary = t->ary;
 const size_t old_size = t->max + 1;
 size_t       new_size = old_size * 2;
 size_t       i;

 XSH_SHARED_RECALLOC(ary, old_size, new_size, ptable_ent *);
 t->max = --new_size;
 t->ary = ary;

 for (i = 0; i < old_size; i++, ary++) {
  ptable_ent **curentp, **entp, *ent;

  ent = *ary;
  if (!ent)
   continue;
  entp    = ary;
  curentp = ary + old_size;

  do {
   if ((new_size & PTABLE_HASH(ent->key)) != i) {
    *entp     = ent->next;
    ent->next = *curentp;
    *curentp  = ent;
   } else {
    entp = &ent->next;
   }
   ent = *entp;
  } while (ent);
 }
}
#endif /* !ptable_split */

#ifndef ptable_ent_vivify
static ptable_ent *ptable_ent_vivify(pPMS_ ptable *t, const void *key) {
#define ptable_ent_vivify(T, K) ptable_ent_vivify(aPMS_ (T), (K))
 ptable_ent  *ent;
 const size_t idx = ptable_bucket(t, key);

 ent = t->ary[idx];
 for (; ent; ent = ent->next) {
  if (ent->key == key)
   return ent;
 }

 XSH_SHARED_ALLOC(ent, 1, ptable_ent);
 ent->key    = key;
 ent->val    = NULL;
 ent->next   = t->ary[idx];
 t->ary[idx] = ent;

 t->items++;
 if (ent->next && t->items > t->max)
  ptable_split(t);

 return ent;
}
#endif /* !ptable_ent_vivify */

#endif /* PTABLE_NEED_ENT_VIVIFY */

#if PTABLE_NEED_ENT_DETACH

#ifndef ptable_ent_detach
static ptable_ent *ptable_ent_detach(ptable *t, const void *key) {
#define ptable_ent_detach ptable_ent_detach
 ptable_ent  *prev, *ent;
 const size_t idx = ptable_bucket(t, key);

 prev = NULL;
 ent  = t->ary[idx];
 for (; ent; prev = ent, ent = ent->next) {
  if (ent->key == key) {
   if (prev)
    prev->next  = ent->next;
   else
    t->ary[idx] = ent->next;
   break;
  }
 }

 return ent;
}
#endif /* !ptable_ent_detach */

#endif /* PTABLE_NEED_ENT_DETACH */

/* --- Public interface ---------------------------------------------------- */

/* ... Common symbols ...................................................... */

#ifndef ptable_new
static ptable *ptable_new(pPMS_ size_t init_buckets) {
#define ptable_new(B) ptable_new(aPMS_ (B))
 ptable *t;

 if (init_buckets < 4) {
  init_buckets = 4;
 } else {
  init_buckets--;
  init_buckets |= init_buckets >> 1;
  init_buckets |= init_buckets >> 2;
  init_buckets |= init_buckets >> 4;
  init_buckets |= init_buckets >> 8;
  init_buckets |= init_buckets >> 16;
  if (sizeof(init_buckets) > 4)
   init_buckets |= init_buckets >> 32;
  init_buckets++;
 }

 XSH_ASSERT(init_buckets >= 4 && ((init_buckets & (init_buckets - 1)) == 0));

 XSH_SHARED_ALLOC(t, 1, ptable);
 t->max   = init_buckets - 1;
 t->items = 0;
 XSH_SHARED_CALLOC(t->ary, t->max + 1, ptable_ent *);

 return t;
}
#endif /* !ptable_new */

#ifndef ptable_fetch
static void *ptable_fetch(const ptable *t, const void *key) {
#define ptable_fetch ptable_fetch
 const ptable_ent *ent = ptable_ent_find(t, key);

 return ent ? ent->val : NULL;
}
#endif /* !ptable_fetch */

#if PTABLE_NEED_SPLICE

#ifndef ptable_splice
static void *ptable_splice(pPMS_ ptable *t, const void *key, void *new_val) {
#define ptable_splice(T, K, V) ptable_splice(aPMS_ (T), (K), (V))
 ptable_ent *ent;
 void       *old_val = NULL;

 if (new_val) {
  ent      = ptable_ent_vivify(t, key);
  old_val  = ent->val;
  ent->val = new_val;
 } else {
  ent = ptable_ent_detach(t, key);
  if (ent) {
   old_val = ent->val;
   XSH_SHARED_FREE(ent, 1, ptable_ent);
  }
 }

 return old_val;
}
#endif /* !ptable_splice */

#endif /* PTABLE_NEED_SPLICE */

#if PTABLE_NEED_WALK

#ifndef ptable_walk
static void ptable_walk(pTHX_ ptable *t, void (*cb)(pTHX_ ptable_ent *ent, void *userdata), void *userdata) {
#define ptable_walk(T, CB, UD) ptable_walk(aTHX_ (T), (CB), (UD))
 if (t && t->items) {
  register ptable_ent **array = t->ary;
  size_t i = t->max;
  do {
   ptable_ent *entry;
   for (entry = array[i]; entry; entry = entry->next)
    if (entry->val)
     cb(aTHX_ entry, userdata);
  } while (i--);
 }
}
#endif /* !ptable_walk */

#endif /* PTABLE_NEED_WALK */

/* ... Specialized symbols ................................................. */

#if PTABLE_NEED_STORE

#if !PTABLE_USE_DEFAULT || !defined(ptable_default_store)
static void PTABLE_PREFIX(_store)(pPTBL_ ptable *t, const void *key, void *val){
 ptable_ent *ent = ptable_ent_vivify(t, key);

#ifdef PTABLE_VAL_FREE
 PTABLE_VAL_FREE(ent->val);
#endif

 ent->val = val;

 return;
}
# if PTABLE_USE_DEFAULT
#  define ptable_default_store ptable_default_store
# endif
#endif /* !PTABLE_USE_DEFAULT || !defined(ptable_default_store) */

#endif /* PTABLE_NEED_STORE */

#if PTABLE_NEED_VIVIFY

#if !PTABLE_USE_DEFAULT || !defined(ptable_default_vivify)
static void *PTABLE_PREFIX(_vivify)(pPTBL_ ptable *t, const void *key) {
 ptable_ent *ent = ptable_ent_vivify(t, key);

 if (!ent->val) {
  PTABLE_VAL_ALLOC(ent->val);
 }

 return ent->val;
}
# if PTABLE_USE_DEFAULT
#  define ptable_default_vivify ptable_default_vivify
# endif
#endif /* !PTABLE_USE_DEFAULT || !defined(ptable_default_vivify) */

#endif /* PTABLE_NEED_VIVIFY */

#if PTABLE_NEED_DELETE

#if !PTABLE_USE_DEFAULT || !defined(ptable_default_delete)
static void PTABLE_PREFIX(_delete)(pPTBL_ ptable *t, const void *key) {
 ptable_ent *ent = ptable_ent_detach(t, key);

#ifdef PTABLE_VAL_FREE
 if (ent) {
  PTABLE_VAL_FREE(ent->val);
 }
#endif

 XSH_SHARED_FREE(ent, 1, ptable_ent);
}
# if PTABLE_USE_DEFAULT
#  define ptable_default_delete ptable_default_delete
# endif
#endif /* !PTABLE_USE_DEFAULT || !defined(ptable_default_delete) */

#endif /* PTABLE_NEED_DELETE */

#if PTABLE_NEED_CLEAR

#if !PTABLE_USE_DEFAULT || !defined(ptable_default_clear)
static void PTABLE_PREFIX(_clear)(pPTBL_ ptable *t) {
 if (t && t->items) {
  register ptable_ent **array = t->ary;
  size_t idx = t->max;

  do {
   ptable_ent *entry = array[idx];
   while (entry) {
    ptable_ent *nentry = entry->next;
#ifdef PTABLE_VAL_FREE
    PTABLE_VAL_FREE(entry->val);
#endif
    XSH_SHARED_FREE(entry, 1, ptable_ent);
    entry = nentry;
   }
   array[idx] = NULL;
  } while (idx--);

  t->items = 0;
 }
}
# if PTABLE_USE_DEFAULT
#  define ptable_default_clear ptable_default_clear
# endif
#endif /* !PTABLE_USE_DEFAULT || !defined(ptable_default_clear) */

#endif /* PTABLE_NEED_CLEAR */

#if !PTABLE_USE_DEFAULT || !defined(ptable_default_free)
static void PTABLE_PREFIX(_free)(pPTBL_ ptable *t) {
 if (!t)
  return;
 PTABLE_PREFIX(_clear)(aPTBL_ t);
 XSH_SHARED_FREE(t->ary, t->max + 1, ptable_ent *);
 XSH_SHARED_FREE(t, 1, ptable);
}
# if PTABLE_USE_DEFAULT
#  define ptable_default_free ptable_default_free
# endif
#endif /* !PTABLE_USE_DEFAULT || !defined(ptable_default_free) */

/* --- Cleanup ------------------------------------------------------------- */

#undef PTABLE_WAS_DEFAULT
#if PTABLE_USE_DEFAULT
# define PTABLE_WAS_DEFAULT 1
#else
# define PTABLE_WAS_DEFAULT 0
#endif

#undef PTABLE_NAME
#undef PTABLE_VAL_ALLOC
#undef PTABLE_VAL_FREE
#undef PTABLE_VAL_NEED_CONTEXT
#undef PTABLE_USE_DEFAULT

#undef PTABLE_NEED_SPLICE
#undef PTABLE_NEED_WALK
#undef PTABLE_NEED_STORE
#undef PTABLE_NEED_VIVIFY
#undef PTABLE_NEED_DELETE
#undef PTABLE_NEED_CLEAR

#undef PTABLE_NEED_ENT_VIVIFY
#undef PTABLE_NEED_ENT_DETACH

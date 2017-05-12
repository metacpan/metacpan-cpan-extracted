// vim: filetype=xs

const U32 KV(secret) = 968723872 + I(KEY) * 64 + I(VALUE);


typedef struct KV(tree_t) {
    struct KV(tree_t) *left, *right;
    IV size;
    T(KEY) key;
#if I(VALUE) != I(void)
    T(VALUE) value;
#endif
} KV(tree_t);

typedef struct KV(tree_seg_t) {
    struct KV(tree_seg_t) * prev_seg;

    KV(tree_t) cell[SEG_SIZE];
} KV(tree_seg_t);

typedef struct KV(tree_cntr_t) {
    void * sv_any;
    U32 sv_refcnt;
    U32 sv_flags;
    SV* cmp;
    KV(tree_t) * root; // (init 後, empty 前) 永不為空, 一開始指向 nil
    KV(tree_t) * free_slot;
    KV(tree_seg_t) * newest_seg;
    int ever_height;
} KV(tree_cntr_t);

static inline KV(tree_cntr_t) * KV(assure_tree_cntr)(SV * obj){
    if( !obj )
        croak("assure_tree_cntr: NULL ptr");

    if( !SvROK(obj) )
        croak("assure_tree_cntr: try to dereference a non-reference");

    SV * ret = SvRV(obj);
    if( !ret )
        croak("assure_tree_cntr: deref to NULL");

    if( !SvROK(ret) )
        croak("assure_tree_cntr: deref to non-reference");

    KV(tree_cntr_t) * cntr = (KV(tree_cntr_t)*) SvRV(ret);
    if( !cntr )
        croak("assure_tree_cntr: NULL cntr");

    if( cntr->sv_refcnt != KV(secret) )
        croak("assure_tree_cntr: unmatched secret %u against %u", cntr->sv_refcnt, KV(secret));

    return cntr;
}

// 把所有的 cell 以 left 串起來, 最後一個指向 NULL
// return 開頭的 cell
static inline KV(tree_t) * KV(init_tree_seg)(KV(tree_seg_t) * seg, KV(tree_seg_t) * prev){
    seg->prev_seg = prev;
    seg->cell[SEG_SIZE-1].left = NULL;
    for(int i=SEG_SIZE-2; i>=0; --i)
        seg->cell[i].left = &seg->cell[i+1];
    return &seg->cell[0];
}

#ifndef MAINTAINER
#define MAINTAINER
KV(tree_t) nil = { .size = 0, .left = &nil, .right = &nil };

// 假設 t->right 存在, return 新的 subtree root
static inline KV(tree_t)* rotate_left(KV(tree_t)* t){
    KV(tree_t) * c = t->right;
    t->right = c->left;
    c->left = t;
    c->size = t->size;
    t->size = t->left->size + t->right->size + 1;
    return c;
}

// 假設 t->left 存在, return 新的 subtree root
static inline KV(tree_t)* rotate_right(KV(tree_t) * t){
    KV(tree_t) * c = t->left;
    t->left = c->right;
    c->right = t;
    c->size = t->size;
    t->size = t->left->size + t->right->size + 1;
    return c;
}

KV(tree_t) * maintain_larger_left(void * t);
KV(tree_t) * maintain_larger_right(void * t);

KV(tree_t) * maintain_larger_left(void * _t){
    KV(tree_t) * t = (KV(tree_t)*) _t;
    if( t->left->left->size > t->right->size )
        t = rotate_right(t);
    else if( t->left->right->size > t->right->size ){
        t->left = rotate_left(t->left);
        t = rotate_right(t);
    }
    else
        return t;

    t->left = maintain_larger_left(t->left);
    t->right = maintain_larger_right(t->right);
    t = maintain_larger_left(t);
    t = maintain_larger_right(t);
    return t;
}

KV(tree_t) * maintain_larger_right(void * _t){
    KV(tree_t) * t = (KV(tree_t)*) _t;
    if( t->right->right->size > t->left->size )
        t = rotate_left(t);
    else if( t->right->left->size > t->left->size ){
        t->right = rotate_right(t->right);
        t = rotate_left(t);
    }
    else
        return t;

    t->left = maintain_larger_left(t->left);
    t->right = maintain_larger_right(t->right);
    t = maintain_larger_left(t);
    t = maintain_larger_right(t);
    return t;
}

// 假設 tree 不是空的
bool tree_check_subtree_size(KV(tree_t) * tree){
    if( tree->size != tree->left->size + tree->right->size + 1 )
        return FALSE;
    if( tree->left != (KV(tree_t)*) &nil && !tree_check_subtree_size(tree->left) )
        return FALSE;
    if( tree->right != (KV(tree_t)*) &nil && !tree_check_subtree_size(tree->right) )
        return FALSE;
    return TRUE;
}
static inline bool tree_check_size(void * _cntr){
    KV(tree_cntr_t)* cntr = (KV(tree_cntr_t)*) _cntr;
    if( cntr->root == (KV(tree_t)*) &nil )
        return TRUE;
    return tree_check_subtree_size(cntr->root);
}

// 假設 tree 不是空的
bool tree_check_subtree_balance(KV(tree_t) * tree){
    if( tree->left->left->size > tree->right->size )
        return FALSE;
    if( tree->left->right->size > tree->right->size )
        return FALSE;
    if( tree->right->left->size > tree->left->size )
        return FALSE;
    if( tree->right->right->size > tree->left->size )
        return FALSE;
    if( tree->left != &nil && !tree_check_subtree_balance(tree->left) )
        return FALSE;
    if( tree->right != &nil && !tree_check_subtree_balance(tree->right) )
        return FALSE;
    return TRUE;
}
static inline bool tree_check_balance(void * _cntr){
    KV(tree_cntr_t)* cntr = (KV(tree_cntr_t)*) _cntr;
    if( cntr->root == (KV(tree_t)*) &nil )
        return TRUE;
    return tree_check_subtree_balance(cntr->root);
}

#endif // MAINTAINER

static inline KV(tree_t) * KV(allocate_cell)(KV(tree_cntr_t) * cntr, T(KEY) key, T(VALUE) value){
    if( UNLIKELY(!cntr->free_slot) ){
        KV(tree_seg_t) * new_seg;
        Newx(new_seg, 1, KV(tree_seg_t));
        cntr->free_slot = KV(init_tree_seg)(new_seg, cntr->newest_seg);
        cntr->newest_seg = new_seg;
    }
    KV(tree_t) * new_cell = cntr->free_slot;
    cntr->free_slot = new_cell->left;

    new_cell->left = new_cell->right = (KV(tree_t)*) &nil;
    new_cell->size = 1;
    new_cell->key = key;
#if I(VALUE) != I(void)
    new_cell->value = value;
#endif

    return new_cell;
}

static inline void KV(free_cell)(KV(tree_cntr_t) * cntr, KV(tree_t) * cell){
    cell->left = cntr->free_slot;
    cntr->free_slot = cell;
}

static inline void KV(empty_tree_cntr)(pTHX_ KV(tree_cntr_t) * cntr){
#if I(KEY) == I(str) || I(KEY) == I(any) || I(VALUE) == I(str) || I(VALUE) == I(any)
    KV(tree_t) * free_slot = cntr->free_slot;
    while( free_slot ){
        KV(tree_t) * next_free_slot = free_slot->left;
#   if I(KEY) == I(str) || I(KEY) == I(any)
        free_slot->key = NULL;
#   endif
#   if I(VALUE) == I(str) || I(VALUE) == I(any)
        free_slot->value = NULL;
#   endif
        free_slot = next_free_slot;
    }
#endif
    KV(tree_seg_t) * seg = cntr->newest_seg;
    while( seg ){
        KV(tree_seg_t) * prev = seg->prev_seg;
#if I(KEY) == I(str) || I(KEY) == I(any) || I(VALUE) == I(str) || I(VALUE) == I(any)
        for(int i=SEG_SIZE-1; i>=0; --i){
#   if I(KEY) == I(str) || I(KEY) == I(any)
            SvREFCNT_dec(seg->cell[i].key);
#   endif
#   if I(VALUE) == I(str) || I(VALUE) == I(any)
            SvREFCNT_dec(seg->cell[i].value);
#   endif
        }
#endif
        Safefree(seg);
        seg = prev;
    }
    cntr->root = (KV(tree_t)*) &nil;
    cntr->free_slot = NULL;
    cntr->newest_seg = NULL;
}

// 假設一給定的 tree 不是空的
// 把子樹的最右節點拉上來成為子樹的 root, return 新的 root
// 新子樹沒有右子樹, 而左子樹符合 SBTree 特性
static inline KV(tree_t) * KV(tree_raise_max_cell)(KV(tree_t) * tree){
    KV(tree_t) * root = tree;

    int step_count = 0;

    KV(tree_t) * parent = (KV(tree_t)*) &nil;
    while( UNLIKELY(tree->right != (KV(tree_t)*) &nil) ){
        --tree->size;
        parent = tree;
        tree = tree->right;
        ++step_count;
    }

    if( LIKELY(parent != (KV(tree_t)*) &nil) ){
        parent->right = tree->left;
        tree->left = root;
        tree->size = root->size + 1;

        KV(tree_t) * stack[step_count];
        for(int i=0; i<step_count; ++i){
            stack[i] = root;
            root = root->right;
        }
        for(int i=step_count-1; i>0; --i)
            stack[i-1]->right = (KV(tree_t)*) maintain_larger_left(stack[i]);
        tree->left = (KV(tree_t)*) maintain_larger_left(stack[0]);
    }

    return tree;
}

// 假設 parent 的 right 是 nil
// 把 right 接到 parent 的 right
// re-return parent;
static inline KV(tree_t) * KV(tree_assign_right)(KV(tree_t) * parent, KV(tree_t) * right){
    parent->right = right;
    parent->size += right->size;
    return parent;
}

// 假設 tree 不是空的
// 如果有左子樹, 把此 tree 的 root 用左子樹裡最大節點取代
// 否則用右字樹取代
// return 新的 root
static inline KV(tree_t) * KV(tree_replace_cell)(KV(tree_t) * tree){
    if( UNLIKELY(tree->left == (KV(tree_t)*) &nil) )
        return tree->right;
    return KV(tree_assign_right)(KV(tree_raise_max_cell)(tree->left), tree->right);
}

// 假設 tree 不是空的
// 刪除 tree 的 root
// return 新的 root
static inline KV(tree_t) * KV(tree_delete_root)(KV(tree_cntr_t) * cntr, KV(tree_t) * tree){
    KV(tree_t) * new_root = KV(tree_replace_cell)(tree);
    KV(free_cell)(cntr, tree);
    return (KV(tree_t)*) maintain_larger_right(new_root);
}

static inline int KV(tree_size)(KV(tree_cntr_t) * cntr){
    return cntr->root->size;
}

#define MIN_MAX_FIND_FUNC tree_find_min
#define SKIP_FIND_FUNC tree_skip_l
#define MIN_MAX_FIND_GOOD_DIR left
#define MIN_MAX_FIND_BAD_DIR right
#include "min_max_find_gen.h"
#undef MIN_MAX_FIND_BAD_DIR
#undef MIN_MAX_FIND_GOOD_DIR
#undef SKIP_FIND_FUNC
#undef MIN_MAX_FIND_FUNC

#define MIN_MAX_FIND_FUNC tree_find_max
#define SKIP_FIND_FUNC tree_skip_g
#define MIN_MAX_FIND_GOOD_DIR right
#define MIN_MAX_FIND_BAD_DIR left
#include "min_max_find_gen.h"
#undef MIN_MAX_FIND_BAD_DIR
#undef MIN_MAX_FIND_GOOD_DIR
#undef SKIP_FIND_FUNC
#undef MIN_MAX_FIND_FUNC

static inline void KV(init_tree_cntr)(KV(tree_cntr_t) * cntr, SV * cmp){
    cntr->sv_refcnt = KV(secret);
    cntr->root = (KV(tree_t)*) &nil;
    cntr->newest_seg = NULL;
    cntr->free_slot = NULL;
    cntr->ever_height = 0;
#if I(KEY) == I(any)
    cntr->cmp = SvREFCNT_inc_simple_NN(cmp);
#endif
}

#define INSERT_FUNC tree_insert_after
#define INSERT_SUBTREE_FUNC tree_insert_after_subtree
#define INSERT_CMP_OP <=
#include "insert_gen.h"
#undef INSERT_CMP_OP
#undef INSERT_SUBTREE_FUNC
#undef INSERT_FUNC

#define INSERT_FUNC tree_insert_before
#define INSERT_SUBTREE_FUNC tree_insert_before_subtree
#define INSERT_CMP_OP <
#include "insert_gen.h"
#undef INSERT_CMP_OP
#undef INSERT_SUBTREE_FUNC
#undef INSERT_FUNC

#define DELETE_FUNC tree_delete_last
#define DELETE_SUBTREE_FUNC tree_delete_subtree_last
#define DELETE_CMP_OP <=
#define DELETE_GOOD_DIR right
#define DELETE_BAD_DIR left
#define DELETE_MAINTAIN_GOOD_DIR maintain_larger_right
#define DELETE_MAINTAIN_BAD_DIR maintain_larger_left
#include "delete_gen.h"
#undef DELETE_MAINTAIN_BAD_DIR
#undef DELETE_MAINTAIN_GOOD_DIR
#undef DELETE_BAD_DIR
#undef DELETE_GOOD_DIR
#undef DELETE_CMP_OP
#undef DELETE_SUBTREE_FUNC
#undef DELETE_FUNC

#define DELETE_FUNC tree_delete_first
#define DELETE_SUBTREE_FUNC tree_delete_subtree_first
#define DELETE_CMP_OP >=
#define DELETE_GOOD_DIR left
#define DELETE_BAD_DIR right
#define DELETE_MAINTAIN_GOOD_DIR maintain_larger_left
#define DELETE_MAINTAIN_BAD_DIR maintain_larger_right
#include "delete_gen.h"
#undef DELETE_MAINTAIN_BAD_DIR
#undef DELETE_MAINTAIN_GOOD_DIR
#undef DELETE_BAD_DIR
#undef DELETE_GOOD_DIR
#undef DELETE_CMP_OP
#undef DELETE_SUBTREE_FUNC
#undef DELETE_FUNC

#define FIND_FUNC tree_find_first
#define FIND_CMP_OP >=
#define FIND_GOOD_DIR left
#define FIND_BAD_DIR right
#include "find_gen.h"
#undef FIND_BAD_DIR
#undef FIND_GOOD_DIR
#undef FIND_CMP_OP
#undef FIND_FUNC

#define FIND_FUNC tree_find_last
#define FIND_CMP_OP <=
#define FIND_GOOD_DIR right
#define FIND_BAD_DIR left
#include "find_gen.h"
#undef FIND_BAD_DIR
#undef FIND_GOOD_DIR
#undef FIND_CMP_OP
#undef FIND_FUNC

#define FUZZY_FIND_FUNC tree_find_lt
#define FUZZY_COUNT_FUNC tree_count_lt
#define FUZZY_FIND_CMP_OP <
#define FUZZY_FIND_GOOD_DIR right
#define FUZZY_FIND_BAD_DIR left
#include "fuzzy_find_gen.h"
#undef FUZZY_FIND_BAD_DIR
#undef FUZZY_FIND_GOOD_DIR
#undef FUZZY_FIND_CMP_OP
#undef FUZZY_COUNT_FUNC
#undef FUZZY_FIND_FUNC

#define FUZZY_FIND_FUNC tree_find_le
#define FUZZY_COUNT_FUNC tree_count_le
#define FUZZY_FIND_CMP_OP <=
#define FUZZY_FIND_GOOD_DIR right
#define FUZZY_FIND_BAD_DIR left
#include "fuzzy_find_gen.h"
#undef FUZZY_FIND_BAD_DIR
#undef FUZZY_FIND_GOOD_DIR
#undef FUZZY_FIND_CMP_OP
#undef FUZZY_COUNT_FUNC
#undef FUZZY_FIND_FUNC

#define FUZZY_FIND_FUNC tree_find_gt
#define FUZZY_COUNT_FUNC tree_count_gt
#define FUZZY_FIND_CMP_OP >
#define FUZZY_FIND_GOOD_DIR left
#define FUZZY_FIND_BAD_DIR right
#include "fuzzy_find_gen.h"
#undef FUZZY_FIND_BAD_DIR
#undef FUZZY_FIND_GOOD_DIR
#undef FUZZY_FIND_CMP_OP
#undef FUZZY_COUNT_FUNC
#undef FUZZY_FIND_FUNC

#define FUZZY_FIND_FUNC tree_find_ge
#define FUZZY_COUNT_FUNC tree_count_ge
#define FUZZY_FIND_CMP_OP >=
#define FUZZY_FIND_GOOD_DIR left
#define FUZZY_FIND_BAD_DIR right
#include "fuzzy_find_gen.h"
#undef FUZZY_FIND_BAD_DIR
#undef FUZZY_FIND_GOOD_DIR
#undef FUZZY_FIND_CMP_OP
#undef FUZZY_COUNT_FUNC
#undef FUZZY_FIND_FUNC

#define RANGE_FIND_FUNC tree_find_gt_lt
#define RANGE_FIND_FALLBACK_FUNC tree_find_gt
#define RANGE_FIND_CMP_L_OP >
#define RANGE_FIND_CMP_R_OP <
#include "range_find_gen.h"
#undef RANGE_FIND_CMP_R_OP
#undef RANGE_FIND_CMP_L_OP
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC

#define RANGE_FIND_FUNC tree_find_ge_lt
#define RANGE_FIND_FALLBACK_FUNC tree_find_ge
#define RANGE_FIND_CMP_L_OP >=
#define RANGE_FIND_CMP_R_OP <
#include "range_find_gen.h"
#undef RANGE_FIND_CMP_R_OP
#undef RANGE_FIND_CMP_L_OP
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC

#define RANGE_FIND_FUNC tree_find_gt_le
#define RANGE_FIND_FALLBACK_FUNC tree_find_gt
#define RANGE_FIND_CMP_L_OP >
#define RANGE_FIND_CMP_R_OP <=
#include "range_find_gen.h"
#undef RANGE_FIND_CMP_R_OP
#undef RANGE_FIND_CMP_L_OP
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC

#define RANGE_FIND_FUNC tree_find_ge_le
#define RANGE_FIND_FALLBACK_FUNC tree_find_ge
#define RANGE_FIND_CMP_L_OP >=
#define RANGE_FIND_CMP_R_OP <=
#include "range_find_gen.h"
#undef RANGE_FIND_CMP_R_OP
#undef RANGE_FIND_CMP_L_OP
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC

void KV(tree_dump_subtree)(pTHX_ SV * out, int indent, KV(tree_t) * tree){
    if( tree->right != (KV(tree_t)*) &nil )
        KV(tree_dump_subtree)(aTHX_ out, indent+1, tree->right);
    for(int i=0; i<indent; ++i)
        sv_catpvn(out, "  ", 2);

#if I(KEY) == I(int)
    T(KEY) key = tree->key;
#   define KEY_FMT "%d"
#   define KEY_FMT_TYPE (int)
#elif I(KEY) == I(num)
    T(KEY) key = tree->key;
#   define KEY_FMT "%lf"
#   define KEY_FMT_TYPE (double)
#else
    char * key = SvPV_nolen(tree->key);
#   define KEY_FMT "%s"
#   define KEY_FMT_TYPE (char*)
#endif
    sv_catpvf(out, "(" KEY_FMT ", %d)\n", KEY_FMT_TYPE key, (int) tree->size);
#undef KEY_FMT_TYPE
#undef KEY_FMT

    if( tree->left != (KV(tree_t)*) &nil )
        KV(tree_dump_subtree)(aTHX_ out, indent+1, tree->left);
}
static inline SV* KV(tree_dump)(pTHX_ KV(tree_cntr_t) * cntr){
    if( cntr->root == (KV(tree_t)*) &nil )
        return newSVpvn("(empty tree)", 12);

    SV * out = newSVpvn("", 0);
    KV(tree_dump_subtree)(aTHX_ out, 0, cntr->root);
    return out;
}

// 假設 tree 不是空的
bool KV(tree_check_subtree_order)(pTHX_ SV**SP, KV(tree_cntr_t) * cntr, KV(tree_t) * tree){
    if( tree->left != (KV(tree_t)*) &nil && (K(cmp)(aTHX_ SP, tree->left->key, tree->key, cntr->cmp) > 0 || !KV(tree_check_subtree_order)(aTHX_ SP, cntr, tree->left)) )
        return FALSE;
    if( tree->right != (KV(tree_t)*) &nil && (K(cmp)(aTHX_ SP, tree->key, tree->right->key, cntr->cmp) > 0 || !KV(tree_check_subtree_order)(aTHX_ SP, cntr, tree->right)) )
        return FALSE;
    return TRUE;
}
static inline bool KV(tree_check_order)(pTHX_ SV**SP, KV(tree_cntr_t) * cntr){
    if( cntr->root == (KV(tree_t)*) &nil )
        return TRUE;
    return KV(tree_check_subtree_order)(aTHX_ SP, cntr, cntr->root);
}

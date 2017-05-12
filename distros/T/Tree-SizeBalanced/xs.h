// vim: filetype=xs

inline static SV ** KV(new)(pTHX_ SV ** SP, SV * class, SV * cmp){
    KV(tree_cntr_t) * cntr;
    Newx(cntr, 1, KV(tree_cntr_t));
    cntr->sv_refcnt = KV(secret);
    cntr->sv_flags = SVt_NULL;
    KV(init_tree_cntr)(cntr, cmp);

    SV * ret = newSV(0);
    SvUPGRADE(ret, SVt_RV);
    SvROK_on(ret);
    SvRV(ret) = (SV*) cntr;

    SV * obj = newRV_noinc(ret);
    STRLEN classname_len;
    char * classname = SvPVbyte(class, classname_len);
    HV * stash = gv_stashpvn(classname, classname_len, 0);
    sv_bless(obj, stash);
    PUSHs(sv_2mortal(obj));
    return SP;
}

inline static SV ** KV(DESTROY)(pTHX_ SV ** SP, SV * obj){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    KV(empty_tree_cntr)(aTHX_ cntr);
    Safefree(cntr);
    SvRV(SvRV(obj)) = NULL;
    return SP;
}

inline static SV ** KV(size)(pTHX_ SV** SP, SV *obj){
    dXSTARG;
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    PUSHu((UV) KV(tree_size)(cntr));
    return SP;
}

inline static SV ** KV(ever_height)(pTHX_ SV** SP, SV *obj){
    dXSTARG;
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    PUSHu((UV) cntr->ever_height);
    return SP;
}

inline static SV ** KV(insert_before)(pTHX_ SV** SP, SV * obj, SV * key, SV * value){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);

    KV(tree_insert_before)(aTHX_ SP, cntr, K(copy_sv)(aTHX_ key), V(copy_sv)(aTHX_ value));
    return SP;
}

inline static SV ** KV(insert_after)(pTHX_ SV** SP, SV * obj, SV * key, SV * value){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);

    KV(tree_insert_after)(aTHX_ SP, cntr, K(copy_sv)(aTHX_ key), V(copy_sv)(aTHX_ value));
    return SP;
}

inline static SV ** KV(insert)(pTHX_ SV** SP, SV * obj, SV * key, SV * value){
    return KV(insert_after)(aTHX_ SP, obj, key, value);
}

inline static SV ** KV(delete_first)(pTHX_ SV** SP, SV * obj, SV * key){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);
#if I(KEY) == I(any)
    SvREFCNT_inc_simple_void_NN(key);
#endif

    if( KV(tree_delete_first)(aTHX_ SP, cntr, K(from_sv)(aTHX_ key)) )
        PUSHs(&PL_sv_yes);
    else
        PUSHs(&PL_sv_no);

#if I(KEY) == I(any)
#   ifdef SvREFCNT_dec_NN
    SvREFCNT_dec_NN(key);
#   else
    SvREFCNT_dec(key);
#   endif
#endif
    return SP;
}

inline static SV ** KV(delete_last)(pTHX_ SV** SP, SV * obj, SV * key){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);
#if I(KEY) == I(any)
    SvREFCNT_inc_simple_void_NN(key);
#endif

    if( KV(tree_delete_last)(aTHX_ SP, cntr, K(from_sv)(aTHX_ key)) )
        PUSHs(&PL_sv_yes);
    else
        PUSHs(&PL_sv_no);

#if I(KEY) == I(any)
#   ifdef SvREFCNT_dec_NN
    SvREFCNT_dec_NN(key);
#   else
    SvREFCNT_dec(key);
#   endif
#endif
    return SP;
}

inline static SV ** KV(delete)(pTHX_ SV** SP, SV * obj, SV * key){
    return KV(delete_last)(aTHX_ SP, obj, key);
}

inline static SV ** KV(find_first)(pTHX_ SV** SP, SV * obj, SV * key, int limit){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);
#if I(KEY) == I(any)
    SvREFCNT_inc_simple_void_NN(key);
#endif

    SP = KV(tree_find_first)(aTHX_ SP, cntr, K(from_sv)(aTHX_ key), limit);

#if I(KEY) == I(any)
#   ifdef SvREFCNT_dec_NN
    SvREFCNT_dec_NN(key);
#   else
    SvREFCNT_dec(key);
#   endif
#endif
    return SP;
}

inline static SV ** KV(find_last)(pTHX_ SV** SP, SV * obj, SV * key, int limit){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);
#if I(KEY) == I(any)
    SvREFCNT_inc_simple_void_NN(key);
#endif

    SP = KV(tree_find_last)(aTHX_ SP, cntr, K(from_sv)(aTHX_ key), limit);

#if I(KEY) == I(any)
#   ifdef SvREFCNT_dec_NN
    SvREFCNT_dec_NN(key);
#   else
    SvREFCNT_dec(key);
#   endif
#endif
    return SP;
}

inline static SV ** KV(find)(pTHX_ SV** SP, SV * obj, SV * key, int limit){
    return KV(find_first)(aTHX_ SP, obj, key, limit);
}

#define XS_FUZZY_FIND_FUNC find_lt
#define FUZZY_FIND_FUNC tree_find_lt
#include "xs_fuzzy_find_gen.h"
#undef FUZZY_FIND_FUNC
#undef XS_FUZZY_FIND_FUNC

#define XS_FUZZY_FIND_FUNC find_le
#define FUZZY_FIND_FUNC tree_find_le
#include "xs_fuzzy_find_gen.h"
#undef FUZZY_FIND_FUNC
#undef XS_FUZZY_FIND_FUNC

#define XS_FUZZY_FIND_FUNC find_gt
#define FUZZY_FIND_FUNC tree_find_gt
#include "xs_fuzzy_find_gen.h"
#undef FUZZY_FIND_FUNC
#undef XS_FUZZY_FIND_FUNC

#define XS_FUZZY_FIND_FUNC find_ge
#define FUZZY_FIND_FUNC tree_find_ge
#include "xs_fuzzy_find_gen.h"
#undef FUZZY_FIND_FUNC
#undef XS_FUZZY_FIND_FUNC

#define XS_FUZZY_COUNT_FUNC count_lt
#define FUZZY_COUNT_FUNC tree_count_lt
#include "xs_fuzzy_count_gen.h"
#undef FUZZY_COUNT_FUNC
#undef XS_FUZZY_COUNT_FUNC

#define XS_FUZZY_COUNT_FUNC count_le
#define FUZZY_COUNT_FUNC tree_count_le
#include "xs_fuzzy_count_gen.h"
#undef FUZZY_COUNT_FUNC
#undef XS_FUZZY_COUNT_FUNC

#define XS_FUZZY_COUNT_FUNC count_gt
#define FUZZY_COUNT_FUNC tree_count_gt
#include "xs_fuzzy_count_gen.h"
#undef FUZZY_COUNT_FUNC
#undef XS_FUZZY_COUNT_FUNC

#define XS_FUZZY_COUNT_FUNC count_ge
#define FUZZY_COUNT_FUNC tree_count_ge
#include "xs_fuzzy_count_gen.h"
#undef FUZZY_COUNT_FUNC
#undef XS_FUZZY_COUNT_FUNC

#define XS_RANGE_FIND_FUNC find_gt_lt
#define RANGE_FIND_FUNC tree_find_gt_lt
#define RANGE_FIND_FALLBACK_FUNC tree_find_gt
#include "xs_range_find_gen.h"
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC
#undef XS_RANGE_FIND_FUNC

#define XS_RANGE_FIND_FUNC find_ge_lt
#define RANGE_FIND_FUNC tree_find_ge_lt
#define RANGE_FIND_FALLBACK_FUNC tree_find_ge
#include "xs_range_find_gen.h"
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC
#undef XS_RANGE_FIND_FUNC

#define XS_RANGE_FIND_FUNC find_gt_le
#define RANGE_FIND_FUNC tree_find_gt_le
#define RANGE_FIND_FALLBACK_FUNC tree_find_gt
#include "xs_range_find_gen.h"
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC
#undef XS_RANGE_FIND_FUNC

#define XS_RANGE_FIND_FUNC find_ge_le
#define RANGE_FIND_FUNC tree_find_ge_le
#define RANGE_FIND_FALLBACK_FUNC tree_find_ge
#include "xs_range_find_gen.h"
#undef RANGE_FIND_FALLBACK_FUNC
#undef RANGE_FIND_FUNC
#undef XS_RANGE_FIND_FUNC

inline static SV ** KV(find_min)(pTHX_ SV** SP, SV * obj, int limit){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    if( KV(tree_size)(cntr) != 0 )
        SP = KV(tree_find_min)(aTHX_ SP, cntr, limit);
    return SP;
}

inline static SV ** KV(find_max)(pTHX_ SV** SP, SV * obj, int limit){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    if( KV(tree_size)(cntr) != 0 )
        SP = KV(tree_find_max)(aTHX_ SP, cntr, limit);
    return SP;
}

inline static SV ** KV(skip_l)(pTHX_ SV** SP, SV * obj, int offset, int limit){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    if( 0 <= offset && offset < KV(tree_size)(cntr) )
        SP = KV(tree_skip_l)(aTHX_ SP, cntr, offset, limit);
    return SP;
}

inline static SV ** KV(skip_g)(pTHX_ SV** SP, SV * obj, int offset, int limit){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    if( 0 <= offset && offset < KV(tree_size)(cntr) )
        SP = KV(tree_skip_g)(aTHX_ SP, cntr, offset, limit);
    return SP;
}

inline static SV ** KV(dump)(pTHX_ SV** SP, SV *obj){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);
    SV * out = KV(tree_dump)(aTHX_ cntr);
    PUSHs(sv_2mortal(out));
    return SP;
}

inline static SV ** KV(check)(pTHX_ SV** SP, SV * obj){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);

    EXTEND(SP, 3);

    if( KV(tree_check_order)(aTHX_ SP, cntr) )
        PUSHs(&PL_sv_yes);
    else
        PUSHs(&PL_sv_no);
    if( tree_check_size(cntr) )
        PUSHs(&PL_sv_yes);
    else
        PUSHs(&PL_sv_no);
    if( tree_check_balance(cntr) )
        PUSHs(&PL_sv_yes);
    else
        PUSHs(&PL_sv_no);
    return SP;
}

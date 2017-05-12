// vim: filetype=xs

SV ** KV(XS_FUZZY_FIND_FUNC)(pTHX_ SV** SP, SV * obj, SV * key, int limit){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);
#if I(KEY) == I(any)
    SvREFCNT_inc_simple_void_NN(key);
#endif

    SP = KV(FUZZY_FIND_FUNC)(aTHX_ SP, cntr, K(from_sv)(aTHX_ key), limit);

#if I(KEY) == I(any)
#   ifdef SvREFCNT_dec_NN
    SvREFCNT_dec_NN(key);
#   else
    SvREFCNT_dec(key);
#   endif
#endif
    return SP;
}

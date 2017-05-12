// vim: filetype=xs

SV ** KV(XS_RANGE_FIND_FUNC)(pTHX_ SV** SP, SV * obj, SV * lower_key, SV * upper_key){
    KV(tree_cntr_t) * cntr = KV(assure_tree_cntr)(obj);

    save_scalar(a_GV);
    save_scalar(b_GV);
#if I(KEY) == I(any)
    SvREFCNT_inc_simple_void_NN(lower_key);
    SvREFCNT_inc_simple_void_NN(upper_key);
#endif

    if( GIMME_V == G_ARRAY )
        SP = KV(RANGE_FIND_FUNC)(aTHX_ SP, cntr, K(from_sv)(aTHX_ lower_key), K(from_sv)(aTHX_ upper_key));
    else
        SP = KV(RANGE_FIND_FALLBACK_FUNC)(aTHX_ SP, cntr, K(from_sv)(aTHX_ lower_key), 1);

#if I(KEY) == I(any)
#   ifdef SvREFCNT_dec_NN
    SvREFCNT_dec_NN(upper_key);
    SvREFCNT_dec_NN(lower_key);
#   else
    SvREFCNT_dec(upper_key);
    SvREFCNT_dec(lower_key);
#   endif
#endif
    return SP;
}

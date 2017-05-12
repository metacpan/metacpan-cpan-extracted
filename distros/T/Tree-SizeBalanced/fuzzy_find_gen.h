// vim: filetype=xs

static inline SV** KV(FUZZY_FIND_FUNC)(pTHX_ SV** SP, KV(tree_cntr_t) * cntr, T(KEY) key, int limit){
    KV(tree_t) * t = cntr->root;

    if( limit != 1 && GIMME_V != G_ARRAY )
        limit = 1;

    KV(tree_t)* stack[cntr->ever_height+1];
    int p = 0;
    stack[0] = NULL;

    while( limit != 0 && p >= 0 ){
        if( stack[p] == NULL ){ // from parent, current = t
            if( t == (KV(tree_t)*) &nil )
                --p;
            else{
                if( K(cmp)(aTHX_ SP, t->key, key, cntr->cmp) FUZZY_FIND_CMP_OP 0 ){
                    stack[p] = t; // attempt GOOD child
                    stack[++p] = NULL;
                    t = t->FUZZY_FIND_GOOD_DIR;
                }
                else{
                    stack[p] = (KV(tree_t)*) &nil; // attempt BAD child
                    stack[++p] = NULL;
                    t = t->FUZZY_FIND_BAD_DIR;
                }
            }
        }
        else if( stack[p] == (KV(tree_t)*) &nil ) // from BAD child, current is useless
            --p;
        else{ // from GOOD child, current = stack[p]
            t = stack[p];
            if( K(cmp)(aTHX_ SP, t->key, key, cntr->cmp) FUZZY_FIND_CMP_OP 0 ){
                SP = K(mxret)(aTHX_ SP, t->key);
#if I(VALUE) != I(void)
                SP = V(mxret)(aTHX_ SP, t->value);
#endif
                --limit;
            }

            stack[p] = (KV(tree_t)*) &nil; // attempt BAD child
            stack[++p] = NULL;
            t = t->FUZZY_FIND_BAD_DIR;
        }
    }

#if I(VALUE) != I(void)
    if( p >= 0 && GIMME_V != G_ARRAY )
        --SP;
#endif
    return SP;
}

static inline UV KV(FUZZY_COUNT_FUNC)(pTHX_ SV**SP, KV(tree_cntr_t) * cntr, T(KEY) key){
    KV(tree_t) * t = cntr->root;
    int count = 0;
    while( t != (KV(tree_t)*) &nil ){
        if( K(cmp)(aTHX_ SP, t->key, key, cntr->cmp) FUZZY_FIND_CMP_OP 0 ){
            count += t->FUZZY_FIND_BAD_DIR->size + 1;
            t = t->FUZZY_FIND_GOOD_DIR;
        }
        else
            t = t->FUZZY_FIND_BAD_DIR;
    }
    return count;
}

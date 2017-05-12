// vim: filetype=xs

static inline SV** KV(FIND_FUNC)(pTHX_ SV** SP, KV(tree_cntr_t) * cntr, T(KEY) key, int limit){
    KV(tree_t) * t = cntr->root;

    if( limit != 1 && GIMME_V != G_ARRAY )
        limit = 1;

    while( t != (KV(tree_t)*) &nil ){
        if( K(cmp)(aTHX_ SP, t->key, key, cntr->cmp) == 0 ){
            KV(tree_t)* stack[cntr->ever_height+1];
            int p = 0;
            stack[0] = NULL;

            while( limit != 0 && p >= 0 ){
                if( stack[p] == NULL ){ // from parent, current = t
                    if( t == (KV(tree_t)*) &nil )
                        --p;
                    else{
                        if( K(cmp)(aTHX_ SP, t->key, key, cntr->cmp) FIND_CMP_OP 0 ){
                            stack[p] = t; // attempt GOOD child
                            stack[++p] = NULL;
                            t = t->FIND_GOOD_DIR;
                        }
                        else{
                            stack[p] = (KV(tree_t)*) &nil; // attempt BAD child
                            stack[++p] = NULL;
                            t = t->FIND_BAD_DIR;
                        }
                    }
                }
                else if( stack[p] == (KV(tree_t)*) &nil ) // from BAD child, current is useless
                    --p;
                else{ // from GOOD child, current = stack[p], current->key >= key
                    t = stack[p];
                    if( K(cmp)(aTHX_ SP, t->key, key, cntr->cmp) == 0 ){
                        SP = K(mxret)(aTHX_ SP, t->key);
#if I(VALUE) != I(void)
                        SP = V(mxret)(aTHX_ SP, t->value);
#endif
                        --limit;

                        stack[p] = (KV(tree_t)*) &nil; // attempt BAD child
                        stack[++p] = NULL;
                        t = t->FIND_BAD_DIR;
                    }
                    else
                        --p;
                }
            }
#if I(VALUE) != I(void)
            if( GIMME_V != G_ARRAY )
                --SP;
#endif
            return SP;
        }
        if( K(cmp)(aTHX_ SP, t->key, key, cntr->cmp) FIND_CMP_OP 0 )
            t = t->FIND_GOOD_DIR;
        else
            t = t->FIND_BAD_DIR;
    }
    return SP;
}

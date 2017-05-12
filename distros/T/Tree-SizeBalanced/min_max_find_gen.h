// vim: filetype=xs

// 假設 tree 不是空的
static inline SV** KV(MIN_MAX_FIND_FUNC)(pTHX_ SV** SP, KV(tree_cntr_t) * cntr, int limit){
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
                stack[p] = t; // attempt GOOD child
                stack[++p] = NULL;
                t = t->MIN_MAX_FIND_GOOD_DIR;
            }
        }
        else if( stack[p] == (KV(tree_t)*) &nil ) // from BAD child, current is useless
            --p;
        else{ // from GOOD child, current = stack[p]
            t = stack[p];
            SP = K(mxret)(aTHX_ SP, t->key);
#if I(VALUE) != I(void)
            SP = V(mxret)(aTHX_ SP, t->value);
#endif
            --limit;

            stack[p] = (KV(tree_t)*) &nil; // attempt BAD child
            stack[++p] = NULL;
            t = t->MIN_MAX_FIND_BAD_DIR;
        }
    }

#if I(VALUE) != I(void)
    if( p >= 0 && GIMME_V != G_ARRAY )
        --SP;
#endif
    return SP;
}

// 假設 0 <= offset < cntr->size
static inline SV** KV(SKIP_FIND_FUNC)(pTHX_ SV** SP, KV(tree_cntr_t) * cntr, int offset, int limit){
    KV(tree_t) * t = cntr->root;

    if( limit != 1 && GIMME_V != G_ARRAY )
        limit = 1;

    KV(tree_t)* stack[cntr->ever_height+1];
    int p = 0;

    while(TRUE){
        if( offset == t->MIN_MAX_FIND_GOOD_DIR->size ){
            stack[p] = t;
            while( limit != 0 && p >= 0 ){
                if( stack[p] == NULL ){ // from parent, current = t
                    if( t == (KV(tree_t)*) &nil )
                        --p;
                    else{
                        stack[p] = t; // attempt GOOD child
                        stack[++p] = NULL;
                        t = t->MIN_MAX_FIND_GOOD_DIR;
                    }
                }
                else if( stack[p] == (KV(tree_t)*) &nil ) // from BAD child, current is useless
                    --p;
                else{ // from GOOD child, current = stack[p]
                    t = stack[p];
                    SP = K(mxret)(aTHX_ SP, t->key);
#if I(VALUE) != I(void)
                    SP = V(mxret)(aTHX_ SP, t->value);
#endif
                    --limit;

                    stack[p] = (KV(tree_t)*) &nil; // attempt BAD child
                    stack[++p] = NULL;
                    t = t->MIN_MAX_FIND_BAD_DIR;
                }
            }

#if I(VALUE) != I(void)
            if( p >= 0 && GIMME_V != G_ARRAY )
                --SP;
#endif
            return SP;
        }
        if( offset < t->MIN_MAX_FIND_GOOD_DIR->size ){
            stack[p] = t;
            stack[++p] = NULL;
            t = t->MIN_MAX_FIND_GOOD_DIR;
        }
        else{
            stack[p] = (KV(tree_t)*) &nil;
            stack[++p] = NULL;
            offset -= t->MIN_MAX_FIND_GOOD_DIR->size + 1;
            t = t->MIN_MAX_FIND_BAD_DIR;
        }
    }
}

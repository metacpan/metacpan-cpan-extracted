// vim: filetype=xs

SV ** KV(RANGE_FIND_FUNC)(pTHX_ SV** SP, KV(tree_cntr_t) * cntr, T(KEY) lower_key, T(KEY) upper_key){
    KV(tree_t)* t = cntr->root;

    KV(tree_t)* stack[cntr->ever_height+1];
    int p = 0;
    stack[0] = NULL;

    while( p >= 0 ){
        if( stack[p] == NULL ){ // from parent, current = t
            if( t == (KV(tree_t)*) &nil )
                --p;
            else{
                if( K(cmp)(aTHX_ SP, t->key, lower_key, cntr->cmp) RANGE_FIND_CMP_L_OP 0 ){
                    stack[p] = t; // attempt left child
                    stack[++p] = NULL;
                    t = t->left;
                }
                else if( K(cmp)(aTHX_ SP, t->key, upper_key, cntr->cmp) RANGE_FIND_CMP_R_OP 0 ){
                    stack[p] = (KV(tree_t)*) &nil; // attempt right child
                    stack[++p] = NULL;
                    t = t->right;
                }
                else
                    --p;
            }
        }
        else if( stack[p] == (KV(tree_t)*) &nil ) // from right child, current is useless
            --p;
        else{ // from left child, current = stack[p]
            t = stack[p];
            if( K(cmp)(aTHX_ SP, t->key, upper_key, cntr->cmp) RANGE_FIND_CMP_R_OP 0 ){
                SP = K(mxret)(aTHX_ SP, t->key);
#if I(VALUE) != I(void)
                SP = V(mxret)(aTHX_ SP, t->value);
#endif

                stack[p] = (KV(tree_t)*) &nil; // attempt right child
                stack[++p] = NULL;
                t = t->right;
            }
            else
                --p;
        }
    }

    return SP;
}

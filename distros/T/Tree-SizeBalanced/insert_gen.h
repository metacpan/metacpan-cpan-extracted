// vim: filetype=xs

KV(tree_t) * KV(INSERT_SUBTREE_FUNC)(pTHX_ SV**SP, KV(tree_cntr_t) * cntr, KV(tree_t) * p, T(KEY) key, KV(tree_t) * new_tree, T(VALUE) value, int height){
    ++p->size;
    if( K(cmp)(aTHX_ SP, p->key, key, cntr->cmp) INSERT_CMP_OP 0 ){
        if( p->right == (KV(tree_t)*) &nil ){
            p->right = new_tree;
            if( height > cntr->ever_height )
                cntr->ever_height = height;
        }
        else{
            p->right = KV(INSERT_SUBTREE_FUNC)(aTHX_ SP, cntr, p->right, key, new_tree, value, height+1);
            p = (KV(tree_t)*) maintain_larger_right(p);
        }
    }
    else{
        if( p->left == (KV(tree_t)*) &nil ){
            p->left = new_tree;
            if( height > cntr->ever_height )
                cntr->ever_height = height;
        }
        else{
            p->left = KV(INSERT_SUBTREE_FUNC)(aTHX_ SP, cntr, p->left, key, new_tree, value, height+1);
            p = (KV(tree_t)*) maintain_larger_left(p);
        }
    }
    return p;
}
static inline void KV(INSERT_FUNC)(pTHX_ SV**SP, KV(tree_cntr_t) * cntr, T(KEY) key, T(VALUE) value){
    KV(tree_t) * new_tree = KV(allocate_cell)(cntr, key, value);

    if( UNLIKELY(cntr->root == (KV(tree_t)*) &nil) ){
        cntr->root = new_tree;
        if( cntr->ever_height < 1 )
            cntr->ever_height = 1;
        return;
    }

    cntr->root = KV(INSERT_SUBTREE_FUNC)(aTHX_ SP, cntr, cntr->root, key, new_tree, value, 2);
}

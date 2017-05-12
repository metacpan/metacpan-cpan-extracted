// vim: filetype=xs

KV(tree_t) * KV(DELETE_SUBTREE_FUNC)(pTHX_ SV**SP, KV(tree_cntr_t) * cntr, KV(tree_t) * tree, T(KEY) key){
    if( LIKELY(tree != (KV(tree_t)*) &nil) ){
        KV(tree_t) * c;
        if( K(cmp)(aTHX_ SP, tree->key, key, cntr->cmp) DELETE_CMP_OP 0 ){
            c = KV(DELETE_SUBTREE_FUNC)(aTHX_ SP, cntr, tree->DELETE_GOOD_DIR, key);
            if( c ){
                tree->DELETE_GOOD_DIR = c;
                --tree->size;
                return (KV(tree_t)*) DELETE_MAINTAIN_BAD_DIR(tree);
            }

            if( K(cmp)(aTHX_ SP, tree->key, key, cntr->cmp) == 0 )
                return KV(tree_delete_root)(cntr, tree);
        }
        else{
            c = KV(DELETE_SUBTREE_FUNC)(aTHX_ SP, cntr, tree->DELETE_BAD_DIR, key);
            if( c ){
                tree->DELETE_BAD_DIR = c;
                --tree->size;
                return (KV(tree_t)*) DELETE_MAINTAIN_GOOD_DIR(tree);
            }
        }
    }
    return NULL;
}

static inline bool KV(DELETE_FUNC)(pTHX_ SV**SP, KV(tree_cntr_t) * cntr, T(KEY) key){
    KV(tree_t) * new_root = KV(DELETE_SUBTREE_FUNC)(aTHX_ SP, cntr, cntr->root, key);
    if( new_root ){
        cntr->root = new_root;
        return TRUE;
    }
    return FALSE;
}

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

// #define ENABLE_DEBUG 1

#define debug(fmt, ...) \
            do { if (ENABLE_DEBUG) fprintf(stderr, "DEBUG: " fmt "\n", ##__VA_ARGS__); } while (0)

typedef struct _btree_node BinaryTreeNode;
typedef struct _btree_pad BinaryTreePad;

struct _btree_pad { 
    BinaryTreeNode *root;
    HV * options;
};

struct _btree_node {  
    IV key;
    // unsigned long size;
    BinaryTreeNode* parent;
    BinaryTreeNode* left;
    BinaryTreeNode* right;
    HV * payload;
};


BinaryTreePad * btree_pad_new();


BinaryTreeNode * btree_find_leftmost_node(BinaryTreeNode * n);

BinaryTreeNode * btree_node_create(IV key, HV *payload);


BinaryTreePad * btree_pad_new()
{
    BinaryTreePad * pad = NULL;
    Newx(pad, sizeof(BinaryTreePad), BinaryTreePad);
    pad->root = NULL;
    pad->options = NULL;
    return pad;
}

BinaryTreeNode * btree_node_create(IV key, HV *payload)
{
    BinaryTreeNode * new_node = NULL;
    Newx(new_node, sizeof(BinaryTreeNode), BinaryTreeNode);
    new_node->payload = payload;
    new_node->key = key;
    new_node->left = NULL;
    new_node->right = NULL;
    return new_node;
}


bool btree_update(BinaryTreeNode * node, IV key, HV * payload);
BinaryTreeNode * btree_search(BinaryTreeNode * node, IV key);
inline bool btree_insert_node_hash_by_key(BinaryTreeNode * node, IV key, HV * payload);
inline bool btree_pad_insert_node(BinaryTreePad *pad, IV key, HV *node_hash);
inline bool btree_pad_insert_node_by_key_field(BinaryTreePad *pad, char * key_field, int key_field_len, HV *node_hash);
inline AV * btree_pad_insert_av_nodes_by_key_field(BinaryTreePad * pad, char * key_field, unsigned int key_field_len, AV* new_nodes);
bool btree_node_exists(BinaryTreeNode * node, IV key);

void btree_preorder_traverse(BinaryTreeNode * node, SV *callback);
void btree_inorder_traverse(BinaryTreeNode * node, SV *callback);
void btree_postorder_traverse(BinaryTreeNode * node, SV *callback);

BinaryTreeNode * btree_find_leftmost_node(BinaryTreeNode * n)
{
    if (n->left) {
        return btree_find_leftmost_node(n->left);
    }
    return n;
}

bool btree_delete(BinaryTreeNode * node, IV key);

void btree_node_free(BinaryTreeNode * node)
{
    if (node) {
        if (node->left) {
            btree_node_free(node->left);
        }
        if (node->right) {
            btree_node_free(node->right);
        }
        if (node->payload) {
            // SvREFCNT_dec(node->payload);
        }
        Safefree(node);
    }
}

bool btree_delete(BinaryTreeNode * node, IV key) 
{
    if (key < node->key) {
        if (node->left) {
            return btree_delete(node->left, key);
        } else {
            return FALSE;
        }
    } else if (key > node->key) {
        if (node->right) {
            return btree_delete(node->right, key);
        } else {
            return FALSE;
        }
    } else if (key == node->key) {

        if (node->left && node->right) {
            BinaryTreeNode* leftmost = btree_find_leftmost_node(node->right);
            node->key = leftmost->key;
            node->payload = leftmost->payload;
            btree_node_free(leftmost);
        } else if (node->left) {
            BinaryTreeNode *to_free = node->left;
            node->key = to_free->key;
            node->payload = to_free->payload;
            node->left = to_free->left;
            Safefree(to_free);
        } else if (node->right) {
            BinaryTreeNode *to_free = node->right;
            node->key = to_free->key;
            node->payload = to_free->payload;
            node->right = to_free->right;
            Safefree(to_free);
        } else {
            if (node->parent && node->parent->left == node) {
                node->parent->left = NULL;
            } else if (node->parent && node->parent->right == node) {
                node->parent->right = NULL;
            }
            btree_node_free(node);
        }
        return TRUE;
    }
    return FALSE;
}


static
inline
void callback_value(IV key, SV* node_sv, SV* callback)
{
    int ret;

    dSP;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(key)));
    XPUSHs(node_sv);
    PUTBACK;

    ret = call_sv(callback, G_SCALAR);
    SPAGAIN;

    /*
    if (!ret)
        croak("callback did not return a value");
    */
    // IV value = POPi;
    PUTBACK;
    // return value;
}

void btree_postorder_traverse(BinaryTreeNode * node, SV *callback)
{
    if (node->left) {
        btree_preorder_traverse(node->left, callback);
    }
    if (node->right) {
        btree_preorder_traverse(node->right, callback);
    }
    if (node->payload) {
        callback_value(node->key, (SV*) newRV_noinc((SV*) node->payload), callback);
    }
}

void btree_inorder_traverse(BinaryTreeNode * node, SV *callback)
{
    if (node->left) {
        btree_preorder_traverse(node->left, callback);
    }
    if (node->payload) {
        callback_value(node->key, (SV*) newRV_noinc((SV*) node->payload), callback);
    }
    if (node->right) {
        btree_preorder_traverse(node->right, callback);
    }
}

void btree_preorder_traverse(BinaryTreeNode * node, SV *callback)
{
    if (node->payload) {
        callback_value(node->key, (SV*) newRV_noinc((SV*) node->payload), callback);
    }
    if (node->left) {
        btree_preorder_traverse(node->left, callback);
    }
    if (node->right) {
        btree_preorder_traverse(node->right, callback);
    }
}

bool btree_update(BinaryTreeNode * node, IV key, HV * payload)
{
    if (key < node->key) {
        if (node->left) {
            return btree_update(node->left, key, payload);
        }
        return FALSE;
    } else if (key > node->key) {
        if (node->right) {
            return btree_update(node->right, key, payload);
        }
        return FALSE;
    } else if (key == node->key) {
        if (node->payload) {
            SvREFCNT_dec(node->payload);
        }
        node->payload = payload;
        return TRUE;
    }
    return FALSE;
}


bool btree_node_exists(BinaryTreeNode * node, IV key)
{
    if (key < node->key) {
        if (node->left) {
            return btree_node_exists(node->left, key);
        }
        return false;
    } else if (key > node->key) {
        if (node->right) {
            return btree_node_exists(node->right, key);
        }
        return false;
    } else if (key == node->key) {
        return true;
    }
    return false;
}

BinaryTreeNode * btree_search(BinaryTreeNode * node, IV key)
{
    if (key < node->key) {
        if (node->left) {
            return btree_search(node->left, key);
        }
        return NULL;
    } else if (key > node->key) {
        if (node->right) {
            return btree_search(node->right, key);
        }
        return NULL;
    } else if (key == node->key) {
        return node;
    }
    return NULL;
}

bool btree_insert_node_hash_by_key(BinaryTreeNode * node, IV key, HV * payload) 
{
    if (key < node->key) {
        if (node->left) {
            return btree_insert_node_hash_by_key(node->left, key, payload);
        } else {
            BinaryTreeNode * new_node = btree_node_create(key, payload);
            new_node->parent = node;
            node->left = new_node;
        }
        return TRUE;
    } else if (key > node->key) {
        if (node->right) {
            return btree_insert_node_hash_by_key(node->right, key, payload);
        } else {
            BinaryTreeNode * new_node = btree_node_create(key, payload);
            new_node->parent = node;
            node->right = new_node;
        }
        return TRUE;
    } else if (key == node->key) {
        croak("the key already exists in the tree.");
        return FALSE;
    }
    return FALSE;
}


void btree_dump(BinaryTreeNode* node, uint indent);

void btree_dump(BinaryTreeNode* node, uint indent)
{
    for (int i = 0 ; i < indent; i++) {
        fprintf(stderr, "    ");
    }
    fprintf(stderr, "(o) key: %lu", node->key);
    if (node->payload) {
        fprintf(stderr, ", hash: %s", Perl_sv_peek((SV*) node->payload) );
    } else {
        fprintf(stderr, ", hash: (empty)");
    }
    fprintf(stderr, "\n");

    if (node->left) {
        for (int i = 0 ; i < indent; i++) {
            fprintf(stderr, "    ");
        }
        fprintf(stderr, "    ->left:\n");
        btree_dump(node->left, indent+2);
    }
    if (node->right) {
        for (int i = 0 ; i < indent; i++) {
            fprintf(stderr, "    ");
        }
        fprintf(stderr, "    ->right:\n");
        btree_dump(node->right, indent+2);
    }
}


IV hv_fetch_key_must(HV * hash, char *field, uint field_len);

IV hv_fetch_key_must(HV * hash, char *field, uint field_len)
{
    SV** ret = hv_fetch(hash, field, field_len, FALSE);
    if (ret == NULL) {
        croak("key field %s does not exist", field);
    }
    if (!SvIOK(*ret)) {
        croak("The value of %s is invalid", field);
    }
    return SvIV(*ret);
}



char * get_options_key_field(HV * options)
{
    if (!hv_exists(options, "by_key", sizeof("by_key") - 1)) {
        return NULL;
    }

    SV** field_sv = hv_fetch(options, "by_key", 6, 0);
    if (field_sv == NULL) {
        return NULL;
    }

    if (SvTYPE(*field_sv) != SVt_PV) {
        return NULL;
    }

    char * key_field = (char *)SvPV_nolen(*field_sv);
    if (key_field == NULL) {
        return NULL;
    }
    return key_field;
}



bool btree_pad_insert_node(BinaryTreePad *pad, IV key, HV *node_hash)
{
    SvREFCNT_inc(node_hash);
    if (pad->root) {
        return btree_insert_node_hash_by_key(pad->root, key, node_hash);
    }
    pad->root = btree_node_create(key, node_hash);
    return TRUE;
}

bool btree_pad_insert_node_by_key_field(BinaryTreePad *pad, char * key_field, int key_field_len, HV *node_hash)
{
    IV key = hv_fetch_key_must(node_hash, key_field, key_field_len);
    return btree_pad_insert_node(pad, key, node_hash);
}

AV * btree_pad_insert_av_nodes_by_key_field(BinaryTreePad * pad, char * key_field, unsigned int key_field_len, AV* new_nodes)
{
    bool ret;
    AV * av_result = newAV();
    SSize_t top_index = av_top_index(new_nodes);
    for (int i = 0; i <= top_index; i++) {
        SV **  new_node_ref_p = av_fetch(new_nodes, i, FALSE);
        HV * new_node = (HV*) SvRV(*new_node_ref_p);
        ret = btree_pad_insert_node_by_key_field(pad, key_field, key_field_len, new_node);
        av_push(av_result, newSViv(ret));
    }
    return av_result;
}


MODULE = Tree::Binary::XS		PACKAGE = Tree::Binary::XS		

TYPEMAP: <<END;

END

void
new(...)
    PPCODE:
        BinaryTreePad *pad = btree_pad_new();

        // printf("pad: %x\n", pad);

        // newHV();
        SV* ret = newSV(0);
        SvUPGRADE(ret, SVt_RV);
        SvROK_on(ret);
        SvRV(ret) = (SV*)pad;

        SV * obj = newRV_noinc(ret);
        STRLEN classname_len;
        char * classname = SvPVbyte(ST(0), classname_len);
        HV * stash = gv_stashpvn(classname, classname_len, 0);
        sv_bless(obj, stash);

        SV * options_ref = ST(1);
        if (options_ref) {
            HV * options_hv = (HV*) SvRV(options_ref);
            SvREFCNT_inc(options_hv);
            pad->options = options_hv;
        }
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(obj));


HV*
options(self_sv)
    SV* self_sv
    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));
        if (pad->options) {
            RETVAL = pad->options;
        } else {
            RETVAL = newHV();
        }
    OUTPUT:
        RETVAL



SV*
delete(self_sv, ...)
    SV* self_sv
    CODE:

    BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));
    if (!pad->root) {
        // Empty tree
        XSRETURN_UNDEF;
    }

    if (items > 1) {
        bool deleted_any = false;
        int i;
        for (i = 1; i < items; i++) {
            SV * arg_sv = ST(i);
            if (!SvIOK(arg_sv)) {
                croak("Invalid key: it should be an integer.");
            }
            IV key = SvIV(arg_sv);
            if (btree_delete(pad->root, key)) {
                deleted_any = true;
            }
        }

        if (deleted_any) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }
    XSRETURN_NO;


void
dump(self_sv)
    SV* self_sv
    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));
        btree_dump(pad->root, 0);



SV *
search(self_sv, key_sv)
    SV * self_sv
    SV * key_sv
    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));

        if (!pad->root) {
            XSRETURN_UNDEF;
        }

        if (!SvIOK(key_sv)) {
            croak("The search key must be IV");
        }

        IV key = SvIV(key_sv);
        BinaryTreeNode * node = btree_search(pad->root, key);

        if (node == NULL || node->payload == NULL) {
            XSRETURN_UNDEF;
        }

        // Perl_sv_dump(node->payload);
        RETVAL = newRV_inc((SV*) node->payload);
    OUTPUT:
        RETVAL


SV*
update(self_sv, ...)
    SV* self_sv
    CODE:

        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));

        char *key_field = "key";

        if (!pad || !pad->options) {
            XSRETURN_UNDEF;
        }
        if (pad->options) {
            key_field = get_options_key_field(pad->options);
        }

        IV key;
        HV * node_hash = NULL;

        // if there is only one argument (items == 2 including $self)
        if (items == 2) {
            if (SvIOK(ST(1))) {
                key = SvIV( ST(1) );
                node_hash = newHV();
            } else if (SvROK( ST(1) ) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
                node_hash = (HV*) SvRV(ST(1));
            }
        } else if (items == 3) {
            if (SvIOK(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
                key = SvIV( ST(1) );
                node_hash = (HV*) SvRV(ST(2));
            } else {
                croak("The BinaryTree::insert method can only accept either (key, hashref) or (hashref)");
            }
        }

        if (!key) {
            // If the key does not exist
            key = hv_fetch_key_must(node_hash, key_field, strlen(key_field));
        }

        if (pad->root) {
            SvREFCNT_inc(node_hash);
            if (btree_update(pad->root, key, node_hash)) {
                XSRETURN_YES;
            }
        }
        XSRETURN_NO;


void
preorder_traverse(self_sv, callback)
    SV* self_sv
    SV* callback
    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));
        if (pad->root) {
            btree_preorder_traverse(pad->root, callback);
        }

void
inorder_traverse(self_sv, callback)
    SV* self_sv
    SV* callback
    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));
        if (pad->root) {
            btree_inorder_traverse(pad->root, callback);
        }

void
postorder_traverse(self_sv, callback)
    SV* self_sv
    SV* callback
    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));
        if (pad->root) {
            btree_postorder_traverse(pad->root, callback);
        }


SV *
exists(self_sv, arg)
    SV* self_sv
    SV* arg

    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));

        IV key;
        
        if (SvIOK(arg)) {
            key = SvIV(arg);
        } else if (SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HV * node_hash = (HV*) SvRV(ST(1));
            char * key_field = "key";
            if (!pad || !pad->options) {
                XSRETURN_UNDEF;
            }
            if (pad->options) {
                key_field = get_options_key_field(pad->options);
            }
            key = hv_fetch_key_must(node_hash, key_field, strlen(key_field));

        } else {
            croak("The exists method can only accept exists(IV) or exists(HashRef)");
        }

        if (pad->root) {
            bool ret = btree_node_exists(pad->root, key);
            XSRETURN(ret);
        }

AV *
insert_those(self_sv, ...)
    SV* self_sv
    CODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));

        char * key_field = "key";
        if (!pad || !pad->options) {
            XSRETURN_UNDEF;
        }
        if (pad->options) {
            key_field = get_options_key_field(pad->options);
        }
        if (SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV ) {
            RETVAL = btree_pad_insert_av_nodes_by_key_field(pad, key_field, strlen(key_field), (AV*) SvRV(ST(1)));
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL


SV *
insert(self_sv, ...)
    SV* self_sv
    CODE:

    BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));

    char * key_field = "key";
    if (!pad || !pad->options) {
        XSRETURN_UNDEF;
    }
    if (pad->options) {
        key_field = get_options_key_field(pad->options);
    }

    IV key;
    HV * node_hash = NULL;

    // if there is only one argument (items == 2 including $self)
    if (items == 2) {

        // If the key is defined but without hash
        if (SvIOK(ST(1))) {
            key = SvIV( ST(1) );
            node_hash = newHV();
        } else if (SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
            // dereference the hashref
            node_hash = (HV*) SvRV(ST(1));
        } else if (SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV ) {

            AV * result = btree_pad_insert_av_nodes_by_key_field(pad, key_field, strlen(key_field), (AV*) SvRV(ST(1)));
            XSRETURN_YES;
            // RETVAL = sv_2mortal(result);

        } else {
            croak("The BinaryTree::insert method can only accept either (key, hashref) or (hashref)");
        }
    } else if (items == 3) {
        if (SvIOK(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            key = SvIV( ST(1) );
            node_hash = (HV*) SvRV(ST(2));
        } else {
            croak("The BinaryTree::insert method can only accept either (key, hashref) or (hashref)");
        }
    }

    if (!key) {
        // If the key does not exist
        key = hv_fetch_key_must(node_hash, key_field, strlen(key_field));
    }

    bool ret = btree_pad_insert_node(pad, key, node_hash);
    XSRETURN(ret);

void
DESTROY(self_sv)
    SV* self_sv
    PPCODE:
        BinaryTreePad* pad = (BinaryTreePad*) SvRV(SvRV(self_sv));
        // printf("DESTORY pad: %x\n", pad);
        // BinaryTreePad* pad = *(BinaryTreePad**) p;
        if (pad && pad->root) {
            btree_node_free(pad->root);
        }
        Safefree(pad);
        SvRV(SvRV(self_sv)) = 0;


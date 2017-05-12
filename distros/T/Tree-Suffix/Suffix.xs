#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

#include <libstree.h>

int
redirect_stderr () {
    return dup2(fileno(stdout), fileno(stderr));
}

void
restore_stderr (int old) {
    if (old != -1) dup2(old, fileno(stderr));
}

LST_Node *
follow_string (LST_STree *tree, LST_String *string) {
    LST_Node *node = tree->root_node;
    LST_Edge *edge = NULL;
    u_int done = 0, len, common;
    u_int todo = string->num_items;

    while (todo > 0) {
        for (edge = node->kids.lh_first; edge; edge = edge->siblings.le_next) {
            if (lst_string_eq(edge->range.string, edge->range.start_index,
                              string, done))
            {
                break;
            }
        }
        if (! edge) {
            break;
        }

        len = lst_edge_get_length(edge);
        common = lst_string_items_common(edge->range.string,
                                         edge->range.start_index, string, done,
                                         len);
        done += common;
        todo -= common;
        node = edge->dst_node;
    }

    return (done < string->num_items - 1) ? NULL : node;
}

typedef LST_STree *Tree__Suffix;

MODULE = Tree::Suffix  PACKAGE = Tree::Suffix

Tree::Suffix
new (class, ...)
    char *class
PROTOTYPE: $;@
PREINIT:
    LST_STree *self;
    IV i;
    STRLEN len;
    char *string;
CODE:
    self = lst_stree_new(NULL);
    if (! self) {
        XSRETURN_UNDEF;
    }
    for (i = 1; i < items; i++) {
        if (! SvOK(ST(i))) {
            continue;
        }
        string = SvPV(ST(i), len);
        lst_stree_add_string(self, lst_string_new(string, 1, len));
    }
    RETVAL = self;
OUTPUT:
    RETVAL

IV
allow_duplicates (self, flag=&PL_sv_yes)
    Tree::Suffix self
    SV *flag
PROTOTYPE: $;$
CODE:
    if (items == 2) {
        lst_stree_allow_duplicates(self, SvTRUE(flag));
    }
    RETVAL = self->allow_duplicates;
OUTPUT:
    RETVAL

IV
insert (self, ...)
    Tree::Suffix self
PROTOTYPE: $@
PREINIT:
    STRLEN len;
    char *string;
    IV i, pre;
CODE:
    if (items == 1) {
        XSRETURN_IV(0);
    }
    pre = self->num_strings;
    for (i = 1; i < items; i++) {
        if (! SvOK(ST(i))) {
            continue;
        }
        string = SvPV(ST(i), len);
        lst_stree_add_string(self, lst_string_new(string, 1, len));
    }
    XSRETURN_IV(self->num_strings - pre);

void
strings (self)
    Tree::Suffix self
PROTOTYPE: $
PREINIT:
    LST_StringHash *hash;
    LST_StringHashItem *hi;
    IV i;
PPCODE:
    if (GIMME_V != G_ARRAY) {
        XSRETURN_IV(self->num_strings);
    }
    EXTEND(SP, self->num_strings);
    for (i = 0; i < LST_STRING_HASH_SIZE; i++) {
        hash = &self->string_hash[i];
        for (hi = hash->lh_first; hi; hi = hi->items.le_next) {
            PUSHs(sv_2mortal(newSViv(hi->index)));
        }
    }

IV
nodes (self)
    Tree::Suffix self
PROTOTYPE: $
CODE:
    XSRETURN_IV(self->root_node->num_kids);

void
clear (self)
    Tree::Suffix self
PROTOTYPE: $
CODE:
    lst_stree_clear(self);
    lst_stree_init(self);

void
dump (self)
    Tree::Suffix self
PROTOTYPE: $
PREINIT:
    IV fn;
CODE:
    /* Redirect from stderr to stdout */
    fn = redirect_stderr();
    lst_debug_print_tree(self);
    restore_stderr(fn);

IV
remove (self, ...)
    Tree::Suffix self
PROTOTYPE: $@
PREINIT:
    LST_StringHash *hash;
    LST_StringHashItem *hi;
    LST_String *str;
    STRLEN len;
    char *string;
    IV i, j, k, done = 0;
CODE:
    for (i = 1; i < items; i++) {
        if (! SvOK(ST(i))) {
            continue;
        }
        string = SvPV(ST(i), len);
        str = lst_string_new(string, 1, len);
        /* Check each hash bucket for the string.  Would it be better to use
        *  find() ?
        */
        for (j = 0; j < LST_STRING_HASH_SIZE; j++) {
            hash = &self->string_hash[j];
            for (hi = hash->lh_first; hi; hi = hi->items.le_next) {
                if (lst_string_get_length(hi->string) != len) {
                    continue;
                }
                for (k = 0; k < len && lst_string_eq(str, k, hi->string, k);
                     k++);
                if (k == len) {
                    lst_stree_remove_string(self, hi->string);
                    done++;
                    if (! self->allow_duplicates) {
                        goto next_item;
                    }
                }
            }
        }
        next_item:
            lst_string_free(str);
    }
    XSRETURN_IV(done);

void
_algorithm_longest_substrings (self, min_len=0, max_len=0)
    Tree::Suffix self
    IV min_len
    IV max_len
ALIAS:
    lcs = 1
    longest_common_substrings = 2
    lrs = 3
    longest_repeated_substrings = 4
PROTOTYPE: $;$$
PREINIT:
    LST_StringSet *res;
    LST_String *str;
PPCODE:
    if (ix > 2) {
        res = lst_alg_longest_repeated_substring(self, min_len, max_len);
    }
    else {
        res = lst_alg_longest_common_substring(self, min_len, max_len);
    }
    if (res) {
        EXTEND(SP, res->size);
        for (str = res->members.lh_first; str; str = str->set.le_next) {
            PUSHs(sv_2mortal(newSVpv((char *)lst_string_print(str), 0)));
        }
        lst_stringset_free(res);
    }

void
find (self, string)
    Tree::Suffix self
    SV *string
ALIAS:
    match = 1
    search = 2
PROTOTYPE: $$
PREINIT:
    LST_String *str;
    LST_Edge *edge;
    LST_Node *node;
    TAILQ_HEAD(shead, lst_node) stack;
    AV *match;
    STRLEN len = 0;
PPCODE:
    if (SvOK(string)) {
        len = SvCUR(string);
    }
    if (len < 1) {
        GIMME_V == G_ARRAY ? XSRETURN_EMPTY : XSRETURN_IV(0);
    }
    str = lst_string_new(SvPV_nolen(string), 1, len);
    node = follow_string(self, str);
    lst_string_free(str);
    if (! node) {
        GIMME_V == G_ARRAY ? XSRETURN_EMPTY : XSRETURN_IV(0);
    }
    /* Perform a depth-first search from matching node to find leafs. */
    TAILQ_INIT(&stack);
    TAILQ_INSERT_HEAD(&stack, node, iteration);
    while ((node = stack.tqh_first)) {
        TAILQ_REMOVE(&stack, stack.tqh_first, iteration);
        if (lst_node_is_leaf(node)) {
            match = (AV *)newAV();
            av_extend(match, 3);
            av_push(match, newSViv(lst_stree_get_string_index(self, node->up_edge->range.string)));
            av_push(match, newSViv(node->index));
            av_push(match, newSViv(node->index + len - 1));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)match)));
        }
        for (edge = node->kids.lh_first; edge; edge = edge->siblings.le_next) {
            TAILQ_INSERT_HEAD(&stack, edge->dst_node, iteration);
        }
    }
    if (GIMME_V == G_SCALAR) {
        XSRETURN_IV(SP - MARK);
    }

SV *
string (self, idx, start=0, end=-1)
    Tree::Suffix self
    IV idx
    IV start
    IV end
PROTOTYPE: $$;$$
PREINIT:
    LST_StringHash *hash;
    LST_StringHashItem *hi;
    LST_StringIndex range;
    IV i;
CODE:
    for (i = 0; i < LST_STRING_HASH_SIZE; i++) {
        hash = &self->string_hash[i];
        for (hi = hash->lh_first; hi && hi->index != idx;
            hi = hi->items.le_next);
        if (hi && hi->index == idx) {
            break;
        }
    }
    if (! hi) {
        XSRETURN_NO;
    }

    lst_string_index_init(&range);
    range.string = hi->string;

    if (items < 4) {
        end = hi->string->num_items - 1;
    }
    if (start < 0) {
        start = 0;
    }
    /* Avoid print_func from returning "<eos>" */
    else if (start == hi->string->num_items - 1) {
        start++;
    }
    if (end < start) {
        XSRETURN_NO;
    }
    range.start_index = start;
    *(range.end_index) = end;
    RETVAL = newSVpv(hi->string->sclass->print_func(&range), 0);
OUTPUT:
    RETVAL

void
DESTROY (self)
    Tree::Suffix self
PROTOTYPE: $
CODE:
    lst_stree_free(self);

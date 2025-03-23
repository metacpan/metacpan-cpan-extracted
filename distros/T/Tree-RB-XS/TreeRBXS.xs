#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#include "ppport.h"

/* The core Red/Black algorithm which operates on rbtree_node_t */
#include "rbtree.h"

struct TreeRBXS;
struct TreeRBXS_item;

#define AUTOCREATE 1
#define OR_DIE 2

/* These get serialized as bytes for Storable, so should not change,
 * or else STORABLE_thaw needs adapted.
 */
#define KEY_TYPE_ANY   1
#define KEY_TYPE_CLAIM 2
#define KEY_TYPE_INT   3
#define KEY_TYPE_FLOAT 4
#define KEY_TYPE_BSTR  5
#define KEY_TYPE_USTR  6
#define KEY_TYPE_MAX   6

/* I am only using foldEQ for parsing user parameters, not for the sort functions,
 * so this should be fine for Perl < 5.14 */
#ifndef foldEQ
static bool shim_foldEQ(const char *s1, const char *s2, int len) {
	for (--len; len >= 0; --len)
		if (toLOWER(s1[len]) != toLOWER(s2[len]))
			return 0;
	return 1;
}
#define foldEQ shim_foldEQ
#endif

static bool looks_like_integer(SV *sv) {
	if (!sv) return false;
	if (SvMAGICAL(sv))
		mg_get(sv);
	if (SvIOK(sv) || SvUOK(sv))
		return true;
	if (SvNOK(sv) && (SvNV(sv) == (NV)(IV)SvNV(sv)))
		return true;
	if (SvPOK(sv)) {
		STRLEN len;
		const char *str= SvPV(sv, len);
		if (len == 0 || !((str[0] >= '0' && str[0] <= '9') || str[0] == '-' || str[0] == '+'))
			return false;
		while (--len > 0) {
			if (str[len] < '0' || str[len] > '9')
				return false;
		}
		return true;
	}
	return false;
}

static int parse_key_type(SV *type_sv) {
	const char *str;
	IV key_type= -1;
	if (SvIOK(type_sv)) {
		key_type= SvIV(type_sv);
		if (key_type < 1 || key_type > KEY_TYPE_MAX)
			key_type= -1;
	}
	else if (SvPOK(type_sv)) {
		STRLEN len;
		str= SvPV(type_sv, len);
		if (len > 9 && foldEQ(str, "KEY_TYPE_", 9)) {
			str += 9;
			len -= 9;
		}
		key_type= (len == 3 && foldEQ(str, "ANY",   3))? KEY_TYPE_ANY
		        : (len == 5 && foldEQ(str, "CLAIM", 5))? KEY_TYPE_CLAIM
		        : (len == 3 && foldEQ(str, "INT",   3))? KEY_TYPE_INT
		        : (len == 5 && foldEQ(str, "FLOAT", 5))? KEY_TYPE_FLOAT
		        : (len == 4 && foldEQ(str, "BSTR",  4))? KEY_TYPE_BSTR
		        : (len == 4 && foldEQ(str, "USTR",  4))? KEY_TYPE_USTR
		        : -1;
	}
	return (int) key_type;
}

static const char *get_key_type_name(int key_type) {
	switch (key_type) {
	case KEY_TYPE_ANY:   return "KEY_TYPE_ANY";
	case KEY_TYPE_CLAIM: return "KEY_TYPE_CLAIM";
	case KEY_TYPE_INT:   return "KEY_TYPE_INT";
	case KEY_TYPE_FLOAT: return "KEY_TYPE_FLOAT";
	case KEY_TYPE_BSTR:  return "KEY_TYPE_BSTR";
	case KEY_TYPE_USTR:  return "KEY_TYPE_USTR";
	default: return NULL;
	}
}

typedef int TreeRBXS_cmp_fn(struct TreeRBXS *tree, struct TreeRBXS_item *a, struct TreeRBXS_item *b);
static TreeRBXS_cmp_fn TreeRBXS_cmp_int;
static TreeRBXS_cmp_fn TreeRBXS_cmp_float;
static TreeRBXS_cmp_fn TreeRBXS_cmp_memcmp;
//static TreeRBXS_cmp_fn TreeRBXS_cmp_utf8;
static TreeRBXS_cmp_fn TreeRBXS_cmp_numsplit;
static TreeRBXS_cmp_fn TreeRBXS_cmp_perl;
static TreeRBXS_cmp_fn TreeRBXS_cmp_perl_cb;

typedef SV* TreeRBXS_xform_fn(struct TreeRBXS *tree, SV *orig_key);
static TreeRBXS_xform_fn TreeRBXS_xform_fc;

/* These get serialized as bytes for Storable, so should not change,
 * or else STORABLE_thaw needs adapted.
 */
#define CMP_PERL        1
#define CMP_INT         2
#define CMP_FLOAT       3
#define CMP_MEMCMP      4
#define CMP_STR         5
#define CMP_SUB         6
#define CMP_NUMSPLIT    7
#define CMP_FOLDCASE    8
#define CMP_NUMSPLIT_FOLDCASE 9
#define CMP_MAX         9

static int parse_cmp_fn(SV *cmp_sv) {
	int cmp_id= -1;
	if (SvROK(cmp_sv) && SvTYPE(SvRV(cmp_sv)) == SVt_PVCV)
		cmp_id= CMP_SUB;
	else if (SvIOK(cmp_sv)) {
		IV i= SvIV(cmp_sv);
		cmp_id= (i < 1 || i > CMP_MAX || i == CMP_SUB)? -1 : (int) i;
	}
	else if (SvPOK(cmp_sv)) {
		STRLEN len;
		const char *str= SvPV(cmp_sv, len);
		if (len > 4 && foldEQ(str, "CMP_", 4)) {
			str += 4;
			len -= 4;
		}
		cmp_id= (len == 3 && foldEQ(str, "INT",          3))? CMP_INT
		      : (len == 3 && foldEQ(str, "STR",          3))? CMP_STR
		      : (len == 4 && foldEQ(str, "UTF8",         4))? CMP_STR // back-compat name
		      : (len == 4 && foldEQ(str, "PERL",         4))? CMP_PERL
		      : (len == 5 && foldEQ(str, "FLOAT",        5))? CMP_FLOAT
		      : (len == 6 && foldEQ(str, "MEMCMP",       6))? CMP_MEMCMP
		      : (len == 8 && foldEQ(str, "FOLDCASE",     8))? CMP_FOLDCASE
		      : (len == 8 && foldEQ(str, "NUMSPLIT",     8))? CMP_NUMSPLIT
		      : (len ==17 && foldEQ(str, "NUMSPLIT_FOLDCASE", 17))? CMP_NUMSPLIT_FOLDCASE
		    //: (len == 7 && foldEQ(str, "SUB",    3))? CMP_SUB   can only be requested by a CV*
		      : -1;
	}
	return cmp_id;
}

static const char * get_cmp_name(int cmp_id) {
	switch (cmp_id) {
	case CMP_PERL:   return "CMP_PERL";
	case CMP_INT:    return "CMP_INT";
	case CMP_FLOAT:  return "CMP_FLOAT";
	case CMP_STR:    return "CMP_STR";
	case CMP_SUB:    return "CMP_SUB";
	case CMP_MEMCMP: return "CMP_MEMCMP";
	case CMP_NUMSPLIT:    return "CMP_NUMSPLIT";
	case CMP_FOLDCASE:     return "CMP_FOLDCASE";
	case CMP_NUMSPLIT_FOLDCASE: return "CMP_NUMSPLIT_FOLDCASE";
	default: return NULL;
	}
}

#define GET_EQ   0
#define GET_GE   1
#define GET_LE   2
#define GET_GT   3
#define GET_LT   4
#define GET_NEXT 5
#define GET_PREV 6
#define GET_EQ_LAST 7
#define GET_LE_LAST 8
#define GET_OR_ADD 9
#define GET_MAX  9

static int parse_lookup_mode(SV *mode_sv) {
	int mode= -1;
	if (SvIOK(mode_sv)) {
		IV i= SvIV(mode_sv);
		mode= (i < 0 || i > GET_MAX)? -1 : (int) i;
	} else if (SvPOK(mode_sv)) {
		STRLEN len;
		char* mode_str= SvPV(mode_sv, len);
		if (len > 4 && foldEQ(mode_str, "GET_", 4)) {
			mode_str+= 4;
			len -= 4;
		}
		// Allow alternate syntax of "==" etc, 'eq' etc, or any of the official constant names
		switch (mode_str[0]) {
		case '<': mode= len == 1? GET_LT : len == 2 && mode_str[1] == '='? GET_LE : -1; break;
		case '>': mode= len == 1? GET_GT : len == 2 && mode_str[1] == '='? GET_GE : -1; break;
		case '=': mode= len == 2 && mode_str[1] == '='? GET_EQ : -1; break;
		case '-': mode= len == 2 && mode_str[1] == '-'? GET_PREV : -1; break;
		case '+': mode= len == 2 && mode_str[1] == '+'? GET_NEXT : -1; break;
		case 'E': case 'e':
		          mode= len == 2 && (mode_str[1] == 'q' || mode_str[1] == 'Q')? GET_EQ
		              : len == 7 && foldEQ(mode_str, "EQ_LAST", 7)? GET_EQ_LAST
		              : -1;
		          break;
		case 'G': case 'g':
		          mode= len == 2 && (mode_str[1] == 't' || mode_str[1] == 'T')? GET_GT
                      : len == 2 && (mode_str[1] == 'e' || mode_str[1] == 'E')? GET_GE
		              : -1;
		          break;
		case 'L': case 'l':
		          mode= len == 2 && (mode_str[1] == 't' || mode_str[1] == 'T')? GET_LT
                      : len == 2 && (mode_str[1] == 'e' || mode_str[1] == 'E')? GET_LE
		              : len == 7 && foldEQ(mode_str, "LE_LAST", 7)? GET_LE_LAST
		              : -1;
		          break;
		case 'P': case 'p': mode= foldEQ(mode_str, "PREV", 4)? GET_PREV : -1; break;
		case 'N': case 'n': mode= foldEQ(mode_str, "NEXT", 4)? GET_NEXT : -1; break;
		case 'o': case 'O': mode= foldEQ(mode_str, "OR_ADD", 6)? GET_OR_ADD : -1; break;
		}
	}
	return mode;
}

static SV* make_aligned_buffer(SV *sv, size_t size, int align) {
	char *p;
	STRLEN len;

	if (!sv)
		sv= newSVpvn("", 0);
	else if (!SvPOK(sv))
		sv_setpvs(sv, "");
	p= SvPV_force(sv, len);
	if (len < size || ((intptr_t)p) & (align-1)) {
		SvGROW(sv, size+align-1);
		SvCUR_set(sv, size);
		p= SvPVX(sv);
		if ((intptr_t)p & (align-1)) {
			sv_chop(sv, p + align - ((intptr_t)p & (align-1)));
			SvCUR_set(sv, size);
		}
	}
	return sv;
}

struct dllist_node {
	struct dllist_node *prev, *next;
};

#define INSERT_TREND_TRIGGER 3
#define INSERT_TREND_CAP 5

// Struct attached to each instance of Tree::RB::XS
struct TreeRBXS {
	SV *owner;                     // points to Tree::RB::XS internal HV (not ref)
	TreeRBXS_cmp_fn *compare;      // internal compare function.  Always set and never changed.
	TreeRBXS_xform_fn *transform;  // internal key-transformation function, applied before key comparisons.
	SV *compare_callback;          // user-supplied compare.  May be NULL, but can never be changed.
	int key_type;                  // must always be set and never changed
	int compare_fn_id;             // indicates which compare is in use, for debugging
	bool allow_duplicates;         // flag to affect behavior of insert.  may be changed.
	bool allowed_duplicates;       // was a duplicate ever inserted?  helps optimize put()
	bool compat_list_get;          // flag to enable full compat with Tree::RB's list context behavior
	bool track_recent;             // flag to automatically add new nodes to the recent-list
	bool lookup_updates_recent;    // whether 'lookup' and 'get' move a node to the front of the recent-list
	rbtree_node_t root_sentinel;   // parent-of-root, used by rbtree implementation.
	rbtree_node_t leaf_sentinel;   // dummy node used by rbtree implementation.
	struct TreeRBXS_iter *hashiter;// iterator used for TIEHASH
	struct dllist_node recent;     // insertion order tracking
	size_t recent_count;           // number of nodes being LRU-tracked
	bool hashiterset;              // true if the hashiter has been set manually with hseek
	struct TreeRBXS_item
	    *prev_inserted_item;       // optimize adjacent inserts by tracking previous insert
	int  prev_inserted_trend;      // number of consecutive adjacent inserts
	bool prev_inserted_dup;        // whether previous insert was an allow_duplicate case
};

static void TreeRBXS_init(struct TreeRBXS *tree, SV *owner);
static void TreeRBXS_clear(struct TreeRBXS *tree);
static void TreeRBXS_assert_structure(struct TreeRBXS *tree);
struct TreeRBXS_iter * TreeRBXS_get_hashiter(struct TreeRBXS *tree);
static struct TreeRBXS_item *TreeRBXS_find_item(struct TreeRBXS *tree, struct TreeRBXS_item *key, int mode);
static bool TreeRBXS_is_member(struct TreeRBXS *tree, struct TreeRBXS_item *item);
static void TreeRBXS_recent_insert_before(struct TreeRBXS *tree, struct TreeRBXS_item *item, struct dllist_node *node_after);
static void TreeRBXS_recent_prune(struct TreeRBXS *tree, struct TreeRBXS_item *item);
static void TreeRBXS_destroy(struct TreeRBXS *tree);

#define TreeRBXS_get_root(tree) ((tree)->root_sentinel.left)
#define TreeRBXS_get_count(tree) ((tree)->root_sentinel.left->count)

#define OFS_TreeRBXS_FIELD_root_sentinel ( ((char*) &(((struct TreeRBXS*)(void*)10000)->root_sentinel)) - ((char*)10000) )
#define GET_TreeRBXS_FROM_root_sentinel(node) ((struct TreeRBXS*) (((char*)node) - OFS_TreeRBXS_FIELD_root_sentinel))

#define OFS_TreeRBXS_item_FIELD_rbnode ( ((char*) &(((struct TreeRBXS_item *)(void*)10000)->rbnode)) - ((char*)10000) )
#define GET_TreeRBXS_item_FROM_rbnode(node) ((struct TreeRBXS_item*) (((char*)node) - OFS_TreeRBXS_item_FIELD_rbnode))

#define OFS_TreeRBXS_item_FIELD_recent ( ((char*) &(((struct TreeRBXS_item *)(void*)10000)->recent)) - ((char*)10000) )
#define GET_TreeRBXS_item_FROM_recent(node) ((struct TreeRBXS_item*) (((char*)node) - OFS_TreeRBXS_item_FIELD_recent))

// Struct attached to each instance of Tree::RB::XS::Node
// I named it 'item' instead of 'node' to prevent confusion with the actual
// rbtree_node_t used by the underlying library.
struct TreeRBXS_item {
	rbtree_node_t rbnode; // actual red/black left/right/color/parent/count fields
	SV *owner;            // points to Tree::RB::XS::Node internal SV (not ref), or NULL if not wrapped
	union itemkey_u {     // key variations are overlapped to save space
		IV ikey;
		NV nkey;
		const char *ckey;
		SV *svkey;
	} keyunion;
	struct TreeRBXS_iter *iter; // linked list of iterators who reference this item
	struct dllist_node recent;  // doubly linked list of insertion order tracking
	SV *value;            // value will be set unless struct is just used as a search key
	size_t key_type: 3,
	       orig_key_stored: 1,
#if SIZE_MAX == 0xFFFFFFFF
#define CKEYLEN_MAX ((((size_t)1)<<28)-1)
	       ckeylen: 28;
#else
#define CKEYLEN_MAX ((((size_t)1)<<60)-1)
	       ckeylen: 60;
#endif
	char extra[];
};

static SV* GET_TreeRBXS_item_ORIG_KEY(struct TreeRBXS_item *item) {
	SV *k= NULL;
	if (item->orig_key_stored)
		memcpy(&k, item->extra, sizeof(SV*));
	return k;
}
#define SET_TreeRBXS_item_ORIG_KEY(item, key) memcpy(item->extra, &key, sizeof(SV*))
#define GET_TreeRBXS_stack_item_ORIG_KEY(item) ((item)->owner)
#define SET_TreeRBXS_stack_item_ORIG_KEY(item, key) ((item)->owner= (key))

static void TreeRBXS_init_tmp_item(struct TreeRBXS_item *item, struct TreeRBXS *tree, SV *key, SV *value);
static struct TreeRBXS_item * TreeRBXS_new_item_from_tmp_item(struct TreeRBXS_item *src);
static struct TreeRBXS* TreeRBXS_item_get_tree(struct TreeRBXS_item *item);
static void TreeRBXS_item_advance_all_iters(struct TreeRBXS_item* item, int flags);
static void TreeRBXS_item_detach_iter(struct TreeRBXS_item *item, struct TreeRBXS_iter *iter);
static void TreeRBXS_item_detach_owner(struct TreeRBXS_item* item);
static void TreeRBXS_item_detach_tree(struct TreeRBXS_item* item, struct TreeRBXS *tree);
static void TreeRBXS_item_clear(struct TreeRBXS_item* item, struct TreeRBXS *tree);
static void TreeRBXS_item_free(struct TreeRBXS_item *item);

struct TreeRBXS_iter {
	struct TreeRBXS *tree;
	SV *owner;
	struct TreeRBXS_iter *next_iter;
	struct TreeRBXS_item *item;
	int reverse: 1, recent: 1;
};

static void TreeRBXS_iter_rewind(struct TreeRBXS_iter *iter);
static void TreeRBXS_iter_set_item(struct TreeRBXS_iter *iter, struct TreeRBXS_item *item);
static void TreeRBXS_iter_advance(struct TreeRBXS_iter *iter, IV ofs);
static void TreeRBXS_iter_free(struct TreeRBXS_iter *iter);

static void TreeRBXS_init(struct TreeRBXS *tree, SV *owner) {
	memset(tree, 0, sizeof(struct TreeRBXS));
	tree->owner= owner;
	rbtree_init_tree(&tree->root_sentinel, &tree->leaf_sentinel);
	tree->recent.next= &tree->recent;
	tree->recent.prev= &tree->recent;
	/* defaults, which can be overridden by _init_tree */
	tree->key_type= KEY_TYPE_ANY;
	tree->compare_fn_id= CMP_PERL;
}

static void TreeRBXS_clear(struct TreeRBXS *tree) {
	tree->prev_inserted_item= NULL;
	tree->prev_inserted_trend= 0;
	tree->prev_inserted_dup= false;
	tree->allowed_duplicates= false;
	rbtree_clear(&tree->root_sentinel, (void (*)(void *, void *)) &TreeRBXS_item_clear,
		-OFS_TreeRBXS_item_FIELD_rbnode, tree);
	tree->recent.prev= &tree->recent;
	tree->recent.next= &tree->recent;
	tree->recent_count= 0;
}

static void TreeRBXS_assert_structure(struct TreeRBXS *tree) {
	int err;
	rbtree_node_t *node;
	struct TreeRBXS_item *item;
	struct TreeRBXS_iter *iter;

	if (!tree) croak("tree is NULL");
	if (!tree->owner) croak("no owner");
	if (tree->key_type < 0 || tree->key_type > KEY_TYPE_MAX) croak("bad key_type");
	if (!tree->compare) croak("no compare function");
	if ((err= rbtree_check_structure(&tree->root_sentinel, (int(*)(void*,void*,void*)) tree->compare, tree, -OFS_TreeRBXS_item_FIELD_rbnode)))
		croak("tree structure damaged: %d", err);
	if (TreeRBXS_get_count(tree)) {
		node= rbtree_node_left_leaf(tree->root_sentinel.left);
		while (node) {
			item= GET_TreeRBXS_item_FROM_rbnode(node);
			if (item->key_type != tree->key_type)
				croak("node key_type doesn't match tree");
			if (!item->value)
				croak("node value SV lost");
			if (item->iter) {
				iter= item->iter;
				while (iter) {
					if (!iter->owner) croak("Iterator lacks owner reference");
					if (iter->item != item) croak("Iterator referenced by wrong item");
					iter= iter->next_iter;
				}
			}
			node= rbtree_node_next(node);
		}
	}
	if (!tree->recent_count) {
		if (tree->recent.prev != &tree->recent || tree->recent.next != &tree->recent)
			croak("recent_count = 0, but list contains nodes");
	} else {
		if (tree->recent.prev == &tree->recent || tree->recent.next == &tree->recent)
			croak("recent_count > 0, but list is empty");
	}
	//warn("Tree is healthy");
}

struct TreeRBXS_iter * TreeRBXS_get_hashiter(struct TreeRBXS *tree) {
	// This iterator is owned by the tree.  All other iterators would hold a reference to the tree.
	if (!tree->hashiter) {
		Newxz(tree->hashiter, 1, struct TreeRBXS_iter);
		tree->hashiter->tree= tree;
	}
	return tree->hashiter;
}

/* For insert/put, there needs to be a node created before it can be
 * inserted.  But if the insert fails, the item needs cleaned up.
 * This initializes a temporary incomplete item on the stack that can be
 * used for searching without the expense of allocating buffers etc.
 * The temporary item does not require any destructor/cleanup.
 * (and, the destructor *must not* be called on the stack item)
 */
static void TreeRBXS_init_tmp_item(struct TreeRBXS_item *item, struct TreeRBXS *tree, SV *key, SV *value) {
	STRLEN len= 0;

	// all fields should start NULL just to be safe
	memset(item, 0, sizeof(*item));
	// copy key type from tree
	item->key_type= tree->key_type;
	// If there's a transform function, apply that first
	if (tree->transform) {
		SET_TreeRBXS_stack_item_ORIG_KEY(item, key); // temporary storage for original key
		item->orig_key_stored= 1;
		key= tree->transform(tree, key); // returns a mortal SV
	}
	else item->orig_key_stored= 0;

	// set up the keys.  
	item->ckeylen= 0;
	switch (item->key_type) {
	case KEY_TYPE_ANY:
	case KEY_TYPE_CLAIM: item->keyunion.svkey= key; break;
	case KEY_TYPE_INT:   item->keyunion.ikey= SvIV(key); break;
	case KEY_TYPE_FLOAT: item->keyunion.nkey= SvNV(key); break;
	// STR and BSTR assume that the 'key' SV has a longer lifespan than the use of the tmp item,
	// and directly reference the PV pointer.  The insert and search algorithms should not be
	// calling into Perl for their entire execution.
	case KEY_TYPE_USTR:
		item->keyunion.ckey= SvPVutf8(key, len);
		if (0)
	case KEY_TYPE_BSTR:
			item->keyunion.ckey= SvPVbyte(key, len);
		// the ckeylen is a bit field, so can't go the full range of int
		if (len > CKEYLEN_MAX)
			croak("String length %ld exceeds maximum %ld for optimized key_type", (long)len, (long)CKEYLEN_MAX);
		item->ckeylen= len;
		break;
	default:
		croak("BUG: un-handled key_type");
	}
	item->value= value;
}

/* When insert has decided that the temporary node is permitted to be inserted,
 * this function allocates a real item struct with its own reference counts
 * and buffer data, etc.
 */
static struct TreeRBXS_item * TreeRBXS_new_item_from_tmp_item(struct TreeRBXS_item *src) {
	struct TreeRBXS_item *dst;
	bool is_buffered_key= src->key_type == KEY_TYPE_USTR || src->key_type == KEY_TYPE_BSTR;
	/* If the item references a string that is not managed by a SV,
	   copy that into the space at the end of the allocated block.
	   Also, if 'owner' is set, it is holding the original SV key
	   which the stack item was initialized from, and also means that
	   a transform function is in effect.
	   The node needs to hold onto the original key, which gets stored
	   at the end of the buffer area */
	if (src->orig_key_stored || is_buffered_key) {
		size_t keyptr_len, strbuf_len;
		strbuf_len= is_buffered_key? src->ckeylen+1 : 0;
		keyptr_len= src->orig_key_stored? sizeof(SV*) : 0;
		Newxc(dst, sizeof(struct TreeRBXS_item) + keyptr_len + strbuf_len, char, struct TreeRBXS_item);
		memset(dst, 0, sizeof(struct TreeRBXS_item));
		if (keyptr_len) {
			// make a copy of the SV, unless requested to take ownership of keys
			SV *kept= GET_TreeRBXS_stack_item_ORIG_KEY(src);
			kept= src->key_type == KEY_TYPE_CLAIM? SvREFCNT_inc(kept) : newSVsv(kept);
			SvREADONLY_on(kept);
			// I don't want to bother aligning this since it's seldomly accessed anyway.
			SET_TreeRBXS_item_ORIG_KEY(dst, kept);
		}
		if (is_buffered_key) {
			char *dst_buf= dst->extra + keyptr_len;
			memcpy(dst_buf, src->keyunion.ckey, src->ckeylen);
			dst_buf[src->ckeylen]= '\0';
			dst->keyunion.ckey= dst_buf;
			dst->ckeylen= src->ckeylen;
		}
		else {
			switch (src->key_type) {
			// when the key has been transformed, it is a mortal pointer and waiting to be claimed
			// so TYPE_ANY and TYPE_CLAIM do the same thing here.
			case KEY_TYPE_ANY:
			case KEY_TYPE_CLAIM:
				dst->keyunion.svkey= src->keyunion.svkey;
				SvREADONLY_on(dst->keyunion.svkey);
				break;
			case KEY_TYPE_INT:   dst->keyunion.ikey=  src->keyunion.ikey; break;
			case KEY_TYPE_FLOAT: dst->keyunion.nkey=  src->keyunion.nkey; break;
			default:
				croak("BUG: un-handled key_type %d", src->key_type);
			}
		}
	}
	else {
		Newxz(dst, 1, struct TreeRBXS_item);
		switch (src->key_type) {
		case KEY_TYPE_ANY:   dst->keyunion.svkey= newSVsv(src->keyunion.svkey);
			if (0)
		case KEY_TYPE_CLAIM: dst->keyunion.svkey= SvREFCNT_inc(src->keyunion.svkey);
			SvREADONLY_on(dst->keyunion.svkey);
			break;
		case KEY_TYPE_INT:   dst->keyunion.ikey=  src->keyunion.ikey; break;
		case KEY_TYPE_FLOAT: dst->keyunion.nkey=  src->keyunion.nkey; break;
		default:
			croak("BUG: un-handled key_type %d", src->key_type);
		}
	}
	dst->orig_key_stored= src->orig_key_stored;
	dst->key_type= src->key_type;
	dst->value= newSVsv(src->value);
	return dst;
}

/* Get the tree pointer for an item, or NULL if the item is no longer in a tree.
 * This is an O(log(N)) operation.  It could be made constant, but then the node
 * would be 8 bytes bigger...
 */
static struct TreeRBXS* TreeRBXS_item_get_tree(struct TreeRBXS_item *item) {
	rbtree_node_t *node= rbtree_node_rootsentinel(&item->rbnode);
	return node? GET_TreeRBXS_FROM_root_sentinel(node) : NULL;
}

static bool TreeRBXS_is_member(struct TreeRBXS *tree, struct TreeRBXS_item *item) {
	rbtree_node_t *node= &item->rbnode;
	while (node && node->parent)
		node= node->parent;
	return node == &tree->root_sentinel;
}

static void TreeRBXS_item_free(struct TreeRBXS_item *item) {
	//warn("TreeRBXS_item_free");
	switch (item->key_type) {
	case KEY_TYPE_ANY:
	case KEY_TYPE_CLAIM: SvREFCNT_dec(item->keyunion.svkey); break;
	}
	if (item->orig_key_stored) {
		SV *tmp= GET_TreeRBXS_item_ORIG_KEY(item);
		SvREFCNT_dec(tmp);
	}
	if (item->value)
		SvREFCNT_dec(item->value);
	Safefree(item);
}

/* Detach the C-struct TreeRBXS_item from the Perl object wrapping it (owner).
 * If the item was no longer referenced by the tree, either, this deletes the item.
 */
static void TreeRBXS_item_detach_owner(struct TreeRBXS_item* item) {
	//warn("TreeRBXS_item_detach_owner");
	/* the MAGIC of owner doens't need changed because the only time this gets called
	   is when something else is taking care of that. */
	//if (item->owner != NULL) {
	//	TreeRBXS_set_magic_item(item->owner, NULL);
	//}
	item->owner= NULL;
	/* The tree is the other 'owner' of the node.  If the item is not in the tree,
	   then this was the last reference, and it needs freed. */
	if (!rbtree_node_is_in_tree(&item->rbnode))
		TreeRBXS_item_free(item);
}

/* Simple linked-list deletion of an iterator from the list pointing to this item.
 */
static void TreeRBXS_item_detach_iter(struct TreeRBXS_item *item, struct TreeRBXS_iter *iter) {
	struct TreeRBXS_iter **cur;

	// Linked-list remove
	for (cur= &item->iter; *cur; cur= &((*cur)->next_iter)) {
		if (*cur == iter) {
			*cur= iter->next_iter;
			iter->next_iter= NULL;
			iter->item= NULL;
			return;
		}
	}
	croak("BUG: iterator not found in item's linked list");
}

/* Reset an iterator to a fresh iteration of whatever direction it was configured to iterate.
 */
static void TreeRBXS_iter_rewind(struct TreeRBXS_iter *iter) {
	struct TreeRBXS *tree= iter->tree;
	struct TreeRBXS_item *item;
	rbtree_node_t *root;
	struct dllist_node *lnode;
	if (iter->recent) {
		lnode= iter->reverse? tree->recent.prev : tree->recent.next;
		item= (lnode == &tree->recent)? NULL : GET_TreeRBXS_item_FROM_recent(lnode);
	}
	else {
		root= TreeRBXS_get_root(tree);
		rbtree_node_t *node= iter->reverse
			? rbtree_node_right_leaf(root)
			: rbtree_node_left_leaf(root);
		item= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	}
	TreeRBXS_iter_set_item(iter, item);
}

/* Point an iterator at a new item, or NULL.
 */
static void TreeRBXS_iter_set_item(struct TreeRBXS_iter *iter, struct TreeRBXS_item *item) {
	if (iter->item == item)
		return;

	if (iter->item)
		TreeRBXS_item_detach_iter(iter->item, iter);

	if (item) {
		// If this is a 'recent' iterator, it must be attached to a recent-tracked item
		if (iter->recent && !item->recent.next)
			croak("BUG: Attempt to bind recent-iterator to non-recent-tracked item");
		iter->item= item;
		// linked-list insert
		iter->next_iter= item->iter;
		item->iter= iter;
	}
}

/* Advance an iterator by a number of steps (ofs) in the configured direction of
 * travel for that iterator.  i.e. negative ofs on a reverse iterator iterates forward.
 */
static void TreeRBXS_iter_advance(struct TreeRBXS_iter *iter, IV ofs) {
	rbtree_node_t *node;
	struct TreeRBXS_item *item= iter->item;
	struct dllist_node *cur, *end;

	if (!iter->tree)
		croak("BUG: iterator lost tree");
	// Special logic for when iterating insertion order
	if (iter->recent) {
		end= &iter->tree->recent;
		// Stepping backward from end of iteration?
		if (ofs < 0 && !item) {
			cur= iter->reverse? iter->tree->recent.prev : iter->tree->recent.next;
			++ofs;
		} else 
			cur= &item->recent;
		// after here, ofs is the direction of travel
		if (iter->reverse)
			ofs= -ofs;
		if (ofs > 0) {
			while (ofs-- > 0 && cur && cur != end)
				cur= cur->next;
		} else if (ofs < 0) {
			while (ofs++ < 0 && cur && cur != end)
				cur= cur->prev;
		}
		item= cur && cur != end? GET_TreeRBXS_item_FROM_recent(cur) : NULL;
		TreeRBXS_iter_set_item(iter, item);
	}
	// Most common case
	else if (ofs == 1) {
		// nothing to do at end of iteration
		if (item) {
			node= &item->rbnode;
			node= iter->reverse? rbtree_node_prev(node) : rbtree_node_next(node);
			TreeRBXS_iter_set_item(iter, node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL);
		}
	}
	else {
		size_t pos, newpos, cnt;
		// More advanced case falls back to by-index, since the log(n) of indexes is likely
		// about the same as a few hops forward or backward, and because reversing from EOF
		// means there isn't a current node to step from anyway.
		cnt= TreeRBXS_get_count(iter->tree);
		// rbtree measures index in size_t, but this function applies a signed offset to it
		// of possibly a different word length.  Also, clamp overflows to the ends of the
		// range of nodes and don't wrap.
		pos= !item? cnt
			: !iter->reverse? rbtree_node_index(&item->rbnode)
			// For reverse iterators, swap the scale so that math goes upward
			: cnt - 1 - rbtree_node_index(&item->rbnode);
		if (ofs > 0) {
			newpos= (UV)ofs < (cnt-pos)? pos + ofs : cnt;
		} else {
			size_t o= (size_t) -ofs;
			newpos= (pos < o)? 0 : pos - o;
		}
		// swap back for reverse iterators
		if (iter->reverse) newpos= cnt - 1 - newpos;
		node= rbtree_node_child_at_index(TreeRBXS_get_root(iter->tree), (size_t)newpos);
		TreeRBXS_iter_set_item(iter, node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL);
	}
}

/* Advance all iterators for a given item one step in their respective directions of travel.
 *
 * This is an optimized version of calling _iter_advance(item,1) on each iterator of an item.
 * This has O(log(N) + IterCount) complexity instead of O(log(N) * IterCount),
 * which could matter for the case where deleting many nodes has resulted in many iterators
 * piled up on the same node.
 */
#define ONLY_ADVANCE_RECENT 1
static void TreeRBXS_item_advance_all_iters(struct TreeRBXS_item* item, int flags) {
	rbtree_node_t *node;
	struct dllist_node *lnode;
	struct TreeRBXS_item *next_item= NULL, *prev_item= NULL,
		*next_recent= NULL, *prev_recent= NULL;
	struct TreeRBXS_iter *iter, *next;
	
	// Dissolve a linked list to move the iters to the previous or next item's linked list
	for (iter= item->iter, item->iter= NULL; iter; iter= next) {
		next= iter->next_iter;
		if (iter->recent) { // iterating insertion order?
			if (iter->reverse) { // newest to oldest?
				if (!prev_recent) {
					lnode= item->recent.prev;
					if (lnode == NULL || lnode == &iter->tree->recent) {
						iter->item= NULL;
						iter->next_iter= NULL;
						continue;
					}
					prev_recent= GET_TreeRBXS_item_FROM_recent(lnode);
				}
				iter->item= prev_recent;
				// linked list add head node
				iter->next_iter= prev_recent->iter;
				prev_recent->iter= iter;
			}
			else { // oldest to newest
				if (!next_recent) {
					lnode= item->recent.next;
					if (lnode == NULL || lnode == &iter->tree->recent) {
						iter->item= NULL;
						iter->next_iter= NULL;
						continue;
					}
					next_recent= GET_TreeRBXS_item_FROM_recent(lnode);
				}
				iter->item= next_recent;
				iter->next_iter= next_recent->iter;
				next_recent->iter= iter;
			}
		}
		else if (flags & ONLY_ADVANCE_RECENT) {
			// only advancing recent-list iterators, so key-order iterator needs to stay at this item.
			iter->next_iter= item->iter;
			item->iter= iter;
		}
		else { // iterating key order
			if (iter->reverse) { // iterating high to low
				if (!prev_item) {
					node= rbtree_node_prev(&item->rbnode);
					if (!node) {
						// end of iteration
						iter->item= NULL;
						iter->next_iter= NULL;
						continue;
					}
					prev_item= GET_TreeRBXS_item_FROM_rbnode(node);
				}
				iter->item= prev_item;
				// linked list add head node
				iter->next_iter= prev_item->iter;
				prev_item->iter= iter;
			}
			else { // iterating low to high
				if (!next_item) {
					node= rbtree_node_next(&item->rbnode);
					if (!node) {
						// end of iteration
						iter->item= NULL;
						iter->next_iter= NULL;
						continue;
					}
					next_item= GET_TreeRBXS_item_FROM_rbnode(node);
				}
				iter->item= next_item;
				// linked list add head node
				iter->next_iter= next_item->iter;
				next_item->iter= iter;
			}
		}
	}
}

/* Disconnect an item from the tree, gracefully
 */
static void TreeRBXS_item_detach_tree(struct TreeRBXS_item* item, struct TreeRBXS *tree) {
	//warn("TreeRBXS_item_detach_tree");
	//warn("detach tree %p %p key %d", item, tree, (int) item->keyunion.ikey);
	if (rbtree_node_is_in_tree(&item->rbnode)) {
		if (tree->prev_inserted_item == item) {
			tree->prev_inserted_item= NULL;
			tree->prev_inserted_trend= 0;
		}
		// If any iterator points to this node, move it to the following node.
		if (item->iter)
			TreeRBXS_item_advance_all_iters(item, 0);
		// If the node was part of LRU cache, cancel that
		if (item->recent.next)
			TreeRBXS_recent_prune(tree, item);
		rbtree_node_prune(&item->rbnode);
	}
	/* The item could be owned by a tree or by a Node/Iterator, or both.
	   If the tree releases the reference, the Node/Iterator will be the owner.
	   Else the tree was the only owner, and the node needs freed */
	if (!item->owner)
		TreeRBXS_item_free(item);
}

/* Callback when clearing the entire tree.
 * This is like _detach_tree, but doesn't need to clean up relation to other nodes.
 */
static void TreeRBXS_item_clear(struct TreeRBXS_item* item, struct TreeRBXS *tree) {
	struct TreeRBXS_iter *iter= item->iter, *next;
	// Detach all iterators from this node.
	while (iter) {
		next= iter->next_iter;
		iter->item= NULL;
		iter->next_iter= NULL;
		iter= next;
	}
	item->iter= NULL;
	item->recent.next= NULL;
	item->recent.prev= NULL;
	if (rbtree_node_is_in_tree(&item->rbnode))
		memset(&item->rbnode, 0, sizeof(item->rbnode));
	// If the item is still referenced by the perl Node object, don't delete it.
	if (!item->owner)
		TreeRBXS_item_free(item);
}

static void TreeRBXS_iter_free(struct TreeRBXS_iter *iter) {
	if (iter->item)
		TreeRBXS_item_detach_iter(iter->item, iter);
	if (iter->tree) {
		if (iter->tree->hashiter == iter)
			iter->tree->hashiter= NULL;
		else
			SvREFCNT_dec(iter->tree->owner);
	}
	Safefree(iter);
}

static void TreeRBXS_destroy(struct TreeRBXS *tree) {
	//warn("TreeRBXS_destroy");
	rbtree_clear(&tree->root_sentinel, (void (*)(void *, void *)) &TreeRBXS_item_clear, -OFS_TreeRBXS_item_FIELD_rbnode, tree);
	if (tree->compare_callback)
		SvREFCNT_dec(tree->compare_callback);
	if (tree->hashiter)
		TreeRBXS_iter_free(tree->hashiter);
}

// This gets used in two places, but I don't want to make it a function.
#define TREERBXS_INSERT_ITEM_AT_NODE(tree, item, parent_node, direction) \
	do { \
		if (!(parent_node)) /* empty tree */ \
			rbtree_node_insert_before(&(tree)->root_sentinel, &(item)->rbnode); \
		else if ((direction) > 0) \
			rbtree_node_insert_after((parent_node), &(item)->rbnode); \
		else \
			rbtree_node_insert_before((parent_node), &(item)->rbnode); \
		if ((tree)->track_recent) \
			TreeRBXS_recent_insert_before((tree), (item), &(tree)->recent); \
	} while (0)

static struct TreeRBXS_item *TreeRBXS_find_item(struct TreeRBXS *tree, struct TreeRBXS_item *stack_item, int mode) {
	struct TreeRBXS_item *item;
	rbtree_node_t *node= NULL;
	int cmp;
	bool step= false;

	// Need to ensure we find the *first* matching node for a key,
	// to deal with the case of duplicate keys.
	node= rbtree_find_nearest(
		&tree->root_sentinel,
		stack_item, // The item *is* the key that gets passed to the compare function
		(int(*)(void*,void*,void*)) tree->compare,
		tree, -OFS_TreeRBXS_item_FIELD_rbnode,
		&cmp);
	if (node && cmp == 0) {
		// Found an exact match.  First and last are the range of nodes matching.
		switch (mode) {
		case GET_LT:
		case GET_PREV:
			step= true;
		case GET_EQ:
		case GET_OR_ADD:
		case GET_GE:
		case GET_LE:
			// make sure it is the first of nodes with same key
			if (tree->allowed_duplicates)
				node= rbtree_find_leftmost_samekey(node, (int(*)(void*,void*,void*)) tree->compare,
					tree, -OFS_TreeRBXS_item_FIELD_rbnode);
			if (step)
				node= rbtree_node_prev(node);
			break;
		case GET_GT:
		case GET_NEXT:
			step= true;
		case GET_EQ_LAST:
		case GET_LE_LAST:
			// make sure it is the last of nodes with same key
			if (tree->allowed_duplicates)
				node= rbtree_find_rightmost_samekey(node, (int(*)(void*,void*,void*)) tree->compare,
					tree, -OFS_TreeRBXS_item_FIELD_rbnode);
			if (step)
				node= rbtree_node_next(node);
			break;
		default: croak("BUG: unhandled mode");
		}
	} else {
		// Didn't find an exact match.  First and last are the bounds of what would have matched.
		switch (mode) {
		case GET_EQ:
		case GET_EQ_LAST:
		case GET_PREV:
		case GET_NEXT:
			node= NULL; break;
		case GET_GE:
		case GET_GT:
			if (node && cmp > 0)
				node= rbtree_node_next(node);
			break;
		case GET_LE:
		case GET_LE_LAST:
		case GET_LT:
			if (node && cmp < 0)
				node= rbtree_node_prev(node);
			break;
		case GET_OR_ADD:
			item= TreeRBXS_new_item_from_tmp_item(stack_item);
			TREERBXS_INSERT_ITEM_AT_NODE(tree, item, node, cmp);
			return item;
		default: croak("BUG: unhandled mode");
		}
	}
	return node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
}

struct TreeRBXS_item *
TreeRBXS_insert_item(struct TreeRBXS *tree, struct TreeRBXS_item *stack_item, bool overwrite, SV **oldval_out) {
	struct TreeRBXS_item *item;
	rbtree_node_t *hint, *tmpnode, *first, *last;
	int cmp;
	/* If newly inserted items have been adjacent to prev_inserted_item 3 or more times in a row,
	   It is worth comparing them with that first.  This optimization results in nearly linear
	   insertion time when the keys are pre-sorted. */
	if (tree->prev_inserted_trend >= INSERT_TREND_TRIGGER) {
		if (tree->prev_inserted_trend > INSERT_TREND_CAP)
			tree->prev_inserted_trend= INSERT_TREND_CAP;
		hint= &tree->prev_inserted_item->rbnode;
		cmp= tree->compare(tree, stack_item, tree->prev_inserted_item);
		if (cmp == 0) {
			++tree->prev_inserted_trend;
			if (overwrite) {
				if (tree->prev_inserted_dup)
					goto overwrite_multi;
				else
					goto overwrite_single;
			} else if (tree->allow_duplicates)
				goto insert_new_duplicate;
			else
				return NULL;
		}
		else if (cmp > 0) {
			tmpnode= rbtree_node_next(hint);
			if (!tmpnode || tree->compare(tree, stack_item, GET_TreeRBXS_item_FROM_rbnode(tmpnode)) < 0) {
				++tree->prev_inserted_trend;
				goto insert_relative;
			}
			// else it broke the trend and needs inserted normally.
		}
		else {
			tmpnode= rbtree_node_prev(hint);
			if (!tmpnode || tree->compare(tree, stack_item, GET_TreeRBXS_item_FROM_rbnode(tmpnode)) > 0) {
				++tree->prev_inserted_trend;
				goto insert_relative;
			}
			// else it broke the trend and needs inserted normally.
		}
		--tree->prev_inserted_trend;
	}
	hint= rbtree_find_nearest(
		&tree->root_sentinel,
		stack_item, // The item *is* the key that gets passed to the compare function
		(int(*)(void*,void*,void*)) tree->compare,
		tree, -OFS_TreeRBXS_item_FIELD_rbnode,
		&cmp);
	if (hint && cmp == 0) {
		if (overwrite) {
			// In case of multiple matches, find all
			if (tree->allowed_duplicates) {
				overwrite_multi:
				if (!rbtree_find_all(
					hint, stack_item,
					(int(*)(void*,void*,void*)) tree->compare,
					tree, -OFS_TreeRBXS_item_FIELD_rbnode,
					&first, &last, NULL)
					)
					croak("BUG");
				//warn("replacing %d matching keys with new value", (int)count);
				// prune every node that follows 'first'
				while (last != first) {
					item= GET_TreeRBXS_item_FROM_rbnode(last);
					last= rbtree_node_prev(last);
					TreeRBXS_item_detach_tree(item, tree);
				}
				hint= first;
			}
			/* overwrite the value of the node */
			overwrite_single:
			item= GET_TreeRBXS_item_FROM_rbnode(hint);
			sv_2mortal(item->value);
			if (oldval_out)
				*oldval_out= item->value; // return the old value
			item->value= newSVsv(stack_item->value); // store new copy of supplied param
			/* If the tree is applying a transform to the items, the new key might not be identical
			   to the old, even though the transformed keys are equal.  (i.e. different case)
			   So, store the new key in its place. */
			if (item->orig_key_stored) {
				SV *orig_key= GET_TreeRBXS_item_ORIG_KEY(item);
				SV *new_key= GET_TreeRBXS_stack_item_ORIG_KEY(stack_item);
				if (sv_cmp(orig_key, new_key)) {
					SvREFCNT_dec(orig_key);
					orig_key= newSVsv(new_key);
					SvREADONLY_on(orig_key);
					SET_TreeRBXS_item_ORIG_KEY(item, orig_key);
				}
			}
			if (tree->track_recent || item->recent.next)
				TreeRBXS_recent_insert_before(tree, item, &tree->recent);
			tree->prev_inserted_dup= false;
		} else if (tree->allow_duplicates) {
			hint= rbtree_find_rightmost_samekey(hint, (int(*)(void*,void*,void*)) tree->compare,
				tree, -OFS_TreeRBXS_item_FIELD_rbnode);
			insert_new_duplicate:
			item= TreeRBXS_new_item_from_tmp_item(stack_item);
			rbtree_node_insert_after(hint, &item->rbnode);
			if (tree->track_recent)
				TreeRBXS_recent_insert_before(tree, item, &tree->recent);
			tree->allowed_duplicates= true;
			tree->prev_inserted_dup= true;
		} else {
			item= GET_TreeRBXS_item_FROM_rbnode(hint);
			if (item == tree->prev_inserted_item)
				++tree->prev_inserted_trend;
			return NULL; // nothing inserted
		}
	}
	else {
		insert_relative:
		item= TreeRBXS_new_item_from_tmp_item(stack_item);
		TREERBXS_INSERT_ITEM_AT_NODE(tree, item, hint, cmp);
		tree->prev_inserted_dup= false;
	}
	// If trend logic is triggered above, this is already calculated.  Else check adjacency.
	if (tree->prev_inserted_trend < INSERT_TREND_TRIGGER && tree->prev_inserted_item) {
		// Check trend.  Is item adjacent to 'prev'?
		if (item == tree->prev_inserted_item
			|| item->rbnode.parent == &tree->prev_inserted_item->rbnode
			|| item->rbnode.left   == &tree->prev_inserted_item->rbnode
			|| item->rbnode.right  == &tree->prev_inserted_item->rbnode
		) {
			++tree->prev_inserted_trend;
		} else if (tree->prev_inserted_trend)
			--tree->prev_inserted_trend;
	}
	tree->prev_inserted_item= item;
	return item;
}

/* Mark the current tree item as the most recent, regardless of whether it was previously tracked.
 */
static void TreeRBXS_recent_insert_before(struct TreeRBXS *tree, struct TreeRBXS_item *item, struct dllist_node *node_after) {
	struct dllist_node *node_before;
	// Not already before this node?
	if (item->recent.next != node_after) {
		if (item->recent.next) {
			// remove from linkedlist
			item->recent.prev->next= item->recent.next;
			item->recent.next->prev= item->recent.prev;
		} else
			++tree->recent_count;
		// Add following 'node_before'
		node_before= node_after->prev;
		node_after->prev= &item->recent;
		node_before->next= &item->recent;
		item->recent.prev= node_before;
		item->recent.next= node_after;
	}
}

/* Stop recent-tracking for the tree item.
 * Users can call this at any time in order to remove certain nodes from consideration.
 */
static void TreeRBXS_recent_prune(struct TreeRBXS *tree, struct TreeRBXS_item *item) {
	if (item->recent.next) {
		// Move recent-list iterators pointing to this node
		if (item->iter)
			TreeRBXS_item_advance_all_iters(item, ONLY_ADVANCE_RECENT);
		item->recent.prev->next= item->recent.next;
		item->recent.next->prev= item->recent.prev;
		item->recent.next= NULL;
		item->recent.prev= NULL;
		--tree->recent_count;
	}
}

/*----------------------------------------------------------------------------
 * Comparison Functions.
 * These conform to the rbtree_compare_fn signature of a context followed by
 *  two "key" pointers.  In this case, the keys are TreeRBXS_item structs
 * and the actual key field depends on the key_type of the node.  However,
 * for speed, the key_type is assumed to have been chosen correctly for the
 * comparison function during _init
 */

// Compare integers which were both already decoded from the original SVs
static int TreeRBXS_cmp_int(struct TreeRBXS *tree, struct TreeRBXS_item *a, struct TreeRBXS_item *b) {
	//warn("  int compare %p (%d) <=> %p (%d)", a, (int)a->keyunion.ikey, b, (int)b->keyunion.ikey);
	IV diff= a->keyunion.ikey - b->keyunion.ikey;
	return diff < 0? -1 : diff > 0? 1 : 0; /* shrink from IV to int might lose upper bits */
}

// Compare floats which were both already decoded from the original SVs
static int TreeRBXS_cmp_float(struct TreeRBXS *tree, struct TreeRBXS_item *a, struct TreeRBXS_item *b) {
	NV diff= a->keyunion.nkey - b->keyunion.nkey;
	return diff < 0? -1 : diff > 0? 1 : 0;
}

// Compare C strings using memcmp, on raw byte values.  The strings have been pre-processed to
// be comparable with memcmp, by case-folding, or making sure both are UTF-8, etc.
static int TreeRBXS_cmp_memcmp(struct TreeRBXS *tree, struct TreeRBXS_item *a, struct TreeRBXS_item *b) {
	size_t alen= a->ckeylen, blen= b->ckeylen;
	int cmp= memcmp(a->keyunion.ckey, b->keyunion.ckey, alen < blen? alen : blen);
	return cmp? cmp : alen < blen? -1 : alen > blen? 1 : 0;
}

static int cmp_numsplit(
	const char *apos, const char *alim, bool a_utf8,
	const char *bpos, const char *blim, bool b_utf8
) {
	const char *amark, *bmark;
	size_t alen, blen;
	int cmp;

	while (apos < alim && bpos < blim) {
		// Step forward as long as both strings are identical
		while (apos < alim && bpos < blim && *apos == *bpos && !isdigit(*apos))
			apos++, bpos++;
		// find the next start of digits along the strings
		amark= apos;
		while (apos < alim && !isdigit(*apos)) apos++;
		bmark= bpos;
		while (bpos < blim && !isdigit(*bpos)) bpos++;
		alen= apos - amark;
		blen= bpos - bmark;
		// compare the non-digit portions found in each string
		if (alen || blen) {
			// If one of the non-digit spans was length=0, then we are comparing digits (or EOF)
			// with string, and digits sort first.
			if (alen == 0) return -1;
			if (blen == 0) return  1;
			// else compare the portions in common.
#if PERL_VERSION_GE(5,14,0)
			if (a_utf8 != b_utf8) {
				cmp= a_utf8? -bytes_cmp_utf8((const U8*) bmark, blen, (const U8*) amark, alen)
					: bytes_cmp_utf8((const U8*) amark, alen, (const U8*) bmark, blen);
				if (cmp) return cmp;
			} else
#endif
			{
				cmp= memcmp(amark, bmark, alen < blen? alen : blen);
				if (cmp) return cmp;
				if (alen < blen) return -1;
				if (alen > blen) return -1;
			}
		}
		// If one of the strings ran out of characters, it is the lesser one.
		if (!(apos < alim && bpos < blim)) break;
		// compare the digit portions found in each string
		// Find the start of nonzero digits
		while (apos < alim && *apos == '0') apos++;
		while (bpos < blim && *bpos == '0') bpos++;
		amark= apos;
		bmark= bpos;
		// find the first differing digit
		while (apos < alim && bpos < blim && *apos == *bpos && isdigit(*apos))
			apos++, bpos++;
		// If there are more digits to consider beyond the first mismatch (or EOF) then need to
		// find the end of the digits and see which number was longer.
		if ((apos < alim && isdigit(*apos)) || (bpos < blim && isdigit(*bpos))) {
			if (apos == alim) return -1;
			if (bpos == blim) return 1;
			// If the strings happen to be the same length, this will be the deciding character
			cmp= *apos - *bpos;
			// find the end of digits
			while (apos < alim && isdigit(*apos)) apos++;
			while (bpos < blim && isdigit(*bpos)) bpos++;
			// Whichever number is longer is greater
			alen= apos - amark;
			blen= bpos - bmark;
			if (alen < blen) return -1;
			if (alen > blen) return 1;
			// Else they're the same length, and the 'cmp' captured earlier is the answer.
			return cmp;
		}
		// Else they're equal, continue to the next component.
	}
	// One or both of the strings ran out of characters
	if (bpos < blim) return -1;
	if (apos < alim) return 1;
	return 0;
}

static int TreeRBXS_cmp_numsplit(struct TreeRBXS *tree, struct TreeRBXS_item *a, struct TreeRBXS_item *b) {
	const char *apos, *alim;
	const char *bpos, *blim;
	size_t alen, blen;
	bool a_utf8= false, b_utf8= false;

	switch (tree->key_type) {
	case KEY_TYPE_USTR:
		a_utf8= b_utf8= true;
	case KEY_TYPE_BSTR:
		apos= a->keyunion.ckey; alim= apos + a->ckeylen;
		bpos= b->keyunion.ckey; blim= bpos + b->ckeylen;
		break;
	case KEY_TYPE_ANY:
	case KEY_TYPE_CLAIM:
#if PERL_VERSION_LT(5,14,0)
		// before 5.14, need to force both to utf8 if either are utf8
		if (SvUTF8(a->keyunion.svkey) || SvUTF8(b->keyunion.svkey)) {
			apos= SvPVutf8(a->keyunion.svkey, alen);
			bpos= SvPVutf8(b->keyunion.svkey, blen);
			a_utf8= b_utf8= true;
		} else
#else
		// After 5.14, can compare utf8 with bytes without converting the buffer
		a_utf8= SvUTF8(a->keyunion.svkey);
		b_utf8= SvUTF8(b->keyunion.svkey);
#endif		
		{
			apos= SvPV(a->keyunion.svkey, alen);
			bpos= SvPV(b->keyunion.svkey, blen);
		}
		alim= apos + alen;
		blim= bpos + blen;
		break;
	default: croak("BUG");
	}
	return cmp_numsplit(apos, alim, a_utf8, bpos, blim, b_utf8);
}

// Compare SV items using Perl's 'cmp' operator
static int TreeRBXS_cmp_perl(struct TreeRBXS *tree, struct TreeRBXS_item *a, struct TreeRBXS_item *b) {
	return sv_cmp(a->keyunion.svkey, b->keyunion.svkey);
}

// Compare SV items using a user-supplied perl callback
static int TreeRBXS_cmp_perl_cb(struct TreeRBXS *tree, struct TreeRBXS_item *a, struct TreeRBXS_item *b) {
	IV ret;
    dSP;
    ENTER;
	// There are a max of $tree_depth comparisons to do during an insert or search,
	// so should be safe to not free temporaries for a little bit.
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(a->keyunion.svkey);
    PUSHs(b->keyunion.svkey);
    PUTBACK;
    if (call_sv(tree->compare_callback, G_SCALAR) != 1)
        croak("stack assertion failed");
    SPAGAIN;
    ret= POPi;
    PUTBACK;
	// FREETMPS;
    LEAVE;
    return (int)(ret < 0? -1 : ret > 0? 1 : 0);
}

// Equivalent of "return fc($key)"  (case folding)
static SV* TreeRBXS_xform_fc(struct TreeRBXS *tree, SV *orig_key) {
	SV *folded_mortal;
	dSP;
	/* Annoyingly, the 'fc' implementation is not packaged into the perl api
	 * as a callable function, so I just have to invoke the perl op itself :-(
	 * For 5.16 and onward I can call CORE::fc, but before that I even need
	 * to wrap the op in my own sub.  (see XS.pm)
	 */
	ENTER;
	PUSHMARK(SP);
	XPUSHs(orig_key);
	PUTBACK;
#if PERL_VERSION_GE(5,16,0)
	call_pv("CORE::fc", G_SCALAR);
#else
	call_pv("Tree::RB::XS::_fc_impl", G_SCALAR);
#endif
	SPAGAIN;
	folded_mortal= POPs;
	PUTBACK;
	LEAVE;
	return folded_mortal;
}

/*------------------------------------------------------------------------------------
 * Definitions of Perl MAGIC that attach C structs to Perl SVs
 * All instances of Tree::RB::XS have a magic-attached struct TreeRBXS
 * All instances of Tree::RB::XS::Node have a magic-attached struct TreeRBXS_item
 */

// destructor for Tree::RB::XS
static int TreeRBXS_magic_free(pTHX_ SV* sv, MAGIC* mg) {
    if (mg->mg_ptr) {
        TreeRBXS_destroy((struct TreeRBXS*) mg->mg_ptr);
		Safefree(mg->mg_ptr);
		mg->mg_ptr= NULL;
	}
    return 0; // ignored anyway
}
#ifdef USE_ITHREADS
static int TreeRBXS_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    croak("This object cannot be shared between threads");
    return 0;
};
#else
#define TreeRBXS_magic_dup 0
#endif

// magic table for Tree::RB::XS
static MGVTBL TreeRBXS_magic_vt= {
	0, /* get */
	0, /* write */
	0, /* length */
	0, /* clear */
	TreeRBXS_magic_free,
	0, /* copy */
	TreeRBXS_magic_dup
#ifdef MGf_LOCAL
	,0
#endif
};

// destructor for Tree::RB::XS::Node
static int TreeRBXS_item_magic_free(pTHX_ SV* sv, MAGIC* mg) {
	if (mg->mg_ptr) {
		TreeRBXS_item_detach_owner((struct TreeRBXS_item*) mg->mg_ptr);
		mg->mg_ptr= NULL;
	}
	return 0;
}

// magic table for Tree::RB::XS::Node
static MGVTBL TreeRBXS_item_magic_vt= {
	0, /* get */
	0, /* write */
	0, /* length */
	0, /* clear */
	TreeRBXS_item_magic_free,
	0, /* copy */
	TreeRBXS_magic_dup
#ifdef MGf_LOCAL
	,0
#endif
};

// destructor for Tree::RB::XS::Iter
static int TreeRBXS_iter_magic_free(pTHX_ SV* sv, MAGIC *mg) {
	if (mg->mg_ptr)
		TreeRBXS_iter_free((struct TreeRBXS_iter*) mg->mg_ptr);
	return 0;
}

static MGVTBL TreeRBXS_iter_magic_vt= {
	0, /* get */
	0, /* write */
	0, /* length */
	0, /* clear */
	TreeRBXS_iter_magic_free,
	0, /* copy */
	TreeRBXS_magic_dup
#ifdef MGf_LOCAL
	,0
#endif
};

// Return the TreeRBXS struct attached to a Perl object via MAGIC.
// The 'obj' should be a reference to a blessed SV.
// Use AUTOCREATE to attach magic and allocate a struct if it wasn't present.
// Use OR_DIE for a built-in croak() if the return value would be NULL.
static struct TreeRBXS* TreeRBXS_get_magic_tree(SV *obj, int flags) {
	SV *sv;
	MAGIC* magic;
    struct TreeRBXS *tree;
	if (!sv_isobject(obj)) {
		if (flags & OR_DIE)
			croak("Not an object");
		return NULL;
	}
	sv= SvRV(obj);
	if (SvMAGICAL(sv) && (magic= mg_findext(sv, PERL_MAGIC_ext, &TreeRBXS_magic_vt)))
		return (struct TreeRBXS*) magic->mg_ptr;

    if (flags & AUTOCREATE) {
        Newxz(tree, 1, struct TreeRBXS);
		TreeRBXS_init(tree, sv);
        magic= sv_magicext(sv, NULL, PERL_MAGIC_ext, &TreeRBXS_magic_vt, (const char*) tree, 0);
#ifdef USE_ITHREADS
        magic->mg_flags |= MGf_DUP;
#endif
        return tree;
    }
    else if (flags & OR_DIE)
        croak("Object lacks 'struct TreeRBXS' magic");
	return NULL;
}

// Return the TreeRBXS_item that was attached to a perl object via MAGIC.
// The 'obj' should be a reference to a blessed magical SV.
static struct TreeRBXS_item* TreeRBXS_get_magic_item(SV *obj, int flags) {
	SV *sv;
	MAGIC* magic;

	if (!sv_isobject(obj)) {
		if (flags & OR_DIE)
			croak("Not an object");
		return NULL;
	}
	sv= SvRV(obj);
	if (SvMAGICAL(sv) && (magic= mg_findext(sv, PERL_MAGIC_ext, &TreeRBXS_item_magic_vt)))
		return (struct TreeRBXS_item*) magic->mg_ptr;

    if (flags & OR_DIE)
        croak("Object lacks 'struct TreeRBXS_item' magic");
	return NULL;
}

// Return existing Node object, or create a new one.
// Returned SV is a reference with active refcount, which is what the typemap
// wants for returning a "struct TreeRBXS_item*" to perl-land
static SV* TreeRBXS_wrap_item(struct TreeRBXS_item *item) {
	SV *obj;
	MAGIC *magic;
	// Since this is used in typemap, handle NULL gracefully
	if (!item)
		return &PL_sv_undef;
	// If there is already a node object, return a new reference to it.
	if (item->owner)
		return newRV_inc(item->owner);
	// else create a node object
	item->owner= newSV(0);
	obj= newRV_noinc(item->owner);
	sv_bless(obj, gv_stashpv("Tree::RB::XS::Node", GV_ADD));
	magic= sv_magicext(item->owner, NULL, PERL_MAGIC_ext, &TreeRBXS_item_magic_vt, (const char*) item, 0);
#ifdef USE_ITHREADS
	magic->mg_flags |= MGf_DUP;
#else
	(void)magic; // suppress warning
#endif
	return obj;
}

static SV* TreeRBXS_item_wrap_key(struct TreeRBXS_item *item) {
	if (!item)
		return &PL_sv_undef;
	if (item->orig_key_stored) {
		SV *tmp= GET_TreeRBXS_item_ORIG_KEY(item);
		return SvREFCNT_inc(tmp);
	}
	switch (item->key_type) {
	case KEY_TYPE_ANY:
	case KEY_TYPE_CLAIM: return SvREFCNT_inc(item->keyunion.svkey);
	case KEY_TYPE_INT:   return newSViv(item->keyunion.ikey);
	case KEY_TYPE_FLOAT: return newSVnv(item->keyunion.nkey);
	case KEY_TYPE_USTR:  return newSVpvn_flags(item->keyunion.ckey, item->ckeylen, SVf_UTF8);
	case KEY_TYPE_BSTR:  return newSVpvn(item->keyunion.ckey, item->ckeylen);
	default: croak("BUG: un-handled key_type");
	}
}

// Can't figure out how to create new CV instances on the fly...
/*
static SV* TreeRBXS_wrap_iter(pTHX_ struct TreeRBXS_iter *iter) {
	SV *obj;
	CV *iter_next_cv;
	MAGIC *magic;
	// Since this is used in typemap, handle NULL gracefully
	if (!iter)
		return &PL_sv_undef;
	// If there is already a node object, return a new reference to it.
	if (iter->owner)
		return newRV_inc(iter->owner);
	// else create an iterator
	iter_next_cv= get_cv("Tree::RB::XS::Iter::next", 0);
	if (!iter_next_cv) croak("BUG: can't find Iter->next");
	obj= newRV_noinc((SV*)cv_clone(iter_next_cv));
	sv_bless(obj, gv_stashpv("Tree::RB::XS::Iter", GV_ADD));
	magic= sv_magicext(SvRV(obj), NULL, PERL_MAGIC_ext, &TreeRBXS_iter_magic_vt, (const char*) iter, 0);
#ifdef USE_ITHREADS
	magic->mg_flags |= MGf_DUP;
#else
	(void)magic; // suppress warning
#endif
	return obj;
}
*/

// Return the TreeRBXS_iter struct attached to a Perl object via MAGIC.
// The 'obj' should be a reference to a blessed SV.
// Use AUTOCREATE to attach magic and allocate a struct if it wasn't present.
// Use OR_DIE for a built-in croak() if the return value would be NULL.
static struct TreeRBXS_iter* TreeRBXS_get_magic_iter(SV *obj, int flags) {
	SV *sv;
	MAGIC* magic;
	struct TreeRBXS_iter *iter;
	if (!sv_isobject(obj)) {
		if (flags & OR_DIE)
			croak("Not an object");
		return NULL;
	}
	sv= SvRV(obj);
	if (SvMAGICAL(sv) && (magic= mg_findext(sv, PERL_MAGIC_ext, &TreeRBXS_iter_magic_vt)))
		return (struct TreeRBXS_iter*) magic->mg_ptr;

	if (flags & AUTOCREATE) {
		Newxz(iter, 1, struct TreeRBXS_iter);
		magic= sv_magicext(sv, NULL, PERL_MAGIC_ext, &TreeRBXS_iter_magic_vt, (const char*) iter, 0);
#ifdef USE_ITHREADS
		magic->mg_flags |= MGf_DUP;
#endif
		iter->owner= sv;
		return iter;
	}
	else if (flags & OR_DIE)
		croak("Object lacks 'struct TreeRBXS_iter' magic");
	return NULL;
}

#define FUNCTION_IS_LVALUE(x) function_is_lvalue(aTHX_ stash, #x)
static void function_is_lvalue(pTHX_ HV *stash, const char *name) {
	CV *method_cv;
	GV *method_gv;
	if (!(method_gv= gv_fetchmethod(stash, name))
		|| !(method_cv= GvCV(method_gv)))
		croak("Missing method %s", name);
	CvLVALUE_on(method_cv);
}

#define EXPORT_ENUM(x) newCONSTSUB(stash, #x, new_enum_dualvar(aTHX_ x, newSVpvs_share(#x)))
static SV * new_enum_dualvar(pTHX_ IV ival, SV *name) {
	SvUPGRADE(name, SVt_PVNV);
	SvIV_set(name, ival);
	SvIOK_on(name);
	SvREADONLY_on(name);
	return name;
}

/* Return an SV array of an AV.
 * Returns NULL if it wasn't an AV or arrayref.
 */
static SV** unwrap_array(SV *array, IV *len) {
	AV *av;
	SV **vec;
	IV n;
	if (array && SvTYPE(array) == SVt_PVAV)
		av= (AV*) array;
	else if (array && SvROK(array) && SvTYPE(SvRV(array)) == SVt_PVAV)
		av= (AV*) SvRV(array);
	else
		return NULL;
	n= av_len(av) + 1;
	vec= AvARRAY(av);
	/* tied arrays and non-allocated empty arrays return NULL */
	if (!vec) {
		if (n == 0) /* don't return a NULL for an empty array, but doesn't need to be a real pointer */
			vec= (SV**) 8;
		else {
			/* in case of a tied array, extract the elements into a temporary buffer */
			IV i;
			Newx(vec, n, SV*);
			SAVEFREEPV(vec);
			for (i= 0; i < n; i++) {
				SV **el= av_fetch(av, i, 0);
				vec[i]= el? *el : NULL;
			}
		}
	}
	if (len) *len= n;
	return vec;
}

/* Initialize a new tree from settings in a list of perl SVs
 *
 * This functions expects that 'tree' has been suitably initialized so that if an attribute
 * does not occur in the list, it has already received a sensible default value.
 * The attr_list is assumed to be an array of mortal SVs such that they can be re-ordered
 * or removed freely, so that _init_tree can return the list of un-consumed attributes.
 * This means that attr_list should *NOT* be AvARRAY of an AV.
 * Returns the number of unknown attributes, which have been re-packed in the list.
 */
IV init_tree_from_attr_list(
	struct TreeRBXS *tree,
	SV **attr_list,
	IV attr_list_len
) {
	IV i, out_i;
	SV *key_type_sv= NULL,
	   *compare_fn_sv= NULL,
	   *kv_sv= NULL,
	   *keys_sv= NULL,
	   *values_sv= NULL,
	   *recent_sv= NULL,
	   *hashiter_sv= NULL;
	int key_type;
	IV nodecount= 0;
	struct TreeRBXS_item *item, stack_item;
	rbtree_node_t *node;

	/* Begin iterating arguments, and store the SVs we know in variables, and put the
	 * rest into the object hash. */
	for (i= out_i= 0; i < attr_list_len; i += 2) {
		SV *key= attr_list[i], *val;
		STRLEN len;
		const char *attrname= SvPV(key, len);
		/* every attribute needs a value */
		if (i + 1 == attr_list_len)
			croak("No value provided for %s", attrname);
		val= attr_list[i+1];
		if (!SvOK(val))
			val= NULL; /* prefer NULLs for unset attributes */
		switch (len) {
		case  2: if (strcmp("kv", attrname) == 0) { kv_sv= val; break; }
			else goto keep_unknown;
		case  4: if (strcmp("keys", attrname) == 0) { keys_sv= val; break; }
			else goto keep_unknown;
		case  6: if (strcmp("values", attrname) == 0) { values_sv= val; break; }
			else if (strcmp("recent", attrname) == 0) { recent_sv= val; break; }
			else goto keep_unknown;
		case  8: if (strcmp("key_type", attrname) == 0) { key_type_sv= val; break; }
			else if (strcmp("hashiter", attrname) == 0) { hashiter_sv= val; break; }
			else goto keep_unknown;
		case 10: if (strcmp("compare_fn", attrname) == 0) { compare_fn_sv= val; break; }
			else goto keep_unknown;
		case 12: if (strcmp("track_recent", attrname) == 0) { tree->track_recent= val && SvTRUE(val); break; }
			else goto keep_unknown;
		case 15: if (strcmp("compat_list_get", attrname) == 0) { tree->compat_list_get= val && SvTRUE(val); break; }
			else goto keep_unknown;
		case 16: if (strcmp("allow_duplicates", attrname) == 0) { tree->allow_duplicates= val && SvTRUE(val); break; }
			else goto keep_unknown;
		case 21: if (strcmp("lookup_updates_recent", attrname) == 0) { tree->lookup_updates_recent= val && SvTRUE(val); break; }
		default: keep_unknown:
			/* unknown attribute.  Re-pack it into the list */
			if (i > out_i) {
				attr_list[out_i]=   attr_list[i];
				attr_list[out_i+1]= attr_list[i+1];
			}
			out_i += 2;
		}
	}

	// parse key type and compare_fn
	if (key_type_sv) {
		key_type= parse_key_type(key_type_sv);
		if (key_type < 0)
			croak("invalid key_type %s", SvPV_nolen(key_type_sv));
		tree->key_type= key_type;
	}
	else key_type= tree->key_type;
	
	if (compare_fn_sv) {
		int cmp_id= parse_cmp_fn(compare_fn_sv);
		if (cmp_id < 0)
			croak("invalid compare_fn %s", SvPV_nolen(compare_fn_sv));
		tree->compare_fn_id= cmp_id;
	} else if (key_type_sv) {
		tree->compare_fn_id=
			  key_type == KEY_TYPE_INT?   CMP_INT
			: key_type == KEY_TYPE_FLOAT? CMP_FLOAT
			: key_type == KEY_TYPE_BSTR?  CMP_MEMCMP
			: key_type == KEY_TYPE_USTR?  CMP_STR
			: key_type == KEY_TYPE_ANY?   CMP_PERL /* use Perl's cmp operator */
			: key_type == KEY_TYPE_CLAIM? CMP_PERL
			: CMP_PERL;
	}

	switch (tree->compare_fn_id) {
	case CMP_SUB:
		if (!compare_fn_sv || !SvRV(compare_fn_sv) || SvTYPE(SvRV(compare_fn_sv)) != SVt_PVCV)
			croak("Can't set compare_fn to CMP_SUB without supplying a coderef");
		tree->compare_callback= compare_fn_sv;
		SvREFCNT_inc(tree->compare_callback);
		if (key_type != KEY_TYPE_CLAIM) tree->key_type= KEY_TYPE_ANY;
		tree->compare= TreeRBXS_cmp_perl_cb;
		break;
	case CMP_FOLDCASE:
		tree->transform= TreeRBXS_xform_fc;
	case CMP_STR:
		tree->key_type= KEY_TYPE_USTR;
		tree->compare= TreeRBXS_cmp_memcmp;
		break;
	case CMP_PERL:
		if (key_type != KEY_TYPE_CLAIM) tree->key_type= KEY_TYPE_ANY;
		tree->compare= TreeRBXS_cmp_perl;
		break;
	case CMP_INT:
		tree->key_type= KEY_TYPE_INT;
		tree->compare= TreeRBXS_cmp_int;
		break;
	case CMP_FLOAT:
		tree->key_type= KEY_TYPE_FLOAT;
		tree->compare= TreeRBXS_cmp_float;
		break;
	case CMP_MEMCMP:
		tree->key_type= KEY_TYPE_BSTR;
		tree->compare= TreeRBXS_cmp_memcmp;
		break;
	case CMP_NUMSPLIT_FOLDCASE:
		tree->key_type= KEY_TYPE_USTR;
		tree->transform= TreeRBXS_xform_fc;
		tree->compare= TreeRBXS_cmp_numsplit;
		break;
	case CMP_NUMSPLIT:
		if (key_type != KEY_TYPE_USTR && key_type != KEY_TYPE_ANY && key_type != KEY_TYPE_CLAIM)
			tree->key_type= KEY_TYPE_BSTR;
		tree->compare= TreeRBXS_cmp_numsplit;
		break;
	default:
		croak("BUG: unhandled cmp_id");
	}

	/* if keys and/or values supplied... */
	if (kv_sv || keys_sv || values_sv) {
		SV **key_vec= NULL, **key_lim, **val_vec= NULL;
		IV num_kv, key_step= 0, val_step= 0;
		bool track_recent= tree->track_recent;
		
		if (kv_sv) {
			if (keys_sv || values_sv)
				croak("'kv' cannot be specified at the same time as 'keys' or 'values'");
			if (!(key_vec= unwrap_array(kv_sv, &num_kv)))
				croak("'kv' must be an arrayref");
			if (num_kv & 1)
				croak("Odd number of elements in 'kv' array");
			num_kv >>= 1;
			val_vec= key_vec+1;
			key_step= val_step= 2;
		}
		if (keys_sv) {
			if (!(key_vec= unwrap_array(keys_sv, &num_kv)))
				croak("'keys' must be an arrayref");
			key_step= 1;
		}
		if (values_sv) {
			IV nvals;
			if (!key_vec)
				croak("'values' can't be specified without 'keys'");
			if (!(val_vec= unwrap_array(values_sv, &nvals)))
				croak("'values' must be an arrayref");
			if (nvals != num_kv)
				croak("Length of 'values' array (%ld) does not match keys (%ld)", (long)nvals, (long)num_kv);
			val_step= 1;
		}
		/* If recent list is about to be overwritten, don't track any insertions */
		if (recent_sv)
			tree->track_recent= false;
		for (key_lim= key_vec + num_kv * key_step; key_vec < key_lim; key_vec += key_step, val_vec += val_step) {
			TreeRBXS_init_tmp_item(&stack_item, tree, (*key_vec? *key_vec : &PL_sv_undef), (val_vec? *val_vec : &PL_sv_undef));
			TreeRBXS_insert_item(tree, &stack_item, !tree->allow_duplicates, NULL);
		}
		/* restore tracking setting */
		tree->track_recent= track_recent;
		/* might not equal num_kv if there were duplicates */
		nodecount= TreeRBXS_get_count(tree);
	}
	/* user wants to initialize the linked list of track_recent */
	if (recent_sv) {
		IV i, idx, n;
		SV **rvec= unwrap_array(recent_sv, &n);
		if (!rvec) croak("'recent' must be an arrayref");
		for (i= 0; i < n; i++) {
			if (!looks_like_integer(rvec[i]))
				croak("Elements of 'recent' must be integers");
			idx= SvIV(rvec[i]);
			if (idx < 0 || idx >= nodecount)
				croak("Element in 'recent' (%ld) is out of bounds (0-%ld)", (long)idx, (long)(nodecount-1));
			node= rbtree_node_child_at_index(TreeRBXS_get_root(tree), idx);
			if (!node) croak("BUG: access node[idx]");
			item= GET_TreeRBXS_item_FROM_rbnode(node);
			TreeRBXS_recent_insert_before(tree, item, &tree->recent);
		}
	}
	/* hashiter_sv restores the state of tied-hash iteration */
	if (hashiter_sv) {
		struct TreeRBXS_iter *iter= TreeRBXS_get_hashiter(tree);
		IV idx;
		if (!looks_like_integer(hashiter_sv))
			croak("Expected integer for 'hashiter'");
		idx= SvIV(hashiter_sv);
		if (idx < 0 || idx >= nodecount)
			croak("'hashiter' value out of bounds");
		node= rbtree_node_child_at_index(TreeRBXS_get_root(tree), idx);
		if (!node) croak("BUG: access node[idx]");
		item= GET_TreeRBXS_item_FROM_rbnode(node);
		TreeRBXS_iter_set_item(iter, item);
	}

	/* return number of attribute (k,v) remaining in the supplied list */
	return out_i;
}

int get_integer_version() {
	SV *version= get_sv("Tree::RB::XS::VERSION", 0);
	if (!version || !SvOK(version))
		croak("$Tree::RB::XS::VERSION is not defined");
	return (int)(SvNV(version) * 1000000);
}

/*----------------------------------------------------------------------------
 * Tree Methods
 */

MODULE = Tree::RB::XS              PACKAGE = Tree::RB::XS

void
new(obj_or_pkg, ...)
	SV *obj_or_pkg
	ALIAS:
		Tree::RB::XS::TIEHASH    = 0
		Tree::RB::XS::_init_tree = 1
	INIT:
		struct TreeRBXS *tree= NULL;
		SV *objref= NULL, **attr_list;
		HV *obj_hv= NULL, *pkg= NULL;
		IV n_unknown, i, attr_len;
	PPCODE:
		if (sv_isobject(obj_or_pkg) && SvTYPE(SvRV(obj_or_pkg)) == SVt_PVHV) {
			objref= obj_or_pkg;
			obj_hv= (HV*) SvRV(objref);
		}
		else if (SvPOK(obj_or_pkg) && (pkg= gv_stashsv(obj_or_pkg, 0))) {
			if (!sv_derived_from(obj_or_pkg, "Tree::RB::XS"))
				croak("Package %s does not derive from Tree:RB::XS", SvPV_nolen(obj_or_pkg));
			obj_hv= newHV();
			objref= sv_2mortal(newRV_noinc((SV*)obj_hv));
			sv_bless(objref, pkg);
			ST(0)= objref;
		}
		else 
			croak("%s: first arg must be package name or blessed object", ix == 1? "_init_tree":"new");
		
		/* Special cases for 'new': it can be compare_fn, or a hashref */
		if (items == 2) {
			SV *first= ST(1);
			/* non-ref means a compare_fn constant, likewise for coderef */
			if (!SvROK(first) || SvTYPE(SvRV(first)) == SVt_PVCV) {
				Newx(attr_list, 2, SV*);
				SAVEFREEPV(attr_list);
				attr_list[0]= newSVpvs("compare_fn");
				attr_list[1]= first;
				attr_len= 2;
			}
			else if (SvTYPE(SvRV(first)) == SVt_PVHV) {
				HV *attrhv= (HV*) SvRV(first);
				IV n= hv_iterinit(attrhv);
				HE *ent;
				attr_len= n*2;
				Newx(attr_list, attr_len, SV*);
				SAVEFREEPV(attr_list);
				i= 0;
				while ((ent= hv_iternext(attrhv)) && i < attr_len) {
					attr_list[i++]= hv_iterkeysv(ent);
					attr_list[i++]= hv_iterval(attrhv, ent);
				}
			}
			else croak("Expected compare_fn constant, coderef, hashref, or key/value pairs");
		} else {
			attr_list= PL_stack_base+ax+1;
			attr_len= items - 1;
		}

		/* Upgrade this object to have TreeRBXS struct attached magically */
		tree= TreeRBXS_get_magic_tree(objref, AUTOCREATE|OR_DIE);
		if (tree->owner != (SV*) obj_hv)
			croak("Tree was already initialized");

		n_unknown= init_tree_from_attr_list(tree, attr_list, attr_len);
		if (n_unknown) {
			/* if called by the public constructor, throw an error */
			if (ix == 0)
				croak("Unknown attribute %s", SvPV_nolen(attr_list[0]));
			/* else return them to caller.  They might already be in the stack. */
			if (attr_list != PL_stack_base+ax+1) {
				EXTEND(SP, n_unknown);
				for (i= 0; i < n_unknown; i++)
					ST(i+1)= attr_list[i];
			}
		}
		i= ix == 0? 1 : n_unknown;
		XSRETURN(i);

void
_assert_structure(tree)
	struct TreeRBXS *tree
	CODE:
		TreeRBXS_assert_structure(tree);

void
STORABLE_freeze(tree, cloning)
	struct TreeRBXS *tree
	bool cloning
	INIT:
		IV nodecount= TreeRBXS_get_count(tree);
		rbtree_node_t *node= rbtree_node_left_leaf(TreeRBXS_get_root(tree));
		struct TreeRBXS_item *item;
		int i, cmp_id= tree->compare_fn_id, key_type= tree->key_type,
			flags, version= get_integer_version();
		unsigned char sb[14];
		AV *attrs= newAV();
		SV *attrs_ref= sv_2mortal(newRV_noinc((SV*) attrs));
		HV *treehv= (HV*) tree->owner;
		HE *pos;
	PPCODE:
		/* dump out the contents of the hashref, which is empty unless set by subclass */
		hv_iterinit(treehv);
		while ((pos= hv_iternext(treehv))) {
			av_push(attrs, SvREFCNT_inc(hv_iterkeysv(pos)));
			av_push(attrs, newSVsv(hv_iterval(treehv, pos)));
		}

		/* Build lists of keys and values */
		if (nodecount) {
			AV *keys_av, *values_av;
			SV *keys= NULL, *values= NULL;
			//IV *keys_ivec;
			//NV *keys_nvec;
			//bool all_one= true, all_undef= true;
			values_av= newAV();
			values= sv_2mortal(newRV_noinc((SV*) values_av));
			av_extend(values_av, nodecount-1);
			/* decide whether keys will be an AV, or packed in a buffer */
			//if (key_type == KEY_TYPE_INT) {
			//	/* allocate a buffer of ints */
			//	svtmp= make_aligned_buffer(NULL, sizeof(IV)*nodecount, sizeof(IV));
			//	keys_ivec= (IV*) SvPVX(svtmp);
			//	keys= newRV_noinc(svtmp);
			//} else if (key_type == KEY_TYPE_FLOAT) {
			//	/* allocate a buffer of NV */
			//	svtmp= make_aligned_buffer(NULL, sizeof(NV)*nodecount, sizeof(NV));
			//	keys_nvec= (NV*) SvPVX(svtmp);
			//	keys= newRV_noinc(svtmp);
			//} else {
				keys_av= newAV();
				keys= sv_2mortal(newRV_noinc((SV*) keys_av));
				av_extend(keys_av, nodecount-1);
			//}
			/* Now fill the key and value arrays */
			for (i= 0; i < nodecount && node; i++, node=rbtree_node_next(node)) {
				item= GET_TreeRBXS_item_FROM_rbnode(node);
				/* I think I need to populate this array with the exact SV from the tree so that
				 * Storable can recognize repeat references that might live in the larger graph.
				 * In normal circumstances the correct thing here is to newSVsv() so that
				 * the array items aren't shared. */
				av_push(values_av, SvREFCNT_inc(item->value));
				/* for packed keys, write the existing buffer.  else create a new SV */
				//switch (key_type) {
				//case KEY_TYPE_INT:
				//	keys_ivec[i]= item->keyunion.ikey;
				//	break;
				//case KEY_TYPE_FLOAT:
				//	keys_nvec[i]= item->keyunion.nkey;
				//	break;
				//case KEY_TYPE_ANY:
				//case KEY_TYPE_CLAIM: av_push(keys_av, SvREFCNT_inc(item->keyunion.svkey)); break;
				//default:
					av_push(keys_av, TreeRBXS_item_wrap_key(item));
				//}
			}
			/* sanity-check: ensure loop ended at expected count */
			if (i < nodecount) croak("BUG: too few nodes in tree");
			if (node) croak("BUG: too many nodes in tree");
			/* optimize key storage */
			//if (key_type == KEY_TYPE_INT) {
			//	key_bits= 
			//}
			av_push(attrs, newSVpvs("keys"));
			av_push(attrs, SvREFCNT_inc(keys));
			av_push(attrs, newSVpvs("values"));
			av_push(attrs, SvREFCNT_inc(values));

			/* if any nodes belong to the recent-list, emit that as an array of node indices */
			if (tree->recent_count) {
				struct dllist_node *root= &tree->recent, *pos= tree->recent.next;
				AV *recent_av= newAV();
				av_push(attrs, newSVpvs("recent"));
				av_push(attrs, newRV_noinc((SV*) recent_av));
				av_extend(recent_av, tree->recent_count-1);
				for (i= tree->recent_count; i > 0 && pos != root; --i, pos= pos->next) {
					item= GET_TreeRBXS_item_FROM_recent(pos);
					av_push(recent_av, newSViv(rbtree_node_index(&item->rbnode)));
				}
				/* sanity check */
				if (i != 0) croak("BUG: too few recent-tracked nodes");
				if (pos != root) croak("BUG: too many recent-tracked nodes");
			}
			/* and finally, the optional built-in iterator for when the tree is tied to a hash */
			if (tree->hashiter && tree->hashiter->item) {
				/* only need to initialize it if it is pointing somewhere other than the first
				 * tree node. */
				IV pointing_at= rbtree_node_index(&tree->hashiter->item->rbnode);
				if (pointing_at) {
					av_push(attrs, newSVpvs("hashiter"));
					av_push(attrs, newSViv(pointing_at));
				}
			}
		}
		/* Attempting to clone a tree with a user-supplied callback comparison function will
		 * fail, because Storable won't encode coderefs by default.  This makes sense for
		 * process-to-process serialization, but for dclone() I want to enable it so long as
		 * the coderef is a global function. */
		if (cmp_id == CMP_SUB) {
			if (!cloning)
				croak("Can't serialize a Tree::RB::XS with a custom comparison coderef");
			else {
				CV *cv= (CV*) SvRV(tree->compare_callback);
				GV *gv= CvGV(cv), *re_gv;
				HV *stash= GvSTASH(gv);
				const char *name= GvNAME(gv);
				
				if (!stash || !name || !(re_gv= gv_fetchmethod(stash, name)) || GvCV(re_gv) != cv)
					croak("Comparison function (%s::%s) for Tree::RB::XS instance cannot be serialized unless it exists as a global package function",
						stash? HvNAME(stash) : "NULL",
						name? name : "NULL"
					);
				av_push(attrs, newSVpvs("compare_fn"));
				av_push(attrs, newSVpvf("%s::%s", HvNAME(stash), name));
			}
		}

		if (version < 0 || version > 0x7FFFFFFF)
			croak("BUG: version out of bounds");
		sb[0]= version & 0xFF;
		sb[1]= (version >>  8) & 0xFF;
		sb[2]= (version >> 16) & 0xFF;
		sb[3]= (version >> 24) & 0xFF;
		if (key_type < 1 || key_type > 255)
			croak("BUG: key_type out of bounds");
		sb[4]= key_type & 0xFF;
		sb[5]= (key_type >> 8) & 0xFF;
		if (cmp_id < 1 || cmp_id > 255)
			croak("BUG: compare_fn outof bounds");
		sb[6]= cmp_id & 0xFF;
		sb[7]= (cmp_id >> 8) & 0xFF;
		flags= (tree->allow_duplicates? 1 : 0)
		     | (tree->compat_list_get? 2 : 0)
		     | (tree->track_recent? 4 : 0)
		     | (tree->lookup_updates_recent? 8 : 0);
		sb[8]= flags & 0xFF;
		sb[9]= (flags >> 8) & 0xFF;

		EXTEND(SP, 2);
		ST(0)= sv_2mortal(newSVpvn((char*)sb, 10));
		ST(1)= attrs_ref;
		XSRETURN(2);

void
STORABLE_thaw(objref, cloning, serialized, attrs)
	SV *objref
	bool cloning
	SV *serialized
	AV *attrs
	INIT:
		struct TreeRBXS *tree= NULL;
		int version, cmp_id, key_type, flags, i;
		IV attr_len, n_unknown;
		const unsigned char *sb;
		STRLEN sb_len;
		SV **attr_vec= unwrap_array((SV*)attrs, &attr_len), **attr_list, *tmpsv;
	PPCODE:
		if (!SvROK(objref) || SvTYPE(SvRV(objref)) != SVt_PVHV)
			croak("Expected blessed hashref as first argument");
		tree= TreeRBXS_get_magic_tree(objref, AUTOCREATE|OR_DIE);
		if (tree->owner != SvRV(objref))
			croak("Tree was already initialized");
		
		/* unpack serialized fields */
		sb= (const unsigned char*) SvPV(serialized, sb_len);
		if (sb_len < 10)
			croak("Expected at least 10 bytes of serialized data");
		version=  sb[0] + (sb[1] << 8) + (sb[2] << 16) + (sb[3] << 24); // 4 bytes LE
		key_type= sb[4] + (sb[5] << 8);                                 // 2 bytes LE
		cmp_id=   sb[6] + (sb[7] << 8);                                 // 2 bytes LE
		flags=    sb[8] + (sb[9] << 8);                                 // 2 bytes LE

		if (version <= 0)
			croak("Invalid serialized version");
		if (version > get_integer_version())
			croak("Attempt to deserialize Tree::RB::XS from a newer version");
		/* STORABLE_freeze lists nodes exactly as they were, so alllow duplicates if present,
		 * regardless of the final state of the allow_duplicates attribute. */
		tree->allow_duplicates= /* flags & 1 */ true; /* corrected below */
		tree->compat_list_get= flags & 2;
		tree->track_recent= flags & 4;
		tree->lookup_updates_recent= flags & 8;

		if (key_type <= 0 || key_type > KEY_TYPE_MAX)
			croak("Invalid serialized key_type");
		tree->key_type= key_type;

		if (cmp_id <= 0 || cmp_id > CMP_MAX)
			croak("Invalid serialized compare_fn");
		tree->compare_fn_id= cmp_id;
		/* These two comparison function codes imply a transform function */
		if (cmp_id == CMP_FOLDCASE || cmp_id == CMP_NUMSPLIT_FOLDCASE)
			tree->transform= TreeRBXS_xform_fc;

		/* attr_vec gets modified, so make a copy of attrs' AvARRAY */
		Newx(attr_list, attr_len, SV*);
		SAVEFREEPV(attr_list);
		memcpy(attr_list, attr_vec, sizeof(SV*) * attr_len);

		/* If the comparison function is a coderef, try to look up the name of the function */
		if (cmp_id == CMP_SUB) {
			if (!cloning) croak("compare_fn lookup is forbidden unless cloning");
			/* look for attribute compare_fn, which is probably the final one */
			for (i= attr_len-2; i >= 0; i-= 2) {
				if (strcmp(SvPV_nolen(attr_list[i]), "compare_fn") == 0) {
					/* replace function name with coderef */
					GV *gv= gv_fetchsv(attr_list[i+1], 0, SVt_PVCV);
					if (gv && GvCV(gv))
						attr_list[i+1]= sv_2mortal(newRV_inc((SV*) GvCV(gv)));
					else
						croak("Can't find function %s", SvPV_nolen(attr_list[i+1]));
					break;
				}
			}
			if (i < 0)
				croak("No compare_fn name found in serialized data");
		}

		n_unknown= init_tree_from_attr_list(tree, attr_list, attr_len);
		if (n_unknown) {
			HV *obj= (HV*) SvRV(objref);
			/* store leftovers into the hashref of the object */
			for (i= 0; i < n_unknown-1; i += 2)
				if (!hv_store_ent(obj, attr_list[i], (tmpsv= newSVsv(attr_list[i+1])), 0))
					sv_2mortal(tmpsv);
		}
		tree->allow_duplicates= flags & 1; /* delayed for reason above */
		XSRETURN(0);

void
key_type(tree)
	struct TreeRBXS *tree
	INIT:
		int kt= tree->key_type;
	PPCODE:
		ST(0)= sv_2mortal(new_enum_dualvar(aTHX_ kt, newSVpv(get_key_type_name(kt), 0)));
		XSRETURN(1);

void
compare_fn(tree)
	struct TreeRBXS *tree
	INIT:
		int id= tree->compare_fn_id;
	PPCODE:
		ST(0)= id == CMP_SUB? tree->compare_callback
			: sv_2mortal(new_enum_dualvar(aTHX_ id, newSVpv(get_cmp_name(id), 0)));
		XSRETURN(1);

void
allow_duplicates(tree, allow= NULL)
	struct TreeRBXS *tree
	SV* allow
	PPCODE:
		if (items > 1) {
			tree->allow_duplicates= SvTRUE(allow);
			// ST(0) is $self, so let it be the return value
		} else {
			ST(0)= sv_2mortal(newSViv(tree->allow_duplicates? 1 : 0));
		}
		XSRETURN(1);

void
compat_list_get(tree, allow= NULL)
	struct TreeRBXS *tree
	SV* allow
	PPCODE:
		if (items > 1) {
			tree->compat_list_get= SvTRUE(allow);
			// ST(0) is $self, so let it be the return value
		} else {
			ST(0)= tree->compat_list_get? &PL_sv_yes : &PL_sv_no;
		}
		XSRETURN(1);

void
track_recent(tree, enable= NULL)
	struct TreeRBXS *tree
	SV* enable
	PPCODE:
		if (items > 1) {
			tree->track_recent= SvTRUE(enable);
			// ST(0) is $self, so let it be the return value
		} else {
			ST(0)= tree->track_recent? &PL_sv_yes : &PL_sv_no;
		}
		XSRETURN(1);

void
lookup_updates_recent(tree, enable= NULL)
	struct TreeRBXS *tree
	SV *enable
	PPCODE:
		if (items > 1) {
			tree->lookup_updates_recent= SvTRUE(enable);
			//ST(0) is $self, so let it be the return value
		} else {
			ST(0)= tree->lookup_updates_recent? &PL_sv_yes : &PL_sv_no;
		}
		XSRETURN(1);

IV
size(tree)
	struct TreeRBXS *tree
	CODE:
		RETVAL= TreeRBXS_get_count(tree);
	OUTPUT:
		RETVAL

IV
recent_count(tree)
	struct TreeRBXS *tree;
	CODE:
		RETVAL= tree->recent_count;
	OUTPUT:
		RETVAL

void
_insert_optimization_debug(tree)
	struct TreeRBXS *tree;
	PPCODE:
		EXTEND(SP, 5);
		PUSHs(sv_2mortal(newSViv(tree->prev_inserted_trend)));
		PUSHs(sv_2mortal(newSViv(INSERT_TREND_TRIGGER)));
		PUSHs(sv_2mortal(newSViv(INSERT_TREND_CAP)));
		PUSHs(sv_2mortal(newSViv(tree->prev_inserted_dup? 1 : 0)));

void
insert(tree, key, val=&PL_sv_undef)
	struct TreeRBXS *tree
	SV *key
	SV *val
	ALIAS:
		Tree::RB::XS::put         = 1
		Tree::RB::XS::STORE       = 1
	INIT:
		struct TreeRBXS_item stack_item, *inserted;
		SV *oldval= NULL;
	PPCODE:
		//TreeRBXS_assert_structure(tree);
		if (!SvOK(key))
			croak("Can't use undef as a key");
		TreeRBXS_init_tmp_item(&stack_item, tree, key, val);
		inserted= TreeRBXS_insert_item(tree, &stack_item, ix == 1, &oldval);
		ST(0)= ix == 0? sv_2mortal(newSViv(inserted? rbtree_node_index(&inserted->rbnode) : -1))
			: (oldval? oldval : &PL_sv_undef);
		XSRETURN(1);

IV
insert_multi(tree, ...)
	struct TreeRBXS *tree
	ALIAS:
		Tree::RB::XS::put_multi        = 1
	INIT:
		struct TreeRBXS_item stack_item, *inserted;
		AV *av= NULL;
		SV *key, *val, *oldval, **el;
		int added= 0, i, lim;
	CODE:
		// Is there exactly one element which is an un-blessed arrayref?
		if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV && !sv_isobject(ST(1))) {
			av= (AV*) SvRV(ST(1));
			i= 0;
			lim= av_len(av)+1;
		} else {
			i= 1;
			lim= items;
		}
		// Iterate either the array or the stack
		while (i < lim) {
			val= &PL_sv_undef;
			// either iterating an array, or iterating the stack
			if (av) {
				el= av_fetch(av, i, 0);
				if (!el) croak("Tree->insert_multi does not support tied or sparse arrays");
				key= *el;
				i++;
				if (i < lim) {
					el= av_fetch(av, i, 0);
					if (!el) croak("Tree->insert_multi does not support tied or sparse arrays");
					val= *el;
					i++;
				}
			} else {
				key= ST(i);
				if (++i < lim) {
					val= ST(i);
					i++;
				}
			}
			if (!SvOK(key))
				croak("Can't use undef as a key");
			TreeRBXS_init_tmp_item(&stack_item, tree, key, val);
			oldval= NULL;
			inserted= TreeRBXS_insert_item(tree, &stack_item, ix == 1, &oldval);
			// Count the newly added nodes.  For insert, that is the number of non-null 'inserted'.
			// For put, that is the number of inserts that did not return an old value.
			if (ix == 0? (inserted != NULL) : (oldval == NULL))
				++added;
		}
		RETVAL= added;
	OUTPUT:
		RETVAL

IV
exists(tree, ...)
	struct TreeRBXS *tree
	ALIAS:
		Tree::RB::XS::EXISTS = 1
	INIT:
		struct TreeRBXS_item stack_item;
		rbtree_node_t *node;
		SV *key;
		int i, cmp;
		size_t count, total= 0;
	CODE:
		(void) ix; /* unused */
		for (i= 1; i < items; i++) {
			key= ST(i);
			TreeRBXS_init_tmp_item(&stack_item, tree, key, &PL_sv_undef);
			if (tree->allowed_duplicates) {
				count= 0;
				rbtree_find_all(&tree->root_sentinel,
					&stack_item,
					(int(*)(void*,void*,void*)) tree->compare,
					tree, -OFS_TreeRBXS_item_FIELD_rbnode,
					NULL, NULL, &count);
				total += count;
			} else {
				node= rbtree_find_nearest(
					&tree->root_sentinel,
					&stack_item,
					(int(*)(void*,void*,void*)) tree->compare,
					tree, -OFS_TreeRBXS_item_FIELD_rbnode,
					&cmp);
				if (node && cmp == 0)
					++total;
			}
		}
		RETVAL= total;
	OUTPUT:
		RETVAL

void
get(tree, key, mode_sv= NULL)
	struct TreeRBXS *tree
	SV *key
	SV *mode_sv
	ALIAS:
		Tree::RB::XS::get_node         = 0x00
		Tree::RB::XS::get_key          = 0x01
		Tree::RB::XS::key              = 0x01
		Tree::RB::XS::FETCH            = 0x02
		Tree::RB::XS::lookup           = 0x03
		Tree::RB::XS::get              = 0x04
		Tree::RB::XS::get_node_ge      = 0x10
		Tree::RB::XS::get_key_ge       = 0x11
		Tree::RB::XS::get_node_le      = 0x20
		Tree::RB::XS::get_key_le       = 0x21
		Tree::RB::XS::get_node_gt      = 0x30
		Tree::RB::XS::get_key_gt       = 0x31
		Tree::RB::XS::get_node_lt      = 0x40
		Tree::RB::XS::get_key_lt       = 0x41
		Tree::RB::XS::get_node_last    = 0x70
		Tree::RB::XS::get_node_le_last = 0x80
		Tree::RB::XS::get_or_add       = 0x92
	INIT:
		struct TreeRBXS_item stack_item, *item;
		int mode= 0, n= 0;
	PPCODE:
		if (!SvOK(key))
			croak("Can't use undef as a key");
		// Extract the comparison enum from ix, or read it from mode_sv
		if (ix >> 4) {
			mode= (ix >> 4);
			ix &= 0xF;
			if (mode_sv)
				croak("extra get-mode argument");
		} else {
			mode= mode_sv? parse_lookup_mode(mode_sv) : GET_EQ;
			if (mode < 0)
				croak("Invalid lookup mode %s", SvPV_nolen(mode_sv));
		}
		// In "full compatibility mode", 'get' is identical to 'lookup' and depends on list context.
		// In scalar context, they both become the same as FETCH
		if (ix >= 3)
			ix= (GIMME_V == G_SCALAR || (ix == 4 && !tree->compat_list_get))? 2 : 3;
		// From here,
		//  ix = 0 : return node
		//  ix = 1 : return key
		//  ix = 2 : return value
		//  ix = 3 : return (value, node)

		// create a fake item to act as a search key
		TreeRBXS_init_tmp_item(&stack_item, tree, key, &PL_sv_undef);
		item= TreeRBXS_find_item(tree, &stack_item, mode);
		if (item) {
			if (tree->lookup_updates_recent)
				TreeRBXS_recent_insert_before(tree, item, &tree->recent);
			if (GIMME_V == G_VOID)
				n= 0;
			else if (ix <= 1) {
				if (ix == 0) { // return node
					ST(0)= sv_2mortal(TreeRBXS_wrap_item(item));
					n= 1;
				} else {       // return key
					ST(0)= sv_2mortal(TreeRBXS_item_wrap_key(item));
					n= 1;
				}
			} else if (ix == 2) { // return value
				ST(0)= item->value;
				n= 1;
			} else {              // return (value, node)
				ST(0)= item->value;
				ST(1)= sv_2mortal(TreeRBXS_wrap_item(item));
				n= 2;
			}
		} else {
			ST(0)= &PL_sv_undef;
			n= (ix == 3)? 0 : 1; // empty list, else single undef
		}
		XSRETURN(n);

void
get_all(tree, key)
	struct TreeRBXS *tree
	SV *key
	INIT:
		struct TreeRBXS_item stack_item, *item;
		rbtree_node_t *first;
		size_t count, i;
	PPCODE:
		if (!SvOK(key))
			croak("Can't use undef as a key");
		TreeRBXS_init_tmp_item(&stack_item, tree, key, &PL_sv_undef);
		if (rbtree_find_all(
			&tree->root_sentinel,
			&stack_item,
			(int(*)(void*,void*,void*)) tree->compare,
			tree, -OFS_TreeRBXS_item_FIELD_rbnode,
			&first, NULL, &count)
		) {
			EXTEND(SP, count);
			for (i= 0; i < count; i++) {
				item= GET_TreeRBXS_item_FROM_rbnode(first);
				ST(i)= item->value;
				if (tree->lookup_updates_recent)
					TreeRBXS_recent_insert_before(tree, item, &tree->recent);
				first= rbtree_node_next(first);
			}
		} else
			count= 0;
		XSRETURN(count);

IV
delete(tree, key1, key2= NULL)
	struct TreeRBXS *tree
	SV *key1
	SV *key2
	INIT:
		struct TreeRBXS_item stack_item, *item;
		rbtree_node_t *first, *last, *node;
		size_t count, i;
	CODE:
		if (!SvOK(key1))
			croak("Can't use undef as a key");
		RETVAL= 0;
		if ((item= TreeRBXS_get_magic_item(key1, 0))) {
			if (!TreeRBXS_is_member(tree, item))
				croak("Node does not belong to this tree");
		}
		else {
			TreeRBXS_init_tmp_item(&stack_item, tree, key1, &PL_sv_undef);
			if (rbtree_find_all(
				&tree->root_sentinel,
				&stack_item,
				(int(*)(void*,void*,void*)) tree->compare,
				tree, -OFS_TreeRBXS_item_FIELD_rbnode,
				&first, &last, &count)
			) {
				if (key2)
					last= NULL;
			}
			else {
				// Didn't find any matches.  But if range is given, then start deleting
				// from the node following the key
				if (key2) {
					first= last;
					last= NULL;
				}
			}
		}
		// If a range is given, and the first part of the range found a node,
		// look for the end of the range.
		if (key2 && first) {
			if ((item= TreeRBXS_get_magic_item(key2, 0))) {
				if (!TreeRBXS_is_member(tree, item))
					croak("Node does not belong to this tree");
			}
			else {
				TreeRBXS_init_tmp_item(&stack_item, tree, key2, &PL_sv_undef);
				if (rbtree_find_all(
					&tree->root_sentinel,
					&stack_item,
					(int(*)(void*,void*,void*)) tree->compare,
					tree, -OFS_TreeRBXS_item_FIELD_rbnode,
					&node, &last, NULL)
				) {
					// first..last is ready to be deleted
				} else {
					// didn't match, so 'node' holds the final element before the key
					last= node;
				}
			}
			// Ensure that first comes before last
			if (last && rbtree_node_index(first) > rbtree_node_index(last))
				last= NULL;
		}
		// Delete the nodes if constructed a successful range
		i= 0;
		if (first && last) {
			do {
				item= GET_TreeRBXS_item_FROM_rbnode(first);
				first= (first == last)? NULL : rbtree_node_next(first);
				TreeRBXS_item_detach_tree(item, tree);
				++i;
			} while (first);
		}
		RETVAL= i;
	OUTPUT:
		RETVAL

void
rekey(tree, ...)
	struct TreeRBXS *tree
	INIT:
		struct TreeRBXS_item *min_item= NULL, *max_item= NULL;
		SV *min_sv= NULL, *max_sv= NULL, *offset_sv= NULL;
		int i;
	PPCODE:
		/* Look for parameters named:
			offset
		    min
		    max
		*/
		for (i= 1; i < items; i++) {
			STRLEN len;
			char *opt_name= SvPV(ST(i), len);
			if (++i >= items)
				croak("Expected value for key '%s'", opt_name);
			switch (len) {
			case 3:
				switch (opt_name[1]) {
				case 'a': if (strncmp(opt_name, "max", len) == 0) { max_sv= ST(i); continue; }
				case 'i': if (strncmp(opt_name, "min", len) == 0) { min_sv= ST(i); continue; }
				}
				break;
			case 6:
				if (strncmp(opt_name, "offset", len) == 0) { offset_sv= ST(i); continue; }
			}
			croak("Unknown option '%s'", opt_name);
		}
		/* Nothing to do for an empty tree */
		if (!TreeRBXS_get_count(tree))
			goto done;
		/* Translate min/max from iterators or keys to the nearest affected nodes */
		if (min_sv) {
			min_item= TreeRBXS_get_magic_item(min_sv, 0);
			if (!min_item) {
				struct TreeRBXS_iter *it;
				if (SvROK(min_sv) && (it= TreeRBXS_get_magic_iter(min_sv, 0))) {
					min_item= it->item;
					if (!min_item) croak("Iterator for 'min' is not referencing a tree node");
				}
				else {
					struct TreeRBXS_item stack_item;
					TreeRBXS_init_tmp_item(&stack_item, tree, min_sv, &PL_sv_undef);
					min_item= TreeRBXS_find_item(tree, &stack_item, GET_GE);
				}
			}
		}
		if (max_sv) {
			max_item= TreeRBXS_get_magic_item(max_sv, 0);
			if (!max_item) {
				struct TreeRBXS_iter *it;
				if (SvROK(max_sv) && (it= TreeRBXS_get_magic_iter(max_sv, 0))) {
					max_item= it->item;
					if (!max_item) croak("Iterator for 'max' is not referencing a tree node");
				}
				else {
					struct TreeRBXS_item stack_item;
					TreeRBXS_init_tmp_item(&stack_item, tree, max_sv, &PL_sv_undef);
					max_item= TreeRBXS_find_item(tree, &stack_item, GET_LE);
				}
			}
		}
		if (offset_sv) {
			int intmode= 0, positive= 0;
			IV offset_iv;
			NV offset_nv;
			struct TreeRBXS_item *first_item= GET_TreeRBXS_item_FROM_rbnode(rbtree_node_left_leaf(TreeRBXS_get_root(tree)));
			struct TreeRBXS_item *last_item=  GET_TreeRBXS_item_FROM_rbnode(rbtree_node_right_leaf(TreeRBXS_get_root(tree)));
			struct TreeRBXS_item *edge_item;
			rbtree_node_t *boundary_node;
			rbtree_node_t* (*node_seek[2])(rbtree_node_t *)= { rbtree_node_prev, rbtree_node_next };
			/* offset can only be used for integer or floating point keys */
			if (tree->key_type == KEY_TYPE_INT) {
				intmode= 1;
				/* I could create a whole branch of UV comparisons and handling, but I don't feel like it */
				if (SvUOK(offset_sv) && SvUV(offset_sv) > IV_MAX)
					croak("Unsigned values larger than can fit in a signed IV are not supported.  Patches welcome.");
				offset_iv= SvIV(offset_sv);
				if (offset_iv == 0)
					goto done;
				else
					positive= offset_iv > 0? 1 : 0;
				/* For integers, ensure there isn't an overflow */
				if (positive) {
					IV max_key= (max_item? max_item : last_item)->keyunion.ikey;
					if (IV_MAX - offset_iv < max_key)
						croak("Integer overflow when adding this offset (%"IVdf") to the maximum key (%"IVdf")", offset_iv, max_key);
				} else {
					IV min_key= (min_item? min_item : first_item)->keyunion.ikey;
					if (IV_MIN - offset_iv > min_key)
						croak("Integer overflow when adding this offset (%"IVdf") to the maximum key (%"IVdf")", offset_iv, min_key);
				}
			}
			else if (tree->key_type == KEY_TYPE_FLOAT) {
				offset_nv= SvNV(offset_sv);
				if (offset_nv == 0.0)
					goto done;
				else
					positive= offset_nv > 0? 1 : 0;
			}
			else croak("Option 'offset' may only be used on trees with integer or floating point numeric keys");

			/* If keys are increasing, compare max modified vs. node to the right of that.
			 * If keys are decreasing, compare min modified vs. node to the left of that.
			 * To prevent redundant code, use the 'positive' flag to indicate rightward
			 * or leftward comparisons.  The 'edge_item' is the one that needs checked for
			 * collisions with its stationary neighbors, the first of thich is 'boundary_item'..
			 */
			edge_item= positive? max_item : min_item;
			if (edge_item && (boundary_node= node_seek[positive](&edge_item->rbnode))) {
				void (*node_insert[2])(rbtree_node_t *parent, rbtree_node_t *child)=
					{ rbtree_node_insert_before, rbtree_node_insert_after };
				struct TreeRBXS_item
					*boundary_item= GET_TreeRBXS_item_FROM_rbnode(boundary_node),
					*final_item= (positive? (min_item? min_item : first_item)
					                      : (max_item? max_item : last_item)),
					stack_item;
				TreeRBXS_init_tmp_item(&stack_item, tree, &PL_sv_no, &PL_sv_undef);
				while (1) {
					if (intmode) {
						IV newval= edge_item->keyunion.ikey + offset_iv;
						if (positive? (newval < boundary_item->keyunion.ikey)
						            : (newval > boundary_item->keyunion.ikey)
						) break; /* no longer overlappig boundary */
						stack_item.keyunion.ikey= newval;
					} else {
						NV newval= edge_item->keyunion.nkey + offset_nv;
						if (positive? (newval < boundary_item->keyunion.nkey)
						            : (newval > boundary_item->keyunion.nkey)
						) break; /* no longer overlappig boundary */
						stack_item.keyunion.nkey= newval;
					}
					/* There is an overlap.  Perform a prune + insert.  This can't re-use
					 * the standard insertion code for nodes because that makes assumptions
					 * that the tree is changing size, where in this case the size remains
					 * the same.  Also this code intentionally doesn't modify the 'recent'
					 * order.
					 *
					 * In the spirit of preserving order, make sure this element inserts closest
					 * to the boundary_item of any duplicates, so use rbtree_find_all to get the
					 * leftmost/rightmost match, or else the nearest node to insert under.
					 *
					 * Also, wait until the last minute to perform the prune operation so
					 * that if there is a perl exception in a compare function we don't leak
					 * the node.
					 */
					rbtree_node_t *next= node_seek[1-positive](&edge_item->rbnode);
					rbtree_node_t *search[2];
					bool found_identical= rbtree_find_all(
						&tree->root_sentinel,
						&stack_item,
						(int(*)(void*,void*,void*)) tree->compare,
						tree, -OFS_TreeRBXS_item_FIELD_rbnode,
						&search[0], &search[1], NULL);
					/* remove */
					rbtree_node_prune(&edge_item->rbnode);
					/* alter key */
					if (intmode) edge_item->keyunion.ikey= stack_item.keyunion.ikey;
					else edge_item->keyunion.nkey= stack_item.keyunion.nkey;
					if (found_identical) {
						/* insert-before leftmost, or insert-after rightmost */
						node_insert[1-positive](search[1-positive], &edge_item->rbnode);
						/* remove conflicting nodes, if not permitted */
						if (!tree->allow_duplicates) {
							rbtree_node_t *node= search[0];
							do {
								struct TreeRBXS_item *item= GET_TreeRBXS_item_FROM_rbnode(node);
								node= (node == search[1])? NULL : rbtree_node_next(node);
								if (item != edge_item)
									TreeRBXS_item_detach_tree(item, tree);
							} while (node);
							/* boundary item may have just been deleted */
							boundary_item= GET_TreeRBXS_item_FROM_rbnode(node_seek[positive](next));
						}
					}
					else if (search[0])
						rbtree_node_insert_after(search[0], &edge_item->rbnode);
					else
						rbtree_node_insert_before(search[1], &edge_item->rbnode);
					if (!next || edge_item == final_item)
						goto done;
					edge_item= GET_TreeRBXS_item_FROM_rbnode(next);
				}
				/* The loop above ends as soon as there is no more overlap, or skips to end of
				 * function when there are no more nodes to move.  The code below will continue
				 * modifying keys under the assumption that nothing collides and the tree
				 * structure remains unchanged.
				 */
				*(positive? &max_item : &min_item)= edge_item;
			}
			{
				rbtree_node_t *node= min_item? &min_item->rbnode : &first_item->rbnode;
				rbtree_node_t *end= max_item? &max_item->rbnode : &last_item->rbnode;
				while (1) {
					if (intmode)
						GET_TreeRBXS_item_FROM_rbnode(node)->keyunion.ikey += offset_iv;
					else
						GET_TreeRBXS_item_FROM_rbnode(node)->keyunion.nkey += offset_nv;
					if (node == end) break;
					node= rbtree_node_next(node);
				}
			}
		}
		else {
			/* In the future, other modes of altering keys could be available */
			croak("offset not specified");
		}
		
		done:
		XSRETURN(1); /* return self for chaining */

void
truncate_recent(tree, max_count)
	struct TreeRBXS *tree
	IV max_count
	INIT:
		struct dllist_node *cur, *next;
		struct TreeRBXS_item *item;
		bool keep= !(GIMME_V == G_VOID || GIMME_V == G_SCALAR);
		IV i, n= 0;
	PPCODE:
		if (max_count > 0 && tree->recent_count > max_count) {
			n= tree->recent_count - max_count;
			cur= tree->recent.next;
			if (keep)
				EXTEND(SP, n);
			for (i= 0; i < n && cur && cur != &tree->recent; i++) {
				item= GET_TreeRBXS_item_FROM_recent(cur);
				if (keep)
					ST(i)= sv_2mortal(TreeRBXS_wrap_item(item));
				next= cur->next;
				TreeRBXS_item_detach_tree(item, tree);
				cur= next;
			}
			if (i != n)
				croak("BUG: recent_count inconsistent with length of linked list");
		}
		if (keep) {
			XSRETURN(n);
		} else if (GIMME_V == G_SCALAR) {
			ST(0)= sv_2mortal(newSViv(n));
			XSRETURN(1);
		} else {
			XSRETURN(0);
		}

IV
clear(tree)
	struct TreeRBXS *tree
	ALIAS:
		Tree::RB::XS::CLEAR = 1
	CODE:
		(void) ix; /* unused */
		RETVAL= TreeRBXS_get_count(tree);
		TreeRBXS_clear(tree);
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
min_node(tree)
	struct TreeRBXS *tree
	INIT:
		rbtree_node_t *node= rbtree_node_left_leaf(TreeRBXS_get_root(tree));
	CODE:
		RETVAL= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
max_node(tree)
	struct TreeRBXS *tree
	INIT:
		rbtree_node_t *node= rbtree_node_right_leaf(TreeRBXS_get_root(tree));
	CODE:
		RETVAL= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
nth_node(tree, ofs)
	struct TreeRBXS *tree
	IV ofs
	INIT:
		rbtree_node_t *node;
	CODE:
		if (ofs < 0) ofs += TreeRBXS_get_count(tree);
		node= rbtree_node_child_at_index(TreeRBXS_get_root(tree), ofs);
		RETVAL= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
root_node(tree)
	struct TreeRBXS *tree
	CODE:
		RETVAL= !TreeRBXS_get_count(tree)? NULL
			: GET_TreeRBXS_item_FROM_rbnode(TreeRBXS_get_root(tree));
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
oldest_node(tree, newval= NULL)
	struct TreeRBXS *tree
	struct TreeRBXS_item *newval
	CODE:
		if (newval) {
			if (!TreeRBXS_is_member(tree, newval))
				croak("Node does not belong to this tree");
			TreeRBXS_recent_insert_before(tree, newval, tree->recent.next);
		}
		RETVAL= tree->recent.next == &tree->recent? NULL
			: GET_TreeRBXS_item_FROM_recent(tree->recent.next);
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
newest_node(tree, newval= NULL)
	struct TreeRBXS *tree
	struct TreeRBXS_item *newval
	CODE:
		if (newval) {
			if (!TreeRBXS_is_member(tree, newval))
				croak("Node does not belong to this tree");
			TreeRBXS_recent_insert_before(tree, newval, &tree->recent);
		}
		RETVAL= tree->recent.prev == &tree->recent? NULL
			: GET_TreeRBXS_item_FROM_recent(tree->recent.prev);
	OUTPUT:
		RETVAL

void
keys(tree)
	struct TreeRBXS *tree
	ALIAS:
		Tree::RB::XS::values             = 1
		Tree::RB::XS::kv                 = 2
		Tree::RB::XS::reverse_keys       = 4
		Tree::RB::XS::reverse_values     = 5
		Tree::RB::XS::reverse_kv         = 6
	INIT:
		size_t n_ret, i, node_count= TreeRBXS_get_count(tree);
		rbtree_node_t *node;
		rbtree_node_t *(*start)(rbtree_node_t *)= (ix & 4)? rbtree_node_right_leaf : rbtree_node_left_leaf;
		rbtree_node_t *(*step)(rbtree_node_t *)= (ix & 4)? rbtree_node_prev : rbtree_node_next;
	PPCODE:
		if (GIMME_V == G_VOID) {
			n_ret= 0;
		}
		else if (GIMME_V == G_SCALAR) {
			n_ret= 1;
			ST(0)= sv_2mortal(newSViv(node_count));
		}
		else {
			n_ret= ix == 2? node_count*2 : node_count;
			EXTEND(SP, n_ret);
			node= start(TreeRBXS_get_root(tree));
			if ((ix & 3) == 0) {
				for (i= 0; i < n_ret && node; i++, node= step(node))
					ST(i)= sv_2mortal(TreeRBXS_item_wrap_key(GET_TreeRBXS_item_FROM_rbnode(node)));
			}
			else if ((ix & 3) == 1) {
				for (i= 0; i < n_ret && node; i++, node= step(node))
					ST(i)= GET_TreeRBXS_item_FROM_rbnode(node)->value;
			}
			else {
				for (i= 0; i < n_ret && node; node= step(node)) {
					ST(i)= sv_2mortal(TreeRBXS_item_wrap_key(GET_TreeRBXS_item_FROM_rbnode(node)));
					i++;
					ST(i)= GET_TreeRBXS_item_FROM_rbnode(node)->value;
					i++;
				}
			}
			if (i != n_ret || node != NULL)
				croak("BUG: expected %ld nodes but found %ld", (long) (n_ret>>1), (long) ((ix & 3) == 2? i : (i>>1)));
		}
		XSRETURN(n_ret);

SV *
FIRSTKEY(tree)
	struct TreeRBXS *tree
	INIT:
		struct TreeRBXS_iter *iter= TreeRBXS_get_hashiter(tree);
	CODE:
		if (tree->hashiterset)
			tree->hashiterset= false; // iter has 'hseek' applied, don't change it
		else
			TreeRBXS_iter_rewind(iter);
		RETVAL= TreeRBXS_item_wrap_key(iter->item); // handles null by returning undef
	OUTPUT:
		RETVAL

SV *
NEXTKEY(tree, lastkey)
	struct TreeRBXS *tree
	SV *lastkey
	INIT:
		struct TreeRBXS_iter *iter= TreeRBXS_get_hashiter(tree);
	CODE:
		if (tree->hashiterset)
			tree->hashiterset= false; // iter has 'hseek' applied, don't change it
		else
			TreeRBXS_iter_advance(iter, 1);
		RETVAL= TreeRBXS_item_wrap_key(iter->item);
		(void)lastkey;
	OUTPUT:
		RETVAL

void
_set_hashiter(tree, item_sv, reverse)
	struct TreeRBXS *tree
	SV *item_sv
	bool reverse
	INIT:
		struct TreeRBXS_item *item= TreeRBXS_get_magic_item(item_sv, 0);
		struct TreeRBXS_iter *iter= TreeRBXS_get_hashiter(tree);
	PPCODE:
		if (item && (TreeRBXS_item_get_tree(item) != tree))
			croak("Node is not part of this tree");
		iter->reverse= reverse;
		TreeRBXS_iter_set_item(iter, item);
		if (!item) TreeRBXS_iter_rewind(iter);
		tree->hashiterset= true;
		XSRETURN(0);

SV *
SCALAR(tree)
	struct TreeRBXS *tree
	CODE:
		RETVAL= newSViv(TreeRBXS_get_count(tree));
	OUTPUT:
		RETVAL

void
DELETE(tree, key)
	struct TreeRBXS *tree
	SV *key
	INIT:
		struct TreeRBXS_item stack_item, *item;
		rbtree_node_t *first, *last;
	PPCODE:
		if (!SvOK(key))
			croak("Can't use undef as a key");
		TreeRBXS_init_tmp_item(&stack_item, tree, key, &PL_sv_undef);
		if (rbtree_find_all(
			&tree->root_sentinel,
			&stack_item,
			(int(*)(void*,void*,void*)) tree->compare,
			tree, -OFS_TreeRBXS_item_FIELD_rbnode,
			&first, &last, NULL)
		) {
			ST(0)= sv_2mortal(SvREFCNT_inc(GET_TreeRBXS_item_FROM_rbnode(first)->value));
			do {
				item= GET_TreeRBXS_item_FROM_rbnode(first);
				first= (first == last)? NULL : rbtree_node_next(first);
				TreeRBXS_item_detach_tree(item, tree);
			} while (first);
		} else {
			ST(0)= &PL_sv_undef;
		}
		XSRETURN(1);

IV
cmp_numsplit(key_a, key_b)
	SV *key_a
	SV *key_b
	INIT:
		const char *apos, *bpos;
		STRLEN alen, blen;
		bool a_utf8= false, b_utf8= false;
	CODE:
#if PERL_VERSION_LT(5,14,0)
		// before 5.14, need to force both to utf8 if either are utf8
		if (SvUTF8(key_a) || SvUTF8(key_b)) {
			apos= SvPVutf8(key_a, alen);
			bpos= SvPVutf8(key_b, blen);
			a_utf8= b_utf8= true;
		} else
#else
		// After 5.14, can compare utf8 with bytes without converting the buffer
		a_utf8= SvUTF8(key_a);
		b_utf8= SvUTF8(key_b);
#endif		
		{
			apos= SvPV(key_a, alen);
			bpos= SvPV(key_b, blen);
		}
		RETVAL= cmp_numsplit(apos, apos+alen, a_utf8, bpos, bpos+blen, b_utf8);
	OUTPUT:
		RETVAL

#-----------------------------------------------------------------------------
#  Node Methods
#

MODULE = Tree::RB::XS              PACKAGE = Tree::RB::XS::Node

SV *
key(item)
	struct TreeRBXS_item *item
	CODE:
		RETVAL= TreeRBXS_item_wrap_key(item);
	OUTPUT:
		RETVAL

SV *
value(item, newval=NULL)
	struct TreeRBXS_item *item
	SV *newval;
	CODE:
		if (newval)
			sv_setsv(item->value, newval);
		RETVAL= SvREFCNT_inc_simple_NN(item->value);
	OUTPUT:
		RETVAL

IV
index(item)
	struct TreeRBXS_item *item
	CODE:
		RETVAL= rbtree_node_index(&item->rbnode);
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
prev(item)
	struct TreeRBXS_item *item
	INIT:
		rbtree_node_t *node= rbtree_node_prev(&item->rbnode);
	CODE:
		RETVAL= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
next(item)
	struct TreeRBXS_item *item
	INIT:
		rbtree_node_t *node= rbtree_node_next(&item->rbnode);
	CODE:
		RETVAL= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
newer(item, newval=NULL)
	struct TreeRBXS_item *item
	struct TreeRBXS_item *newval
	INIT:
		struct TreeRBXS *tree= TreeRBXS_item_get_tree(item);
		struct dllist_node *next= item->recent.next;
	CODE:
		if (newval) {
			if (!next)
				croak("Can't insert relative to a node that isn't recent_tracked");
			if (!tree) croak("Node was removed from tree");
			TreeRBXS_recent_insert_before(tree, newval, next);
			next= &newval->recent;
		}
		RETVAL= (!next || !tree || next == &tree->recent)? NULL
			: GET_TreeRBXS_item_FROM_recent(next);
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
older(item, newval=NULL)
	struct TreeRBXS_item *item
	struct TreeRBXS_item *newval
	INIT:
		struct TreeRBXS *tree= TreeRBXS_item_get_tree(item);
		struct dllist_node *prev= item->recent.prev;
	CODE:
		if (newval) {
			if (!prev)
				croak("Can't insert relative to a node that isn't recent_tracked");
			if (!tree) croak("Node was removed from tree");
			TreeRBXS_recent_insert_before(tree, newval, &item->recent);
			prev= &newval->recent;
		}
		RETVAL= (!prev || !tree || prev == &tree->recent)? NULL
			: GET_TreeRBXS_item_FROM_recent(prev);
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
parent(item)
	struct TreeRBXS_item *item
	CODE:
		RETVAL= rbtree_node_is_in_tree(&item->rbnode) && item->rbnode.parent->count?
			GET_TreeRBXS_item_FROM_rbnode(item->rbnode.parent) : NULL;
	OUTPUT:
		RETVAL

void
tree(item)
	struct TreeRBXS_item *item
	INIT:
		struct TreeRBXS *tree= TreeRBXS_item_get_tree(item);
	PPCODE:
		ST(0)= tree && tree->owner? sv_2mortal(newRV_inc(tree->owner)) : &PL_sv_undef;
		XSRETURN(1);

struct TreeRBXS_item *
left(item)
	struct TreeRBXS_item *item
	CODE:
		RETVAL= rbtree_node_is_in_tree(&item->rbnode) && item->rbnode.left->count?
			GET_TreeRBXS_item_FROM_rbnode(item->rbnode.left) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
right(item)
	struct TreeRBXS_item *item
	CODE:
		RETVAL= rbtree_node_is_in_tree(&item->rbnode) && item->rbnode.right->count?
			GET_TreeRBXS_item_FROM_rbnode(item->rbnode.right) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
left_leaf(item)
	struct TreeRBXS_item *item
	INIT:
		rbtree_node_t *node= rbtree_node_left_leaf(&item->rbnode);
	CODE:
		RETVAL= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
right_leaf(item)
	struct TreeRBXS_item *item
	INIT:
		rbtree_node_t *node= rbtree_node_right_leaf(&item->rbnode);
	CODE:
		RETVAL= node? GET_TreeRBXS_item_FROM_rbnode(node) : NULL;
	OUTPUT:
		RETVAL

IV
color(item)
	struct TreeRBXS_item *item
	CODE:
		RETVAL= item->rbnode.color;
	OUTPUT:
		RETVAL

IV
count(item)
	struct TreeRBXS_item *item
	CODE:
		RETVAL= item->rbnode.count;
	OUTPUT:
		RETVAL

IV
prune(item)
	struct TreeRBXS_item *item
	INIT:
		struct TreeRBXS *tree= TreeRBXS_item_get_tree(item);
	CODE:
		RETVAL= 0;
		if (tree) {
			TreeRBXS_item_detach_tree(item, tree);
			RETVAL= 1;
		}
	OUTPUT:
		RETVAL

void
recent_tracked(item, newval=NULL)
	struct TreeRBXS_item *item
	SV* newval
	INIT:
		struct TreeRBXS *tree;
	PPCODE:
		if (items > 1) {
			tree= TreeRBXS_item_get_tree(item);
			if (!tree) croak("Node was removed from tree");
			if (SvTRUE(newval))
				TreeRBXS_recent_insert_before(tree, item, &tree->recent);
			else
				TreeRBXS_recent_prune(tree, item);
			// ST(0) is $self, so let it be the return value
		} else {
			ST(0)= sv_2mortal(newSViv(item->recent.next? 1 : 0));
		}
		XSRETURN(1);

void
mark_newest(item)
	struct TreeRBXS_item *item
	INIT:
		struct TreeRBXS *tree= TreeRBXS_item_get_tree(item);
	PPCODE:
		if (!tree) croak("Node was removed from tree");
		TreeRBXS_recent_insert_before(tree, item, &tree->recent);
		XSRETURN(1);

void
mark_oldest(item)
	struct TreeRBXS_item *item
	INIT:
		struct TreeRBXS *tree= TreeRBXS_item_get_tree(item);
	PPCODE:
		if (!tree) croak("Node was removed from tree");
		TreeRBXS_recent_insert_before(tree, item, tree->recent.next);
		XSRETURN(1);

void
STORABLE_freeze(item, cloning)
	struct TreeRBXS_item *item
	bool cloning
	INIT:
		struct TreeRBXS *tree= TreeRBXS_item_get_tree(item);
		AV *av;
	PPCODE:
		(void) cloning; /* unused */
		if (tree) {
			ST(0)= sv_2mortal(newSViv(rbtree_node_index(&item->rbnode)));
			ST(1)= sv_2mortal(newRV_inc(tree->owner));
		} else {
			ST(0)= sv_2mortal(newSViv(-1));
			ST(1)= sv_2mortal(newRV_noinc((SV*)(av= newAV())));
			av_push(av, TreeRBXS_item_wrap_key(item));
			av_push(av, SvREFCNT_inc(item->value));
		}
		XSRETURN(2);

void
STORABLE_thaw(item_sv, cloning, idx, refs)
	SV *item_sv
	bool cloning
	IV idx
	SV *refs
	INIT:
		struct TreeRBXS *tree;
		struct TreeRBXS_item *item;
		rbtree_node_t *node;
		MAGIC *magic;
	PPCODE:
		(void) cloning; /* unused */
		if (idx == -1) {
			IV n;
			SV **svec= unwrap_array(refs, &n);
			if (!svec || n != 2 || !svec[0] || !svec[1])
				croak("Expected arrayref of (key,value)");
			Newx(item, 1, struct TreeRBXS_item);
			memset(item, 0, sizeof(*item));
			item->key_type= KEY_TYPE_ANY;
			item->keyunion.svkey= SvREFCNT_inc(svec[0]);
			item->value= SvREFCNT_inc(svec[1]);
		} else {
			tree= TreeRBXS_get_magic_tree(refs, OR_DIE);
			if (!(node= rbtree_node_child_at_index(TreeRBXS_get_root(tree), idx)))
				croak("Tree does not have element %ld", (long) idx);
			item= GET_TreeRBXS_item_FROM_rbnode(node);
			if (item->owner) {
				if (item->owner != SvRV(item_sv))
					croak("BUG: Storable deserialized tree node multiple times");
				return;
			}
		}
		item->owner= SvRV(item_sv);
		magic= sv_magicext(item->owner, NULL, PERL_MAGIC_ext, &TreeRBXS_item_magic_vt, (const char*) item, 0);
		#ifdef USE_ITHREADS
		magic->mg_flags |= MGf_DUP;
		#else
		(void)magic; // suppress warning
		#endif
		XSRETURN(0);

#-----------------------------------------------------------------------------
#  Iterator methods
#

MODULE = Tree::RB::XS              PACKAGE = Tree::RB::XS::Iter

void
_init(iter_sv, target, direction= 1)
	SV *iter_sv
	SV *target
	IV direction
	INIT:
		struct TreeRBXS_iter *iter2, *iter= TreeRBXS_get_magic_iter(iter_sv, AUTOCREATE|OR_DIE);
		struct TreeRBXS *tree;
		struct TreeRBXS_item *item= NULL;
		rbtree_node_t *node= NULL;
		struct dllist_node *lnode;
	PPCODE:
		if (iter->item || iter->tree)
			croak("Iterator is already initialized");
		switch (direction) {
		case -2: iter->recent= 1; iter->reverse= 1; break;
		case -1: iter->recent= 0; iter->reverse= 1; break;
		case  1: iter->recent= 0; iter->reverse= 0; break;
		case  2: iter->recent= 1; iter->reverse= 0; break;
		default: croak("Invalid direction code");
		}

		// target can be a tree, a node, or another iterator
		if ((iter2= TreeRBXS_get_magic_iter(target, 0))) {
			// use this direction unless overridden
			if (items < 2) {
				iter->reverse= iter2->reverse;
				iter->recent=  iter2->recent;
			}
			tree= iter2->tree;
			item= iter2->item;
		}
		else if ((item= TreeRBXS_get_magic_item(target, 0))) {
			tree= TreeRBXS_item_get_tree(item);
		}
		else if ((tree= TreeRBXS_get_magic_tree(target, 0))) {
			if (iter->recent) {
				lnode= iter->reverse? tree->recent.prev : tree->recent.next;
				item= (lnode == &tree->recent)? NULL
					: GET_TreeRBXS_item_FROM_recent(lnode);
			}
			else {
				node= !TreeRBXS_get_count(tree)? NULL
					: iter->reverse? rbtree_node_right_leaf(TreeRBXS_get_root(tree))
					: rbtree_node_left_leaf(TreeRBXS_get_root(tree));
				if (node)
					item= GET_TreeRBXS_item_FROM_rbnode(node);
			}
		}
		if (!tree)
			croak("Can't iterate a node that isn't in the tree");
		if (iter->recent && item && !item->recent.next)
			croak("Can't perform insertion-order iteration on a node that isn't tracked");
		iter->tree= tree;
		if (tree->owner)
			SvREFCNT_inc(tree->owner);
		TreeRBXS_iter_set_item(iter, item);
		ST(0)= iter_sv;
		XSRETURN(1);

SV *
key(iter)
	struct TreeRBXS_iter *iter
	CODE:
		// wrap_key handles NULL items
		RETVAL= TreeRBXS_item_wrap_key(iter->item);
	OUTPUT:
		RETVAL

SV *
value(iter)
	struct TreeRBXS_iter *iter
	CODE:
		RETVAL= iter->item? SvREFCNT_inc_simple_NN(iter->item->value) : &PL_sv_undef;
	OUTPUT:
		RETVAL

struct TreeRBXS_item *
node(iter)
	struct TreeRBXS_iter *iter
	CODE:
		RETVAL= iter->item;
	OUTPUT:
		RETVAL

SV *
index(iter)
	struct TreeRBXS_iter *iter
	CODE:
		RETVAL= !iter->item || !rbtree_node_is_in_tree(&iter->item->rbnode)? &PL_sv_undef
			: newSViv(rbtree_node_index(&iter->item->rbnode));
	OUTPUT:
		RETVAL

SV *
tree(iter)
	struct TreeRBXS_iter *iter
	CODE:
		RETVAL= iter->tree && iter->tree->owner? newRV_inc(iter->tree->owner) : &PL_sv_undef;
	OUTPUT:
		RETVAL

bool
done(iter)
	struct TreeRBXS_iter *iter
	CODE:
		RETVAL= !iter->item;
	OUTPUT:
		RETVAL

void
next(iter, count_sv= NULL)
	struct TreeRBXS_iter *iter
	SV* count_sv
	ALIAS:
		Tree::RB::XS::Iter::next         = 0
		Tree::RB::XS::Iter::next_key     = 1
		Tree::RB::XS::Iter::next_keys    = 1
		Tree::RB::XS::Iter::next_value   = 2
		Tree::RB::XS::Iter::next_values  = 2
		Tree::RB::XS::Iter::next_kv      = 3
	INIT:
		size_t pos, n, nret, i, max_count= iter->recent? iter->tree->recent_count : TreeRBXS_get_count(iter->tree);
		IV request;
		rbtree_node_t *node;
		rbtree_node_t *(*step)(rbtree_node_t *)= iter->reverse? &rbtree_node_prev : rbtree_node_next;
	PPCODE:
		if (iter->item) {
			request= !count_sv? 1
				: ((SvPOK(count_sv) && *SvPV_nolen(count_sv) == '*')
					|| (SvNOK(count_sv) && SvNV(count_sv) > (NV)PERL_INT_MAX))? max_count
				: SvIV(count_sv);
			if (request < 1) {
				nret= 0;
			}
			// A request for 1 is simpler because there is no need to count how many will be returned.
			// iter->item wasn't NULL so it is guaranteed to be 1.
			else if (GIMME_V == G_VOID) {
				// skip all the busywork if called in void context
				// (but still advance the iterator below)
				TreeRBXS_iter_advance(iter, request);
				nret= 0;
			}
			else if (request == 1 || iter->recent) { // un-optimized loop
				nret= ix == 3? request<<1 : request;
				EXTEND(SP, nret);
				for (i= 0; i < nret && iter->item; ) {
					ST(i++)= ix == 0? sv_2mortal(TreeRBXS_wrap_item(iter->item))
						: ix == 2? iter->item->value
						: sv_2mortal(TreeRBXS_item_wrap_key(iter->item));
					if (ix == 3)
						ST(i++)= iter->item->value;
					TreeRBXS_iter_advance(iter, 1);
				}
				nret= i;
			}
			else { // optimized loop, for iterating batches of tree nodes quickly
				pos= rbtree_node_index(&iter->item->rbnode);
				// calculate how many nodes will be returned
				n= iter->reverse? 1 + pos : max_count - pos;
				if (n > request) n= request;
				node= &iter->item->rbnode;
				nret= (ix == 3)? n<<1 : n;
				EXTEND(SP, nret); // EXTEND macro declares a temp 'ix' internally - GitHub #2
				if (ix == 0) {
					for (i= 0; i < nret && node; i++, node= step(node))
						ST(i)= sv_2mortal(TreeRBXS_wrap_item(GET_TreeRBXS_item_FROM_rbnode(node)));
				}
				else if (ix == 1) {
					for (i= 0; i < nret && node; i++, node= step(node))
						ST(i)= sv_2mortal(TreeRBXS_item_wrap_key(GET_TreeRBXS_item_FROM_rbnode(node)));
				}
				else if (ix == 2) {
					for (i= 0; i < nret && node; i++, node= step(node))
						ST(i)= GET_TreeRBXS_item_FROM_rbnode(node)->value;
				}
				else {
					for (i= 0; i < nret && node; node= step(node)) {
						ST(i)= sv_2mortal(TreeRBXS_item_wrap_key(GET_TreeRBXS_item_FROM_rbnode(node)));
						i++;
						ST(i)= GET_TreeRBXS_item_FROM_rbnode(node)->value;
						i++;
					}
				}
				if (i != nret)
					croak("BUG: expected %ld nodes but found %ld", (long) n, (long) (ix == 3? i>>1 : i));
				TreeRBXS_iter_advance(iter, n);
			}
			XSRETURN(nret);
		} else {
			// end of iteration, nothing to do
			ST(0)= &PL_sv_undef;
			// return the undef only if the user didn't specify a count
			XSRETURN(count_sv? 0 : 1);
		}

bool
step(iter, ofs= 1)
	struct TreeRBXS_iter *iter
	IV ofs
	CODE:
		TreeRBXS_iter_advance(iter, ofs);
		// Return boolean whether the iterator points to an item
		RETVAL= !!iter->item;
	OUTPUT:
		RETVAL

void
delete(iter)
	struct TreeRBXS_iter *iter
	PPCODE:
		if (iter->item) {
			// up the refcnt temporarily to make sure it doesn't get lost when item gets freed
			ST(0)= sv_2mortal(SvREFCNT_inc(iter->item->value));
			// pruning the item automatically moves iterators to next, including this iterator.
			TreeRBXS_item_detach_tree(iter->item, iter->tree);
		}
		else
			ST(0)= &PL_sv_undef;
		XSRETURN(1);

void
STORABLE_freeze(iter, cloning)
	struct TreeRBXS_iter *iter
	bool cloning
	INIT:
		char itertype= (iter->reverse? 1 : 0) | (iter->recent? 2 : 0);
		AV *refs;
	PPCODE:
		(void) cloning; /* unused */
		ST(0)= sv_2mortal(newSVpvn(&itertype, 1));
		ST(1)= sv_2mortal(newRV_noinc((SV*) (refs= newAV())));
		av_push(refs, newRV_inc(iter->tree->owner));
		av_push(refs, iter->item? newSViv(rbtree_node_index(&iter->item->rbnode)) : newSV(0));
		XSRETURN(2);

#-----------------------------------------------------------------------------
#  Constants
#

BOOT:
	HV *stash= gv_stashpvn("Tree::RB::XS::Node", 18, 1);
	FUNCTION_IS_LVALUE(value);
	
	stash= gv_stashpvn("Tree::RB::XS", 12, 1);
	FUNCTION_IS_LVALUE(get);
	FUNCTION_IS_LVALUE(get_or_add);
	FUNCTION_IS_LVALUE(FETCH);
	FUNCTION_IS_LVALUE(lookup);
	EXPORT_ENUM(KEY_TYPE_ANY);
	EXPORT_ENUM(KEY_TYPE_INT);
	EXPORT_ENUM(KEY_TYPE_FLOAT);
	EXPORT_ENUM(KEY_TYPE_USTR);
	EXPORT_ENUM(KEY_TYPE_BSTR);
	EXPORT_ENUM(KEY_TYPE_CLAIM);
	EXPORT_ENUM(CMP_PERL);
	EXPORT_ENUM(CMP_INT);
	EXPORT_ENUM(CMP_FLOAT);
	EXPORT_ENUM(CMP_STR);
	EXPORT_ENUM(CMP_FOLDCASE);
	EXPORT_ENUM(CMP_MEMCMP);
	EXPORT_ENUM(CMP_NUMSPLIT);
	EXPORT_ENUM(CMP_NUMSPLIT_FOLDCASE);
	EXPORT_ENUM(GET_EQ);
	EXPORT_ENUM(GET_OR_ADD);
	EXPORT_ENUM(GET_EQ_LAST);
	EXPORT_ENUM(GET_GE);
	EXPORT_ENUM(GET_LE);
	EXPORT_ENUM(GET_LE_LAST);
	EXPORT_ENUM(GET_GT);
	EXPORT_ENUM(GET_LT);
	EXPORT_ENUM(GET_NEXT);
	EXPORT_ENUM(GET_PREV);

PROTOTYPES: DISABLE

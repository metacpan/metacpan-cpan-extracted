/* C++ headers before Perl to avoid macro conflicts (do_open/do_close vs <locale>) */
#include <pugixml.hpp>

/* Hard floor: the binding references format_no_empty_element_tags, added in
   pugixml 1.8 (PUGIXML_VERSION 180). Fail the build with a clear message rather
   than a cryptic C++ error if compiled against an older header (e.g. a system
   lib whose pkg-config over-reported its version). ensure_child / ensure_attr
   transparently emulate the 1.16 API below 1160. */
#if PUGIXML_VERSION < 180
#  error "XML::PugiXML requires pugixml >= 1.8 (format_no_empty_element_tags)"
#endif

#include <sstream>
#include <string>
#include <vector>
#include <cerrno>
#include <cstring>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

using namespace pugi;

/* A const char* whose typemap rejects an embedded NUL byte. Plain const char*
   args use SvPV_nolen and would silently truncate a name/value at the first
   NUL (storing a different string than was passed); NUL is invalid in XML 1.0
   anyway. Used for the string arguments of the tree-mutation methods. */
typedef const char* nul_safe_pv;

/* SvPV with an embedded-NUL guard, used by the nul_safe_pv typemap. Keep it a
   function (not inline typemap code): an inline INPUT block with a quoted
   croak() breaks ExtUtils::ParseXS template interpolation on some versions
   (the '"' ends the interpolated string), which mis-emits the argument and
   then crashes pugixml on a NULL. The typemap INPUT just calls this. */
static const char* ng_check_nul(pTHX_ SV* sv) {
    STRLEN len;
    const char* p = SvPV(sv, len);
    if (strlen(p) != len)
        croak("XML::PugiXML: string argument contains an embedded NUL byte (invalid in XML)");
    return p;
}

/* Compiled XPath wrapper */
struct PugiXPath {
    xpath_query* query;
};

/* Wrapper structures.

   A handle is invalidated by either of two independent mechanisms:

   * generation -- bumped by reset()/load_file()/load_string(), which replace
     the whole tree at once. Each wrapper snapshots it at creation.
   * the `dead` flag -- set by remove_child()/remove_attr() on exactly those
     wrappers that point into the removed subtree. pugixml's remove_* really
     do free the storage (destroy_tree -> deallocate_memory; a fully-freed
     non-top page is handed back to the system with free()), so a surviving
     Perl handle into a removed subtree is a dangling pointer rather than a
     harmless orphan. Finding those wrappers needs a registry.

   The registry is a per-document hash index keyed by the pugixml pointer each
   wrapper holds, with the chain links stored inside the wrapper (no per-entry
   allocation). Keying it that way is what keeps removal cheap: invalidation
   walks the subtree being destroyed and probes the index for each node and
   attribute in it, so it costs O(removed subtree) -- the same order pugixml
   already pays in destroy_tree -- rather than O(live handles). A flat list
   would instead make the ordinary idiom

       $root->remove_child($_) for $root->children;

   quadratic, because every removal would rescan every retained handle.

   Note the index is probed by pointer VALUE and never dereferences a stored
   pugixml pointer, so entries left behind by a reset/reload (whose pointers
   dangle) are safe to walk past; the gen_snap guard skips them anyway.

   `owner` is NULL once the document wrapper itself has been destroyed. That
   happens during global destruction, where perl calls DESTROY in arbitrary
   order and may free the document before its nodes; the document's DESTROY
   detaches every live wrapper so their DESTROY never dereferences it. */

struct PugiNode;
struct PugiAttr;

struct PugiDoc {
    xml_document* doc;
    unsigned int generation;  /* Incremented on reset/load to detect stale handles */
    PugiNode** node_buckets;  /* Hash index of live node wrappers */
    size_t node_nbuckets;     /* Always a power of two, never 0 after new() */
    size_t node_count;
    PugiAttr** attr_buckets;  /* Hash index of live attribute wrappers */
    size_t attr_nbuckets;
    size_t attr_count;
};

/* hnext/hprev are the intrusive hash chain. hprev is the address of the link
   pointing AT this wrapper (a bucket slot, or the previous entry's hnext),
   which makes unlinking O(1) without a back-pointer to the entry itself. */
struct PugiNode {
    xml_node node;
    SV* doc_sv;              /* Reference to document to keep it alive */
    PugiDoc* owner;          /* NULL once the document has been destroyed */
    unsigned int gen_snap;   /* owner->generation at creation time */
    bool dead;               /* Removed from the tree: storage is gone */
    PugiNode*  hnext;
    PugiNode** hprev;
};

struct PugiAttr {
    xml_attribute attr;
    xml_node parent_node;    /* Element owning this attribute */
    SV* doc_sv;              /* Reference to document to keep it alive */
    PugiDoc* owner;          /* NULL once the document has been destroyed */
    unsigned int gen_snap;   /* owner->generation at creation time */
    bool dead;               /* Removed from its element: storage is gone */
    PugiAttr*  hnext;
    PugiAttr** hprev;
};

typedef PugiDoc*   XML__PugiXML;
typedef PugiNode*  XML__PugiXML__Node;
typedef PugiAttr*  XML__PugiXML__Attr;
typedef PugiXPath* XML__PugiXML__XPath;


/* True once the whole tree the handle was taken from has been replaced. */
#define HANDLE_STALE(self) \
    (!(self)->owner || (self)->gen_snap != (self)->owner->generation)

#define CHECK_NODE_ALIVE(self) STMT_START { \
    if (HANDLE_STALE(self)) \
        croak("Stale node handle: document has been reset or reloaded"); \
    if ((self)->dead) \
        croak("Stale node handle: node has been removed from the document"); \
} STMT_END

#define CHECK_ATTR_ALIVE(self) STMT_START { \
    if (HANDLE_STALE(self)) \
        croak("Stale attribute handle: document has been reset or reloaded"); \
    if ((self)->dead) \
        croak("Stale attribute handle: attribute has been removed from its element"); \
} STMT_END

/* Two handles share a document iff they name the same PugiDoc. insert_child_*
   / remove_child require the ref/child argument to live in the same document
   as self; pugixml otherwise silently returns a null node. Only used after
   CHECK_*_ALIVE, so neither owner is NULL. */
#define CHECK_SAME_DOC(a, b) \
    if ((a)->owner != (b)->owner) \
        croak("Node belongs to a different document")

/* croak() longjmps out of a catch block, skipping __cxa_end_catch and leaking
   the caught C++ exception object (kept reachable on the EH chain, ~150 bytes
   each) on every caught exception. So stash the message in the catch and croak
   only AFTER it has unwound. XPATH_GUARDED opens the guarded block;
   END_XPATH_GUARDED closes it with the standard XPath-error handlers. */
#define XPATH_GUARDED char xpath_err[256]; xpath_err[0] = '\0'; try
#define END_XPATH_GUARDED \
    catch (const xpath_exception& e) { snprintf(xpath_err, sizeof(xpath_err), "XPath error: %s", e.what()); } \
    catch (const std::exception& e)  { snprintf(xpath_err, sizeof(xpath_err), "Internal XPath error: %s", e.what()); } \
    if (xpath_err[0]) croak("%s", xpath_err)

/* Helper functions */

/* --- Hash index of live wrappers -------------------------------------- */

#define PUGI_HIDX_MIN 16   /* initial bucket count, power of two */

static size_t ptr_hash(const void* p) {
    size_t x = (size_t)p;
    x >>= 4;                 /* pugixml structs are at least 16-byte aligned */
    x ^= x >> 16;
    return x;
}

/* Both wrapper types expose the same hnext/hprev members, so one set of
   templates serves both indexes. */

static const void* wrapper_key(PugiNode* n) { return n->node.internal_object(); }
static const void* wrapper_key(PugiAttr* a) { return a->attr.internal_object(); }

template <typename W>
static void hidx_insert(W** buckets, size_t nbuckets, W* w, const void* key) {
    W** head = &buckets[ptr_hash(key) & (nbuckets - 1)];
    w->hnext = *head;
    if (*head) (*head)->hprev = &w->hnext;
    w->hprev = head;
    *head = w;
}

template <typename W>
static void hidx_erase(W* w) {
    if (!w->hprev) return;
    *(w->hprev) = w->hnext;
    if (w->hnext) w->hnext->hprev = w->hprev;
    w->hnext = NULL;
    w->hprev = NULL;
}

/* Double the table. Best-effort: on allocation failure the old table stays
   valid and simply carries longer chains, so this never has to fail loudly. */
template <typename W>
static void hidx_grow(W*** pbuckets, size_t* pnbuckets) {
    size_t newn = *pnbuckets * 2;
    W** nb = (W**)calloc(newn, sizeof(W*));
    if (!nb) return;
    for (size_t i = 0; i < *pnbuckets; i++)
        for (W* w = (*pbuckets)[i]; w; ) {
            W* next = w->hnext;
            hidx_insert(nb, newn, w, wrapper_key(w));
            w = next;
        }
    free(*pbuckets);
    *pbuckets = nb;
    *pnbuckets = newn;
}

static void doc_register_node(PugiDoc* doc, PugiNode* n) {
    if (doc->node_count + 1 > doc->node_nbuckets)
        hidx_grow(&doc->node_buckets, &doc->node_nbuckets);
    n->owner = doc;
    hidx_insert(doc->node_buckets, doc->node_nbuckets, n, n->node.internal_object());
    doc->node_count++;
}

static void doc_unregister_node(PugiNode* n) {
    if (!n->owner) return;   /* document already destroyed, index is gone */
    hidx_erase(n);
    n->owner->node_count--;
    n->owner = NULL;
}

static void doc_register_attr(PugiDoc* doc, PugiAttr* a) {
    if (doc->attr_count + 1 > doc->attr_nbuckets)
        hidx_grow(&doc->attr_buckets, &doc->attr_nbuckets);
    a->owner = doc;
    hidx_insert(doc->attr_buckets, doc->attr_nbuckets, a, a->attr.internal_object());
    doc->attr_count++;
}

static void doc_unregister_attr(PugiAttr* a) {
    if (!a->owner) return;
    hidx_erase(a);
    a->owner->attr_count--;
    a->owner = NULL;
}

/* --- Invalidation ------------------------------------------------------ */

/* Kill every live handle to `n` itself and to its attributes, recording what
   was killed so a removal that pugixml then refuses can be undone exactly.
   Only wrappers this call marks are recorded, so undoing can never resurrect
   a handle that was already dead. */
static void kill_handles_for(PugiDoc* doc, xml_node n,
                             std::vector<PugiNode*>& killed_nodes,
                             std::vector<PugiAttr*>& killed_attrs) {
    const void* nkey = n.internal_object();
    for (PugiNode* p = doc->node_buckets[ptr_hash(nkey) & (doc->node_nbuckets - 1)];
         p; p = p->hnext)
        if (!p->dead && p->gen_snap == doc->generation && p->node == n) {
            p->dead = true;
            killed_nodes.push_back(p);
        }

    for (xml_attribute a = n.first_attribute(); a; a = a.next_attribute()) {
        const void* akey = a.internal_object();
        for (PugiAttr* q = doc->attr_buckets[ptr_hash(akey) & (doc->attr_nbuckets - 1)];
             q; q = q->hnext)
            if (!q->dead && q->gen_snap == doc->generation && q->attr == a) {
                q->dead = true;
                killed_attrs.push_back(q);
            }
    }
}

struct KillWalker : public xml_tree_walker {
    PugiDoc* doc;
    std::vector<PugiNode*>* killed_nodes;
    std::vector<PugiAttr*>* killed_attrs;
    virtual bool for_each(xml_node& n) {
        kill_handles_for(doc, n, *killed_nodes, *killed_attrs);
        return true;
    }
};

/* Mark every live handle pointing into the subtree rooted at `victim` dead.
   MUST run before pugixml frees that subtree, while it is still walkable. */
static void invalidate_subtree(PugiDoc* doc, xml_node victim,
                               std::vector<PugiNode*>& killed_nodes,
                               std::vector<PugiAttr*>& killed_attrs) {
    kill_handles_for(doc, victim, killed_nodes, killed_attrs);  /* traverse() starts below victim */
    KillWalker w;
    w.doc = doc;
    w.killed_nodes = &killed_nodes;
    w.killed_attrs = &killed_attrs;
    victim.traverse(w);
}

static void invalidate_attribute(PugiDoc* doc, xml_attribute victim,
                                 std::vector<PugiAttr*>& killed_attrs) {
    const void* key = victim.internal_object();
    for (PugiAttr* q = doc->attr_buckets[ptr_hash(key) & (doc->attr_nbuckets - 1)];
         q; q = q->hnext)
        if (!q->dead && q->gen_snap == doc->generation && q->attr == victim) {
            q->dead = true;
            killed_attrs.push_back(q);
        }
}

/* pugixml's remove_child/remove_attribute re-check an allocator reserve AFTER
   the ownership check and can still return false, leaving the subtree alive.
   Undo the invalidation in that case so the handles are not falsely stale. */
static void revive_handles(std::vector<PugiNode*>& nodes, std::vector<PugiAttr*>& attrs) {
    for (size_t i = 0; i < nodes.size(); i++) nodes[i]->dead = false;
    for (size_t i = 0; i < attrs.size(); i++) attrs[i]->dead = false;
}

static SV* wrap_node(pTHX_ xml_node node, SV* doc_sv) {
    if (!node) {
        return &PL_sv_undef;
    }

    PugiDoc* doc = INT2PTR(PugiDoc*, SvIV(SvRV(doc_sv)));
    PugiNode* wrapper = new (std::nothrow) PugiNode;
    if (!wrapper) {
        croak("Out of memory allocating node wrapper");
    }
    wrapper->node = node;
    wrapper->doc_sv = SvREFCNT_inc(doc_sv);
    wrapper->gen_snap = doc->generation;
    wrapper->dead = false;
    doc_register_node(doc, wrapper);

    SV* sv = newSV(0);
    sv_setref_pv(sv, "XML::PugiXML::Node", (void*)wrapper);
    return sv;
}

static SV* wrap_attr(pTHX_ xml_attribute attr, xml_node parent, SV* doc_sv) {
    if (!attr) {
        return &PL_sv_undef;
    }

    PugiDoc* doc = INT2PTR(PugiDoc*, SvIV(SvRV(doc_sv)));
    PugiAttr* wrapper = new (std::nothrow) PugiAttr;
    if (!wrapper) {
        croak("Out of memory allocating attr wrapper");
    }
    wrapper->attr = attr;
    wrapper->parent_node = parent;
    wrapper->doc_sv = SvREFCNT_inc(doc_sv);
    wrapper->gen_snap = doc->generation;
    wrapper->dead = false;
    doc_register_attr(doc, wrapper);

    SV* sv = newSV(0);
    sv_setref_pv(sv, "XML::PugiXML::Attr", (void*)wrapper);
    return sv;
}

/* Wrap an XPath result -- returns Node or Attr depending on what matched */
static SV* wrap_xpath_result(pTHX_ const xpath_node& xnode, SV* doc_sv) {
    if (xnode.attribute()) {
        return wrap_attr(aTHX_ xnode.attribute(), xnode.parent(), doc_sv);
    }
    return wrap_node(aTHX_ xnode.node(), doc_sv);
}

/* Helpers to return UTF-8 strings */
static SV* newSVpv_utf8(pTHX_ const char* str) {
    SV* sv = newSVpv(str, 0);
    SvUTF8_on(sv);
    return sv;
}

static SV* new_utf8_svpvn(pTHX_ const char* str, STRLEN len) {
    SV* sv = newSVpvn(str, len);
    SvUTF8_on(sv);
    return sv;
}

static void set_parse_result(pTHX_ xml_parse_result& result) {
    if (!result) {
        sv_setpvf(get_sv("@", GV_ADD), "XML parse error: %s at offset %" IVdf,
                  result.description(), (IV)result.offset);
    } else {
        sv_setpvs(get_sv("@", GV_ADD), "");
    }
}

MODULE = XML::PugiXML  PACKAGE = XML::PugiXML

PROTOTYPES: DISABLE

XML::PugiXML
new(const char* CLASS)
CODE:
{
    PERL_UNUSED_VAR(CLASS);
    PugiDoc* doc = new (std::nothrow) PugiDoc;
    if (!doc) {
        croak("Out of memory allocating document");
    }
    doc->doc = new (std::nothrow) xml_document();
    if (!doc->doc) {
        delete doc;
        croak("Out of memory allocating xml_document");
    }
    doc->generation = 0;
    /* Allocate both indexes up front so registration can never fail and leave
       an unindexed (hence never-invalidated) wrapper behind. */
    doc->node_buckets = (PugiNode**)calloc(PUGI_HIDX_MIN, sizeof(PugiNode*));
    doc->attr_buckets = (PugiAttr**)calloc(PUGI_HIDX_MIN, sizeof(PugiAttr*));
    if (!doc->node_buckets || !doc->attr_buckets) {
        free(doc->node_buckets);
        free(doc->attr_buckets);
        delete doc->doc;
        delete doc;
        croak("Out of memory allocating document handle index");
    }
    doc->node_nbuckets = PUGI_HIDX_MIN;
    doc->attr_nbuckets = PUGI_HIDX_MIN;
    doc->node_count = 0;
    doc->attr_count = 0;
    RETVAL = doc;
}
OUTPUT:
    RETVAL

void
DESTROY(XML::PugiXML self)
CODE:
{
    /* Global destruction calls DESTROY in arbitrary order and may free the
       document before the nodes that reference it. Detach every live handle
       so their own DESTROY does not dereference this struct. */
    for (size_t i = 0; i < self->node_nbuckets; i++)
        for (PugiNode* p = self->node_buckets[i]; p; ) {
            PugiNode* next = p->hnext;
            p->owner = NULL; p->hnext = NULL; p->hprev = NULL; p->dead = true;
            p = next;
        }
    for (size_t i = 0; i < self->attr_nbuckets; i++)
        for (PugiAttr* a = self->attr_buckets[i]; a; ) {
            PugiAttr* next = a->hnext;
            a->owner = NULL; a->hnext = NULL; a->hprev = NULL; a->dead = true;
            a = next;
        }
    free(self->node_buckets);
    free(self->attr_buckets);
    delete self->doc;
    delete self;
}

bool
load_file(XML::PugiXML self, nul_safe_pv path, unsigned int parse_options = parse_default)
CODE:
{
    self->generation++;
    xml_parse_result result = self->doc->load_file(path, parse_options);
    set_parse_result(aTHX_ result);
    RETVAL = (bool)result;
}
OUTPUT:
    RETVAL

bool
load_string(XML::PugiXML self, SV* xml_sv, unsigned int parse_options = parse_default)
CODE:
{
    STRLEN xml_len;
    const char* xml = SvPV(xml_sv, xml_len);
    /* load_string takes a C string, so an embedded NUL would silently
       truncate the document and parse a different (shorter) one than was
       passed. NUL is invalid in XML 1.0 anyway -- reject it with a clear
       error rather than succeed on the truncated prefix. */
    if (strlen(xml) != xml_len)
        croak("load_string: XML contains an embedded NUL byte (invalid XML)");
    self->generation++;
    xml_parse_result result = self->doc->load_string(xml, parse_options);
    set_parse_result(aTHX_ result);
    RETVAL = (bool)result;
}
OUTPUT:
    RETVAL

void
reset(XML::PugiXML self)
CODE:
{
    self->generation++;
    self->doc->reset();
}

bool
save_file(XML::PugiXML self, nul_safe_pv path, nul_safe_pv indent = NULL, unsigned int flags = format_default)
CODE:
{
    if (!indent) indent = "\t";   /* default: avoid ParseXS mangling "\t" in the signature */
    RETVAL = self->doc->save_file(path, indent, flags);
    if (!RETVAL) {
        /* capture errno before get_sv(), whose evaluation order relative to
           strerror(errno) is otherwise unspecified and could clobber it */
        int saved_errno = errno;
        sv_setpvf(get_sv("@", GV_ADD), "Failed to save XML file: %s", strerror(saved_errno));
    } else {
        sv_setpvs(get_sv("@", GV_ADD), "");
    }
}
OUTPUT:
    RETVAL

SV*
to_string(XML::PugiXML self, nul_safe_pv indent = NULL, unsigned int flags = format_default)
CODE:
{
    if (!indent) indent = "\t";   /* default: avoid ParseXS mangling "\t" in the signature */
    RETVAL = 0;
    XPATH_GUARDED {
        std::ostringstream oss;
        self->doc->save(oss, indent, flags);
        std::string str = oss.str();
        RETVAL = new_utf8_svpvn(aTHX_ str.c_str(), str.length());
    } catch (const std::exception& e) {
        snprintf(xpath_err, sizeof(xpath_err), "to_string error: %s", e.what());
    }
    if (xpath_err[0]) croak("%s", xpath_err);
}
OUTPUT:
    RETVAL

SV*
root(XML::PugiXML self)
CODE:
{
    xml_node root = self->doc->document_element();
    RETVAL = wrap_node(aTHX_ root, ST(0));
}
OUTPUT:
    RETVAL

SV*
child(XML::PugiXML self, nul_safe_pv name)
CODE:
{
    xml_node child = self->doc->child(name);
    RETVAL = wrap_node(aTHX_ child, ST(0));
}
OUTPUT:
    RETVAL

SV*
select_node(XML::PugiXML self, nul_safe_pv xpath)
CODE:
{
    RETVAL = 0;
    XPATH_GUARDED {
        xpath_node result = self->doc->select_node(xpath);
        RETVAL = wrap_xpath_result(aTHX_ result, ST(0));
    } END_XPATH_GUARDED;
}
OUTPUT:
    RETVAL

void
select_nodes(XML::PugiXML self, nul_safe_pv xpath)
PPCODE:
{
    /* xsubpp emits "SP -= items" before this body, so the first PUSHs below
       overwrites the ST(0) slot. Cache the invocant before pushing anything:
       reading ST(0) inside the loop would hand every result after the first
       the preceding result's RV in place of the document. */
    SV* doc_sv = ST(0);
    XPATH_GUARDED {
        xpath_node_set nodes = self->doc->select_nodes(xpath);
        EXTEND(SP, (SSize_t)nodes.size());
        for (xpath_node_set::const_iterator it = nodes.begin(); it != nodes.end(); ++it) {
            SV* sv = wrap_xpath_result(aTHX_ *it, doc_sv);
            PUSHs(sv_2mortal(sv));
        }
    } END_XPATH_GUARDED;
}

SV*
compile_xpath(XML::PugiXML self, nul_safe_pv xpath)
CODE:
{
    PERL_UNUSED_VAR(self);
    RETVAL = 0;
    XPATH_GUARDED {
        xpath_query* query = new (std::nothrow) xpath_query(xpath);
        if (!query) {
            croak("Out of memory allocating xpath_query");
        }
        PugiXPath* wrapper = new (std::nothrow) PugiXPath;
        if (!wrapper) {
            delete query;
            croak("Out of memory allocating XPath wrapper");
        }
        wrapper->query = query;

        SV* sv = newSV(0);
        sv_setref_pv(sv, "XML::PugiXML::XPath", (void*)wrapper);
        RETVAL = sv;
    } catch (const xpath_exception& e) {
        snprintf(xpath_err, sizeof(xpath_err), "XPath compilation error: %s", e.what());
    } catch (const std::exception& e) {
        snprintf(xpath_err, sizeof(xpath_err), "Internal XPath compilation error: %s", e.what());
    }
    if (xpath_err[0]) croak("%s", xpath_err);
}
OUTPUT:
    RETVAL

BOOT:
{
    HV* stash = gv_stashpv("XML::PugiXML", GV_ADD);
#define PUGI_CONST(name, val) \
    newCONSTSUB(stash, name, newSVuv((UV)(val)))
    PUGI_CONST("PUGIXML_VERSION",         PUGIXML_VERSION);
    PUGI_CONST("FORMAT_DEFAULT",          format_default);
    PUGI_CONST("FORMAT_INDENT",           format_indent);
    PUGI_CONST("FORMAT_NO_DECLARATION",   format_no_declaration);
    PUGI_CONST("FORMAT_RAW",              format_raw);
    PUGI_CONST("FORMAT_WRITE_BOM",        format_write_bom);
    PUGI_CONST("FORMAT_INDENT_ATTRIBUTES", format_indent_attributes);
    PUGI_CONST("FORMAT_NO_EMPTY_ELEMENT_TAGS", format_no_empty_element_tags);
    PUGI_CONST("PARSE_DEFAULT",           parse_default);
    PUGI_CONST("PARSE_MINIMAL",           parse_minimal);
    PUGI_CONST("PARSE_PI",                parse_pi);
    PUGI_CONST("PARSE_COMMENTS",          parse_comments);
    PUGI_CONST("PARSE_CDATA",             parse_cdata);
    PUGI_CONST("PARSE_WS_PCDATA",         parse_ws_pcdata);
    PUGI_CONST("PARSE_WS_PCDATA_SINGLE",  parse_ws_pcdata_single);
    PUGI_CONST("PARSE_ESCAPES",           parse_escapes);
    PUGI_CONST("PARSE_EOL",               parse_eol);
    PUGI_CONST("PARSE_DECLARATION",       parse_declaration);
    PUGI_CONST("PARSE_DOCTYPE",           parse_doctype);
    PUGI_CONST("PARSE_FULL",              parse_full);
    PUGI_CONST("NODE_NULL",               node_null);
    PUGI_CONST("NODE_DOCUMENT",           node_document);
    PUGI_CONST("NODE_ELEMENT",            node_element);
    PUGI_CONST("NODE_PCDATA",             node_pcdata);
    PUGI_CONST("NODE_CDATA",              node_cdata);
    PUGI_CONST("NODE_COMMENT",            node_comment);
    PUGI_CONST("NODE_PI",                 node_pi);
    PUGI_CONST("NODE_DECLARATION",        node_declaration);
    PUGI_CONST("NODE_DOCTYPE",            node_doctype);
#undef PUGI_CONST
}


MODULE = XML::PugiXML  PACKAGE = XML::PugiXML::Node

void
DESTROY(XML::PugiXML::Node self)
CODE:
{
    doc_unregister_node(self);
    SvREFCNT_dec(self->doc_sv);
    delete self;
}

SV*
name(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = newSVpv_utf8(aTHX_ self->node.name());
}
OUTPUT:
    RETVAL

SV*
value(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = newSVpv_utf8(aTHX_ self->node.value());
}
OUTPUT:
    RETVAL

SV*
text(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = newSVpv_utf8(aTHX_ self->node.text().get());
}
OUTPUT:
    RETVAL

SV*
parent(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = wrap_node(aTHX_ self->node.parent(), self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
child(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = wrap_node(aTHX_ self->node.child(name), self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
first_child(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = wrap_node(aTHX_ self->node.first_child(), self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
next_sibling(XML::PugiXML::Node self, nul_safe_pv name = NULL)
CODE:
{
    CHECK_NODE_ALIVE(self);
    if (name) {
        RETVAL = wrap_node(aTHX_ self->node.next_sibling(name), self->doc_sv);
    } else {
        RETVAL = wrap_node(aTHX_ self->node.next_sibling(), self->doc_sv);
    }
}
OUTPUT:
    RETVAL

SV*
previous_sibling(XML::PugiXML::Node self, nul_safe_pv name = NULL)
CODE:
{
    CHECK_NODE_ALIVE(self);
    if (name) {
        RETVAL = wrap_node(aTHX_ self->node.previous_sibling(name), self->doc_sv);
    } else {
        RETVAL = wrap_node(aTHX_ self->node.previous_sibling(), self->doc_sv);
    }
}
OUTPUT:
    RETVAL

SV*
last_child(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = wrap_node(aTHX_ self->node.last_child(), self->doc_sv);
}
OUTPUT:
    RETVAL

void
children(XML::PugiXML::Node self, nul_safe_pv name = NULL)
PPCODE:
{
    CHECK_NODE_ALIVE(self);
    if (name) {
        for (xml_node child = self->node.child(name); child; child = child.next_sibling(name))
            XPUSHs(sv_2mortal(wrap_node(aTHX_ child, self->doc_sv)));
    } else {
        for (xml_node child = self->node.first_child(); child; child = child.next_sibling())
            XPUSHs(sv_2mortal(wrap_node(aTHX_ child, self->doc_sv)));
    }
}

void
attrs(XML::PugiXML::Node self)
PPCODE:
{
    CHECK_NODE_ALIVE(self);
    for (xml_attribute attr = self->node.first_attribute(); attr; attr = attr.next_attribute())
        XPUSHs(sv_2mortal(wrap_attr(aTHX_ attr, self->node, self->doc_sv)));
}

SV*
attr(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = wrap_attr(aTHX_ self->node.attribute(name), self->node, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_child(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_node child = self->node.append_child(name);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
prepend_child(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_node child = self->node.prepend_child(name);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
ensure_child(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    /* get-or-create the first child element of this name. pugixml 1.16 added a
       native ensure_child; emulate it on older libraries (child-or-append) so
       the binding still builds against a system pugixml < 1.16. */
#if PUGIXML_VERSION >= 1160
    xml_node child = self->node.ensure_child(name);
#else
    xml_node child = self->node.child(name);
    if (!child) child = self->node.append_child(name);
#endif
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_child_before(XML::PugiXML::Node self, nul_safe_pv name, XML::PugiXML::Node ref_node)
CODE:
{
    CHECK_NODE_ALIVE(self);
    CHECK_NODE_ALIVE(ref_node);
    CHECK_SAME_DOC(self, ref_node);
    xml_node child = self->node.insert_child_before(name, ref_node->node);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_child_after(XML::PugiXML::Node self, nul_safe_pv name, XML::PugiXML::Node ref_node)
CODE:
{
    CHECK_NODE_ALIVE(self);
    CHECK_NODE_ALIVE(ref_node);
    CHECK_SAME_DOC(self, ref_node);
    xml_node child = self->node.insert_child_after(name, ref_node->node);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_cdata(XML::PugiXML::Node self, nul_safe_pv content)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_node cdata = self->node.append_child(node_cdata);
    if (cdata) {
        cdata.set_value(content);
    }
    RETVAL = wrap_node(aTHX_ cdata, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_comment(XML::PugiXML::Node self, nul_safe_pv content)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_node comment = self->node.append_child(node_comment);
    if (comment) {
        comment.set_value(content);
    }
    RETVAL = wrap_node(aTHX_ comment, self->doc_sv);
}
OUTPUT:
    RETVAL

int
type(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = (int)self->node.type();
}
OUTPUT:
    RETVAL

SV*
path(XML::PugiXML::Node self, nul_safe_pv delimiter = NULL)
CODE:
{
    CHECK_NODE_ALIVE(self);
    /* pugixml's path() takes a single char. Taking this as a string and
       checking the length beats the T_CHAR typemap, which quietly turned
       path('::') into ':' and path('') into a NUL delimiter. */
    char delim = '/';
    if (delimiter) {
        if (strlen(delimiter) != 1)
            croak("path: delimiter must be a single character");
        delim = delimiter[0];
    }
    RETVAL = 0;
    XPATH_GUARDED {
        std::string p = self->node.path(delim);
        RETVAL = new_utf8_svpvn(aTHX_ p.c_str(), p.length());
    } catch (const std::exception& e) {
        snprintf(xpath_err, sizeof(xpath_err), "path error: %s", e.what());
    }
    if (xpath_err[0]) croak("%s", xpath_err);
}
OUTPUT:
    RETVAL

SV*
find_child_by_attribute(XML::PugiXML::Node self, nul_safe_pv name, nul_safe_pv attr_name, nul_safe_pv attr_value)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_node child = self->node.find_child_by_attribute(name, attr_name, attr_value);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
root(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    /* Document element (consistent with $doc->root). CHECK_NODE_ALIVE has
       already established that owner is non-NULL. */
    RETVAL = wrap_node(aTHX_ self->owner->doc->document_element(), self->doc_sv);
}
OUTPUT:
    RETVAL

bool
set_name(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = self->node.set_name(name);
}
OUTPUT:
    RETVAL

bool
set_value(XML::PugiXML::Node self, nul_safe_pv value)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = self->node.set_value(value);
}
OUTPUT:
    RETVAL

bool
set_text(XML::PugiXML::Node self, nul_safe_pv text)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = self->node.text().set(text);
}
OUTPUT:
    RETVAL

SV*
select_node(XML::PugiXML::Node self, nul_safe_pv xpath)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = 0;
    XPATH_GUARDED {
        xpath_node result = self->node.select_node(xpath);
        RETVAL = wrap_xpath_result(aTHX_ result, self->doc_sv);
    } END_XPATH_GUARDED;
}
OUTPUT:
    RETVAL

void
select_nodes(XML::PugiXML::Node self, nul_safe_pv xpath)
PPCODE:
{
    CHECK_NODE_ALIVE(self);
    XPATH_GUARDED {
        xpath_node_set nodes = self->node.select_nodes(xpath);
        EXTEND(SP, (SSize_t)nodes.size());
        for (xpath_node_set::const_iterator it = nodes.begin(); it != nodes.end(); ++it) {
            SV* sv = wrap_xpath_result(aTHX_ *it, self->doc_sv);
            PUSHs(sv_2mortal(sv));
        }
    } END_XPATH_GUARDED;
}

bool
valid(XML::PugiXML::Node self)
CODE:
{
    /* valid() deliberately skips CHECK_NODE_ALIVE -- returns false for stale handles */
    RETVAL = !HANDLE_STALE(self) && !self->dead && (bool)self->node;
}
OUTPUT:
    RETVAL

SV*
append_attr(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_attribute attr = self->node.append_attribute(name);
    RETVAL = wrap_attr(aTHX_ attr, self->node, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
prepend_attr(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_attribute attr = self->node.prepend_attribute(name);
    RETVAL = wrap_attr(aTHX_ attr, self->node, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
ensure_attr(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    /* get-or-create the attribute of this name. pugixml 1.16 added a native
       ensure_attribute; emulate it on older libraries (find-or-append) so the
       binding still builds against a system pugixml < 1.16. */
#if PUGIXML_VERSION >= 1160
    xml_attribute attr = self->node.ensure_attribute(name);
#else
    xml_attribute attr = self->node.attribute(name);
    if (!attr) attr = self->node.append_attribute(name);
#endif
    RETVAL = wrap_attr(aTHX_ attr, self->node, self->doc_sv);
}
OUTPUT:
    RETVAL

bool
remove_child(XML::PugiXML::Node self, XML::PugiXML::Node child)
CODE:
{
    CHECK_NODE_ALIVE(self);
    CHECK_NODE_ALIVE(child);
    CHECK_SAME_DOC(self, child);
    /* pugixml frees the subtree's storage here, so every handle into it must
       be killed first, while the subtree is still walkable. The condition
       mirrors pugixml's own precondition, so a removal that is going to fail
       for the usual reason invalidates nothing; pugixml can still refuse on
       an allocator reserve after that check, which revive_handles undoes. */
    std::vector<PugiNode*> killed_nodes;
    std::vector<PugiAttr*> killed_attrs;
    if (child->node && child->node.parent() == self->node)
        invalidate_subtree(self->owner, child->node, killed_nodes, killed_attrs);
    RETVAL = self->node.remove_child(child->node);
    if (!RETVAL) revive_handles(killed_nodes, killed_attrs);
}
OUTPUT:
    RETVAL

bool
remove_attr(XML::PugiXML::Node self, nul_safe_pv name)
CODE:
{
    CHECK_NODE_ALIVE(self);
    /* Same reasoning as remove_child: the attribute's storage is freed, so
       handles to it must be killed while it is still readable. */
    xml_attribute victim = self->node.attribute(name);
    if (victim) {
        std::vector<PugiNode*> killed_nodes;
        std::vector<PugiAttr*> killed_attrs;
        invalidate_attribute(self->owner, victim, killed_attrs);
        RETVAL = self->node.remove_attribute(victim);
        if (!RETVAL) revive_handles(killed_nodes, killed_attrs);
    } else {
        RETVAL = false;
    }
}
OUTPUT:
    RETVAL

SV*
append_copy(XML::PugiXML::Node self, XML::PugiXML::Node source)
CODE:
{
    CHECK_NODE_ALIVE(self);
    CHECK_NODE_ALIVE(source);
    xml_node copy = self->node.append_copy(source->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
prepend_copy(XML::PugiXML::Node self, XML::PugiXML::Node source)
CODE:
{
    CHECK_NODE_ALIVE(self);
    CHECK_NODE_ALIVE(source);
    xml_node copy = self->node.prepend_copy(source->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_copy_before(XML::PugiXML::Node self, XML::PugiXML::Node source, XML::PugiXML::Node ref_node)
CODE:
{
    CHECK_NODE_ALIVE(self);
    CHECK_NODE_ALIVE(source);
    CHECK_NODE_ALIVE(ref_node);
    CHECK_SAME_DOC(self, ref_node);
    xml_node copy = self->node.insert_copy_before(source->node, ref_node->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_copy_after(XML::PugiXML::Node self, XML::PugiXML::Node source, XML::PugiXML::Node ref_node)
CODE:
{
    CHECK_NODE_ALIVE(self);
    CHECK_NODE_ALIVE(source);
    CHECK_NODE_ALIVE(ref_node);
    CHECK_SAME_DOC(self, ref_node);
    xml_node copy = self->node.insert_copy_after(source->node, ref_node->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
set_attr(XML::PugiXML::Node self, nul_safe_pv name, nul_safe_pv value)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_attribute attr = self->node.attribute(name);
    if (!attr) {
        attr = self->node.append_attribute(name);
    }
    if (attr) {
        attr.set_value(value);
    }
    RETVAL = wrap_attr(aTHX_ attr, self->node, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_pi(XML::PugiXML::Node self, nul_safe_pv target, nul_safe_pv data = NULL)
CODE:
{
    CHECK_NODE_ALIVE(self);
    xml_node pi = self->node.append_child(node_pi);
    if (pi) {
        pi.set_name(target);
        if (data) {
            pi.set_value(data);
        }
    }
    RETVAL = wrap_node(aTHX_ pi, self->doc_sv);
}
OUTPUT:
    RETVAL

size_t
hash(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = self->node.hash_value();
}
OUTPUT:
    RETVAL

IV
offset_debug(XML::PugiXML::Node self)
CODE:
{
    CHECK_NODE_ALIVE(self);
    RETVAL = (IV)self->node.offset_debug();
}
OUTPUT:
    RETVAL


MODULE = XML::PugiXML  PACKAGE = XML::PugiXML::Attr

void
DESTROY(XML::PugiXML::Attr self)
CODE:
{
    doc_unregister_attr(self);
    SvREFCNT_dec(self->doc_sv);
    delete self;
}

SV*
name(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = newSVpv_utf8(aTHX_ self->attr.name());
}
OUTPUT:
    RETVAL

SV*
value(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = newSVpv_utf8(aTHX_ self->attr.value());
}
OUTPUT:
    RETVAL

int
as_int(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = self->attr.as_int();
}
OUTPUT:
    RETVAL

double
as_double(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = self->attr.as_double();
}
OUTPUT:
    RETVAL

bool
as_bool(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = self->attr.as_bool();
}
OUTPUT:
    RETVAL

unsigned int
as_uint(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = self->attr.as_uint();
}
OUTPUT:
    RETVAL

SV*
as_llong(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
#if IVSIZE >= 8
    RETVAL = newSViv((IV)self->attr.as_llong());
#else
    long long val = self->attr.as_llong();
    char buf[32];
    snprintf(buf, sizeof(buf), "%lld", val);
    RETVAL = newSVpv(buf, 0);
#endif
}
OUTPUT:
    RETVAL

SV*
as_ullong(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
#if IVSIZE >= 8
    RETVAL = newSVuv((UV)self->attr.as_ullong());
#else
    unsigned long long val = self->attr.as_ullong();
    char buf[32];
    snprintf(buf, sizeof(buf), "%llu", val);
    RETVAL = newSVpv(buf, 0);
#endif
}
OUTPUT:
    RETVAL

bool
set_value(XML::PugiXML::Attr self, nul_safe_pv value)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = self->attr.set_value(value);
}
OUTPUT:
    RETVAL

bool
set_name(XML::PugiXML::Attr self, nul_safe_pv name)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = self->attr.set_name(name);
}
OUTPUT:
    RETVAL

SV*
element(XML::PugiXML::Attr self)
CODE:
{
    CHECK_ATTR_ALIVE(self);
    RETVAL = wrap_node(aTHX_ self->parent_node, self->doc_sv);
}
OUTPUT:
    RETVAL

bool
valid(XML::PugiXML::Attr self)
CODE:
{
    /* valid() deliberately skips CHECK_ATTR_ALIVE -- returns false for stale handles */
    RETVAL = !HANDLE_STALE(self) && !self->dead && (bool)self->attr;
}
OUTPUT:
    RETVAL


MODULE = XML::PugiXML  PACKAGE = XML::PugiXML::XPath

void
DESTROY(XML::PugiXML::XPath self)
CODE:
{
    delete self->query;
    delete self;
}

SV*
evaluate_node(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    CHECK_NODE_ALIVE(node);
    RETVAL = 0;
    XPATH_GUARDED {
        xpath_node result = self->query->evaluate_node(node->node);
        RETVAL = wrap_xpath_result(aTHX_ result, node->doc_sv);
    } END_XPATH_GUARDED;
}
OUTPUT:
    RETVAL

void
evaluate_nodes(XML::PugiXML::XPath self, XML::PugiXML::Node node)
PPCODE:
{
    CHECK_NODE_ALIVE(node);
    XPATH_GUARDED {
        xpath_node_set nodes = self->query->evaluate_node_set(node->node);
        EXTEND(SP, (SSize_t)nodes.size());
        for (xpath_node_set::const_iterator it = nodes.begin(); it != nodes.end(); ++it) {
            SV* sv = wrap_xpath_result(aTHX_ *it, node->doc_sv);
            PUSHs(sv_2mortal(sv));
        }
    } END_XPATH_GUARDED;
}

SV*
evaluate_string(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    CHECK_NODE_ALIVE(node);
    RETVAL = 0;
    XPATH_GUARDED {
        std::string result = self->query->evaluate_string(node->node);
        RETVAL = new_utf8_svpvn(aTHX_ result.c_str(), result.length());
    } END_XPATH_GUARDED;
}
OUTPUT:
    RETVAL

double
evaluate_number(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    CHECK_NODE_ALIVE(node);
    RETVAL = 0;
    XPATH_GUARDED {
        RETVAL = self->query->evaluate_number(node->node);
    } END_XPATH_GUARDED;
}
OUTPUT:
    RETVAL

bool
evaluate_boolean(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    CHECK_NODE_ALIVE(node);
    RETVAL = 0;
    XPATH_GUARDED {
        RETVAL = self->query->evaluate_boolean(node->node);
    } END_XPATH_GUARDED;
}
OUTPUT:
    RETVAL

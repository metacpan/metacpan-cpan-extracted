/* zx.h  -  Common definitions for zx generated code (encoders, decoders, etc.)
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zx.h,v 1.45 2009-11-29 12:23:06 sampo Exp $
 *
 * 28.5.2006, created --Sampo
 * 7.8.2006,  renamed from dec.h to zx.h and added comments --Sampo
 * 26.8.2006, some refactoring for CSE --Sampo
 * 23.9.2006, mild re-engineering for WO support --Sampo
 * 23.2.2008, added support for function pointers to malloc(),
 *            realloc(), and free() --Sampo
 * 27.10.2010, namespace re-engineering --Sampo
 * 26.10.2014, changed crypto to GCM and OAEP to combat Backwards Compatibility Attacks --Sampo
 * 18.12.2015, applied patch from soconnor, perceptyx, adding algos --Sampo
 *
 * See paper: Tibor Jager, Kenneth G. Paterson, Juraj Somorovsky: "One Bad Apple: Backwards Compatibility Attacks on State-of-the-Art Cryptography", 2013 http://www.nds.ruhr-uni-bochum.de/research/publications/backwards-compatibility/ /t/BackwardsCompatibilityAttacks.pdf
 *
 * This file is included from various generated grammar files.
 */

#ifndef _zx_h
#define _zx_h

#include <memory.h>
#include <string.h>
#include <stdarg.h>

#ifdef USE_OPENSSL
#include <openssl/x509.h>
#include <openssl/rsa.h>
#else
#define X509 void
#define RSA void
#endif

#ifdef MINGW
#include <windows.h>
#define pthread_mutex_t CRITICAL_SECTION
#define pthread_t DWORD
#define fdtype HANDLE
#else
#include <pthread.h>
#define fdtype int
#endif

#ifndef ZXDECL
#define ZXDECL
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct zx_lock {
  pthread_mutex_t ptmut;
  const char* func;        /* Remember where we locked to ease debugging. */
  int line;
  pthread_t thr;
};

/*(s) Namespace management. The context references this table. The array is
 * terminated by an element with empty URL (url_len == 0). The elements
 * of the array are the official namespace prefixes derived from
 * target() directives in the .sg files. The linked list hanging from
 * n field contains a stack of runtime assigned namespace prefixes.
 * The empty marker element serves as a root for list holding namespace
 * prefixes of namespaces not understood by the system. */

struct zx_ns_s {
  /*int name;              / * For gperf -P (%pic) string-pool offset when in hash. */
  const char* url;          /* Needs to be first so gperf (without -P or %pic) works. nul term */
  int url_len;              /* 0 = end of nstab */
  int prefix_len;
  const char* prefix;       /* Always nul terminated (despite prefix_len field) */
  struct zx_ns_s* n;        /* Next: For holding runtime equivalences as a linked list. */
  struct zx_ns_s* master;   /* For a runtime equivalence, pointer to the master entry. */
  struct zx_ns_s* seen;     /* Pointer to other "seen" namespaces with same prefix (stack) */
  struct zx_ns_s* seen_n;   /* Next prefix in seen structure (list) */
  struct zx_ns_s* seen_p;   /* Previous prefix in seen structure (list) */
  struct zx_ns_s* seen_pop; /* Pop list for seen stack (used in the end of an element). */
  struct zx_ns_s* inc_n;    /* Next link for InclusiveNamespaces */
};

/*struct zx_ns_s zx_ns_tab[]; include c/zx-ns.h instead */

/* Context tracks the input and namespaces. It is also passed to memory allocator. */

struct zx_ctx {
  const char* bas;   /* base is C# keyword :-( */
  const char* p;     /* Current scan pointer */
  const char* lim;
  struct zx_ns_s* ns_tab;      /* Array, such as zx_ns_tab, see zx_prepare_dec_ctx() */
  int n_ns;                    /* Number of entries in ns_tab. */
  struct zx_ns_s* unknown_ns;  /* Linked list of unknown namespaces. */
  /* Namespace prefixes that have been "seen", each prefix is a stack.
   * We keep these prefixes in a doubly linked list so we can add and
   * remove in the middle. */
  struct zx_ns_s guard_seen_n;
  struct zx_ns_s guard_seen_p;
  void* exclude_sig;  /* If nonnull, causes specified signature to be
		       * excluded. This is needed to avoid the signature
		       * under verification in the canonicalization.
		       * See zxsig.c:zxsig_validate(). */
  struct zx_ns_s* inc_ns_len;  /* Derived from InclusiveNamespaces/@PrefixList,length computation phase, */
  struct zx_ns_s* inc_ns;  /* Encoding phase. See zxsig_validate(). */
  /* Allow ZX_ALLOC() layer to be adapted to custom allocators, like Apache pool allocator. */
  void* (*malloc_func)(size_t);
  void* (*realloc_func)(void*, size_t);
  void  (*free_func)(void*);
#ifdef USE_PTHREAD
  struct zx_lock mx;
#endif
  char canon_inopt;   /* Shib2 InclusiveNamespaces/@PrefixList kludge and other sundry options. */
  char enc_tail_opt;  /* In encoding, use non-canon empty tag tail optimization, e.g. <ns:foo/> */
  char top1;          /* There can only be one top level element, e.g. <e:Envelope> */
  char pad3;
  int  zx_errno;      /* Outcome of last filesystem operation */
};

/* We arrange all structs to start with a common header (16 bytes on 32bit platforms).
 * This structure works as a binary clean string. When used as (a part of) an
 * element, the namespace prefix and name of the element form the string. The
 * token value does not need to be represented as it can be recovered by
 * performing zx_elem2tok() lookup again. The namespace information is
 * implicit in the placement of the element in its parent element's struct. */

struct zx_str {
  struct zx_str* n;  /* next pointer for compile time construction of data structures */
  int tok;           /* token number of the ns+tag represented by this struct */
  int len;
  char* s;           /* Start of prefix:element in the scan buffer. */
};

#define ZX_NEXT(x) ((x)->gg.g.n)

/* Attributes that are unforeseen (errornous or extensions). */

struct zx_attr_s {
  struct zx_str g;     /* value at g.s */
  struct zx_ns_s* ns;  /* namespace of the attribute */
  int name_len;
  char* name;
};

//#define ZX_ANY_AT(x) ((struct zx_any_attr_s*)(x))

/* Simple elements, base type for complex elements. */

struct zx_elem_s {
  struct zx_str g;             /* Common fields for all nodes */
  struct zx_elem_s* kids;      /* root of wo list representing child elements */
  struct zx_attr_s* attr;      /* list of attributes */
  struct zx_ns_s*   ns;        /* namespace of the element */
  struct zx_ns_s*   xmlns;     /* xmlns declarations (for inc_ns processing) */
};

#define ZX_ELEM_EXT struct zx_elem_s gg;   /* Used in generated data types */

struct zx_elem_s* zx_new_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok);
struct zx_elem_s* zx_new_str_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, struct zx_str* ss);
struct zx_elem_s* zx_ref_len_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s);
struct zx_elem_s* zx_ref_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s);
struct zx_elem_s* zx_dup_len_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s);
struct zx_elem_s* zx_dup_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s);

struct zx_attr_s* zx_ref_len_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s);
struct zx_attr_s* zx_ref_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s);
struct zx_attr_s* zx_new_len_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len);
struct zx_attr_s* zx_dup_len_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s);
struct zx_attr_s* zx_dup_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s);
struct zx_attr_s* zx_attrf(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* f, ...);

struct zx_str* zx_ref_str(struct zx_ctx* c, const char* s);  /* ref points to underlying data */
struct zx_str* zx_ref_len_str(struct zx_ctx* c, int len, const char* s);
struct zx_str* zx_new_len_str(struct zx_ctx* c, int len);
struct zx_str* zx_dup_len_str(struct zx_ctx* c, int len, const char* s);
struct zx_str* zx_dup_str(struct zx_ctx* c, const char* s);  /* data is new memory */
struct zx_str* zx_dup_zx_str(struct zx_ctx* c, struct zx_str* ss); /* data is new memory */
struct zx_str* zx_strf(struct zx_ctx* c, const char* f, ...);  /* data is new memory */

char* zx_alloc_sprintf(struct zx_ctx* c, int* retlen, const char* f, ...);
void  zx_str_free(struct zx_ctx* c, struct zx_str* ss);   /* free both ss->s and ss */
char* zx_str_to_c(struct zx_ctx* c, struct zx_str* ss);
void  zx_str_conv(struct zx_str* ss, int* out_len, char** out_s);  /* SWIG typemap friendly */
int   zx_str_cmp(struct zx_str* a, struct zx_str* b);
int   zx_str_ends_in(struct zx_str* ss, int len, const char* suffix);
#define ZX_STR_EQ(ss, cstr) ((ss) && (cstr) && (ss)->s && (ss)->len == strlen(cstr) && !memcmp((cstr), (ss)->s, (ss)->len))
#define ZX_STR_ENDS_IN_CONST(ss, suffix) zx_str_ends_in((ss), sizeof(suffix)-1, (suffix))

#define ZX_ELEM_S(e) ((struct zx_elem_s*)(e))
#define ZX_SIMPLE_ELEM_CHK(e) ((e) && ZX_ELEM_S(e)->kids && ZX_ELEM_S(e)->kids->g.tok == ZX_TOK_DATA && ZX_ELEM_S(e)->kids->g.len && ZX_ELEM_S(e)->kids->g.s && ZX_ELEM_S(e)->kids->g.s[0])
#define ZX_CONTENT_EQ_CONST(e, c) ((e) && ZX_ELEM_S(e)->kids && ZX_ELEM_S(e)->kids->g.tok == ZX_TOK_DATA && ZX_ELEM_S(e)->kids->g.len == sizeof(c)-1 && !memcmp(ZX_ELEM_S(e)->kids->g.s, (c), sizeof(c)-1))
#define ZX_GET_CONTENT(e) ((e) && ZX_ELEM_S(e)->kids && ZX_ELEM_S(e)->kids->g.tok == ZX_TOK_DATA ? &ZX_ELEM_S(e)->kids->g : 0)
#define ZX_GET_CONTENT_LEN(e) ((e) && ZX_ELEM_S(e)->kids && ZX_ELEM_S(e)->kids->g.tok == ZX_TOK_DATA ? ZX_ELEM_S(e)->kids->g.len : 0)
#define ZX_GET_CONTENT_S(e) ((e) && ZX_ELEM_S(e)->kids && ZX_ELEM_S(e)->kids->g.tok == ZX_TOK_DATA ? ZX_ELEM_S(e)->kids->g.s : 0)

char* zx_memmem(const char* haystack, int haystack_len, const char* needle, int needle_len);
void* zx_alloc(struct zx_ctx* c, int size);
void* zx_zalloc(struct zx_ctx* c, int size);
void* zx_free(struct zx_ctx* c, void* p);
char* zx_dup_cstr(struct zx_ctx* c, const char* str);
char* zx_dup_len_cstr(struct zx_ctx* c, int len, const char* str);
#define ZX_ALLOC(c, size) zx_alloc((c), (size))
#define ZX_ZALLOC(c, typ) ((typ*)zx_zalloc((c), sizeof(typ)))
#define ZX_DUPALLOC(c, typ, n, o) (n) = (typ*)zx_alloc((c), sizeof(typ)); memcpy((n), (o), sizeof(typ))
#define ZX_FREE(c, p) zx_free((c), (p))

void  zx_reset_ns_ctx(struct zx_ctx* ctx);
void  zx_reset_ctx(struct zx_ctx* ctx);
struct zx_ctx* zx_init_ctx();   /* from malloc(3) */
void zx_free_ctx(struct zx_ctx* ctx);	/* Wrapper for free(3C). */

/* N.B. All string scanning assumes buffer is terminated with C string style nul byte. */
/*#define ZX_SKIP_WS_P(c,p,x) MB for (; ONE_OF_4(*(p), ' ', '\n', '\r', '\t'); ++(p)) ; if (!*(p)) return x; ME*/
#define ZX_SKIP_WS_P(c,p,x) MB p += strspn((p)," \n\r\t"); if (!*(p)) return x; ME
#define ZX_SKIP_WS(c,x)     ZX_SKIP_WS_P((c),(c)->p,x)
#define ZX_LOOK_FOR_P(c,ch,p) MB char* pp = memchr((p), (ch), (c)->lim - (p)); if (!pp) goto look_for_not_found; else (p) = pp; ME
#define ZX_LOOK_FOR(c,ch)   ZX_LOOK_FOR_P((c),(ch),(c)->p)

#define ZX_OUT_CH(p, ch)        (*((p)++) = (ch))
#define ZX_OUT_MEM(p, mem, len) MB memcpy((p), (mem), (len)); (p) += (len); ME
#define ZX_OUT_STR(p, str) ZX_OUT_MEM(p, ((struct zx_str*)(x))->s, ((struct zx_str*)(x))->len)

#define ZX_OUT_TAG(p, tag) ZX_OUT_MEM(p, tag, sizeof(tag)-1)
#define ZX_OUT_CLOSE_TAG(p, tag) ZX_OUT_MEM(p, tag, sizeof(tag)-1)
#if 1
#define ZX_LEN_SIMPLE_TAG(tok, len, ns) (1 + ((tok == ZX_TOK_TOK_NOT_FOUND && ns && ns->prefix_len)?ns->prefix_len+1:0) + len)
#define ZX_OUT_SIMPLE_TAG(p, tok, tag, len, ns) MB ZX_OUT_CH(p, '<'); if (tok == ZX_TOK_TOK_NOT_FOUND && ns && ns->prefix_len) { ZX_OUT_MEM(p, ns->prefix, ns->prefix_len); ZX_OUT_CH(p, ':'); } ZX_OUT_MEM(p, tag, len); ME
#define ZX_OUT_SIMPLE_CLOSE_TAG(p, tok, tag, len, ns) MB ZX_OUT_CH(p, '<'); ZX_OUT_CH(p, '/');  if (tok == ZX_TOK_TOK_NOT_FOUND && ns && ns->prefix_len) { ZX_OUT_MEM(p, ns->prefix, ns->prefix_len); ZX_OUT_CH(p, ':'); } ZX_OUT_MEM(p, tag, len); ZX_OUT_CH(p, '>'); ME
#else
#define ZX_OUT_SIMPLE_TAG(p, tag, len, ns) MB ZX_OUT_CH(p, '<'); if (0&&ns) { ZX_OUT_MEM(p, ns->prefix, ns->prefix_len); ZX_OUT_CH(p, ':'); } ZX_OUT_MEM(p, tag, len); ME
#define ZX_OUT_SIMPLE_CLOSE_TAG(p, tag, len, ns) MB ZX_OUT_CH(p, '<'); ZX_OUT_CH(p, '/');  if (0&&ns) { ZX_OUT_MEM(p, ns->prefix, ns->prefix_len); ZX_OUT_CH(p, ':'); } ZX_OUT_MEM(p, tag, len); ZX_OUT_CH(p, '>'); ME
#endif

/* Special token values. */
#define ZX_TOK_NO_ATTR   (-7)  /* 0xfff9 65529 */
#define ZX_TOK_ATTR_ERR  (-6)
#define ZX_TOK_XMLNS     (-4)
#define ZX_TOK_DATA             0x0000fffd  /* Decimal 65533: string data between elements */
#define ZX_TOK_ATTR_NOT_FOUND   0x0000fffe
#define ZX_TOK_TOK_NOT_FOUND    0x0000ffff
#define ZX_TOK_NS_NOT_FOUND     0x00ff0000
#define ZX_TOK_NOT_FOUND        0x00ffffff  /* Decimal 16777215: common among payload elements */
#define ZX_TOK_TOK_MASK         0x0000ffff
#define ZX_TOK_NS_MASK          0x00ff0000
#define ZX_TOK_NS_SHIFT         16
#define ZX_TOK_FLAGS_MASK       0xff000000

#define zx_xml_lang_ATTR (zx_xml_NS|zx_lang_ATTR)
#define zx_wsu_Id_ATTR   (zx_wsu_NS|zx_Id_ATTR)
#define zx_e_actor_ATTR  (zx_e_NS|zx_actor_ATTR)
#define zx_e_mustUnderstand_ATTR (zx_e_NS|zx_mustUnderstand_ATTR)

struct zx_at_tok { const char* name; };

/* Element descriptor. These are statically initialized in c/zx-elems.c */

struct zx_el_desc {
  struct zx_el_desc* n;
  int tok;
  int siz;  /* max struct size to help allocation */
  int (*at_dec)(struct zx_ctx* c,struct zx_elem_s* x); /* funcptr to attr decode switch */
  int (*el_dec)(struct zx_ctx* c,struct zx_elem_s* x); /* funcptr to elem decode switch */
  int el_order[];  /* Ordered list of tags that should appear as kids. */
};

/* Node of zx_el_tab[] which is indexed by tok number, see c/zx-elems.c */

struct zx_el_tok {
  const char* name;
  struct zx_el_desc* n;
};

/*struct zx_el_tok* zx_elem2tok(register const char *str, register unsigned int len);*/
/*struct zx_note_s* zx_clone_any(struct zx_ctx* c, struct zx_note_s* n, int dup_strs); TBD */
/*void zx_free_any(struct zx_ctx* c, struct zx_note_s* n, int free_strs); TBD */

int   zx_date_time_to_secs(const char* dt);
int   write2_or_append_lock_c_path(const char* c_path, int len1, const char* data1, int len2, const char* data2, const char* which, int seeky, int flag);
int   zx_report_openssl_err(const char* logkey);

#if 0
void  zx_fix_any_elem_dec(struct zx_ctx* c, struct zx_elem_s* x, const char* nam, int namlen);
int   zx_is_ns_prefix(struct zx_ns_s* ns, int len, const char* prefix);
#endif
int zx_dump_ns_tab(struct zx_ctx* c, int flags);
struct zx_ns_s* zx_prefix_seen(struct zx_ctx* c, int len, const char* prefix);
struct zx_ns_s* zx_prefix_seen_whine(struct zx_ctx* c, int len, const char* prefix, const char* logkey, int mk_dummy_ns);
struct zx_ns_s* zx_scan_xmlns(struct zx_ctx* c);
void  zx_see_elem_ns(struct zx_ctx* c, struct zx_ns_s** pop_seen, struct zx_elem_s* el);
void  zx_pop_seen(struct zx_ns_s* ns);
int zx_format_parse_error(struct zx_ctx* ctx, char* buf, int siz, char* logkey);

/* zxcrypto.c - Glue to OpenSSL low level */

#define ZX_SYMKEY_LEN 20  /* size of sha1 */
char* zx_hmac_sha256(struct zx_ctx* c, int key_len, const char* key, int data_len, const char* data, char* md, int* md_len);
int zx_raw_raw_digest2(struct zx_ctx* c, char* mdbuf, const EVP_MD* evp_digest, int len, const char* s, int len2, const char* s2);
int zx_raw_digest2(struct zx_ctx* c, char* mdbuf, const char* algo, int len, const char* s, int len2, const char* s2);
struct zx_str* zx_raw_cipher(struct zx_ctx* c, const char* algo, int encflag, struct zx_str* key, int len, const char* s, int iv_len, const char* iv);
struct zx_str* zx_rsa_pub_enc(struct zx_ctx* c, struct zx_str* plain, RSA* rsa_pkey, int pad);
struct zx_str* zx_rsa_pub_dec(struct zx_ctx* c, struct zx_str* ciphered, RSA* rsa_pkey, int pad);
struct zx_str* zx_rsa_priv_dec(struct zx_ctx* c, struct zx_str* ciphered, RSA* rsa_pkey, int pad);
struct zx_str* zx_rsa_priv_enc(struct zx_ctx* c, struct zx_str* plain, RSA* rsa_pkey, int pad);
RSA*  zx_get_rsa_pub_from_cert(X509* cert, char* logkey);
void  zx_rand(char* buf, int n_bytes);
char* zx_md5_crypt(const char* pw, const char* salt, char* buf);

/* Common Subexpression Elimination (CSE) for generated code. */

#define ZX_ORD_INS_ATTR(b,f,k) (zx_ord_ins_at(&(b)->gg,((b)->f=(k))))
#define ZX_ADD_KID(b,f,k)  (zx_add_kid(&(b)->gg,(struct zx_elem_s*)((b)->f=(k))))

/* zxlib.c */

struct zx_elem_s* zx_add_kid(struct zx_elem_s* father, struct zx_elem_s* kid);
struct zx_elem_s* zx_add_kid_before(struct zx_elem_s* father, int before, struct zx_elem_s* kid);
struct zx_elem_s* zx_add_kid_after_sa_Issuer(struct zx_elem_s* father, struct zx_elem_s* kid);
struct zx_elem_s* zx_replace_kid(struct zx_elem_s* father, struct zx_elem_s* kid);
void  zx_add_content(struct zx_ctx* c, struct zx_elem_s* x, struct zx_str* cont);
struct zx_attr_s* zx_ord_ins_at(struct zx_elem_s* x, struct zx_attr_s* in_at);
void  zx_reverse_elem_lists(struct zx_elem_s* x);
int   zx_len_xmlns_if_not_seen(struct zx_ctx* c, struct zx_ns_s* ns, struct zx_ns_s** pop_seen);
void  zx_add_xmlns_if_not_seen(struct zx_ctx* c, struct zx_ns_s* ns, struct zx_ns_s** pop_seen);
char* zx_enc_seen(char* p, struct zx_ns_s* ns);
int   zx_LEN_WO_any_elem(struct zx_ctx* c, struct zx_elem_s* x);
char* zx_ENC_WO_any_elem(struct zx_ctx* c, struct zx_elem_s* x, char* p);
struct zx_str* zx_EASY_ENC_elem(struct zx_ctx* c, struct zx_elem_s* x);
void  zx_free_attr(struct zx_ctx* c, struct zx_attr_s* attr, int free_strs);
void  zx_free_elem(struct zx_ctx* c, struct zx_elem_s* x, int free_strs);

#ifdef ZX_ENA_AUX
void  zx_dup_attr(struct zx_ctx* c, struct zx_str* attr);
struct zx_str* zx_clone_attr(struct zx_ctx* c, struct zx_str* attr);
struct zx_elem_s* zx_clone_elem_common(struct zx_ctx* c, struct zx_elem_s* x, int size, int dup_strs);
void  zx_dup_strs_common(struct zx_ctx* c, struct zx_elem_s* x);
int   zx_walk_so_unknown_attributes(struct zx_ctx* c, struct zx_elem_s* x, void* ctx, int (*callback)(struct zx_node_s* node, void* ctx));
int   zx_walk_so_unknown_elems_and_content(struct zx_ctx* c, struct zx_elem_s* x, void* ctx, int (*callback)(struct zx_node_s* node, void* ctx));
struct zx_elem_s* zx_deep_clone_elems(struct zx_ctx* c, struct zx_elem_s* x, int dup_strs);
int   zx_walk_so_elems(struct zx_ctx* c, struct zx_elem_s* se, void* ctx, int (*callback)(struct zx_node_s* node, void* ctx));
void  zx_dup_strs_elems(struct zx_ctx* c, struct zx_elem_s* se);
#endif

void  zx_xml_parse_err(struct zx_ctx* c, char quote, const char* func, const char* msg);
void  zx_xml_parse_dbg(struct zx_ctx* c, char quote, const char* func, const char* msg);
struct zx_ns_s* zx_xmlns_detected(struct zx_ctx* c, struct zx_elem_s* x, const char* data);

int   zx_in_inc_ns(struct zx_ctx* c, struct zx_ns_s* new_ns);
struct zx_el_tok* zx_get_el_tok(struct zx_elem_s* x);

void  zx_prepare_dec_ctx(struct zx_ctx* c, struct zx_ns_s* ns_tab, int n_ns, const char* start, const char* lim);
struct zx_root_s* zx_dec_zx_root(struct zx_ctx* c, int len, const char* start, const char* func);
void zx_DEC_elem(struct zx_ctx* c, struct zx_elem_s* x);
struct zx_el_desc* zx_el_desc_lookup(int tok);

#define SIG_ALGO_RSA_SHA1_URLENC   "http://www.w3.org/2000/09/xmldsig%23rsa-sha1"
#define SIG_ALGO_RSA_SHA224_URLENC "http://www.w3.org/2001/04/xmldsig-more%23rsa-sha224"
#define SIG_ALGO_RSA_SHA256_URLENC "http://www.w3.org/2001/04/xmldsig-more%23rsa-sha256"
#define SIG_ALGO_RSA_SHA384_URLENC "http://www.w3.org/2001/04/xmldsig-more%23rsa-sha384"
#define SIG_ALGO_RSA_SHA512_URLENC "http://www.w3.org/2001/04/xmldsig-more%23rsa-sha512"
#define SIG_ALGO_DSA_SHA1_URLENC   "http://www.w3.org/2000/09/xmldsig%23dsa-sha1"
#define SIG_ALGO_DSA_SHA224_URLENC "http://www.w3.org/2001/04/xmldsig-more%23dsa-sha224"
#define SIG_ALGO_DSA_SHA256_URLENC "http://www.w3.org/2001/04/xmldsig-more%23dsa-sha256"
#define SIG_ALGO_DSA_SHA384_URLENC "http://www.w3.org/2001/04/xmldsig-more%23dsa-sha384"
#define SIG_ALGO_DSA_SHA512_URLENC "http://www.w3.org/2001/04/xmldsig-more%23dsa-sha512"
#define SIG_ALGO_ECDSA_SHA1_URLENC   "http://www.w3.org/2001/04/xmldsig-more%23ecdsa-sha1"
#define SIG_ALGO_ECDSA_SHA224_URLENC "http://www.w3.org/2001/04/xmldsig-more%23ecdsa-sha224"
#define SIG_ALGO_ECDSA_SHA256_URLENC "http://www.w3.org/2001/04/xmldsig-more%23ecdsa-sha256"
#define SIG_ALGO_ECDSA_SHA384_URLENC "http://www.w3.org/2001/04/xmldsig-more%23ecdsa-sha384"
#define SIG_ALGO_ECDSA_SHA512_URLENC "http://www.w3.org/2001/04/xmldsig-more%23ecdsa-sha512"

#define SIG_ALGO_RSA_SHA1   "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
#define SIG_ALGO_RSA_SHA224 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha224"
#define SIG_ALGO_RSA_SHA256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
#define SIG_ALGO_RSA_SHA384 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384"
#define SIG_ALGO_RSA_SHA512 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512"
#define SIG_ALGO_DSA_SHA1   "http://www.w3.org/2000/09/xmldsig#dsa-sha1"
#define SIG_ALGO_DSA_SHA224 "http://www.w3.org/2009/xmldsig11#dsa-sha224"
#define SIG_ALGO_DSA_SHA256 "http://www.w3.org/2009/xmldsig11#dsa-sha256"
#define SIG_ALGO_DSA_SHA384 "http://www.w3.org/2009/xmldsig11#dsa-sha384"
#define SIG_ALGO_DSA_SHA512 "http://www.w3.org/2009/xmldsig11#dsa-sha512"
#define SIG_ALGO_ECDSA_SHA1   "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha1"
#define SIG_ALGO_ECDSA_SHA224 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha224"
#define SIG_ALGO_ECDSA_SHA256 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"
#define SIG_ALGO_ECDSA_SHA384 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha384"
#define SIG_ALGO_ECDSA_SHA512 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha512"

#define DIGEST_ALGO_SHA1   "http://www.w3.org/2000/09/xmldsig#sha1"
#define DIGEST_ALGO_SHA224 "http://www.w3.org/2001/04/xmldsig-more#sha224"
#define DIGEST_ALGO_SHA256 "http://www.w3.org/2001/04/xmlenc#sha256"
#define DIGEST_ALGO_SHA384 "http://www.w3.org/2001/04/xmldsig-more#sha384"
#define DIGEST_ALGO_SHA512 "http://www.w3.org/2001/04/xmlenc#sha512"

#define SIG_ALGO        SIG_ALGO_RSA_SHA1
#define SIG_ALGO_URLENC SIG_ALGO_RSA_SHA1_URLENC
#define SIG_SIZE 1024  /* Maximum size of the base64 encoded signature, for buffer allocation */
#define DIGEST_ALGO     DIGEST_ALGO_SHA1
#define CANON_ALGO         "http://www.w3.org/2001/10/xml-exc-c14n#"
#define ENVELOPED_ALGO     "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
#define ENC_ALGO_TRIPLEDES_CBC "http://www.w3.org/2001/04/xmlenc#tripledes-cbc"
#define ENC_ALGO_AES128_CBC    "http://www.w3.org/2001/04/xmlenc#aes128-cbc"
#define ENC_ALGO_AES192_CBC    "http://www.w3.org/2001/04/xmlenc#aes192-cbc"
#define ENC_ALGO_AES256_CBC    "http://www.w3.org/2001/04/xmlenc#aes256-cbc"
#define ENC_ALGO_AES256_GCM    "http://www.w3.org/2001/04/xmlenc11#aes256-gcm"
/* #define ENC_ALGO            ENC_ALGO_AES128_CBC  unsafe, see Backwards Compatibility Attacks */
#define ENC_ALGO               ENC_ALGO_AES256_GCM

/* The ENC_KEYTRAN_ALGO setting must agree with setting in zxenc_pubkey_enc()
 * See paper: Tibor Jager, Kenneth G. Paterson, Juraj Somorovsky: "One Bad Apple: Backwards Compatibility Attacks on State-of-the-Art Cryptography", 2013 http://www.nds.ruhr-uni-bochum.de/research/publications/backwards-compatibility/ /t/BackwardsCompatibilityAttacks.pdf
 */

#define ENC_KEYTRAN_RSA_1_5    "http://www.w3.org/2001/04/xmlenc#rsa-1_5"
#define ENC_KEYTRAN_RSA_OAEP   "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
  /*#define ENC_KEYTRAN_ALGO       ENC_KEYTRAN_RSA_1_5 IBM in 2007 needed this, but it is vulnearable to attacks */
#define ENC_KEYTRAN_ALGO       ENC_KEYTRAN_RSA_OAEP

#define ENC_ENCKEY_METH        "http://www.w3.org/2001/04/xmlenc#EncryptedKey"
#define ENC_TYPE_ELEMENT       "http://www.w3.org/2001/04/xmlenc#Element"
#define ENC_TYPE_CONTENT       "http://www.w3.org/2001/04/xmlenc#Content"

#ifdef __cplusplus
} // extern "C"
#endif

#endif

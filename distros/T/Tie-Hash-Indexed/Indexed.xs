/*******************************************************************************
*
* MODULE: Indexed.xs
*
********************************************************************************
*
* DESCRIPTION: XS Interface for Tie::Hash::Indexed Perl extension module
*
********************************************************************************
*
* Copyright (c) 2002-2016 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/


/*===== GLOBAL INCLUDES ======================================================*/

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags

#include "ppport.h"


/*===== DEFINES ==============================================================*/

#define XSCLASS "Tie::Hash::Indexed"

/*-----------------*/
/* debugging stuff */
/*-----------------*/

#define DB_THI_MAIN      0x00000001

#ifdef THI_DEBUGGING
#  define DEBUG_FLAG(flag) \
            (DB_THI_ ## flag & gs_dbflags)
#  define THI_DEBUG(flag, x) \
            do { if (DEBUG_FLAG(flag)) debug_printf x; } while (0)
#  define DBG_CTXT_FMT "%s"
#  define DBG_CTXT_ARG (GIMME_V == G_VOID   ? "0=" : \
                       (GIMME_V == G_SCALAR ? "$=" : \
                       (GIMME_V == G_ARRAY  ? "@=" : \
                                              "?="   \
                       )))
#else
#  define THI_DEBUG(flag, x) (void) 0
#endif

#define THI_DEBUG_METHOD                                                       \
          THI_DEBUG(MAIN, (DBG_CTXT_FMT XSCLASS "::%s\n", DBG_CTXT_ARG, method))

#define THI_DEBUG_METHOD1(fmt, arg1)                                           \
          THI_DEBUG(MAIN, (DBG_CTXT_FMT XSCLASS "::%s(" fmt ")\n",             \
                           DBG_CTXT_ARG, method, arg1))

#define THI_DEBUG_METHOD2(fmt, arg1, arg2)                                     \
          THI_DEBUG(MAIN, (DBG_CTXT_FMT XSCLASS "::%s(" fmt ")\n",             \
                           DBG_CTXT_ARG, method, arg1, arg2))

#define THI_METHOD( name )         const char * const method = #name

/*---------------------------------*/
/* check object against corruption */
/*---------------------------------*/

#define THI_CHECK_OBJECT                                                       \
        do {                                                                   \
          if (THIS == NULL )                                                   \
            Perl_croak(aTHX_ "NULL OBJECT IN " XSCLASS "::%s", method);        \
          if (THIS->signature != THI_SIGNATURE)                                \
          {                                                                    \
            if (THIS->signature == 0xDEADC0DE)                                 \
              Perl_croak(aTHX_ "DEAD OBJECT IN " XSCLASS "::%s", method);      \
            Perl_croak(aTHX_ "INVALID OBJECT IN " XSCLASS "::%s", method);     \
          }                                                                    \
          if (THIS->hv == NULL || THIS->root == NULL)                          \
            Perl_croak(aTHX_ "OBJECT INCONSITENCY IN " XSCLASS "::%s", method);\
        } while (0)

#define THI_CHECK_ITERATOR                                                     \
        do {                                                                   \
          if (SvIVX(THIS->serial) != THIS->orig_serial)                        \
          {                                                                    \
            Perl_croak(aTHX_ "invalid iterator access");                       \
          }                                                                    \
        } while (0)

#define THI_INVALIDATE_ITERATORS  ++SvIVX(THIS->serial)

#if PERL_BCDVERSION < 0x5010000
#  define HAS_OP_DOR 0
#  define MY_OP_DOR OP_OR
#else
#  define HAS_OP_DOR 1
#  define MY_OP_DOR OP_DOR
#endif

/*--------------------------------*/
/* very simple doubly linked list */
/*--------------------------------*/

#define IxLink_new(link)                                                       \
        do {                                                                   \
          New(0, link, 1, IxLink);                                             \
          (link)->key = NULL;                                                  \
          (link)->val = NULL;                                                  \
          (link)->prev = (link)->next = link;                                  \
        } while (0)

#define IxLink_delete(link)                                                    \
        do {                                                                   \
          Safefree(link);                                                      \
          link = NULL;                                                         \
        } while (0)

#define IxLink_common_(root, link, prev, next)                                 \
        do {                                                                   \
          (link)->prev       = (root)->prev;                                   \
          (link)->next       = (root);                                         \
          (root)->prev->next = (link);                                         \
          (root)->prev       = (link);                                         \
        } while (0)

#define IxLink_push(root, link)                                                \
          IxLink_common_(root, link, prev, next)

#define IxLink_unshift(root, link)                                             \
          IxLink_common_(root, link, next, prev)

#define IxLink_extract(link)                                                   \
        do {                                                                   \
          (link)->prev->next = (link)->next;                                   \
          (link)->next->prev = (link)->prev;                                   \
          (link)->next       = (link);                                         \
          (link)->prev       = (link);                                         \
        } while (0)


/*===== TYPEDEFS =============================================================*/

typedef struct sIxLink IxLink;

struct sIxLink {
  SV     *key;
  SV     *val;
  IxLink *prev;
  IxLink *next;
};

typedef struct {
  HV     *hv;
  IxLink *root;
  IxLink *iter;
  SV     *serial;
  U32     signature;
#define THI_SIGNATURE 0x54484924
} IXHV;

typedef struct {
  IxLink *cur;
  IxLink *end;
  bool reverse;
  SV     *serial;
  IV      orig_serial;
} Iterator;

/*---------------*/
/* serialization */
/*---------------*/

typedef struct {
    char id[4];
#define THI_SERIAL_ID          "THI!"   /* this must _never_ be changed */
    unsigned char major;
#define THI_SERIAL_REV_MAJOR    0        /* incompatible changes */
    unsigned char minor;
#define THI_SERIAL_REV_MINOR    0        /* compatible changes */
} SerialRev;

typedef struct {
  SerialRev rev;
  /* add configuration items here, don't change order, only use bytes */
} Serialized;


/*===== STATIC VARIABLES =====================================================*/

#ifdef THI_DEBUGGING
static U32 gs_dbflags;
#endif


/*===== STATIC FUNCTIONS =====================================================*/

#ifdef THI_DEBUGGING
static void debug_printf(char *f, ...)
{
#ifdef PERL_IMPLICIT_SYS
  dTHX;
#endif
  va_list l;
  va_start(l, f);
  vfprintf(stderr, f, l);
  va_end(l);
}

static void set_debug_opt(pTHX_ const char *dbopts)
{
  if (strEQ(dbopts, "all"))
  {
    gs_dbflags = 0xFFFFFFFF;
  }
  else
  {
    gs_dbflags = 0;
    while (*dbopts)
    {
      switch (*dbopts)
      {
        case 'd': gs_dbflags |= DB_THI_MAIN;  break;
        default:
          Perl_croak(aTHX_ "Unknown debug option '%c'", *dbopts);
          break;
      }
      dbopts++;
    }
  }
}
#endif

#ifndef HeVAL
# define HeVAL(he) (he)->hent_val
#endif

#ifndef HvUSEDKEYS
# define HvUSEDKEYS(hv) HvKEYS(hv)
#endif

#ifndef SvREFCNT_dec_NN
# define SvREFCNT_dec_NN(sv) SvREFCNT_dec(sv)
#endif

enum store_mode {
  SM_SET,
  SM_PUSH,
  SM_UNSHIFT,
  SM_GET,
  SM_GET_NUM
};

static void ixlink_insert(IxLink *root, IxLink *cur, enum store_mode mode)
{
  switch (mode)
  {
    case SM_UNSHIFT: IxLink_unshift(root, cur); break;
    default:         IxLink_push(root, cur);    break;
  }
}

static IxLink *ixhv_store(pTHX_ IXHV *THIS, SV *key, SV *value, enum store_mode mode)
{
  HE *he;
  SV *pair;
  IxLink *cur;

  if ((he = hv_fetch_ent(THIS->hv, key, 1, 0)) == NULL)
  {
    Perl_croak(aTHX_ "couldn't store value");
  }

  pair = HeVAL(he);

  if (SvTYPE(pair) == SVt_NULL)
  {
    IxLink_new(cur);

    ixlink_insert(THIS->root, cur, mode);

    sv_setiv(pair, PTR2IV(cur));

    cur->key = newSVsv(key);

    if (mode == SM_GET_NUM)
    {
      cur->val = newSViv(0);
    }
    else
    {
      if (mode == SM_GET && !value)
      {
        value = &PL_sv_undef;
      }
      assert(value);
      cur->val = newSVsv(value);
    }
  }
  else
  {
    cur = INT2PTR(IxLink *, SvIVX(pair));

    if (mode < SM_GET)
    {
      if (mode != SM_SET)
      {
        IxLink_extract(cur);
        ixlink_insert(THIS->root, cur, mode);
      }

      sv_setsv(cur->val, value);
    }
  }

  return cur;
}

static void ixhv_clear(pTHX_ IXHV *THIS)
{
  IxLink *cur;

  for (cur = THIS->root->next; cur != THIS->root;)
  {
    IxLink *del = cur;
    cur = cur->next;
    SvREFCNT_dec_NN(del->key);
    SvREFCNT_dec(del->val);
    IxLink_delete(del);
  }

  THIS->root->next = THIS->root->prev = THIS->root;

  hv_clear(THIS->hv);
}

static IxLink *ixhv_find(pTHX_ IXHV *THIS, SV *key)
{
  HE *he;

  if ((he = hv_fetch_ent(THIS->hv, key, 0, 0)) == NULL)
  {
    return NULL;
  }

  return INT2PTR(IxLink *, SvIVX(HeVAL(he)));
}

/*===== XS FUNCTIONS =========================================================*/

MODULE = Tie::Hash::Indexed    PACKAGE = Tie::Hash::Indexed::Iterator

PROTOTYPES: DISABLE

void
Iterator::DESTROY()
  PPCODE:
    SvREFCNT_dec(THIS->serial);
    Safefree(THIS);

void
Iterator::next()
  ALIAS:
    prev = 1

  PREINIT:
    int rvnum = 0;

  PPCODE:
    THI_CHECK_ITERATOR;

    if (GIMME_V == G_ARRAY && THIS->cur != THIS->end)
    {
      EXTEND(SP, 2);
      PUSHs(sv_mortalcopy(THIS->cur->key));
      PUSHs(sv_mortalcopy(THIS->cur->val));
      rvnum = 2;
    }

    THIS->cur = ix == THIS->reverse ? THIS->cur->next : THIS->cur->prev;

    XSRETURN(rvnum);

bool
Iterator::valid()
  CODE:
    RETVAL = SvIVX(THIS->serial) == THIS->orig_serial &&
             THIS->cur != THIS->end;

  OUTPUT:
    RETVAL

void
Iterator::key()
  ALIAS:
    value = 1

  PPCODE:
    THI_CHECK_ITERATOR;
    ST(0) = sv_mortalcopy(ix ? THIS->cur->val : THIS->cur->key);
    XSRETURN(1);


MODULE = Tie::Hash::Indexed    PACKAGE = Tie::Hash::Indexed

PROTOTYPES: DISABLE

################################################################################
#
#   METHOD: TIEHASH
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

IXHV *
TIEHASH(CLASS, ...)
  char *CLASS

  ALIAS:
    new = 1

  PREINIT:
    THI_METHOD(TIEHASH);
    SV **cur;
    SV **end;

  CODE:
    THI_DEBUG_METHOD;
    (void) ix;

    if (items % 2 == 0)
    {
      Perl_croak(aTHX_ "odd number of arguments");
    }

    New(0, RETVAL, 1, IXHV);
    IxLink_new(RETVAL->root);
    RETVAL->iter      = NULL;
    RETVAL->hv        = newHV();
    RETVAL->serial    = newSViv(0);
    RETVAL->signature = THI_SIGNATURE;

    end = &ST(items);
    for (cur = &ST(1); cur < end; cur += 2)
    {
      ixhv_store(aTHX_ RETVAL, cur[0], cur[1], SM_SET);
    }

  OUTPUT:
    RETVAL

################################################################################
#
#   METHOD: DESTROY
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::DESTROY()
  PREINIT:
    THI_METHOD(DESTROY);
    IxLink *cur;

  PPCODE:
    PUTBACK;
    THI_DEBUG_METHOD;
    THI_CHECK_OBJECT;

    THI_INVALIDATE_ITERATORS;

    for (cur = THIS->root->next; cur != THIS->root;)
    {
      IxLink *del = cur;
      cur = cur->next;
      SvREFCNT_dec_NN(del->key);
      SvREFCNT_dec(del->val);
      IxLink_delete(del);
    }

    IxLink_delete(THIS->root);
    SvREFCNT_dec(THIS->hv);
    SvREFCNT_dec(THIS->serial);

    THIS->root      = NULL;
    THIS->iter      = NULL;
    THIS->hv        = NULL;
    THIS->serial    = NULL;
    THIS->signature = 0xDEADC0DE;

    Safefree(THIS);
    return;

################################################################################
#
#   METHOD: FETCH
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::FETCH(key)
  SV *key

  ALIAS:
    get = 1

  PREINIT:
    THI_METHOD(FETCH);
    IxLink *link;

  PPCODE:
    THI_DEBUG_METHOD1("'%s'", SvPV_nolen(key));
    THI_CHECK_OBJECT;
    (void) ix;

    link = ixhv_find(aTHX_ THIS, key);

    ST(0) = link == NULL ? &PL_sv_undef : sv_mortalcopy(link->val);

    XSRETURN(1);

################################################################################
#
#   METHOD: STORE
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::STORE(key, value)
  SV *key
  SV *value

  ALIAS:
    set = 1

  PREINIT:
    THI_METHOD(STORE);

  PPCODE:
    PUTBACK;
    THI_DEBUG_METHOD2("'%s', '%s'", SvPV_nolen(key), SvPV_nolen(value));
    THI_CHECK_OBJECT;
    (void) ix;

    THI_INVALIDATE_ITERATORS;

    ixhv_store(aTHX_ THIS, key, value, SM_SET);
    return;

################################################################################
#
#   METHOD: FIRSTKEY
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::FIRSTKEY()
  PREINIT:
    THI_METHOD(FIRSTKEY);

  PPCODE:
    THI_DEBUG_METHOD;
    THI_CHECK_OBJECT;

    THIS->iter = THIS->root->next;

    if (THIS->iter->key == NULL)
    {
      XSRETURN_UNDEF;
    }

    ST(0) = sv_mortalcopy(THIS->iter->key);
    XSRETURN(1);

################################################################################
#
#   METHOD: NEXTKEY
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::NEXTKEY(last)
  SV *last

  PREINIT:
    THI_METHOD(NEXTKEY);

  PPCODE:
    THI_DEBUG_METHOD1("'%s'", SvPV_nolen(last));
    THI_CHECK_OBJECT;

    THIS->iter = THIS->iter->next;

    if (THIS->iter->key == NULL)
    {
      XSRETURN_UNDEF;
    }

    ST(0) = sv_mortalcopy(THIS->iter->key);
    XSRETURN(1);

################################################################################
#
#   METHOD: EXISTS
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::EXISTS(key)
  SV *key

  ALIAS:
    exists = 1
    has = 2

  PREINIT:
    THI_METHOD(EXISTS);

  PPCODE:
    THI_DEBUG_METHOD1("'%s'", SvPV_nolen(key));
    THI_CHECK_OBJECT;
    (void) ix;

    if (hv_exists_ent(THIS->hv, key, 0))
    {
      XSRETURN_YES;
    }
    else
    {
      XSRETURN_NO;
    }

################################################################################
#
#   METHOD: DELETE
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::DELETE(key)
  SV *key

  ALIAS:
    delete = 1

  PREINIT:
    THI_METHOD(DELETE);
    IxLink *cur;
    SV *sv;

  PPCODE:
    SP++;
    PUTBACK;
    THI_DEBUG_METHOD1("'%s'", SvPV_nolen(key));
    THI_CHECK_OBJECT;
    (void) ix;

    if ((sv = hv_delete_ent(THIS->hv, key, 0, 0)) == NULL)
    {
      THI_DEBUG(MAIN, ("key '%s' not found\n", SvPV_nolen(key)));
      *SP = &PL_sv_undef;
      return;
    }

    THI_INVALIDATE_ITERATORS;

    cur = INT2PTR(IxLink *, SvIVX(sv));
    *SP = sv_2mortal(cur->val);

    if (THIS->iter == cur)
    {
      THI_DEBUG(MAIN, ("need to move current iterator %p -> %p\n",
                       THIS->iter, cur->prev));
      THIS->iter = cur->prev;
    }

    IxLink_extract(cur);
    SvREFCNT_dec_NN(cur->key);
    IxLink_delete(cur);

    THI_DEBUG(MAIN, ("key '%s' deleted\n", SvPV_nolen(key)));

    return;

################################################################################
#
#   METHOD: CLEAR
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::CLEAR()
  ALIAS:
    clear = 1

  PREINIT:
    THI_METHOD(CLEAR);

  PPCODE:
    THI_DEBUG_METHOD;
    THI_CHECK_OBJECT;
    (void) ix;

    THI_INVALIDATE_ITERATORS;

    ixhv_clear(aTHX_ THIS);

    if (ix == 1 && GIMME_V != G_VOID)
    {
      XSRETURN(1);
    }

################################################################################
#
#   METHOD: SCALAR
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2004
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::SCALAR()
  PREINIT:
    THI_METHOD(SCALAR);

  PPCODE:
    THI_DEBUG_METHOD;
    THI_CHECK_OBJECT;
#if defined(hv_scalar) && PERL_BCDVERSION < 0x5025003
    ST(0) = hv_scalar(THIS->hv);
#else
    ST(0) = sv_newmortal();
    if (HvFILL(THIS->hv))
    {
      Perl_sv_setpvf(aTHX_ ST(0), "%ld/%ld", (long)HvFILL(THIS->hv),
                                           (long)HvMAX(THIS->hv)+1);
    }
    else
    {
      sv_setiv(ST(0), 0);
    }
#endif
    XSRETURN(1);

################################################################################
#
#   METHOD: items / as_list / keys / values
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: May 2016
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::items(...)
  ALIAS:
    as_list = 0
    keys = 1
    values = 2

  PREINIT:
    THI_METHOD(items);
    long num_keys;
    long num_items;

  PPCODE:
    THI_DEBUG_METHOD;
    THI_CHECK_OBJECT;

    num_keys = items > 1 ? (items - 1) : HvUSEDKEYS(THIS->hv);
    num_items = (ix == 0 ? 2 : 1)*num_keys;

    if (GIMME_V == G_SCALAR)
    {
      mXPUSHi(num_items);
    }
    else
    {
      if (items == 1)   /* "vanilla" version */
      {
        IxLink *cur;

        EXTEND(SP, num_items);

        for (cur = THIS->root->next; cur != THIS->root; cur = cur->next, num_keys--)
        {
          if (ix != 2) PUSHs(sv_mortalcopy(cur->key));
          if (ix != 1) PUSHs(sv_mortalcopy(cur->val));
        }

        assert(num_keys == 0);
      }
      else   /* slice version */
      {
        SV **end;
        SV **key;
        SV **beg;
        HE *he;

        EXTEND(SP, num_items);

        end = &ST(num_items - 1);
        key = &ST(num_keys - 1);
        beg = &ST(0);

        Move(beg + 1, beg, items, SV *);

        for (; key >= beg; --key)
        {
          if ((he = hv_fetch_ent(THIS->hv, *key, 0, 0)) != NULL)
          {
            if (ix != 1)
            {
              *end-- = sv_mortalcopy((INT2PTR(IxLink *, SvIVX(HeVAL(he))))->val);
            }
          }
          else
          {
            if (ix != 1)
            {
              *end-- = &PL_sv_undef;
            }
          }
          if (ix != 2) *end-- = *key;
        }
      }
      XSRETURN(num_items);
    }

################################################################################
#
#   METHOD: merge / assign / push / unshift
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: May 2016
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::merge(...)
  ALIAS:
    assign = 1
    push = 2
    unshift = 3

  PREINIT:
    THI_METHOD(merge);
    SV **cur;
    SV **end;
    enum store_mode mode = SM_SET;

  PPCODE:
    THI_DEBUG_METHOD;
    THI_CHECK_OBJECT;

    if (items % 2 == 0)
    {
      Perl_croak(aTHX_ "odd number of arguments");
    }

    THI_INVALIDATE_ITERATORS;

    switch (ix)
    {
      case 1: ixhv_clear(aTHX_ THIS); break;
      case 2: mode = SM_PUSH; break;
      case 3: mode = SM_UNSHIFT; break;
    }

    if (mode == SM_UNSHIFT)
    {
      end = &ST(0);
      for (cur = &ST(items - 1); cur > end; cur -= 2)
      {
        ixhv_store(aTHX_ THIS, cur[-1], cur[0], mode);
      }
    }
    else
    {
      end = &ST(items);
      for (cur = &ST(1); cur < end; cur += 2)
      {
        ixhv_store(aTHX_ THIS, cur[0], cur[1], mode);
      }
    }

    if (GIMME_V != G_VOID)
    {
      XSRETURN_IV(HvUSEDKEYS(THIS->hv));
    }

################################################################################
#
#   METHOD: pop / shift
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: May 2016
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::pop()
  ALIAS:
    shift = 1

  PREINIT:
    THI_METHOD(pop);
    IxLink *root;
    IxLink *goner;

  PPCODE:
    THI_DEBUG_METHOD;
    THI_CHECK_OBJECT;

    root = THIS->root;

    if (root->next == root)
    {
      XSRETURN_EMPTY;
    }

    THI_INVALIDATE_ITERATORS;

    goner = ix == 0 ? root->prev : root->next;
    IxLink_extract(goner);

    hv_delete_ent(THIS->hv, goner->key, 0, 0);

    if (GIMME_V == G_ARRAY)
    {
      XPUSHs(sv_2mortal(goner->key));
    }
    else
    {
      SvREFCNT_dec_NN(goner->key);
    }

    XPUSHs(sv_2mortal(goner->val));

    IxLink_delete(goner);

################################################################################
#
#   METHOD: iterator / reverse_iterator
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: May 2016
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::iterator()
  ALIAS:
    reverse_iterator = 1

  PREINIT:
    THI_METHOD(iterator);
    Iterator *it;

  PPCODE:
    THI_DEBUG_METHOD;

    New(0, it, 1, Iterator);
    it->cur     = ix == 1 ? THIS->root->prev : THIS->root->next;
    it->end     = THIS->root;
    it->reverse = ix == 1;
    it->serial  = THIS->serial;
    it->orig_serial = SvIVX(it->serial);

    SvREFCNT_inc_simple_void_NN(it->serial);

    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), "Tie::Hash::Indexed::Iterator", (void *) it);
    XSRETURN(1);

################################################################################
#
#   METHOD: preinc / postinc / predec / postdec
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: May 2016
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::preinc(key)
  SV *key

  ALIAS:
    predec = 1
    postinc = 2
    postdec = 3

  PREINIT:
    THI_METHOD(preinc);
    IxLink *link;
    SV *orig = NULL;

  PPCODE:
    THI_DEBUG_METHOD;

    link = ixhv_store(aTHX_ THIS, key, NULL, SM_GET_NUM);

    if (ix >= 2 && GIMME_V != G_VOID)
    {
      orig = sv_mortalcopy(link->val);
    }

    switch (ix)
    {
      case 0:
      case 2: sv_inc(link->val);
              break;

      case 1:
      case 3: sv_dec(link->val);
              break;
    }

    SvSETMAGIC(link->val);

    if (GIMME_V == G_VOID)
    {
      XSRETURN(0);
    }

    ST(0) = orig ? orig : sv_mortalcopy(link->val);
    XSRETURN(1);

################################################################################
#
#   METHOD: add / subtract / multiply / divide / modulo / concat / ...
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: May 2016
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::add(key, val)
  SV *key
  SV *val

  ALIAS:
    subtract = 1
    multiply = 2
    divide = 3
    modulo = 4
    concat = 5
    dor_assign = 6
    or_assign = 7

  PREINIT:
    THI_METHOD(add);
    IxLink *link;
    static const int ops[] = {
      OP_ADD,
      OP_SUBTRACT,
      OP_MULTIPLY,
      OP_DIVIDE,
      OP_MODULO,
      OP_CONCAT,
      MY_OP_DOR,
      OP_OR
    };

  PPCODE:
    THI_DEBUG_METHOD;

    assert(ix < (int)(sizeof(ops)/sizeof(ops[0])));

    link = ixhv_store(aTHX_ THIS, key, NULL, SM_GET);
#if !HAS_OP_DOR
    if (ix == 6)
    {
      if (!SvOK(link->val))
      {
        sv_setsv(link->val, val);
        SvSETMAGIC(link->val);
      }
    }
    else
#endif
    {
      OP *oldop;
      BINOP myop;

      Zero(&myop, 1, struct op);
      myop.op_flags = OPf_STACKED;
      myop.op_type = ops[ix];

      ENTER;
      SAVETMPS;

      PUSHMARK(SP);

      if (myop.op_type == OP_OR || myop.op_type == MY_OP_DOR)
      {
        XPUSHs(val);
        XPUSHs(link->val);
      }
      else
      {
        XPUSHs(link->val);
        XPUSHs(val);
      }

      PUTBACK;

      oldop = PL_op;
      PL_op = (OP *) &myop;
#if PERL_BCDVERSION < 0x5006000
      PL_ppaddr[PL_op->op_type](ARGS);
#else
      PL_ppaddr[PL_op->op_type](aTHX);
#endif
      PL_op = oldop;

      if (myop.op_type == OP_OR || myop.op_type == MY_OP_DOR)
      {
        SPAGAIN;
        sv_setsv(link->val, TOPs);
        SvSETMAGIC(link->val);
      }

      POPMARK;
      FREETMPS;
      LEAVE;
    }

    if (GIMME_V != G_VOID)
    {
      SPAGAIN;
      ST(0) = sv_mortalcopy(link->val);
      XSRETURN(1);
    }

################################################################################
#
#   METHOD: STORABLE_freeze
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
IXHV::STORABLE_freeze(cloning)
  int cloning;

  PREINIT:
    THI_METHOD(STORABLE_freeze);
    Serialized s;
    IxLink *cur;
    long num_keys;

  PPCODE:
    THI_DEBUG_METHOD1("%d", cloning);
    THI_CHECK_OBJECT;

    Copy(THI_SERIAL_ID, &s.rev.id[0], 4, char);
    s.rev.major = THI_SERIAL_REV_MAJOR;
    s.rev.minor = THI_SERIAL_REV_MINOR;

    XPUSHs(sv_2mortal(newSVpvn((char *)&s, sizeof(Serialized))));
    num_keys = HvUSEDKEYS(THIS->hv);
    EXTEND(SP, 2*num_keys);
    for (cur = THIS->root->next; cur != THIS->root; cur = cur->next, num_keys--)
    {
      PUSHs(sv_2mortal(newRV_inc(cur->key)));
      PUSHs(sv_2mortal(newRV_inc(cur->val)));
    }
    assert(num_keys == 0);

################################################################################
#
#   METHOD: STORABLE_thaw
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

void
STORABLE_thaw(object, cloning, serialized, ...)
  SV *object;
  int cloning;
  SV *serialized;

  PREINIT:
    THI_METHOD(STORABLE_thaw);
    IXHV *THIS;
    Serialized *ps;
    STRLEN len;
    int i;

  PPCODE:
    THI_DEBUG_METHOD1("%d", cloning);

    if (!sv_isobject(object) || SvTYPE(SvRV(object)) != SVt_PVMG)
      Perl_croak(aTHX_ XSCLASS "::%s: THIS is not "
                               "a blessed SV reference", method);

    ps = (Serialized *) SvPV(serialized, len);

    if (len < sizeof(SerialRev) ||
        strnNE(THI_SERIAL_ID, &ps->rev.id[0], 4))
      Perl_croak(aTHX_ "invalid frozen "
                       XSCLASS " object (len=%zu)", len);

    if (ps->rev.major != THI_SERIAL_REV_MAJOR)
      Perl_croak(aTHX_ "cannot thaw incompatible "
                       XSCLASS " object");

    /* TODO: implement minor revision handling */

    New(0, THIS, 1, IXHV);
    sv_setiv((SV*)SvRV(object), PTR2IV(THIS));

    THIS->serial = newSViv(0);
    THIS->signature = THI_SIGNATURE;
    THIS->hv = newHV();
    THIS->iter = NULL;
    IxLink_new(THIS->root);

    if ((items-3) % 2)
      Perl_croak(aTHX_ "odd number of items in STORABLE_thaw");

    for (i = 3; i < items; i+=2)
    {
      IxLink *cur;
      SV *key, *val;

      key = SvRV(ST(i));
      val = SvRV(ST(i+1));

      IxLink_new(cur);
      IxLink_push(THIS->root, cur);

      cur->key = newSVsv(key);
      cur->val = newSVsv(val);

      val = newSViv(PTR2IV(cur));

      if (hv_store_ent(THIS->hv, key, val, 0) == NULL)
      {
        SvREFCNT_dec(val);
        Perl_croak(aTHX_ "couldn't store value");
      }
    }

    XSRETURN_EMPTY;

################################################################################
#
#   BOOTCODE
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
#   CHANGED BY:                                   ON:
#
################################################################################

BOOT:
#ifdef THI_DEBUGGING
    {
      const char *str;
      if ((str = getenv("THI_DEBUG_OPT")) != NULL)
        set_debug_opt(aTHX_ str);
    }
#endif

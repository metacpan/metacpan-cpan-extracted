/*
 * Copyright 2011 Alexandr Gomoliako 
 *
 * Copyright (c) 2002-2003 Marcus Holland-Moritz. All rights reserved.
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */

/* based on Tie::Hash::Indexed 0.05 */


#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef THI_DEBUGGING
#define NEED_sv_2pv_nolen
#endif

#include "ppport.h"


#define XSCLASS "Tie::Hash::LRU"

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
#define THI_METHOD_VAR             const char * method = ""
#define THI_METHOD_SET( string )   method = string

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

/*--------------------------------*/
/* very simple doubly linked list */
/*--------------------------------*/

#define IxLink_new(link)                                                       \
        do {                                                                   \
          Newz(0, link, 1, IxLink);                                            \
          (link)->key = NULL;                                                  \
          (link)->val = NULL;                                                  \
          (link)->prev = (link)->next = link;                                  \
        } while (0)

#define IxLink_delete(link)                                                    \
        do {                                                                   \
          Safefree(link);                                                      \
          link = NULL;                                                         \
        } while (0)

#define IxLink_push(root, link)                                                \
        do {                                                                   \
          (link)->prev       = (root)->prev;                                   \
          (link)->next       = (root);                                         \
          (root)->prev->next = (link);                                         \
          (root)->prev       = (link);                                         \
        } while (0)

#define IxLink_unshift(root, link)                                             \
        do {                                                                   \
          (link)->next       = (root)->next;                                   \
          (link)->prev       = (root);                                         \
          (root)->next->prev = (link);                                         \
          (root)->next       = (link);                                         \
        } while (0)

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
  HV        *hv;
  IxLink    *root;
  IxLink    *iter;
  U32        max;
  U32        count;
  U32        signature;
  int        autohit;
#define THI_SIGNATURE 0x54484924
} IXHV;

/*---------------*/
/* serialization */
/*---------------*/

typedef struct {
    char id[4];
#define THI_SERIAL_ID          "THL!"   /* this must _never_ be changed */
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
  va_list l;
  va_start(l, f);
  vfprintf(stderr, f, l);
  va_end(l);
}

static void set_debug_opt(pTHX_ const char *dbopts)
{
  if (strEQ(dbopts, "all"))
    gs_dbflags = 0xFFFFFFFF;
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

static void store(pTHX_ IXHV *THIS, SV *key, SV *value)
{
  HE *he;

  if ((he = hv_fetch_ent(THIS->hv, key, 1, 0)) == NULL)
    Perl_croak(aTHX_ "couldn't store value");
  
  if (SvTYPE(HeVAL(he)) == SVt_NULL)
  {
    IxLink *cur;

    IxLink_new(cur);
    IxLink_unshift(THIS->root, cur);
    sv_setiv(HeVAL(he), PTR2IV(cur));
    cur->key = newSVsv(key);
    cur->val = newSVsv(value);

    if (THIS->count++ >= THIS->max) {
      SV *sv;

      cur = THIS->root->prev;

      if ((sv = hv_delete_ent(THIS->hv, cur->key, 0, 0)) == NULL)
      {
        Perl_croak(aTHX_ "Cannot delete entry: key '%s' not found", SvPV_nolen(cur->key));
      }

      SvREFCNT_dec(cur->key);
      sv = cur->val;

      if (THIS->iter == cur)
      {
        THIS->iter = cur->prev;
      }

      IxLink_extract(cur);
      IxLink_delete(cur);

      THIS->count--;

      SvREFCNT_dec(sv);

    }
  }
  else
    sv_setsv((INT2PTR(IxLink *, SvIV(HeVAL(he))))->val, value);
}


/*===== XS FUNCTIONS =========================================================*/

MODULE = Tie::Hash::LRU		PACKAGE = Tie::Hash::LRU

PROTOTYPES: ENABLE



IXHV *
TIEHASH(CLASS, MAX, ...)
	char *CLASS
	U32   MAX

	PREINIT:
		THI_METHOD(TIEHASH);
		int i;

	CODE:
		THI_DEBUG_METHOD1("'%i'", MAX);

		Newz(0, RETVAL, 1, IXHV);
		IxLink_new(RETVAL->root);
		RETVAL->iter      = NULL;
		RETVAL->hv        = newHV();
		RETVAL->signature = THI_SIGNATURE;
		RETVAL->max       = MAX;
		RETVAL->count     = 0; /* last is a general node */
		RETVAL->autohit   = 1;

		for (i = 2; i < items; i += 2)
		{
		  store(aTHX_ RETVAL, ST(i), ST(i + 1));
		}

	OUTPUT:
		RETVAL


void
IXHV::autohit(AUTOHIT)
	int  AUTOHIT

	PREINIT:
		THI_METHOD(NEXTKEY);

	CODE:
		THI_DEBUG_METHOD;
		THI_CHECK_OBJECT;

		THIS->autohit = AUTOHIT;


void
IXHV::DESTROY()
	PREINIT:
		THI_METHOD(DESTROY);
		IxLink *cur;

	CODE:
		THI_DEBUG_METHOD;
		THI_CHECK_OBJECT;

		for (cur = THIS->root->next; cur != THIS->root;)
		{
		  IxLink *del = cur;
		  cur = cur->next;
		  SvREFCNT_dec(del->key);
                  if (del->val)
		    SvREFCNT_dec(del->val);
		  IxLink_delete(del);
		}

		IxLink_delete(THIS->root);
		SvREFCNT_dec(THIS->hv);

		THIS->max       = 0;
		THIS->count     = 0;
		THIS->root      = NULL;
		THIS->iter      = NULL;
		THIS->hv        = NULL;
		THIS->signature = 0xDEADC0DE;

		Safefree(THIS);


void
IXHV::FETCH(key)
	SV *key

	PREINIT:
		THI_METHOD(FETCH);
		HE *he;
		IxLink *cur;

	PPCODE:
		THI_DEBUG_METHOD1("'%s'", SvPV_nolen(key));
		THI_CHECK_OBJECT;

		if ((he = hv_fetch_ent(THIS->hv, key, 0, 0)) == NULL)
		  XSRETURN_UNDEF;

		if (THIS->autohit) {
		  cur = INT2PTR(IxLink *, SvIV(HeVAL(he))); 

		  IxLink_extract(cur); 
		  IxLink_unshift(THIS->root, cur); 
		}

		ST(0) = sv_mortalcopy((INT2PTR(IxLink *, SvIV(HeVAL(he))))->val);
		XSRETURN(1);


void
IXHV::STORE(key, value)
	SV *key
	SV *value

	PREINIT:
		THI_METHOD(STORE);

	CODE:
		THI_DEBUG_METHOD2("'%s', '%s'", SvPV_nolen(key), SvPV_nolen(value));
		THI_CHECK_OBJECT;

		store(aTHX_ THIS, key, value);


void
IXHV::FIRSTKEY()
	PREINIT:
		THI_METHOD(FIRSTKEY);

	PPCODE:
		THI_DEBUG_METHOD;
		THI_CHECK_OBJECT;

		THIS->iter = THIS->root->next;

		if (THIS->iter->key == NULL)
		  XSRETURN_UNDEF;

		ST(0) = sv_mortalcopy(THIS->iter->key);
		XSRETURN(1);


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
		  XSRETURN_UNDEF;

		ST(0) = sv_mortalcopy(THIS->iter->key);
		XSRETURN(1);


void
IXHV::EXISTS(key)
	SV *key

	PREINIT:
		THI_METHOD(EXISTS);

	PPCODE:
		THI_DEBUG_METHOD1("'%s'", SvPV_nolen(key));
		THI_CHECK_OBJECT;

		if (hv_exists_ent(THIS->hv, key, 0))
		  XSRETURN_YES;
		else
		  XSRETURN_NO;


void
IXHV::DELETE(key)
	SV *key

	PREINIT:
		THI_METHOD(DELETE);
		IxLink *cur;
		SV *sv;

	PPCODE:
		THI_DEBUG_METHOD1("'%s'", SvPV_nolen(key));
		THI_CHECK_OBJECT;

		if ((sv = hv_delete_ent(THIS->hv, key, 0, 0)) == NULL)
		{
		  THI_DEBUG(MAIN, ("key '%s' not found\n", SvPV_nolen(key)));
		  XSRETURN_UNDEF;
		}

		cur = INT2PTR(IxLink *, SvIV(sv));
		SvREFCNT_dec(cur->key);
		sv = cur->val;

		if (THIS->iter == cur)
		{
		  THI_DEBUG(MAIN, ("need to move current iterator %p -> %p\n",
		                   THIS->iter, cur->prev));
		  THIS->iter = cur->prev;
		}

		IxLink_extract(cur);
		IxLink_delete(cur);

		THIS->count--;

		THI_DEBUG(MAIN, ("key '%s' deleted\n", SvPV_nolen(key)));

		ST(0) = sv_2mortal(sv);
		XSRETURN(1);


void
IXHV::CLEAR()
	PREINIT:
		THI_METHOD(CLEAR);
		IxLink *cur;

	PPCODE:
		THI_DEBUG_METHOD;
		THI_CHECK_OBJECT;

		for (cur = THIS->root->next; cur != THIS->root;)
		{
		  IxLink *del = cur;
		  cur = cur->next;
		  SvREFCNT_dec(del->key);
                  if (del->val)
		    SvREFCNT_dec(del->val);
		  IxLink_delete(del);

		  THIS->count--;
		}

		THIS->root->next = THIS->root->prev = THIS->root;

		hv_clear(THIS->hv);


void
IXHV::SCALAR()
	PREINIT:
		THI_METHOD(SCALAR);

	PPCODE:
		THI_DEBUG_METHOD;
		THI_CHECK_OBJECT;
#ifdef hv_scalar
		ST(0) = hv_scalar(THIS->hv);
#else
		ST(0) = sv_newmortal();
		if (HvFILL(THIS->hv)) 
		  Perl_sv_setpvf(aTHX_ ST(0), "%ld/%ld", (long)HvFILL(THIS->hv),
		                                       (long)HvMAX(THIS->hv)+1);
		else
		  sv_setiv(ST(0), 0);
#endif
		XSRETURN(1);


void
IXHV::STORABLE_freeze(cloning)
	int cloning;

	PREINIT:
		THI_METHOD(STORABLE_freeze);
		Serialized s;
		IxLink *cur;
		int n;

	PPCODE:
		THI_DEBUG_METHOD1("%d", cloning);
		THI_CHECK_OBJECT;

		Copy(THI_SERIAL_ID, &s.rev.id[0], 4, char);
		s.rev.major = THI_SERIAL_REV_MAJOR;
		s.rev.minor = THI_SERIAL_REV_MINOR;

		XPUSHs(sv_2mortal(newSVpvn((char *)&s, sizeof(Serialized))));
		n = 1;
		for (cur = THIS->root->next; cur != THIS->root; cur = cur->next)
		{
		  XPUSHs(sv_2mortal(newRV_inc(cur->key)));
		  XPUSHs(sv_2mortal(newRV_inc(cur->val)));
		  n += 2;
		}

		XSRETURN(n);


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
		                   XSCLASS " object (len=%d)", len);

		if (ps->rev.major != THI_SERIAL_REV_MAJOR)
		  Perl_croak(aTHX_ "cannot thaw incompatible "
		                   XSCLASS " object");

		/* TODO: implement minor revision handling */

		Newz(0, THIS, 1, IXHV);
		sv_setiv((SV*)SvRV(object), PTR2IV(THIS));

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


BOOT:
#ifdef THI_DEBUGGING
		{
		  const char *str;
		  if ((str = getenv("THI_DEBUG_OPT")) != NULL)
		    set_debug_opt(aTHX_ str);
		}
#endif


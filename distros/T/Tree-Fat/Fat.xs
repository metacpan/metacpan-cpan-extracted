#include "tietv.h"

#ifdef USING_TV_ARG
# define MYOBJ_ 0,
#else
# define MYOBJ_
#endif

XPVTC *tv_global;
static int Unique=1;

MODULE = Tree::Fat		PACKAGE = Tree::Fat

BOOT:
  tv_global = init_tc((XPVTC*) safemalloc(sizeof(XPVTC)));

PROTOTYPES: ENABLE


void
debug(mask)
	int mask
	CODE:
	tv_set_debug(mask);

void
unique(CLASS, un)
	char *CLASS
	int un;
	CODE:
	Unique = un;

void
new(CLASS)
	char *CLASS;
	PREINIT:
	XPVTV *tv;
	PPCODE:
	tv = init_tv((XPVTV*) safemalloc(sizeof(XPVTV)));
	XPUSHs(sv_setref_pv(sv_newmortal(), CLASS, tv));

void
XPVTV::DESTROY()
	CODE:
	tiefree_tv(THIS);

SV *
XPVTV::FETCH(key)
	char *key
	PREINIT:
	SV **out;
	CODE:
	tc_refocus(tv_global, THIS);
	RETVAL = &PL_sv_undef;
	if (tietc_seek(tv_global, key, Unique)) {
	  key = tietc_fetch(tv_global, &out);
	  RETVAL = *out;
	}
	tc_refocus(tv_global, 0);
	OUTPUT:
	RETVAL

void
XPVTV::insert(key, data)
	char *key
	SV *data
	CODE:
	tc_refocus(tv_global, THIS);
	tietc_seek(tv_global, key, Unique);
	tietc_insert(MYOBJ_ tv_global, key, &data);
	tc_refocus(tv_global, 0);

void
XPVTV::STORE(key, val)
	char *key
	SV *val
	PREINIT:
	XPVTC *tc = tv_global;
	CODE:
	tc_refocus(tc,THIS);
	if (tietc_seek(tc,key, Unique)) {
	  tietc_store(MYOBJ_ tc,&val);
	} else {
	  tietc_insert(MYOBJ_ tc,key,&val);
	}
	tc_refocus(tv_global, 0);

void
XPVTV::DELETE(key)
	char *key
	CODE:
	tc_refocus(tv_global, THIS);
	tietc_seek(tv_global, key, Unique);
	tietc_delete(MYOBJ_ tv_global);
	tc_refocus(tv_global, 0);

int
XPVTV::compress(margin)
	int margin
	CODE:
	tc_refocus(tv_global, THIS);
	RETVAL = tietv_compress(MYOBJ_ tv_global, margin);
	tc_refocus(tv_global, 0);
	OUTPUT:
	RETVAL

int
XPVTV::balance(loose)
	int loose
	CODE:
	tc_refocus(tv_global, THIS);
	RETVAL = tv_balance(tv_global, loose);
	tc_refocus(tv_global, 0);
	OUTPUT:
	RETVAL

void
XPVTV::CLEAR()
	CODE:
	tietv_clear(THIS);

int
XPVTV::EXISTS(key)
	char *key
	PREINIT:
	XPVTC *tc = tv_global;
	CODE:
	tc_refocus(tc, THIS);
	RETVAL = tietc_seek(tc,key, Unique);
	tc_refocus(tc, 0);
	OUTPUT:
	RETVAL

char *
XPVTV::FIRSTKEY()
	PREINIT:
	XPVTC *tc = tv_global;
	SV **out;
	CODE:
	tc_refocus(tc, THIS);
	tc_moveto(tc,-1);
	tc_step(tc,1);
	RETVAL = tietc_fetch(tc, &out);
	tc_refocus(tc, 0);
	OUTPUT:
	RETVAL

char *
XPVTV::NEXTKEY(lastkey)
	char *lastkey
	PREINIT:
	XPVTC *tc = tv_global;
	SV **out;
	CODE:
	tc_refocus(tc, THIS);
	/* Can perl help manage cursors please?! XXX */
	tietc_seek(tc,lastkey, Unique);
	tc_step(tc,1);
	RETVAL = tietc_fetch(tc, &out);
	tc_refocus(tc, 0);
	OUTPUT:
	RETVAL

void
XPVTV::DESTORY()
	CODE:
	tiefree_tv(THIS);

void
XPVTV::unshift(val)
	SV *val
	PREINIT:
	STRLEN n_a;
	XPVTC *tc = tv_global;
	CODE:
	tc_refocus(tc, THIS);
	tc_moveto(tc,-1);
	tietc_insert(MYOBJ_ tc, SvPV(val,n_a), &val);
	tc_refocus(tc, 0);

void
XPVTV::push(val)
	SV *val
	PREINIT:
	STRLEN n_a;
	XPVTC *tc = tv_global;
	CODE:
	tc_refocus(tc, THIS);
	tc_moveto(tc, 1<<30);
	tietc_insert(MYOBJ_ tc, SvPV(val,n_a), &val);
	tc_refocus(tc, 0);

void
XPVTV::stats()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(TvFILL(THIS))));
	XPUSHs(sv_2mortal(newSViv(tieTnWIDTH * TvMAX(THIS))));

void
XPVTV::treestats()
	PREINIT:
	double depth, center;
	PPCODE:
	tc_refocus(tv_global, THIS);
	tietv_treestats(tv_global, &depth, &center);
	XPUSHs(sv_2mortal(newSVpv("fill",0)));
	XPUSHs(sv_2mortal(newSViv(TvFILL(THIS))));
	XPUSHs(sv_2mortal(newSVpv("max",0)));
	XPUSHs(sv_2mortal(newSViv(tieTnWIDTH * TvMAX(THIS))));
	XPUSHs(sv_2mortal(newSVpv("depth",0)));
	XPUSHs(sv_2mortal(newSVnv(depth)));
	XPUSHs(sv_2mortal(newSVpv("center",0)));
	XPUSHs(sv_2mortal(newSVnv(center)));

void
opstats(...)
	PREINIT:
	XPVTC *tc = tv_global;
	I32 val;
	int xx;
	char *name;
	PPCODE:
	xx = 0;
	tc_refocus(tc, 0);
	while (name = tc_getstat(tc, xx++, &val)) {
	  XPUSHs(sv_2mortal(newSVpv(name,0)));
	  XPUSHs(sv_2mortal(newSViv(val)));
	}

void
sizeof(...)
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(tieTnWIDTH)));
	XPUSHs(sv_2mortal(newSViv(sizeof(tieTN))));

void
XPVTV::dump()
	CODE:
	tietv_dump(THIS);

void
XPVTV::new_cursor()
	PREINIT:
	char *CLASS = "Tree::Fat::Remote";
	XPVTC *tc;
	PPCODE:
	/* refcnts XXX */
	tc = init_tc((XPVTC*) safemalloc(sizeof(XPVTC)));
	tc_refocus(tc, THIS);
	XPUSHs(sv_setref_pv(sv_newmortal(), CLASS, tc));


MODULE = Tree::Fat		PACKAGE = Tree::Fat::Remote

void
XPVTC::DESTROY()
	CODE:
	/*warn("TC(%p)->DESTROY\n", THIS);/**/
	if (THIS != tv_global) free_tc(THIS);

XPVTC*
global(...)
	PREINIT:
	char *CLASS = "Tree::Fat::Test::Remote";
	PPCODE:
	assert(tv_global);
	XPUSHs(sv_setref_pv(sv_newmortal(), CLASS, tv_global));

void
XPVTC::stats()
	PREINIT:
	I32 val;
	int xx;
	char *name;
	PPCODE:
	xx = 0;
	while (name = tc_getstat(THIS, xx++, &val)) {
	  XPUSHs(sv_2mortal(newSVpv(name,0)));
	  XPUSHs(sv_2mortal(newSViv(val)));
	}

XPVTV *
XPVTC::focus()
	PREINIT:
	char *CLASS = "Tree::Fat";
	CODE:
	RETVAL = TcTV(THIS);
	OUTPUT:
	RETVAL

void
XPVTC::delete()
	CODE:
	tietc_delete(MYOBJ_ THIS);

void
XPVTC::insert(key, data)
	char *key
	SV *data
	CODE:
	tietc_insert(MYOBJ_ THIS, key, &data);

void
XPVTC::moveto(...)
	PROTOTYPE: $;$
	PREINIT:
	STRLEN n_a;
	SV *where;
	I32 xto=-2;
	CODE:
	if (items == 1) {
	  xto=-1;
	} else {
	  where = ST(1);
	  if (SvNIOK(where)) { xto = SvIV(where); }
	  else if (SvPOK(where)) {
	    char *wh = SvPV(where, n_a);
	    if (strEQ(wh, "start")) xto=-1;
	    else if (strEQ(wh, "end")) {
	      XPVTV *tv = TcTV(THIS);
	      xto=TvFILL(tv);
	    }
	  } else {
	    croak("TC(%p)->moveto(): unknown location", THIS);
	  }
	}
	tc_moveto(THIS, xto);

SV *
XPVTC::pos()
	PREINIT:
	I32 where;
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(tc_pos(THIS))));

int
XPVTC::seek(key)
	char *key
	CODE:
	RETVAL = tietc_seek(THIS, key, Unique);
	OUTPUT:
	RETVAL

void
XPVTC::step(delta)
	int delta
	CODE:
	tc_step(THIS, delta);

void
XPVTC::each(delta)
	int delta;
	PREINIT:
	char *key;
	SV **out;
	PPCODE:
	tc_step(THIS, delta);
	key = tietc_fetch(THIS, &out);
	if (key) {
	  XPUSHs(sv_2mortal(newSVpv(key,0)));
	  XPUSHs(sv_2mortal(newSVsv(*out)));
	}

void
XPVTC::fetch()
	PREINIT:
	char *key;
	SV **out;
	PPCODE:
	key = tietc_fetch(THIS, &out);
	if (key) {
	  XPUSHs(sv_2mortal(newSVpv(key,0)));
	  XPUSHs(sv_2mortal(newSVsv(*out)));
	}

void
XPVTC::store(data)
	SV *data
	CODE:
	tietc_store(MYOBJ_ THIS, &data);

void
XPVTC::dump()
	CODE:
	tietc_dump(THIS);

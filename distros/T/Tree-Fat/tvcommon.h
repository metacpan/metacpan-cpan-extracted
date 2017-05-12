#ifndef _tv_common_
#define _tv_common_

#include "tvcommon0.h"

#ifdef TV_TEST
# ifndef TV_DUMP
#  define TV_DUMP
# endif
# ifndef TV_DEBUG
#  define TV_DEBUG
# endif
#endif

#ifndef dTYPESPEC
# define dTYPESPEC(t)
#endif

struct tn0 {
  dTYPESPEC( tn0 )
  I32		tn_treefill;
  I16		tn_depth;  /*also known as relaxed height*/
  I16		tn_start;
  I16		tn_end;
  I16		pad1;
  struct tn0 *	tn_kids[2];
};

struct xpvtv {
  U32		xtv_flags;
  void		*xtv_root;
  U32		xtv_max;
  U32		xtv_version;
  U32		pad1;
};

struct tce {
  dTYPESPEC( TCE )
  void		*tce_tn;
  I16		tce_flags;
};

struct xpvtc {
  struct xpvtv	*xtc_tv;
  U32		xtc_flags;
  I16		tce_slot;
  I32		xtc_pos;
  U32		xtc_version;
  struct tce	*xtc_path;
#ifdef TV_STATS
  I32		*xtc_stats;
#endif
  I16		xtc_fill;
  I16		xtc_max;
  I16		pad2[3];
};

typedef struct tn0 TN0;
typedef struct xpvtv XPVTV;
typedef struct tce TCE;
typedef struct xpvtc XPVTC;


/*PRIVATE MACROS*/
#define TvMAX(tv)		(tv)->xtv_max
#define TvROOT(tv)		((TN0*)(tv)->xtv_root)
#define TvROOT_set(tv,rt)	(tv)->xtv_root = (rt)
#define TvFILL(tv)		(TvROOT(tv)? TnTREEFILL(TvROOT(tv)) : 0)

#define SCOPE	if(1)

#ifndef TV_FREE
# define TV_FREE(ptr)		TV_PANIC("TV_FREE(%p) unimplemented", ptr);
#endif
#ifndef FREE_XPVTV
# define FREE_XPVTV(tv)		TV_FREE(tv)
#endif
#ifndef FREE_XPVTC
# define FREE_XPVTC(tv)		TV_FREE(tv)
#endif
#ifndef FREE_TN
# define FREE_TN(tv)		TV_FREE(tv)
#endif
#ifndef FREE_TCE
# define FREE_TCE(tv)		TV_FREE(tv)
#endif

#define TnKID(tn,xx)	((TN0*)((TN0*)tn)->tn_kids[xx])
#define TnKID_set(tn,xx,nk)	((TN0*)tn)->tn_kids[xx] = (TN0*)nk
#define TnSTART(tn)	((TN0*)tn)->tn_start
#define TnEND(tn)	((TN0*)tn)->tn_end
#define TnTREEFILL(tn)	((TN0*)tn)->tn_treefill
#define TnDEPTH(tn)	((TN0*)tn)->tn_depth

#define TnLEFT(tn)	TnKID(tn,0)
#define TnRIGHT(tn)	TnKID(tn,1)
#define TnLEFT_set(tn,nk)	TnKID_set(tn,0,nk)
#define TnRIGHT_set(tn,nk)	TnKID_set(tn,1,nk)
#define TnLAST(tn)	(TnEND(tn)-1)
#define TnFILL(tn)	(TnEND(tn) - TnSTART(tn))
#define TnEMPTY(tn)	(TnSTART(tn) == TnEND(tn))
#define TnDEPTHx(tn)	((tn)? TnDEPTH(tn) : 0)
#define TnCALCDEPTH(tn) \
	(1+(TnLEFT(tn) && TnRIGHT(tn) ?			\
	    MAX(TnDEPTH(TnLEFT(tn)),TnDEPTH(TnRIGHT(tn))):	\
	    (TnLEFT(tn)? TnDEPTH(TnLEFT(tn)):		\
	     (TnRIGHT(tn)? TnDEPTH(TnRIGHT(tn)):		\
	      0))))
	/* DO NOT OPTIMIZE until running through the profiler! */

#define TvEMPTY(tv)		(TvFILL(tv)==0)
#define TvVERSION(tv)		(tv)->xtv_version
#define TvFLAGS(tv)		(tv)->xtv_flags
#define TVptv_PARALLEL		0x00000001
#define TvPARALLEL(tv)		(TvFLAGS(tv) & TVptv_PARALLEL)
#define TvPARALLEL_on(tv)	(TvFLAGS(tv) |= TVptv_PARALLEL)
#define TvPARALLEL_off(tv)	(TvFLAGS(tv) &= ~TVptv_PARALLEL)

#define TcTV(tc)		(tc)->xtc_tv
#define TcVERSION(tc)		(tc)->xtc_version
#define TcSYNCCHECK(tc,tv) \
	if (TcVERSION(tc) != TvVERSION(tv)) \
	  TV_PANIC("TV: cursor(0x%p) out of sync with tree(0x%p)", tc,tv);
#define TcMARGIN(tc)		(tc)->xtc_margin
#define TcPATH(tc)		(tc)->xtc_path
#define TcFILL(tc)		(tc)->xtc_fill
#define TcMAX(tc)		(tc)->xtc_max
#define TcPOS(tc)		(tc)->xtc_pos
#define TcNOPOS(tc)		((tc)->xtc_pos==-2)
#define TcFIXDEPTHABOVE(tc, start)		\
STMT_START {					\
  register int _xa;				\
  for (_xa=(start)-1; _xa >= 0; _xa--) {	\
    TN0 *_tn;					\
    assert(_xa < TcFILL(tc));			\
    _tn = (TN0*) CeTN(TcCE(tc,_xa));		\
    assert(_tn);				\
    TnDEPTH(_tn) = TnCALCDEPTH(_tn);		\
    TcRSTAT(tc, TCS_DEPTHCALC, 1);		\
  }						\
} STMT_END

#ifdef TV_TEST
#define CeTRASH(ce)		CeTN_set(ce, (TN0*)0x69696969)
#else
#define CeTRASH(ce)
#endif

#define TcPUSH(tc,tn)				\
STMT_START {					\
  register TCE *_ce;				\
  register TN0 *_topush = (TN0*) (tn);		\
  assert(tc);					\
  assert(_topush);				\
  if (TcFILL(tc)+1 > TcMAX(tc)) tc_extend(tc);	\
  TcFILL(tc)+=1;				\
  _ce = TcCEx(tc);				\
  CeTN_set(_ce, _topush);			\
  CeFLAGS(_ce) = 0;				\
} STMT_END

#define TcPOP(tc)		CeTRASH(TcCEx(tc)); --TcFILL(tc)
#define TcTN(tc,xx)		((TN0*)(tc)->xtc_path[xx].tce_tn)
#define TcTNx(tc)		TcTN(tc,TcFILL(tc)-1)
#define TcSLOT(tc)		(tc)->tce_slot
#define TcCE(tc,xx)		(&(tc)->xtc_path[xx])
#define TcCEx(tc)		(&(tc)->xtc_path[TcFILL(tc)-1])

#ifdef TV_STATS
#define TCS_ROTATE1	0
#define TCS_ROTATE2	1
#define TCS_COPYSLOT	2
#define TCS_STEPNODE	3
#define TCS_INSERT	4
#define TCS_DELETE	5
#define TCS_KEYCMP	6
#define TCS_DEPTHCALC	7
#define TCS_TNRECALC	8
#define TCS_MAX		9
#define TcRSTAT(tc,st,xx)	(tc)->xtc_stats[st] += xx
#define TcSTAT(tc,st)	(tc)->xtc_stats[st]
#else
#define TcRSTAT(tc,st,xx)
#endif

#define TcCUT(tc,at) \
STMT_START {					\
  register int _xa;				\
  for (_xa=(at)+1; _xa < TcFILL(tc); _xa++) {	\
    *TcCE(tc, _xa-1) = *TcCE(tc, _xa);		\
  }						\
  CeTRASH(TcCEx(tc));				\
  --TcFILL(tc);					\
} STMT_END

#define TcFLOW(tc) \
STMT_START {					\
    register TCE *_ce = TcCEx(tc);		\
    if (TcFORWARD(tc)) {			\
      CeRIGHT_off(_ce);				\
      CeLEFT_on(_ce);				\
    } else {					\
      CeLEFT_off(_ce);				\
      CeRIGHT_on(_ce);				\
    }						\
} STMT_END

#define TcFLOWx(tc,dir) \
STMT_START {					\
  TcFORWARD_off(tc);				\
  if (dir > 0) TcFORWARD_on(tc);		\
  TcFLOW(tc);					\
} STMT_END

/* rename to STEPFWD? */
#define TcGOFWD(tc) \
STMT_START {					\
  if (!TcFORWARD(tc)) {				\
    register TCE *_ce = TcCEx(tc);		\
    DEBUG_step(warn("going FORWARD"));		\
    if (CeRIGHT(_ce)) {				\
      CeRIGHT_off(_ce);				\
      CeLEFT_on(_ce);				\
    }						\
    TcFORWARD_on(tc);				\
  }						\
} STMT_END

#define TcGOBWD(tc) \
STMT_START {					\
  if (TcFORWARD(tc)) {				\
    register TCE *ce = TcCEx(tc);		\
    DEBUG_step(warn("going BACKWARD"));		\
    if (CeLEFT(ce)) {				\
      CeLEFT_off(ce);				\
      CeRIGHT_on(ce);				\
    }						\
    TcFORWARD_off(tc);				\
  }						\
} STMT_END

#define CeTN(ce)		((TN0*)(ce)->tce_tn)
#define CeTN_set(ce,tn)		(ce)->tce_tn = tn
#define CeFLAGS(ce)		(ce)->tce_flags

#define CEptv_LEFT		0x0001
#define CEptv_RIGHT		0x0002
#define CeLEFT(ce)		(CeFLAGS(ce) & CEptv_LEFT)
#define CeLEFT_on(ce)		(CeFLAGS(ce) |= CEptv_LEFT)
#define CeLEFT_off(ce)		(CeFLAGS(ce) &= ~CEptv_LEFT)
#define CeRIGHT(ce)		(CeFLAGS(ce) & CEptv_RIGHT)
#define CeRIGHT_on(ce)		(CeFLAGS(ce) |= CEptv_RIGHT)
#define CeRIGHT_off(ce)		(CeFLAGS(ce) &= ~CEptv_RIGHT)

#define TcFLAGS(tc)		(tc)->xtc_flags
#define TCptv_MATCH		0x00000001
#define TCptv_FORWARD		0x00000002
#define TCptv_START		0x00000004
#define TCptv_END		0x00000008
#define TCptv_DEBUGSEEK		0x00000010
#define TcMATCH(tc)		(TcFLAGS(tc) & TCptv_MATCH)
#define TcMATCH_on(tc)		(TcFLAGS(tc) |= TCptv_MATCH, \
				 TcFLAGS(tc) &= ~(TCptv_START|TCptv_END))
#define TcMATCH_off(tc)		(TcFLAGS(tc) &= ~TCptv_MATCH)
#define TcFORWARD(tc)		(TcFLAGS(tc) & TCptv_FORWARD)
#define TcBACKWARD(tc)		(!TcFORWARD(tc))
#define TcFORWARD_on(tc)	(TcFLAGS(tc) |= TCptv_FORWARD)
#define TcFORWARD_off(tc)	(TcFLAGS(tc) &= ~TCptv_FORWARD)
#define TcSTART(tc)		(TcFLAGS(tc) & TCptv_START)
#define TcSTART_on(tc)		(TcFLAGS(tc) |= TCptv_START)
#define TcEND(tc)		(TcFLAGS(tc) & TCptv_END)
#define TcEND_on(tc)		(TcFLAGS(tc) |= TCptv_END)
#define TcSTARTEND_off(tc)	(TcFLAGS(tc) &= ~(TCptv_START|TCptv_END))
#define TcDEBUGSEEK(tc)		(TcFLAGS(tc) & TCptv_DEBUGSEEK)

#ifdef TV_DEBUG
#define DEBUG_step(a)   if (tv_debug & 1)  a
#define DEBUG_rotate(a) if (tv_debug & 2)  a
#define DEBUG_seek(a)   if (tv_debug & 4)  a
#else
#define DEBUG_step(a)
#define DEBUG_rotate(a)
#define DEBUG_seek(a)
#endif

XPVTV *init_tv(XPVTV *tv);
int tv_balance(XPVTC *tc, int looseness);

XPVTC *init_tc(XPVTC *tc);
void free_tc(XPVTC *tc);
void tc_refocus(XPVTC *tc, XPVTV *tv);
void tc_reset(XPVTC *tc);
I32 tc_pos(XPVTC *tc);
void tc_moveto(XPVTC *tc, I32 xto);
int tc_step(XPVTC *tc, I32 delta);

#ifdef TV_DEBUG
void tv_set_debug(int mask);
#endif

#ifdef TV_STATS
char *tc_getstat(XPVTC *tc, int xx, I32 *val);
void tv_treestats(XPVTC *tc, double *depth, double *center);
#endif

/*PRIVATE*/
void tc_extend(XPVTC *tc);
void tc_reset(XPVTC *tc);
void tc_adjust_treefill(XPVTC *tc, int delta);
int tc_stepnode(XPVTC *tc, I32 delta);
void tn_recalc(XPVTC *tc, TN0 *tn);
int tc_rotate(XPVTC *tc, int looseness);
int tc_freetn(XPVTC *tc, XPVTV *tv, TN0 *tn, void(*dtor)(TN0*));
void tv_recalc(XPVTV *tv);
void *tv_testmalloc(size_t size);
/*#define tv_memcpy tv_memmove  /*optimize XXX*/
/*void tv_memmove(void *dst, void *src, int len);*/

#endif

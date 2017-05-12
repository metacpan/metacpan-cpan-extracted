#include "tvcommon.h"

#undef MIN
#define	MIN(a, b)	((a) < (b) ? (a) : (b))
#undef MAX
#define	MAX(a, b)	((a) < (b) ? (b) : (a))


#ifdef TV_TEST

#undef assert
#define assert(what)						\
if (!(what)) {							\
	    croak("Assertion failed: file \"%s\", line %d",	\
		__FILE__, __LINE__);				\
	    exit(1);						\
}

#else
#undef assert
#define assert(s)
#endif

#define PRIVATE  /*like C++!*/

/* CCov: fatal TV_PANIC */
/* CCov: off */

#ifdef TV_DEBUG
static int tv_debug=0;
void
tv_set_debug(int mask)
{
  tv_debug = mask;
}
#endif

#ifdef TV_TEST
void *
tv_testmalloc(size_t size)
{
  void *ptr;
  ptr = safemalloc(size);
  if (ptr != 0) {
    memset(ptr, 0x69, size); /* total paranoia */
    return ptr;
  } else {
    TV_PANIC("out of memory!");
    return 0;
  }
}
#endif

/* CCov: on */

XPVTV *
init_tv(XPVTV *tv)
{
  assert(tv);
  TvFLAGS(tv)=0;
  TvROOT_set(tv,0);
  TvMAX(tv)=0;
  TvVERSION(tv)=0;
  return tv;
}

static void
tc_settce(XPVTC *tc, TCE *tce)
{
  assert(tc);
  assert(tce);
  if (TcPATH(tc)) {
    FREE_TCE(TcPATH(tc));
  }
  TcPATH(tc) = tce;
}

PRIVATE void
tc_extend(XPVTC *tc)
{
  TCE *ce2;
  assert(tc);
  TcMAX(tc) += 7;		/* cursors already grow exponentially */
  NEW_TCE(ce2, tc, TcMAX(tc));
  /*  Copy(TcPATH(tc), ce2, TcFILL(tc), TCE); /* Copy is a perl macro! XXX */
  memcpy(ce2, TcPATH(tc), TcFILL(tc)*sizeof(TCE));
  tc_settce(tc, ce2);
}

PRIVATE void
tc_reset(XPVTC *tc)
{
  XPVTV *tv;
  tv=TcTV(tc);
  assert(tc);
  assert(tv);
  TcVERSION(tc) = TvVERSION(tv);
  TcMATCH_off(tc);
  TcSTARTEND_off(tc);
  TcFILL(tc) = 0;
  TcSTART_on(tc);
  TcPOS(tc) = -1;
  TcFORWARD_on(tc);
}

void
tc_refocus(XPVTC *tc, XPVTV *tv)
{
  TcTV(tc) = tv;
  if (tv) tc_reset(tc);
}

XPVTC *
init_tc(XPVTC *tc)
{
  TCE *tce2;
  assert(tc);
  TcTV(tc) = 0;
  TcFLAGS(tc) = 0;
#ifdef TV_STATS
  tc->xtc_stats = (I32*) safemalloc(sizeof(I32)*TCS_MAX); /* XXX */
  SCOPE {
    int xa;
    for (xa=0; xa < TCS_MAX; xa++) {
      TcSTAT(tc,xa) = 0;
    }
  }
#endif
  TcMAX(tc) = 7;
  TcPATH(tc) = 0;
  /* Cannot scale proportional to TvMAX because TV might not be set! */
  NEW_TCE(tce2, tc,TcMAX(tc));
  tc_settce(tc, tce2);
  return tc;
}

void
free_tc(XPVTC *tc)
{
  assert(TcPATH(tc));
  FREE_TCE(TcPATH(tc));
#ifdef TV_STATS
  safefree(tc->xtc_stats); /*macroize XXX*/
#endif
  FREE_XPVTC(tc);
}

PRIVATE void
tc_adjust_treefill(XPVTC *tc, int delta)
{
  register int lx;
  assert(tc);
  for (lx=0; lx < TcFILL(tc); lx++) {
    TnTREEFILL(TcTN(tc, lx)) += delta;
  }
}

I32
tc_pos(XPVTC *tc)
{
  XPVTV *tv;
  assert(tc);
  tv=TcTV(tc);
  TcSYNCCHECK(tc,tv);
  if (TcMATCH(tc)) {
    return TcPOS(tc);
  } else if (TcPOS(tc) == -1) {  /*cover both at START cases */
    return -1;
  } else if (TcEND(tc)) {
    return TcPOS(tc);
  } else if (TcPOS(tc) == TvFILL(tv)-1) { /*at END (no match)*/
    return TcPOS(tc)+1;
  } else {
    TV_PANIC("TV: attempt to get the position of an unpositioned cursor");
    return 0;
  }
}

PRIVATE int
tc_stepnode(XPVTC *tc, I32 delta)
{
  assert(tc);
  /*  TcSYNCCHECK(tc); assume caller already checked */
  DEBUG_step(warn("step node %d", delta));
  if (TcFILL(tc)==0) {
    XPVTV *tv;
    TN0 *tn;
    tv=TcTV(tc);
    tn = TvROOT(tv);
    if (!tn) {
      return 0;
    } else if ((TcSTART(tc) && delta < 0) ||
	       (TcEND(tc)   && delta > 0) /*OK*/) {
      DEBUG_step(warn("stepped beyond range"));
      return 0;
    }
    TcSTARTEND_off(tc);
    TcPUSH(tc, tn);
  }
  if (delta > 0) {
    TcGOFWD(tc);
    do {
      register TCE *ce;
      register TN0 *down;
    FORWARD:
      TcRSTAT(tc, TCS_STEPNODE, 1);
      ce = TcCEx(tc);
      if (!CeLEFT(ce) && !CeRIGHT(ce)) {
	DEBUG_step(warn("left extreme"));
	CeLEFT_on(ce);
	while (down = TnLEFT(CeTN(ce))) {
	  TcPUSH(tc, down);
	  ce = TcCEx(tc);
	  CeLEFT_on(ce);
	}
	--delta;
	continue;
      }
      --delta;
      if (!CeRIGHT(ce) && (down = TnRIGHT(CeTN(ce)))) {
	DEBUG_step(warn("right"));
	CeLEFT_off(ce);
	CeRIGHT_on(ce);
	TcPUSH(tc, down);
	goto FORWARD;
      }
      DEBUG_step(warn("popping"));
      do {
	TcPOP(tc);
	if (TcFILL(tc) == 0) {
	  delta=0;
	  break;
	}
      } while (CeRIGHT(TcCEx(tc)));
    } while (delta > 0);
  }
  else if (delta < 0) {
    TcGOBWD(tc);
    do {
      register TCE *ce;
      register TN0 *down;
    BACKWARD:
      TcRSTAT(tc, TCS_STEPNODE, 1);
      ce = TcCEx(tc);
      if (!CeRIGHT(ce) && !CeLEFT(ce)) {
	DEBUG_step(warn("right extreme"));
	CeRIGHT_on(ce);
	while (down = TnRIGHT(CeTN(ce))) {
	  TcPUSH(tc, down);
	  ce = TcCEx(tc);
	  CeRIGHT_on(ce);
	}
	++delta;
	continue;
      }
      ++delta;
      if (!CeLEFT(ce) && (down = TnLEFT(CeTN(ce)))) {
	DEBUG_step(warn("left"));
	CeRIGHT_off(ce);
	CeLEFT_on(ce);
	TcPUSH(tc, down);
	goto BACKWARD;
      }
      DEBUG_step(warn("popping"));
      do {
	TcPOP(tc);
	if (TcFILL(tc) == 0) {
	  delta=0;
	  break;
	}
      } while (CeLEFT(TcCEx(tc)));
    } while (delta < 0);
  }
  return TcFILL(tc) > 0;
}

PRIVATE void
tn_recalc(XPVTC *tc, TN0 *tn)
{
  int total = TnFILL(tn);
  if (TnLEFT(tn)) { 
    total += TnTREEFILL(TnLEFT(tn)); 
  }
  if (TnRIGHT(tn)) {
    total += TnTREEFILL(TnRIGHT(tn));
  }
  TnTREEFILL(tn) = total;
  TnDEPTH(tn) = TnCALCDEPTH(tn);
  TcRSTAT(tc, TCS_DEPTHCALC, 1);
  TcRSTAT(tc, TCS_TNRECALC, 1);
}

static void
tn_recalc_r(TN0 *tn)
{
  int total = TnFILL(tn);
  if (TnLEFT(tn)) { 
    tn_recalc_r(TnLEFT(tn));
    total += TnTREEFILL(TnLEFT(tn)); 
  }
  if (TnRIGHT(tn)) {
    tn_recalc_r(TnRIGHT(tn));
    total += TnTREEFILL(TnRIGHT(tn));
  }
  TnTREEFILL(tn) = total;
  TnDEPTH(tn) = TnCALCDEPTH(tn);
}

/*------- ------- ------- ------- ------- ------- ------- -------*/

static void
tc_setnode(XPVTC *tc, int level, int top, TN0 *tn)
{
  TCE *down = level+1 < TcFILL(tc)? TcCE(tc,level+1) : 0;
  TCE *ce = TcCE(tc,level);
  assert(tn);
  CeTN_set(ce, tn);
  if (level > 0) {
    TCE *up = TcCE(tc,level-1);
    TN0 *mom = CeTN(up);
    if (top) {
      if (CeLEFT(up)) {
	TnLEFT_set(mom, tn);
      } else {
	TnRIGHT_set(mom, tn);
      }
    } else {
      if (TnLEFT(mom) == tn) {
	CeRIGHT_off(up);
	CeLEFT_on(up);
      } else {
	assert(TnRIGHT(mom) == tn);
	CeLEFT_off(up);
	CeRIGHT_on(up);
      }
      if (down) {
	if (TnLEFT(tn) == CeTN(down)) {
	  CeRIGHT_off(ce);
	  CeLEFT_on(ce);
	} else if (TnRIGHT(tn) == CeTN(down)) {
	  CeLEFT_off(ce);
	  CeRIGHT_on(ce);
	}
      }
    }
  } else {
    XPVTV *tv;
    tv=TcTV(tc);
    TvROOT_set(tv, tn);
    assert(top);
  }
  if (!down) {
    TcFLOW(tc);
  }
}

static int
tc_rotate1(XPVTC *tc, int xl, int looseness)
{
  int forced = looseness < 0;
  TCE *ce1 = TcCE(tc, xl);
  TCE *ce2 = TcCE(tc, xl+1);
  TCE *ce3 = (xl+2 < TcFILL(tc)? TcCE(tc, xl+2) : 0);
  TN0 *n1 = CeTN(ce1);
  TN0 *n2 = CeTN(ce2);
  int side1;
  int side2;
  assert(xl+1 < TcFILL(tc));
  if (CeRIGHT(ce1)) {
    side1 = 0;
    side2 = 1;
  } else {
    side1 = 1;
    side2 = 0;
  }
  SCOPE {
    TN0 *na = TnKID(n1,side1);
    TN0 *nb = TnKID(n2,side1);
    TN0 *nc = TnKID(n2,side2);
    if (forced ||
	MAX(TnDEPTHx(na)+1, TnDEPTHx(nb)) + looseness < TnDEPTHx(nc) /*OK*/) {
      int type;
      TcRSTAT(tc, TCS_ROTATE1, 1);
      if (!ce3) {
	type = 0;
      } else if (CeTN(ce3) == nc) {
	type = 1;
      } else {
	assert(CeTN(ce3) == nb);
	type = 2;
      }
      DEBUG_rotate(warn("rotate L/R type %d/%d at %d", side1, type, xl));
      TnKID_set(n2,side1, n1);
      TnKID_set(n2,side2, nc);
      TnKID_set(n1,side1, na);
      TnKID_set(n1,side2, nb);
      tc_setnode(tc, xl, 1, n2);
      if (type == 0) {
	TcCUT(tc, xl);
      } else if (type == 1) {
	TcCUT(tc, xl);
      } else if (type == 2) {
	tc_setnode(tc, xl+1, 0, n1);
      } else
	croak("assertion failed");
      tn_recalc(tc,n1);
      tn_recalc(tc,n2);
      TcFIXDEPTHABOVE(tc, xl);
      return 1;
    }
  }
  return 0;
}

static int
tc_rotate2(XPVTC *tc, int xl, int looseness)
{
  int forced = looseness < 0;
  TCE *ce1 = TcCE(tc, xl);
  TCE *ce2 = TcCE(tc, xl+1);
  TCE *ce3 = TcCE(tc, xl+2);
  TCE *ce4 = (xl+3 < TcFILL(tc)? TcCE(tc, xl+3) : 0);
  TN0 *n1 = CeTN(ce1);
  TN0 *n2 = CeTN(ce2);
  TN0 *n3 = CeTN(ce3);
  int side1;
  int side2;
  assert(xl+2 < TcFILL(tc));
  if (CeRIGHT(ce1) && CeLEFT(ce2)) {
    side1=0;
    side2=1;
  } else if (CeLEFT(ce1) && CeRIGHT(ce2)) {
    side1=1;
    side2=0;
  } else {
    return 0;
  }
  SCOPE {
    TN0 *na = TnKID(n1,side1);
    TN0 *nb = TnKID(n3,side1);
    TN0 *nc = TnKID(n3,side2);
    if (forced || TnDEPTHx(na)+1 + looseness < TnDEPTH(n3)-1 /*OK*/) {
      int type;
      TcRSTAT(tc, TCS_ROTATE2, 1);
      /*tc_dump(tc);
	warn("level=%d/%d  ce4=%p", xl, TcFILL(tc), ce4? CeTN(ce4) : 0);/**/
      if (!ce4) {
	type = 0;
      } else if (CeTN(ce4) == nc) {
	type = 1;
      } else {
	assert(CeTN(ce4) == nb);
	type = 2;
      }
      DEBUG_rotate(warn("rotate LR/RL type %d/%d at %d", side1, type, xl));
      TnKID_set(n3,side1, n1);
      TnKID_set(n3,side2, n2);
      TnKID_set(n1,side1, na);
      TnKID_set(n1,side2, nb);
      TnKID_set(n2,side1, nc);
      if (type == 0) {
	TcCUT(tc, xl);
	TcCUT(tc, xl+1);
	tc_setnode(tc, xl, 1, n3);
      } else if (type == 1) {
	TcCUT(tc, xl+2);
	tc_setnode(tc, xl, 1, n3);
	tc_setnode(tc, xl+1, 0, n2);
	tc_setnode(tc, xl+2, 0, nc);
      } else if (type == 2) {
	TcCUT(tc, xl+2);
	tc_setnode(tc, xl, 1, n3);
	tc_setnode(tc, xl+1, 0, n1);
	tc_setnode(tc, xl+2, 0, nb);
      } else
	croak("assertion failed");
      tn_recalc(tc,n1);
      tn_recalc(tc,n2);
      tn_recalc(tc,n3);
      TcFIXDEPTHABOVE(tc, xl);
      return 1;
    }
  }
  return 0;
}

PRIVATE int
tc_rotate(XPVTC *tc, int looseness)
{
  int rotations=0;
  int xl;
  assert(TcMATCH(tc));
  if (TcFILL(tc) < 2) return 0;

  for (xl=TcFILL(tc)-3; xl >= 0; xl--) {
    if (tc_rotate2(tc, xl, looseness)) {
      ++rotations;
      if (xl+2 >= TcFILL(tc)) xl--; /* tc_rotate2 might fixup 2 levels */
    } else {
      rotations += tc_rotate1(tc, xl, looseness);
    }
  }
  xl = TcFILL(tc)-2;
  if (xl >= 0) {
    rotations += tc_rotate1(tc, xl, looseness);
  }
  return rotations;
}

PRIVATE int
tc_freetn(XPVTC *tc, XPVTV *tv, TN0 *tn, void(*dtor)(TN0*))
{
  int stepnext=0;
  int left = TnDEPTHx(TnLEFT(tn));
  int right = TnDEPTHx(TnRIGHT(tn));
  assert(TvVERSION(tv) == TcVERSION(tc));
  assert(TnEMPTY(tn));
  while (left || right) {
    if (left > right) {
      CeLEFT_on(TcCEx(tc));
      TcPUSH(tc, TnLEFT(tn));
      tc_rotate1(tc, TcFILL(tc) - 2, -1);
      CeRIGHT_on(TcCEx(tc));
      TcPUSH(tc, TnRIGHT(TcTNx(tc)));
    } else {
      CeRIGHT_on(TcCEx(tc));
      TcPUSH(tc, TnRIGHT(tn));
      tc_rotate1(tc, TcFILL(tc) - 2, -1);
      CeLEFT_on(TcCEx(tc));
      TcPUSH(tc, TnLEFT(TcTNx(tc)));
    }
    assert(TcTNx(tc) == tn);
    left = TnDEPTHx(TnLEFT(tn));
    right = TnDEPTHx(TnRIGHT(tn));
  }
  TcPOP(tc);
  if (TcFILL(tc)) {
    TCE *ce = TcCEx(tc);
    TN0 *mom = CeTN(ce);
    if (TnLEFT(mom) == tn) {
      (*dtor)(tn);
      FREE_TN(tn);
      TnLEFT_set(mom,0);
      TcSLOT(tc) = 0;
    } else {
      assert(tn == TnRIGHT(mom));
      (*dtor)(tn);
      FREE_TN(tn);
      TnRIGHT_set(mom,0);
      TcSLOT(tc) = TnFILL(mom)-1;
      ++stepnext;
    }
    tn_recalc(tc,mom);
    TcFIXDEPTHABOVE(tc, TcFILL(tc)-1);
  } else {
    assert(TvROOT(tv) == tn);
    (*dtor)(tn);
    FREE_TN(tn);
    TvROOT_set(tv,0);
    --TcPOS(tc);
    TcMATCH_off(tc);
    TcSTART_on(tc);
  }
  TvMAX(tv) -= 1;
  return stepnext;
}

PRIVATE void
tv_recalc(XPVTV *tv)
{
  TN0 *top = TvROOT(tv);
  assert(top);
  tn_recalc_r(top);
}

int
tv_balance(XPVTC *tc, int looseness)
{
  int rot;
  int total=0;
  XPVTV *tv;
  tv=TcTV(tc);
  tc_moveto(tc,0);
  TcPOS(tc) = -2;
  do {
    rot = tc_rotate(tc, looseness);
    total += rot;
  } while (tc_stepnode(tc,1));
  ++TvVERSION(tv);
  return total;
}

void
tc_moveto(XPVTC *tc, I32 xto)
{
  XPVTV *tv;
  TCE *ce;
  TN0 *tn, *down;
  register int cur;
  register int tree;

  assert(tc);
  tv=TcTV(tc);
  if (TvFILL(tv) == 0) {
    tc_reset(tc);
    return;
  }
  if (xto <= -1) {
    xto = -1;
    TcPOS(tc)=-1;
  } else if (xto >= TvFILL(tv)) {
    xto = TvFILL(tv);
    TcPOS(tc)=xto-1;
  } else {
    TcPOS(tc)=xto;
  }
  TcMATCH_off(tc);
  TcSTARTEND_off(tc);
  TcFORWARD_on(tc);
  TcVERSION(tc) = TvVERSION(tv);
  TcFILL(tc) = 0;
  TcPUSH(tc, TvROOT(tv));
  cur=0;
  
  /* right to left might be faster when xto > TvFILL(tv)/2 XXX */
 DOWN:
  ce = TcCEx(tc);
  tn = CeTN(ce);
  tree=0;
  if (down = TnLEFT(CeTN(ce))) {
    tree = TnTREEFILL(down);
  }
  if (xto < cur + tree) {
    CeLEFT_on(ce);
    if (down) {
      TcPUSH(tc, down);
      goto DOWN;
    } else {
      CeLEFT_off(ce);
      TcSLOT(tc) = -1;
      return; /* no match at the left most */
    }
  }
  cur += tree;
  if (xto >= cur && xto < cur+TnFILL(tn)) {
    TcSLOT(tc) = xto - cur;
    CeLEFT_on(ce);
    TcMATCH_on(tc);
    return;
  }
  cur += TnFILL(tn);
  CeRIGHT_on(ce);
  if (down = TnRIGHT(CeTN(ce))) {
    tree = TnTREEFILL(down);
    assert(xto <= cur + tree);
    TcPUSH(tc, down);
    goto DOWN;
  }
  TcSLOT(tc) = TnFILL(tn)-1;
  /* no match at the right most */
}

int
tc_step(XPVTC *tc, I32 delta)
{
  XPVTV *tv;
  assert(tc);
  tv=TcTV(tc);
  TcSYNCCHECK(tc,tv);
  if (delta==0) {
    TV_PANIC("TV: cannot step by zero elements");
  }
  DEBUG_step(warn("step %d", delta));
  /* pre-flight check */
  if (TcFILL(tc)==0) {
    TN0 *tn;
    int dir = delta < 0 ? -1 : 1;
    if (!tc_stepnode(tc, dir)) {
      return 0;
    }
    tn = TcTNx(tc);
    TcSLOT(tc) = delta > 0 ? 0 : TnFILL(tn)-1;
    TcPOS(tc) += delta;
    delta -= dir;
  } else {
    if (!TcMATCH(tc)) {
      if (delta < 0) {
	TCE *ce = TcCEx(tc);
	if (TcSLOT(tc) == -1) {
	  ++TcSLOT(tc);
	  ++TcPOS(tc);
	  DEBUG_step(warn("no match at slot=-1"));
	} else {
	  ++delta;
	  DEBUG_step(warn("no match"));
	}
      }
      TcFLOW(tc);
    }
    TcPOS(tc) += delta;
  }
  TcSTARTEND_off(tc);
  TcMATCH_on(tc);
  if (delta > 0) {
    TN0 *tn = TcTNx(tc);
    TcGOFWD(tc);
    if (TcSLOT(tc) + delta < TnFILL(tn)) {
      TcSLOT(tc) += delta;
    } else {
      delta -= TnFILL(tn)-1 - TcSLOT(tc);
      --delta;
      if (!tc_stepnode(tc, 1)) {
	goto DONE;
      }
      assert(TcFILL(tc) > 0);
      tn = TcTNx(tc);
      while (delta >= TnFILL(tn)) {
	delta -= TnFILL(tn);
	if (!tc_stepnode(tc, 1)) {
	  goto DONE;
	}
	assert(TcFILL(tc) > 0);
	tn = TcTNx(tc);
      }
      TcSLOT(tc) = delta;
    }
  } else if (delta < 0) {
    TN0 *tn = TcTNx(tc);
    TcGOBWD(tc);
    if (TcSLOT(tc) + delta >= 0) {
      TcSLOT(tc) += delta;
    } else {
      delta += TcSLOT(tc);
      ++delta;
      if (!tc_stepnode(tc, -1)) {
	goto DONE;
      }
      assert(TcFILL(tc) > 0);
      tn = TcTNx(tc);
      while (-delta >= TnFILL(tn)) {
	delta += TnFILL(tn);
	if (!tc_stepnode(tc, -1)) {
	  goto DONE;
	}
	assert(TcFILL(tc) > 0);
	tn = TcTNx(tc);
      }
      TcSLOT(tc) = TnFILL(tn)-1 +delta;
    }
  }
 DONE:
  if (TcFILL(tc) == 0) {
    TcMATCH_off(tc);
    if (TcFORWARD(tc)) {
      TcPOS(tc) = TvFILL(tv);
      TcEND_on(tc);
    } else {
      TcPOS(tc) = -1;
      TcSTART_on(tc);
    }
    return 0;
  } else {
    TcMATCH_on(tc);
    return 1;
  }
}

/* CCOV: off */

/* avoid surprises with built-in memory copying
   optimize XXX
PRIVATE void
tv_memmove(void *dst, void *src, int len)
{
  unsigned long dstp = (long) dst;
  unsigned long srcp = (long) src;

  if (dstp - srcp >= len) {
    int xx;
    for (xx=0; xx < len; xx++) {
      ((char*)dst)[xx] = ((char*)src)[xx];
    }
  } else {
    int xx;
    for (xx=len-1; xx >= 0; xx--) {
      ((char*)dst)[xx] = ((char*)src)[xx];
    }
  }
}
/**/

#ifdef TV_STATS

char *
tc_getstat(XPVTC *tc, int xx, I32 *val)
{
  assert(val);
  switch (xx) {
  case TCS_ROTATE1: *val = TcSTAT(tc, xx); return "rotate1";
  case TCS_ROTATE2: *val = TcSTAT(tc, xx); return "rotate2";
  case TCS_COPYSLOT: *val = TcSTAT(tc, xx); return "copyslot";
  case TCS_STEPNODE: *val = TcSTAT(tc, xx); return "stepnode";
  case TCS_INSERT: *val = TcSTAT(tc, xx); return "insert";
  case TCS_DELETE: *val = TcSTAT(tc, xx); return "delete";
  case TCS_KEYCMP: *val = TcSTAT(tc, xx); return "keycmp";
  case TCS_DEPTHCALC: *val = TcSTAT(tc, xx); return "depthcalc";
  case TCS_TNRECALC: *val = TcSTAT(tc, xx); return "tn_recalc";
  default: return 0;
  }
}

#endif






/*
Copyright © 1997-1999 Joshua Nathaniel Pritikin.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)
*/

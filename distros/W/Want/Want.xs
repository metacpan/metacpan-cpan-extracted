#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* The most popular error message */
#define TOO_FAR \
  croak("want: Called from outside a subroutine")

/* Between 5.9.1 and 5.9.2 the retstack was removed, and the
   return op is now stored on the cxstack. */
#define HAS_RETSTACK (\
  PERL_REVISION < 5 || \
  (PERL_REVISION == 5 && PERL_VERSION < 9) || \
  (PERL_REVISION == 5 && PERL_VERSION == 9 && PERL_SUBVERSION < 2) \
)

/* After 5.10, the CxLVAL macro was added. */
#ifndef CxLVAL
#  define CxLVAL(cx) cx->blk_sub.lval
#endif

#ifndef OpSIBLING
#  define OpSIBLING(o) o->op_sibling
#endif

/* Stolen from B.xs */

#ifdef PERL_OBJECT
#undef PL_op_name
#undef PL_opargs 
#undef PL_op_desc
#define PL_op_name (get_op_names())
#define PL_opargs (get_opargs())
#define PL_op_desc (get_op_descs())
#endif


/* Stolen from pp_ctl.c (with modifications) */

I32
dopoptosub_at(pTHX_ PERL_CONTEXT *cxstk, I32 startingblock)
{
    dTHR;
    I32 i;
    PERL_CONTEXT *cx;
    for (i = startingblock; i >= 0; i--) {
        cx = &cxstk[i];
        switch (CxTYPE(cx)) {
        default:
            continue;
        /*case CXt_EVAL:*/
        case CXt_SUB:
        case CXt_FORMAT:
            DEBUG_l( Perl_deb(aTHX_ "(Found sub #%ld)\n", (long)i));
            return i;
        }
    }
    return i;
}

I32
dopoptosub(pTHX_ I32 startingblock)
{
    dTHR;
    return dopoptosub_at(aTHX_ cxstack, startingblock);
}

PERL_CONTEXT*
upcontext(pTHX_ I32 count)
{
    PERL_SI *top_si = PL_curstackinfo;
    I32 cxix = dopoptosub(aTHX_ cxstack_ix);
    PERL_CONTEXT *cx;
    PERL_CONTEXT *ccstack = cxstack;
    I32 dbcxix;

    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = dopoptosub_at(aTHX_ ccstack, top_si->si_cxix);
        }
        if (cxix < 0) {
            return (PERL_CONTEXT *)0;
        }
        if (PL_DBsub && cxix >= 0 &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;
        cxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
    }
    cx = &ccstack[cxix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        dbcxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
        /* We expect that ccstack[dbcxix] is CXt_SUB, anyway, the
           field below is defined for any cx. */
        if (PL_DBsub && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub)) {
            cx = &ccstack[dbcxix];
        }
    }
    return cx;
}

/* This one is like upcontext except that, when it's found the
   sub context, it keeps looking to see if the sub was called
   from within a loop. If it was, it returns the loop context
   instead.
   
   Prior to 0.09, find_ancestors_from was called with start equal
   to the oldcop of the sub we're looking for. Unfortunately it's not
   guaranteed that we'll be able to find the sub just by
   traversing the tree from there: Damian Conway reported
   a bug against 0.08, where code like  while(foo) {...}
   -- where foo calls want -- causes a crash on the second
   iteration of the loop. That is because oldcop then
   points to the last cop in the body of the loop, which
   is lexically *ahead* of the calling point.

   Another change in 0.13: if end_of_block == TRUE, then go
   up another level beyond the sub.
*/
PERL_CONTEXT*
upcontext_plus(pTHX_ I32 count, bool end_of_block)
{
    PERL_SI *top_si = PL_curstackinfo;
    I32 cxix = dopoptosub(aTHX_ cxstack_ix);
    PERL_CONTEXT *cx, *tcx;
    PERL_CONTEXT *ccstack = cxstack;
    I32 dbcxix, i;
    bool debugger_trouble;

    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = dopoptosub_at(aTHX_ ccstack, top_si->si_cxix);
        }
        if (cxix < 0) {
            return (PERL_CONTEXT *)0;
        }
        if (PL_DBsub && cxix >= 0 &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;
        cxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
    }
    cx = &ccstack[cxix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        dbcxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
        /* We expect that ccstack[dbcxix] is CXt_SUB, anyway, the
           field below is defined for any cx. */
        if (PL_DBsub && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
        {
            cxix = dbcxix;
            cx = &ccstack[cxix];
        }
    }

    /* Now for the extra bit */
    debugger_trouble = (cx->blk_oldcop->op_type == OP_DBSTATE);

    for (i = cxix-1; i>=0 ; i--) {
        tcx = &ccstack[i];
        switch (CxTYPE(tcx)) {
        case CXt_BLOCK:
            if (debugger_trouble && i > 0) return tcx;
        default:
            continue;
#ifdef CXt_LOOP_PLAIN
        case CXt_LOOP_PLAIN:
#endif
#ifdef CXt_LOOP_FOR
        case CXt_LOOP_FOR:
#endif
#ifdef CXt_LOOP_LIST
        case CXt_LOOP_LIST:
#endif
#ifdef CXt_LOOP_ARY
        case CXt_LOOP_ARY:
#endif
#ifdef CXt_LOOP
        case CXt_LOOP:
#endif
            return tcx;
        case CXt_SUB:
        case CXt_FORMAT:
            return cx;
        }
    }
    return ((end_of_block && cxix > 1) ? &ccstack[cxix-1] : cx);
}

/* inspired (loosely) by pp_wantarray */

U8
want_gimme (I32 uplevel)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    if (!cx) TOO_FAR;
    return cx->blk_gimme;
}

/* end thievery and "inspiration" */

#define OPLIST_MAX 50
typedef struct {
    U16 numop_num;
    OP* numop_op;
} numop;

typedef struct {
    U16    length;
    numop  ops[OPLIST_MAX];
} oplist;

#define new_oplist                      (oplist*) malloc(sizeof(oplist))
#define init_oplist(l)                  l->length = 0

numop*
lastnumop(oplist* l)
{
    U16 i;
    numop* ret;

    if (!l) die("Want panicked: null list in lastnumop");
    i = l->length;
    while (i-- > 0) {
        ret = &(l->ops)[i];
        if (ret->numop_op->op_type != OP_NULL && ret->numop_op->op_type != OP_SCOPE) {
            return ret;
        }
    }
    return (numop*)0;
}

/* NB: unlike lastnumop, lastop frees the oplist */
OP*
lastop(oplist* l)
{
    U16 i;
    OP* ret;

    if (!l) die("Want panicked: null list in lastop");
    i  = l->length;
    while (i-- > 0) {
        ret = (l->ops)[i].numop_op;
        if (ret->op_type != OP_NULL
            && ret->op_type != OP_SCOPE
            && ret->op_type != OP_LEAVE) {
            free(l);
            return ret;
        }
    }
    free(l);
    return Nullop;
}

oplist*
pushop(oplist* l, OP* o, U16 i)
{
    I16 len = l->length;
    if (o && len < OPLIST_MAX) {
        ++ l->length;
        l->ops[len].numop_op  = o;
        l->ops[len].numop_num = -1;
    }
    if (len > 0)
        l->ops[len-1].numop_num = i;

    return l;
}

oplist*
find_ancestors_from(OP* start, OP* next, oplist* l)
{
    OP     *o, *p;
    U16    cn = 0;
    U16    ll;
    bool outer_call = FALSE;

    if (!next)
        die("want panicked: I've been asked to find a null return address.\n"
		"  (Are you trying to call me from inside a tie handler?)\n ");
    
    if (!l) {
        outer_call = TRUE;
        l = new_oplist;
        init_oplist(l);
        ll = 0;
    }
    else ll = l->length;
   
    /* printf("Looking for 0x%x starting at 0x%x\n", next, start); */
    for (o = start; o; p = o, o = OpSIBLING(o), ++cn) {
        /* printf("(0x%x) %s -> 0x%x\n", o, PL_op_name[o->op_type], o->op_next);*/

        if (o->op_type == OP_ENTERSUB && o->op_next == next)
            return pushop(l, Nullop, cn);

        if (o->op_flags & OPf_KIDS) {
            U16 ll = l->length;
        
            pushop(l, o, cn);
            if (find_ancestors_from(cUNOPo->op_first, next, l))
                return l;
            else
                l->length = ll;
        }

    }
    return 0;
}

OP*
find_return_op(pTHX_ I32 uplevel)
{
    PERL_CONTEXT *cx = upcontext(aTHX_ uplevel);
    if (!cx) TOO_FAR;
#if HAS_RETSTACK
    return PL_retstack[cx->blk_oldretsp - 1];
#else
    return cx->blk_sub.retop;
#endif
}

OP*
find_start_cop(pTHX_ I32 uplevel, bool end_of_block)
{
    PERL_CONTEXT* cx = upcontext_plus(aTHX_ uplevel, end_of_block);
    if (!cx) TOO_FAR;
    return (OP*) cx->blk_oldcop;
}

/**
 * Return the whole oplist leading down to the subcall.
 * It's the caller's responsibility to free the returned oplist.
 */
oplist*
ancestor_ops (I32 uplevel, OP** return_op_out)
{
    OP* return_op = find_return_op(aTHX_ uplevel);
    OP* start_cop = find_start_cop(aTHX_ uplevel,
	return_op->op_type == OP_LEAVE);
    
    if (return_op_out)
        *return_op_out = return_op;

    return find_ancestors_from(start_cop, return_op, 0);
}

/** Return the parent of the OP_ENTERSUB, or the grandparent if the parent
 *  is an OP_NULL or OP_SCOPE. If the parent precedes the last COP, then return Nullop.
 *  (In that last case, we must be in void context.)
 */
OP*
parent_op (I32 uplevel, OP** return_op_out)
{
    return lastop(ancestor_ops(uplevel, return_op_out));
}

/* forward declaration - mutual recursion */
I32 count_list (OP* parent, OP* returnop);

I32 count_slice (OP* o) {
    OP* pm = cUNOPo->op_first;
    OP* l  = Nullop;
    
    if (pm->op_type != OP_PUSHMARK)
        die("%s", "Want panicked: slice doesn't start with pushmark\n");
        
    if ( (l = OpSIBLING(pm)) && (l->op_type == OP_LIST || (l->op_type == OP_NULL && l->op_targ == OP_LIST)))
        return count_list(l, Nullop);

    else if (l)
        switch (l->op_type) {
        case OP_RV2AV:
        case OP_PADAV:
        case OP_PADHV:
        case OP_RV2HV:
            return 0;
        case OP_HSLICE:
        case OP_ASLICE:
            return count_slice(l);
        case OP_STUB:
            return 1;
        default:
            die("Want panicked: Unexpected op in slice (%s)\n", PL_op_name[l->op_type]);
        }
        
    else
        die("Want panicked: Nothing follows pushmark in slice\n");

    return -999;  /* Should never get here - silence compiler warning */
}

/** Count the number of children of this OP.
 *  Except if any of them is OP_RV2AV or OP_ENTERSUB, return 0 instead.
 *  Also, stop counting if an OP_ENTERSUB is reached whose op_next is <returnop>.
 */
I32
count_list (OP* parent, OP* returnop)
{
    OP* o;
    I32 i = 0;
    
    if (! (parent->op_flags & OPf_KIDS))
        return 0;
        
    /*printf("count_list: returnop = 0x%x\n", returnop);*/
    for(o = cUNOPx(parent)->op_first; o; o=OpSIBLING(o)) {
        /* printf("\t%-8s\t(0x%x)\n", PL_op_name[o->op_type], o->op_next);*/
        if (returnop && o->op_type == OP_ENTERSUB && o->op_next == returnop)
            return i;
        if (o->op_type == OP_RV2AV || o->op_type == OP_RV2HV
         || o->op_type == OP_PADAV || o->op_type == OP_PADHV
         || o->op_type == OP_ENTERSUB)
            return 0;
        
        if (o->op_type == OP_HSLICE || o->op_type == OP_ASLICE) {
            I32 slice_length = count_slice(o);
            if (slice_length == 0)
                return 0;
            else
                i += slice_length - 1;
        }
        else ++i;
    }

    return i;
}

I32
countstack(I32 uplevel)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    I32 oldmarksp;
    I32 mark_from;
    I32 mark_to;

    if (!cx) return -1;

    oldmarksp = cx->blk_oldmarksp;
    mark_from = PL_markstack[oldmarksp];
    mark_to   = PL_markstack[oldmarksp+1];
    return (mark_to - mark_from);
}

AV*
copy_rvals(I32 uplevel, I32 skip)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    I32 oldmarksp;
    I32 mark_from;
    I32 mark_to;
    I32 i;
    AV* a;

    oldmarksp = cx->blk_oldmarksp;
    mark_from = PL_markstack[oldmarksp-1];
    mark_to   = PL_markstack[oldmarksp];

    /*printf("\t(%d -> %d) %d skipping %d\n", mark_from, mark_to, oldmarksp, skip);*/

    if (!cx) return Nullav;
    a = newAV();
    for(i=mark_from+1; i<=mark_to; ++i)
        if (skip-- <= 0) av_push(a, newSVsv(PL_stack_base[i]));
    /* printf("avlen = %d\n", av_len(a)); */

    return a;
}

AV*
copy_rval(I32 uplevel)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    I32 oldmarksp;
    AV* a;

    oldmarksp = cx->blk_oldmarksp;
    if (!cx) return Nullav;
    a = newAV();
    /* printf("oldmarksp = %d\n", oldmarksp); */
    av_push(a, newSVsv(PL_stack_base[PL_markstack[oldmarksp+1]]));

    return a;
}


MODULE = Want           PACKAGE = Want          
PROTOTYPES: ENABLE

SV*
wantarray_up(uplevel)
I32 uplevel;
  PREINIT:
    U8 gimme = want_gimme(uplevel);
  CODE:
    switch(gimme) {
      case G_ARRAY:
        RETVAL = &PL_sv_yes;
        break;
      case G_SCALAR:
        RETVAL = &PL_sv_no;
        break;
      default:
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

U8
want_lvalue(uplevel)
I32 uplevel;
  PREINIT:
    PERL_CONTEXT* cx;
  CODE:
    cx = upcontext(aTHX_ uplevel);
    if (!cx) TOO_FAR;
    
    if (CvLVALUE(cx->blk_sub.cv))
	RETVAL = CxLVAL(cx);
    else
	RETVAL = 0;
  OUTPUT:
    RETVAL


char*
parent_op_name(uplevel)
I32 uplevel;
  PREINIT:
    OP *r;
    OP *o = parent_op(uplevel, &r);
    OP *first, *second;
    char *retval;
  PPCODE:
    /* This is a bit of a cheat, admittedly... */
    if (o && o->op_type == OP_ENTERSUB && (first = cUNOPo->op_first)
          && (second = OpSIBLING(first)) && OpSIBLING(second) != Nullop)
      retval = "method_call";
    else {
      retval = o ? (char *)PL_op_name[o->op_type] : "(none)";
    }
    if (GIMME == G_ARRAY) {
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSVpv(retval, 0)));
	PUSHs(sv_2mortal(newSVpv(PL_op_name[r->op_type], 0)));
    }
    else {
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSVpv(retval, 0)));
    }

#ifdef OPpMULTIDEREF_EXISTS
char*
first_multideref_type(uplevel)
I32 uplevel;
  PREINIT:
    OP *r;
    OP *o = parent_op(uplevel, &r);
    UNOP_AUX_item *items;
    UV actions;
    bool repeat;
    char *retval;
  PPCODE:
    if (o->op_type != OP_MULTIDEREF) Perl_croak(aTHX_ "Not a multideref op!");
    items = cUNOP_AUXx(o)->op_aux;
    actions = items->uv;

    do {
	repeat = FALSE;
	switch (actions & MDEREF_ACTION_MASK) {
	    case MDEREF_reload:
		actions = (++items)->uv;
		repeat = TRUE;
		continue;

	    case MDEREF_AV_pop_rv2av_aelem:
	    case MDEREF_AV_gvsv_vivify_rv2av_aelem:
	    case MDEREF_AV_padsv_vivify_rv2av_aelem:
	    case MDEREF_AV_vivify_rv2av_aelem:
	    case MDEREF_AV_padav_aelem:
	    case MDEREF_AV_gvav_aelem:
		retval = "ARRAY";
		break;

	    case MDEREF_HV_pop_rv2hv_helem:
	    case MDEREF_HV_gvsv_vivify_rv2hv_helem:
	    case MDEREF_HV_padsv_vivify_rv2hv_helem:
	    case MDEREF_HV_vivify_rv2hv_helem:
	    case MDEREF_HV_padhv_helem:
	    case MDEREF_HV_gvhv_helem:
		retval = "HASH";
		break;

	    default:
		Perl_croak(aTHX_ "Unrecognised OP_MULTIDEREF action (%lu)!", actions & MDEREF_ACTION_MASK);
	}
    } while (repeat);

    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpv(retval, 0)));

#endif

I32
want_count(uplevel)
I32 uplevel;
  PREINIT:
    OP* returnop;
    OP* o = parent_op(uplevel, &returnop);
    U8 gimme = want_gimme(uplevel);
  CODE:
    if (o && o->op_type == OP_AASSIGN) {
        I32 lhs = count_list(cBINOPo->op_last,  Nullop  );
        I32 rhs = countstack(uplevel);
        /* printf("lhs = %d, rhs = %d\n", lhs, rhs); */
        if      (lhs == 0) RETVAL = -1;         /* (..@x..) = (..., foo(), ...); */
        else if (rhs >= lhs-1) RETVAL =  0;
        else RETVAL = lhs - rhs - 1;
    }

    else switch(gimme) {
      case G_ARRAY:
        RETVAL = -1;
        break;

      case G_SCALAR:
        RETVAL = 1;
        break;

      default:
        RETVAL = 0;
    }
  OUTPUT:
    RETVAL

bool
want_boolean(uplevel)
I32 uplevel;
  PREINIT:
    oplist* l = ancestor_ops(uplevel, 0);
    U16 i;
    bool truebool = FALSE, pseudobool = FALSE;
  CODE:
    for(i=0; i < l->length; ++i) {
      OP* o = l->ops[i].numop_op;
      U16 n = l->ops[i].numop_num;
      bool v = (OP_GIMME(o, -1) == G_VOID);

      /* printf("%-8s %c %d\n", PL_op_name[o->op_type], (v ? 'v' : ' '), n); */

      switch(o->op_type) {
        case OP_NOT:
        case OP_XOR:
          truebool = TRUE;
          break;
          
        case OP_AND:
          if (truebool || v)
            truebool = TRUE;
          else
            pseudobool = (pseudobool || n == 0);
          break;
          
        case OP_OR:
          if (truebool || v)
            truebool = TRUE;
          else
            truebool = FALSE;
          break;

        case OP_COND_EXPR:
          truebool = (truebool || n == 0);
          break;
        
        case OP_NULL:
          break;
            
        default:
          truebool   = FALSE;
          pseudobool = FALSE;
      }
    }
    free(l);
    RETVAL = truebool || pseudobool;
  OUTPUT:
    RETVAL

SV*
want_assign(uplevel)
U32 uplevel;
  PREINIT:
    AV* r;
    OP* returnop;
    oplist* os = ancestor_ops(uplevel, &returnop);
    numop* lno = os ? lastnumop(os) : (numop*)0;
    OPCODE type;
  PPCODE:
    if (lno) type = lno->numop_op->op_type;
    if (lno && (type == OP_AASSIGN || type == OP_SASSIGN) && lno->numop_num == 1)
      if (type == OP_AASSIGN) {
        I32 lhs_count = count_list(cBINOPx(lno->numop_op)->op_last,  returnop);
        if (lhs_count == 0) r = newAV();
        else {
          r = copy_rvals(uplevel, lhs_count-1);
        }
      }
      else r = copy_rval(uplevel);

    else {
      /* Not an assignment */
      r = Nullav;
    }
    
    if (os) free(os);
    EXTEND(SP, 1);
    PUSHs(r ? sv_2mortal(newRV_noinc((SV*) r)) : &PL_sv_undef);

void
double_return(...)
  PREINIT:
    PERL_CONTEXT *ourcx, *cx;
  PPCODE:
    ourcx = upcontext(aTHX_ 0);
    cx    = upcontext(aTHX_ 1);
    if (!cx)
        Perl_croak(aTHX_ "Can't return outside a subroutine");
#ifdef POPBLOCK
    ourcx->cx_type = CXt_NULL;
    CvDEPTH(ourcx->blk_sub.cv)--;
#  if HAS_RETSTACK
    if (PL_retstack_ix > 0)
        --PL_retstack_ix;
#  endif
#else
    /* In 5.23.8 or later, PL_curpad is saved in the context stack and
     * restored by cx_popsub(), rather than being saved on the savestack
     * and restored by LEAVE; so just CXt_NULLing the parent sub
     * skips the PL_curpad restore and so everything done during the
     * second part of the return will have the wrong PL_curpad.
     * So instead, fix up the first return so that it thinks the
     * op to continue at is iteself, forcing it to do a double return.
     */
    assert(PL_op->op_next->op_type == OP_RETURN);
    /* force the op following the 'return' to be 'return' again */
    ourcx->blk_sub.retop = PL_op->op_next;
    assert(PL_markstack + ourcx->blk_oldmarksp + 1 == PL_markstack_ptr);
    ourcx->blk_oldmarksp++;
    ourcx->blk_gimme = cx->blk_gimme;
#endif

    return;

SV *
disarm_temp(sv)
SV *sv;
  CODE:
    RETVAL = sv_2mortal(SvREFCNT_inc(SvREFCNT_inc(sv)));
  OUTPUT:
    RETVAL

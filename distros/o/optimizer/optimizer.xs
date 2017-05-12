/*  -*- c -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* We have to steal a bunch of code from B.xs so that we can generate
   B objects from ops. Disturbing but true. */

#ifdef PERL_OBJECT
#undef PL_opargs
#define PL_opargs (get_opargs())
#endif

/* For 5.10 we have to provide some fake op_seq and op_seqmax places.
 * op_seq can be stored in the B::OP class (really?), op_seqmax can be a package global.
 */
#if PERL_VERSION > 9
U16     opt_op_seqmax = 0;
#define PL_op_seqmax opt_op_seqmax
#define op_seq_inc_max(o) 		sv_setiv(get_sv("optimize::seq", 1), PL_op_seqmax++)
#else
#define op_seq_inc_max(o) 		o->op_seq = PL_op_seqmax++
#endif

typedef enum { OPc_NULL, OPc_BASEOP, OPc_UNOP, OPc_BINOP, OPc_LOGOP, OPc_LISTOP,
    OPc_PMOP, OPc_SVOP, OPc_PADOP, OPc_PVOP, OPc_CVOP, OPc_LOOP, OPc_COP } opclass;

static char *opclassnames[] = {
    "B::NULL", "B::OP", "B::UNOP", "B::BINOP", "B::LOGOP", "B::LISTOP",
    "B::PMOP", "B::SVOP", "B::PADOP", "B::PVOP", "B::CVOP", "B::LOOP", "B::COP"
};

typedef OP *B__OP;

static opclass
cc_opclass(pTHX_ OP *o)
{
    if (!o)
        return OPc_NULL;

    if (o->op_type == 0)
        return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    if (o->op_type == OP_SASSIGN)
        return ((o->op_private & OPpASSIGN_BACKWARDS) ? OPc_UNOP : OPc_BINOP);

    if (o->op_type == OP_AELEMFAST) {
	if (o->op_flags & OPf_SPECIAL)
	    return OPc_BASEOP;
	else
#ifdef USE_ITHREADS
	    return OPc_PADOP;
#else
	    return OPc_SVOP;
#endif
    }

#ifdef USE_ITHREADS
    if (o->op_type == OP_GV || o->op_type == OP_GVSV ||
	o->op_type == OP_RCATLINE)
	return OPc_PADOP;
#endif

    switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
    case OA_BASEOP: return OPc_BASEOP;
    case OA_UNOP:   return OPc_UNOP;
    case OA_BINOP:  return OPc_BINOP;
    case OA_LOGOP:  return OPc_LOGOP;
    case OA_LISTOP: return OPc_LISTOP;
    case OA_PMOP:   return OPc_PMOP;
    case OA_SVOP:   return OPc_SVOP;
    case OA_PADOP:  return OPc_PADOP;
    case OA_PVOP_OR_SVOP:
        return (o->op_private & (OPpTRANS_TO_UTF|OPpTRANS_FROM_UTF))
                ? OPc_SVOP : OPc_PVOP;
    case OA_LOOP:   return OPc_LOOP;
    case OA_COP:    return OPc_COP;
    case OA_BASEOP_OR_UNOP:
        return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    case OA_FILESTATOP:
        return ((o->op_flags & OPf_KIDS) ? OPc_UNOP :
#ifdef USE_ITHREADS
                (o->op_flags & OPf_REF) ? OPc_PADOP : OPc_BASEOP);
#else
                (o->op_flags & OPf_REF) ? OPc_SVOP : OPc_BASEOP);
#endif
    case OA_LOOPEXOP:
        if (o->op_flags & OPf_STACKED)
            return OPc_UNOP;
        else if (o->op_flags & OPf_SPECIAL)
            return OPc_BASEOP;
        else
            return OPc_PVOP;
    }
    warn("can't determine class of operator %s, assuming BASEOP\n",
	 PL_op_name[o->op_type]);
    return OPc_BASEOP;
}

static char *
cc_opclassname(pTHX_ OP *o)
{
    return opclassnames[cc_opclass(aTHX_ o)];
}

/* We return you to optimizer code. */
static SV* peep_in_perl;

void
peep_callback(pTHX_ OP *o)
{
    /* First we convert the op to a B:: object */
    SV* bobject = newSViv(PTR2IV(o));
    sv_setiv(newSVrv(bobject, cc_opclassname(aTHX_ (OP*)o)), PTR2IV(o));

    /* Call the callback */

    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(bobject));
        PUTBACK;
        call_sv(peep_in_perl, G_DISCARD);

        FREETMPS;
        LEAVE;
    }
    PL_curpad = AvARRAY(PL_comppad);

}

static void
uninstall(pTHX)
{
    PL_peepp = Perl_peep;
    sv_free(peep_in_perl);
}

static void
install(pTHX_ SV* subref)
{
    /* We'll do the argument checking in Perl */
    PL_peepp = peep_callback;
    peep_in_perl = newSVsv(subref); /* Copy to be safe */
}

static void
_relocatetopad(pTHX_ OP* op, CV* cv)
{
#ifdef USE_ITHREADS
  /* Relocate const->op_sv to the pad for thread safety.
   * Despite being a "constant", the SV is written to,
   * for reference counts, sv_upgrade() etc. */
  if ((cc_opclass(aTHX_ op) == OPc_SVOP) && ((SVOP*)op)->op_sv) {
    SV** tmp_pad;
    AV* padlist;
    SV** svp;
    SVOP* o = (SVOP*)op;
    padlist = CvPADLIST(cv);
    svp = AvARRAY(padlist);
    tmp_pad = PL_curpad;
    PL_curpad = AvARRAY((AV*)svp[1]);
    PADOFFSET ix = Perl_pad_alloc(aTHX_ OP_CONST, SVs_PADTMP);
    if (SvPADTMP(o->op_sv)) {
      /* If op_sv is already a PADTMP then it is being used by
       * some pad, so make a copy. */
      sv_setsv(PL_curpad[ix],o->op_sv);
      SvREADONLY_on(PL_curpad[ix]);
      SvREFCNT_dec(o->op_sv);
    }
    else {
      SvREFCNT_dec(PL_curpad[ix]);
      SvPADTMP_on(o->op_sv);
      PL_curpad[ix] = o->op_sv;
      /* XXX I don't know how this isn't readonly already. */
      SvREADONLY_on(PL_curpad[ix]);
    }
    o->op_sv = Nullsv;
    o->op_targ = ix;
    PL_curpad = tmp_pad;
  }
#endif
}

STATIC void
no_bareword_allowed(pTHX_ OP *o)
{
    Perl_qerror(aTHX_ Perl_mess(aTHX_
		     "Bareword \"%s\" not allowed while \"strict subs\" in use",
		     SvPV_nolen(cSVOPo_sv)));
}

/* stolen from ext/B/B.xs */
#if PERL_VERSION >= 9
#  define PMOP_pmreplstart(o)   o->op_pmstashstartu.op_pmreplstart
#else
#  define PMOP_pmreplstart(o)   o->op_pmreplstart
#  define PMOP_pmpermflags(o)   o->op_pmpermflags
#  define PMOP_pmdynflags(o)    o->op_pmdynflags
#endif

void
c_extend_peep(pTHX_ register OP *o)
{
    register OP* oldop = 0;
    STRLEN n_a;
#if PERL_VERSION < 10
    if (!o || o->op_seq)
#else
    if (!o || o->op_opt)
#endif
	return;
    ENTER;
    Perl_save_op(aTHX);
    SAVEVPTR(PL_curcop);
    for (; o; o = o->op_next) {
#if PERL_VERSION < 10
	if (o->op_seq)
	    break;
#else
	if (o->op_opt)
	    break;
	/* By default, this op has now been optimised. A couple of cases below
	   clear this again.  */
	o->op_opt = 1;
#endif
	if (!PL_op_seqmax)
	    PL_op_seqmax++;
	PL_op = o;
	switch (o->op_type) {
#if PERL_VERSION < 11
	case OP_SETSTATE:
#endif
	case OP_NEXTSTATE:
	case OP_DBSTATE:
	    PL_curcop = ((COP*)o);		/* for warnings */
	    op_seq_inc_max(o);
	    break;

	case OP_CONST:
	    if (cSVOPo->op_private & OPpCONST_STRICT)
		no_bareword_allowed(aTHX_ o);
#ifdef USE_ITHREADS
	    /* Relocate sv to the pad for thread safety.
	     * Despite being a "constant", the SV is written to,
	     * for reference counts, sv_upgrade() etc. */
	    if (cSVOP->op_sv) {
		PADOFFSET ix = Perl_pad_alloc(aTHX_ OP_CONST, SVs_PADTMP);
		if (SvPADTMP(cSVOPo->op_sv)) {
		    /* If op_sv is already a PADTMP then it is being used by
		     * some pad, so make a copy. */
		    sv_setsv(PL_curpad[ix],cSVOPo->op_sv);
		    SvREADONLY_on(PL_curpad[ix]);
		    SvREFCNT_dec(cSVOPo->op_sv);
		}
		else {
		    SvREFCNT_dec(PL_curpad[ix]);
		    SvPADTMP_on(cSVOPo->op_sv);
		    PL_curpad[ix] = cSVOPo->op_sv;
		    /* XXX I don't know how this isn't readonly already. */
		    SvREADONLY_on(PL_curpad[ix]);
		}
		cSVOPo->op_sv = Nullsv;
		o->op_targ = ix;
	    }
#endif
	    op_seq_inc_max(o);
	    break;

	case OP_CONCAT:
	    if (o->op_next && o->op_next->op_type == OP_STRINGIFY) {
		if (o->op_next->op_private & OPpTARGET_MY) {
		    if (o->op_flags & OPf_STACKED) /* chained concats */
			goto ignore_optimization;
		    else {
			/* assert(PL_opargs[o->op_type] & OA_TARGLEX); */
			o->op_targ = o->op_next->op_targ;
			o->op_next->op_targ = 0;
			o->op_private |= OPpTARGET_MY;
		    }
		}
		op_null(o->op_next);
	    }
	  ignore_optimization:
	    op_seq_inc_max(o);
	    break;
	case OP_STUB:
	    if ((o->op_flags & OPf_WANT) != OPf_WANT_LIST) {
		op_seq_inc_max(o);
		break; /* Scalar stub must produce undef.  List stub is noop */
	    }
	    goto nothin;
	case OP_NULL:
	    if (o->op_targ == OP_NEXTSTATE
		|| o->op_targ == OP_DBSTATE
#if PERL_VERSION < 11
		|| o->op_targ == OP_SETSTATE
#endif
		)
	    {
		PL_curcop = ((COP*)o);
	    }
	    /* XXX: We avoid setting op_seq here to prevent later calls
	       to peep() from mistakenly concluding that optimisation
	       has already occurred. This doesn't fix the real problem,
	       though (See 20010220.007). AMS 20010719 */
	    /* op_seq functionality is now replaced by op_opt */
#if PERL_VERSION >= 10
	    o->op_opt = 0;
#endif
	    /* FALL THROUGH */
	case OP_SCALAR:
	case OP_LINESEQ:
	case OP_SCOPE:
	  nothin:
	    if (oldop && o->op_next) {
		oldop->op_next = o->op_next;
		continue;
	    }
	    op_seq_inc_max(o);
	    break;

	case OP_PADAV:
	case OP_GV:
	    if (o->op_type == OP_PADAV || o->op_next->op_type == OP_RV2AV) {
		OP* const pop = (o->op_type == OP_PADAV) ?
			    o->op_next : o->op_next->op_next;
		IV i;
		if (pop && pop->op_type == OP_CONST &&
		    (PL_op = pop->op_next) &&
		    pop->op_next->op_type == OP_AELEM &&
		    !(pop->op_next->op_private &
		      (OPpLVAL_INTRO|OPpLVAL_DEFER|OPpDEREF|OPpMAYBE_LVSUB)) &&
		    (i = SvIV(((SVOP*)pop)->op_sv) -
#if PERL_VERSION < 10
		     	PL_curcop->cop_arybase
#else
# if PERL_VERSION < 15
			CopARYBASE_get(PL_curcop)
# else
		        0
# endif
#endif
		     )	<= 255 &&
		    i >= 0)
		{
		    GV *gv;
#if PERL_VERSION >= 10
		    if (cSVOPx(pop)->op_private & OPpCONST_STRICT)
			no_bareword_allowed(aTHX_ pop);
		    if (o->op_type == OP_GV)
			op_null(o->op_next);
#endif
		    op_null(pop->op_next);
		    op_null(pop);
		    o->op_flags |= pop->op_next->op_flags & OPf_MOD;
		    o->op_next = pop->op_next->op_next;
		    o->op_ppaddr = PL_ppaddr[OP_AELEMFAST];
		    o->op_private = (U8)i;
		    if (o->op_type == OP_GV) {
			gv = cGVOPo_gv;
			GvAVn(gv);
		    }
		    else
			o->op_flags |= OPf_SPECIAL;
		    o->op_type = OP_AELEMFAST;
		}
		break;
	    }

	    if (o->op_next->op_type == OP_RV2SV) {
		if (!(o->op_next->op_private & OPpDEREF)) {
		    op_null(o->op_next);
		    o->op_private |= o->op_next->op_private & (OPpLVAL_INTRO
							       | OPpOUR_INTRO);
		    o->op_next = o->op_next->op_next;
		    o->op_type = OP_GVSV;
		    o->op_ppaddr = PL_ppaddr[OP_GVSV];
		}
	    }
	    else if ((o->op_private & OPpEARLY_CV) && ckWARN(WARN_PROTOTYPE)) {
		GV *gv = cGVOPo_gv;
		if (SvTYPE(gv) == SVt_PVGV && GvCV(gv) && SvPVX(GvCV(gv))) {
		    /* XXX could check prototype here instead of just carping */
		    SV *sv = sv_newmortal();
		    gv_efullname3(sv, gv, Nullch);
		    Perl_warner(aTHX_ packWARN(WARN_PROTOTYPE),
				"%s() called too early to check prototype",
				SvPV_nolen(sv));
		}
	    }
	    else if (o->op_next->op_type == OP_READLINE
		    && o->op_next->op_next->op_type == OP_CONCAT
		    && (o->op_next->op_next->op_flags & OPf_STACKED))
	    {
		/* Turn "$a .= <FH>" into an OP_RCATLINE. AMS 20010917 */
		o->op_type   = OP_RCATLINE;
		o->op_flags |= OPf_STACKED;
		o->op_ppaddr = PL_ppaddr[OP_RCATLINE];
		op_null(o->op_next->op_next);
		op_null(o->op_next);
	    }

	    op_seq_inc_max(o);
	    break;

	case OP_MAPWHILE:
	case OP_GREPWHILE:
	case OP_AND:
	case OP_OR:
	case OP_ANDASSIGN:
	case OP_ORASSIGN:
	case OP_COND_EXPR:
	case OP_RANGE:
#if PERL_VERSION >= 10
	case OP_DOR:
	case OP_DORASSIGN:
	case OP_ONCE:
#endif
	    op_seq_inc_max(o);
	    while (cLOGOP->op_other->op_type == OP_NULL)
		cLOGOP->op_other = cLOGOP->op_other->op_next;
	    c_extend_peep(aTHX_ cLOGOP->op_other); /* Recursive calls are not replaced by fptr calls */
	    break;

	case OP_ENTERLOOP:
	case OP_ENTERITER:
	    op_seq_inc_max(o);
	    while (cLOOP->op_redoop->op_type == OP_NULL)
		cLOOP->op_redoop = cLOOP->op_redoop->op_next;
	    c_extend_peep(aTHX_ cLOOP->op_redoop);
	    while (cLOOP->op_nextop->op_type == OP_NULL)
		cLOOP->op_nextop = cLOOP->op_nextop->op_next;
	    c_extend_peep(aTHX_ cLOOP->op_nextop);
	    while (cLOOP->op_lastop->op_type == OP_NULL)
		cLOOP->op_lastop = cLOOP->op_lastop->op_next;
	    c_extend_peep(aTHX_ cLOOP->op_lastop);
	    break;

	case OP_QR:
	case OP_MATCH:
	case OP_SUBST:
	    op_seq_inc_max(o);
	    while (PMOP_pmreplstart(cPMOPo) &&
		   PMOP_pmreplstart(cPMOPo)->op_type == OP_NULL)
	      PMOP_pmreplstart(cPMOPo) = PMOP_pmreplstart(cPMOPo)->op_next;
	    c_extend_peep(aTHX_ PMOP_pmreplstart(cPMOPo));
#if PERL_VERSION >= 10
	    //if (!(cPMOP->op_pmflags & PMf_ONCE)) {
	    //  assert (!PMOP_pmreplstart(cPMOP));
	    //}
#endif
	    break;

	case OP_EXEC:
	    op_seq_inc_max(o);
	    if (ckWARN(WARN_SYNTAX) && o->op_next
		&& o->op_next->op_type == OP_NEXTSTATE) {
		if (o->op_next->op_sibling) {
		    const OPCODE type = o->op_next->op_sibling->op_type;
		    if (type != OP_EXIT && type != OP_WARN && type != OP_DIE) {
			const line_t oldline = CopLINE(PL_curcop);
			CopLINE_set(PL_curcop, CopLINE((COP*)o->op_next));
			Perl_warner(aTHX_ packWARN(WARN_EXEC),
				    "Statement unlikely to be reached");
			Perl_warner(aTHX_ packWARN(WARN_EXEC),
				    "\t(Maybe you meant system() when you said exec()?)\n");
			CopLINE_set(PL_curcop, oldline);
		    }
		}
	    }
	    break;

	case OP_HELEM: {
	    UNOP *rop;
	    SV *lexname;
	    GV **fields;
	    SV **svp, **indsvp, *sv;
	    I32 ind;
	    char *key = NULL;
	    STRLEN keylen;

	    op_seq_inc_max(o);

	    if (((BINOP*)o)->op_last->op_type != OP_CONST)
		break;

	    /* Make the CONST have a shared SV */
	    svp = cSVOPx_svp(((BINOP*)o)->op_last);
	    if ((!SvFAKE(sv = *svp) || !SvREADONLY(sv)) && !IS_PADCONST(sv)) {
		key = SvPV(sv, keylen);
		lexname = newSVpvn_share(key,
					 SvUTF8(sv) ? -(I32)keylen : keylen,
					 0);
		SvREFCNT_dec(sv);
		*svp = lexname;
	    }

	    if ((o->op_private & (OPpLVAL_INTRO)))
		break;

	    rop = (UNOP*)((BINOP*)o)->op_first;
	    if (rop->op_type != OP_RV2HV || rop->op_first->op_type != OP_PADSV)
		break;
	    lexname = *av_fetch(PL_comppad_name, rop->op_first->op_targ, TRUE);
	    if (!(SvFLAGS(lexname) & SVpad_TYPED))
		break;
	    fields = (GV**)hv_fetch(SvSTASH(lexname), "FIELDS", 6, FALSE);
	    if (!fields || !GvHV(*fields))
		break;
	    key = SvPV(*svp, keylen);
	    indsvp = hv_fetch(GvHV(*fields), key,
			      SvUTF8(*svp) ? -(I32)keylen : keylen, FALSE);
	    if (!indsvp) {
#if PERL_VERSION < 10
		Perl_croak(aTHX_ "No such pseudo-hash field \"%s\" in variable %s of type %s",
		      key, SvPV(lexname, n_a), HvNAME(SvSTASH(lexname)));
#else
		Perl_croak(aTHX_ "No such class field \"%s\" "
			   "in variable %s of type %s",
		      key, SvPV_nolen_const(lexname), HvNAME_get(SvSTASH(lexname)));
#endif
	    }
#if PERL_VERSION < 10
	    /* Note: 5.10 has no optimization here */
	    ind = SvIV(*indsvp);
	    if (ind < 1)
		Perl_croak(aTHX_ "Bad index while coercing array into hash");
	    rop->op_type = OP_RV2AV;
	    rop->op_ppaddr = PL_ppaddr[OP_RV2AV];
	    o->op_type = OP_AELEM;
	    o->op_ppaddr = PL_ppaddr[OP_AELEM];
	    sv = newSViv(ind);
	    if (SvREADONLY(*svp))
		SvREADONLY_on(sv);
	    SvFLAGS(sv) |= (SvFLAGS(*svp)
			    & (SVs_PADBUSY|SVs_PADTMP|SVs_PADMY));
	    SvREFCNT_dec(*svp);
	    *svp = sv;
#endif
	    break;
	}

	case OP_HSLICE: {
	    UNOP *rop;
	    SV *lexname;
	    GV **fields;
	    SV **svp, **indsvp, *sv;
	    I32 ind;
	    const char *key;
	    STRLEN keylen;
	    SVOP *first_key_op, *key_op;

	    op_seq_inc_max(o);
	    if ((o->op_private & (OPpLVAL_INTRO))
		/* I bet there's always a pushmark... */
		|| ((LISTOP*)o)->op_first->op_sibling->op_type != OP_LIST)
		/* hmmm, no optimization if list contains only one key. */
		break;
	    rop = (UNOP*)((LISTOP*)o)->op_last;
	    if (rop->op_type != OP_RV2HV)
		break;
	    if (rop->op_first->op_type == OP_PADSV)
		/* @$hash{qw(keys here)} */
		rop = (UNOP*)rop->op_first;
	    else {
		/* @{$hash}{qw(keys here)} */
		if (rop->op_first->op_type == OP_SCOPE
		    && cLISTOPx(rop->op_first)->op_last->op_type == OP_PADSV)
		{
		    rop = (UNOP*)cLISTOPx(rop->op_first)->op_last;
		}
		else
		    break;
	    }

	    lexname = *av_fetch(PL_comppad_name, rop->op_first->op_targ, TRUE);
	    if (!(SvFLAGS(lexname) & SVpad_TYPED))
		break;
	    fields = (GV**)hv_fetch(SvSTASH(lexname), "FIELDS", 6, FALSE);
	    if (!fields || !GvHV(*fields))
		break;
	    /* Again guessing that the pushmark can be jumped over.... */
	    first_key_op = (SVOP*)((LISTOP*)((LISTOP*)o)->op_first->op_sibling)
		->op_first->op_sibling;
	    /* Check that the key list contains only constants. */
	    for (key_op = first_key_op; key_op;
		 key_op = (SVOP*)key_op->op_sibling)
		if (key_op->op_type != OP_CONST)
		    break;
	    if (key_op)
		break;
	    rop->op_type = OP_RV2AV;
	    rop->op_ppaddr = PL_ppaddr[OP_RV2AV];
	    o->op_type = OP_ASLICE;
	    o->op_ppaddr = PL_ppaddr[OP_ASLICE];
	    for (key_op = first_key_op; key_op;
		 key_op = (SVOP*)key_op->op_sibling) {
		if (key_op->op_type != OP_CONST)
		    continue;
		svp = cSVOPx_svp(key_op);
		key = SvPV_const(*svp, keylen);
		indsvp = hv_fetch(GvHV(*fields), key,
				  SvUTF8(*svp) ? -(I32)keylen : keylen, FALSE);
#if PERL_VERSION < 10
		if (!indsvp) {
		    Perl_croak(aTHX_ "No such pseudo-hash field \"%s\" "
			       "in variable %s of type %s",
			  key, SvPV(lexname, n_a), HvNAME(SvSTASH(lexname)));
		}
		ind = SvIV(*indsvp);
		if (ind < 1)
		    Perl_croak(aTHX_ "Bad index while coercing array into hash");
		sv = newSViv(ind);
		if (SvREADONLY(*svp))
		    SvREADONLY_on(sv);
#  if PERL_VERSION > 8
		SvFLAGS(sv) |= (SvFLAGS(*svp)
				& (SVs_PADSTALE|SVs_PADTMP|SVs_PADMY));
#  else
		SvFLAGS(sv) |= (SvFLAGS(*svp)
				& (SVs_PADBUSY|SVs_PADTMP|SVs_PADMY));
#  endif
		SvREFCNT_dec(*svp);
		*svp = sv;
#else
		if (!indsvp) {
		    Perl_croak(aTHX_ "No such class field \"%s\" "
			       "in variable %s of type %s",
			  key, SvPV_nolen(lexname), HvNAME_get(SvSTASH(lexname)));
		}
#endif
	    }
	    break;
	}

	case OP_SORT: {
	    /* will point to RV2AV or PADAV op on LHS/RHS of assign */
	    OP *oleft;
	    OP *o2;

	    /* check that RHS of sort is a single plain array */
	    OP *oright = cUNOPo->op_first;
	    if (!oright || oright->op_type != OP_PUSHMARK)
		break;

	    /* reverse sort ... can be optimised.  */
	    if (!cUNOPo->op_sibling) {
		/* Nothing follows us on the list. */
		OP * const reverse = o->op_next;

		if (reverse->op_type == OP_REVERSE &&
		    (reverse->op_flags & OPf_WANT) == OPf_WANT_LIST) {
		    OP * const pushmark = cUNOPx(reverse)->op_first;
		    if (pushmark && (pushmark->op_type == OP_PUSHMARK)
			&& (cUNOPx(pushmark)->op_sibling == o)) {
			/* reverse -> pushmark -> sort */
			o->op_private |= OPpSORT_REVERSE;
			op_null(reverse);
			pushmark->op_next = oright->op_next;
			op_null(oright);
		    }
		}
	    }

	    /* make @a = sort @a act in-place */

	    oright = cUNOPx(oright)->op_sibling;
	    if (!oright)
		break;
	    if (oright->op_type == OP_NULL) { /* skip sort block/sub */
		oright = cUNOPx(oright)->op_sibling;
	    }

	    if (!oright ||
		(oright->op_type != OP_RV2AV && oright->op_type != OP_PADAV)
		|| oright->op_next != o
		|| (oright->op_private & OPpLVAL_INTRO)
	    )
		break;

	    /* o2 follows the chain of op_nexts through the LHS of the
	     * assign (if any) to the aassign op itself */
	    o2 = o->op_next;
	    if (!o2 || o2->op_type != OP_NULL)
		break;
	    o2 = o2->op_next;
	    if (!o2 || o2->op_type != OP_PUSHMARK)
		break;
	    o2 = o2->op_next;
	    if (o2 && o2->op_type == OP_GV)
		o2 = o2->op_next;
	    if (!o2
		|| (o2->op_type != OP_PADAV && o2->op_type != OP_RV2AV)
		|| (o2->op_private & OPpLVAL_INTRO)
	    )
		break;
	    oleft = o2;
	    o2 = o2->op_next;
	    if (!o2 || o2->op_type != OP_NULL)
		break;
	    o2 = o2->op_next;
	    if (!o2 || o2->op_type != OP_AASSIGN
		    || (o2->op_flags & OPf_WANT) != OPf_WANT_VOID)
		break;

	    /* check that the sort is the first arg on RHS of assign */

	    o2 = cUNOPx(o2)->op_first;
	    if (!o2 || o2->op_type != OP_NULL)
		break;
	    o2 = cUNOPx(o2)->op_first;
	    if (!o2 || o2->op_type != OP_PUSHMARK)
		break;
	    if (o2->op_sibling != o)
		break;

	    /* check the array is the same on both sides */
	    if (oleft->op_type == OP_RV2AV) {
		if (oright->op_type != OP_RV2AV
		    || !cUNOPx(oright)->op_first
		    || cUNOPx(oright)->op_first->op_type != OP_GV
		    ||  cGVOPx_gv(cUNOPx(oleft)->op_first) !=
		       	cGVOPx_gv(cUNOPx(oright)->op_first)
		)
		    break;
	    }
	    else if (oright->op_type != OP_PADAV
		|| oright->op_targ != oleft->op_targ
	    )
		break;

	    /* transfer MODishness etc from LHS arg to RHS arg */
	    oright->op_flags = oleft->op_flags;
	    o->op_private |= OPpSORT_INPLACE;

	    /* excise push->gv->rv2av->null->aassign */
	    o2 = o->op_next->op_next;
	    op_null(o2); /* PUSHMARK */
	    o2 = o2->op_next;
	    if (o2->op_type == OP_GV) {
		op_null(o2); /* GV */
		o2 = o2->op_next;
	    }
	    op_null(o2); /* RV2AV or PADAV */
	    o2 = o2->op_next->op_next;
	    op_null(o2); /* AASSIGN */

	    o->op_next = o2->op_next;

	    break;
	}

	case OP_REVERSE: {
	    OP *ourmark, *theirmark, *ourlast, *iter, *expushmark, *rv2av;
	    OP *gvop = NULL;
	    LISTOP *enter, *exlist;

	    enter = (LISTOP *) o->op_next;
	    if (!enter)
		break;
	    if (enter->op_type == OP_NULL) {
		enter = (LISTOP *) enter->op_next;
		if (!enter)
		    break;
	    }
	    /* for $a (...) will have OP_GV then OP_RV2GV here.
	       for (...) just has an OP_GV.  */
	    if (enter->op_type == OP_GV) {
		gvop = (OP *) enter;
		enter = (LISTOP *) enter->op_next;
		if (!enter)
		    break;
		if (enter->op_type == OP_RV2GV) {
		  enter = (LISTOP *) enter->op_next;
		  if (!enter)
		    break;
		}
	    }

	    if (enter->op_type != OP_ENTERITER)
		break;

	    iter = enter->op_next;
	    if (!iter || iter->op_type != OP_ITER)
		break;
	
	    expushmark = enter->op_first;
	    if (!expushmark || expushmark->op_type != OP_NULL
		|| expushmark->op_targ != OP_PUSHMARK)
		break;

	    exlist = (LISTOP *) expushmark->op_sibling;
	    if (!exlist || exlist->op_type != OP_NULL
		|| exlist->op_targ != OP_LIST)
		break;

	    if (exlist->op_last != o) {
		/* Mmm. Was expecting to point back to this op.  */
		break;
	    }
	    theirmark = exlist->op_first;
	    if (!theirmark || theirmark->op_type != OP_PUSHMARK)
		break;

	    if (theirmark->op_sibling != o) {
		/* There's something between the mark and the reverse, eg
		   for (1, reverse (...))
		   so no go.  */
		break;
	    }

	    ourmark = ((LISTOP *)o)->op_first;
	    if (!ourmark || ourmark->op_type != OP_PUSHMARK)
		break;

	    ourlast = ((LISTOP *)o)->op_last;
	    if (!ourlast || ourlast->op_next != o)
		break;

	    rv2av = ourmark->op_sibling;
	    if (rv2av && rv2av->op_type == OP_RV2AV && rv2av->op_sibling == 0
		&& rv2av->op_flags == (OPf_WANT_LIST | OPf_KIDS)
		&& enter->op_flags == (OPf_WANT_LIST | OPf_KIDS)) {
		/* We're just reversing a single array.  */
		rv2av->op_flags = OPf_WANT_SCALAR | OPf_KIDS | OPf_REF;
		enter->op_flags |= OPf_STACKED;
	    }

	    /* We don't have control over who points to theirmark, so sacrifice
	       ours.  */
	    theirmark->op_next = ourmark->op_next;
	    theirmark->op_flags = ourmark->op_flags;
	    ourlast->op_next = gvop ? gvop : (OP *) enter;
	    op_null(ourmark);
	    op_null(o);
	    enter->op_private |= OPpITER_REVERSED;
	    iter->op_private |= OPpITER_REVERSED;
	
	    break;
	}

	case OP_SASSIGN: {
	    OP *rv2gv;
	    UNOP *refgen, *rv2cv;
	    LISTOP *exlist;

	    if ((o->op_flags & OPf_WANT) != OPf_WANT_VOID)
		break;

	    if ((o->op_private & ~OPpASSIGN_BACKWARDS) != 2)
		break;

	    rv2gv = ((BINOP *)o)->op_last;
	    if (!rv2gv || rv2gv->op_type != OP_RV2GV)
		break;

	    refgen = (UNOP *)((BINOP *)o)->op_first;

	    if (!refgen || refgen->op_type != OP_REFGEN)
		break;

	    exlist = (LISTOP *)refgen->op_first;
	    if (!exlist || exlist->op_type != OP_NULL
		|| exlist->op_targ != OP_LIST)
		break;

	    if (exlist->op_first->op_type != OP_PUSHMARK)
		break;

	    rv2cv = (UNOP*)exlist->op_last;

	    if (rv2cv->op_type != OP_RV2CV)
		break;

#if PERL_VERSION >= 10
	    assert ((rv2gv->op_private & OPpDONT_INIT_GV) == 0);
	    assert ((o->op_private & OPpASSIGN_CV_TO_GV) == 0);
	    assert ((rv2cv->op_private & OPpMAY_RETURN_CONSTANT) == 0);

	    o->op_private |= OPpASSIGN_CV_TO_GV;
	    rv2gv->op_private |= OPpDONT_INIT_GV;
	    rv2cv->op_private |= OPpMAY_RETURN_CONSTANT;
#endif
	    break;
	}

	default:
	    op_seq_inc_max(o);
	    break;
	}
	peep_callback(aTHX_ o);
	oldop = o;
    }
    LEAVE;
}

void
c_sub_detect(pTHX_ register OP *o)
{

  /* Here we call the perl peep function so we don't get bit by
     by the fact that doing stuff while optimization is highly dangerous
  */

  Perl_peep(aTHX_ o);

  /* Since we get the start here, we should try and find the
     leave by following next until we find it
  */

  while(o) {
    if(o->op_next)
      o = o->op_next;
    else
      break;
  }
  if(!o)
    return;
  if(o->op_type == OP_LEAVESUB   ||
     o->op_type == OP_LEAVESUBLV ||
     o->op_type == OP_LEAVE      ||
     o->op_type == OP_LEAVEEVAL) {
    HE *entry;
    HV *callbacks = get_hv("optimizer::callbacks", 1);
    hv_iterinit(callbacks);
    while ((entry = hv_iternext(callbacks))) {
      peep_in_perl = HeVAL(entry);
      peep_callback(aTHX_ o);	
    }

  }

}

/* This trick stolen from B.xs */
#define PEEP_op_seqmax() PL_op_seqmax
#define PEEP_op_seqmax_inc() PL_op_seqmax++

MODULE = optimizer		PACKAGE = optimizer		PREFIX = PEEP_

PROTOTYPES: DISABLE

U32
PEEP_op_seqmax()

U32
PEEP_op_seqmax_inc()

void
PEEP_c_extend_install(SV* subref)
     CODE:
     PL_peepp = c_extend_peep;
     peep_in_perl = newSVsv(subref);

void
PEEP_c_sub_detect_install()
     CODE:
     PL_peepp = c_sub_detect;

void
PEEP_install(SV* subref)
    CODE:
    install(aTHX_ subref);

void
PEEP_uninstall()
    CODE:
    uninstall(aTHX);

void
PEEP__relocatetopad(o,cvref)
      B::OP  o
      SV*  cvref
    CODE:
    if (cvref) { 
      CV* cv = INT2PTR(CV*, SvIV(SvRV(cvref)));
      _relocatetopad(aTHX_ o, cv);
    }

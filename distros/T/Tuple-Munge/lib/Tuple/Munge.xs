#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef newSTUB
# define newSTUB(gv, fake) THX_newSTUB(aTHX_ gv, fake)
static CV *THX_newSTUB(pTHX_ GV *gv, bool fake)
{
	CV *cv = (CV*)newSV_type(SVt_PVCV);
	GV *cvgv;
	assert(!GvCVu(gv));
	GvCV_set(gv, cv);
	GvCVGEN(gv) = 0;
	if(!fake && GvSTASH(gv) && HvENAME_HEK(GvSTASH(gv)))
		gv_method_changed(gv);
	if(SvFAKE(gv)) {
		cvgv = gv_fetchsv((SV*)gv, GV_ADDMULTI, SVt_PVCV);
		SvFAKE_off(cvgv);
	} else
		cvgv = gv;
	CvGV_set(cv, cvgv);
	CvFILE_set_from_cop(cv, PL_curcop);
	CvSTASH_set(cv, PL_curstash);
	GvMULTI_on(gv);
	return cv;
}
#endif /* !newSTUB */

#define SvREADONLY_fully_on(sv) (SvFLAGS(sv) |= SVf_READONLY|SVf_PROTECT)
#define SvREADONLY_fully_off(sv) (SvFLAGS(sv) &= ~(SVf_READONLY|SVf_PROTECT))
#define SvREADONLY_slightly_on(sv) (SvFLAGS(sv) |= SVf_READONLY)
#define SvREADONLY_slightly_off(sv) (SvFLAGS(sv) &= ~SVf_READONLY)

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)
#define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#define sv_is_undef(sv) (!sv_is_glob(sv) && !sv_is_regexp(sv) && !SvOK(sv))

#define Q_OPp_CONSTRUCT_READONLY   0x01
#define Q_OPp_FIXED_INDEX          0x02
#define Q_OPp_PAD_TUPLE            0x04
#define Q_OPp_SLOTVAL_MASK         0x38
#define Q_OPp_SLOTVAL_RV2SV_LAX    0x08
#define Q_OPp_SLOTVAL_RV2SV_STRICT 0x10
#define Q_OPp_SLOTVAL_RV2AV        0x18
#define Q_OPp_SLOTVAL_RV2HV        0x20
#define Q_OPp_SLOTVAL_RV2CV        0x28
#define Q_OPp_SLOTVAL_RV2GV        0x30

#define Q_CKf_FOLD              0x0100
#define Q_CKf_NOT_SCALAR_RETURN 0x0200
#define Q_ARGf_TUPLE            0x0400
#define Q_ARGf_INDEX            0x0800
#define Q_ARGf_REF              0x1000
#define Q_ARGf_REF_LIST         0x2000
#define Q_BTf_NO_REGISTER_XOP   0x4000
#define Q_BTf_SLOTVAL_RET       0x8000

#define Q_ARGf_LIST Q_ARGf_REF_LIST

typedef struct {
	UNOP unop;
	SSize_t index;
} Q_TUPLE_OP;

#define Q_POPs_TUPLE_ARG \
	(LIKELY(PL_op->op_private & Q_OPp_PAD_TUPLE) ? \
		PAD_SV(PL_op->op_targ) : POPs)

#define Q_POPs_INDEX_ARG \
	(LIKELY(PL_op->op_private & Q_OPp_FIXED_INDEX) ? NULL : POPs)
#define Q_GET_INDEX_VAL(ixsv) \
	(LIKELY(PL_op->op_private & Q_OPp_FIXED_INDEX) ? \
		((Q_TUPLE_OP*)PL_op)->index : index_from_arg(ixsv))

#define tuple_from_arg(arg) THX_tuple_from_arg(aTHX_ arg)
PERL_STATIC_INLINE SV *THX_tuple_from_arg(pTHX_ SV *arg)
{
	SV *tuple;
	SvGETMAGIC(arg);
	if(!LIKELY(SvROK(arg) && (tuple = SvRV(arg)) &&
			SvTYPE(tuple) == SVt_PVOBJ))
		croak("tuple argument is not a tuple reference");
	return tuple;
}

#define slotval_from_arg(arg) THX_slotval_from_arg(aTHX_ arg)
PERL_STATIC_INLINE SV *THX_slotval_from_arg(pTHX_ SV *arg)
{
	SvGETMAGIC(arg);
	if(LIKELY(SvROK(arg))) {
		return SvRV(arg);
	} else if(LIKELY(sv_is_undef(arg))) {
		return NULL;
	} else {
		croak("slot value is neither a reference nor undefined");
	}
}

#define slotval_as_ret(slotval) THX_slotval_as_ret(aTHX_ slotval)
PERL_STATIC_INLINE SV *THX_slotval_as_ret(pTHX_ SV *slotval)
{
	if(!LIKELY(slotval)) {
		return &PL_sv_undef;
	} else {
		SV *refsv = sv_2mortal(newRV_inc(slotval));
		SvREADONLY_fully_on(refsv);
		return refsv;
	}
}

#define tuple_as_ret_takeref(tuple) THX_tuple_as_ret_takeref(aTHX_ tuple)
PERL_STATIC_INLINE SV *THX_tuple_as_ret_takeref(pTHX_ SV *tuple)
{
	SV *refsv = sv_2mortal(newRV_noinc(tuple));
	SvREADONLY_fully_on(refsv);
	return refsv;
}

#define tuple_as_ret(tuple) tuple_as_ret_takeref(SvREFCNT_inc(tuple))

#define index_from_arg(arg) THX_index_from_arg(aTHX_ arg)
PERL_STATIC_INLINE SSize_t THX_index_from_arg(pTHX_ SV *arg)
{
	IV ixiv = SvIV(arg);
	return UNLIKELY(((IV)(SSize_t)ixiv) != ixiv) ? -1 : ((SSize_t)ixiv);
}

static OP *THX_pp_tuple(pTHX)
{
	dMARK; dSP;
	SSize_t len = SP - MARK, i;
	SV *tuple;
	for(i = 0; i != len; i++) MARK[1+i] = slotval_from_arg(MARK[1+i]);
	tuple = newSV_type(SVt_PVOBJ);
	if(LIKELY(len != 0)) {
		SV **fields;
		Newx(fields, len, SV*);
		Copy(MARK+1, fields, len, SV*);
		for(i = 0; i != len; i++) SvREFCNT_inc(fields[i]);
		ObjectFIELDS(tuple) = fields;
		ObjectMAXFIELD(tuple) = len - 1;
	}
	if(PL_op->op_private & Q_OPp_CONSTRUCT_READONLY)
		SvREADONLY_fully_on(tuple);
	SP = MARK;
	if(UNLIKELY(len == 0)) EXTEND(SP, 1);
	if(PL_op->op_private & Q_OPp_PAD_TUPLE) {
		SV **padentry = &PAD_SVl(PL_op->op_targ), *targ = *padentry;
		if(PL_op->op_flags & OPf_SPECIAL) save_clearsv(padentry);
		TAINT_NOT;
		sv_setrv_noinc_mg(targ, tuple);
		PUSHs(targ);
	} else {
		PUSHs(tuple_as_ret_takeref(tuple));
	}
	PUTBACK;
	return NORMAL;
}

static OP *THX_pp_tuple_mutable(pTHX)
{
	dSP;
	SV *tuple = tuple_from_arg(Q_POPs_TUPLE_ARG);
	XPUSHs(boolSV(!SvREADONLY(tuple)));
	PUTBACK;
	return NORMAL;
}

static OP *THX_pp_tuple_length(pTHX)
{
	dSP;
	SV *tuple = tuple_from_arg(Q_POPs_TUPLE_ARG);
	SV *lensv = sv_2mortal(newSViv(ObjectMAXFIELD(tuple) + 1));
	SvREADONLY_fully_on(lensv);
	XPUSHs(lensv);
	PUTBACK;
	return NORMAL;
}

static OP *THX_pp2_slotval_ret(pTHX_ SV *slotval)
{
	int deref_method;
	switch(PL_op->op_private & Q_OPp_SLOTVAL_MASK) {
		case 0: slotval = slotval_as_ret(slotval); goto finalised;
		case Q_OPp_SLOTVAL_RV2SV_LAX:
		case Q_OPp_SLOTVAL_RV2SV_STRICT:
			deref_method = to_sv_amg;
			break;
		case Q_OPp_SLOTVAL_RV2AV: deref_method = to_av_amg; break;
		case Q_OPp_SLOTVAL_RV2HV: deref_method = to_hv_amg; break;
		case Q_OPp_SLOTVAL_RV2CV: deref_method = to_cv_amg; break;
		case Q_OPp_SLOTVAL_RV2GV: deref_method = to_gv_amg; break;
		default: assert(0); goto finalised;
	}
	if(LIKELY(slotval) && UNLIKELY(SvOBJECT(slotval)) &&
			UNLIKELY(HvAMAGIC(SvSTASH(slotval)))) {
		SV *rv = amagic_deref_call(sv_2mortal(newRV_inc(slotval)),
				deref_method);
		slotval = SvRV(rv);
	}
	switch(PL_op->op_private & Q_OPp_SLOTVAL_MASK) {
		case Q_OPp_SLOTVAL_RV2SV_LAX: {
			if(!LIKELY(slotval)) {
				if(ckWARN(WARN_UNINITIALIZED))
					Perl_warner(aTHX_
						packWARN(WARN_UNINITIALIZED),
						PL_warn_uninit_sv, &PL_sv_no,
						" in ", PL_op_desc[OP_RV2SV]);
				slotval = &PL_sv_undef;
				break;
			}
			goto sv_not_null;
		} break;
		case Q_OPp_SLOTVAL_RV2SV_STRICT: {
			if(!LIKELY(slotval)) DIE(aTHX_ PL_no_usym, "a SCALAR");
			sv_not_null:
			if(!LIKELY(SvTYPE(slotval) < SVt_PVAV))
				DIE(aTHX_ "Not %s reference", "a SCALAR");
		} break;
		case Q_OPp_SLOTVAL_RV2AV: {
			if(!LIKELY(slotval))
				DIE(aTHX_ PL_no_usym, "an ARRAY");
			else if(!LIKELY(SvTYPE(slotval) == SVt_PVAV))
				DIE(aTHX_ "Not %s reference", "an ARRAY");
		} break;
		case Q_OPp_SLOTVAL_RV2HV: {
			if(!LIKELY(slotval))
				DIE(aTHX_ PL_no_usym, "a HASH");
			else if(!LIKELY(SvTYPE(slotval) == SVt_PVHV))
				DIE(aTHX_ "Not %s reference", "a HASH");
		} break;
		case Q_OPp_SLOTVAL_RV2CV: {
			if(!LIKELY(slotval)) {
				if(!PL_localizing && ckWARN(WARN_UNINITIALIZED))
					Perl_warner(aTHX_
						packWARN(WARN_UNINITIALIZED),
						PL_warn_uninit_sv, &PL_sv_no,
						" in ", PL_op_desc[OP_RV2CV]);
				slotval = (SV*)gv_fetchpvn_flags("", 0,
						GV_ADD|GV_NO_SVGMAGIC,
						SVt_PVCV);
				goto handle_gv_for_cv;
			} else if(LIKELY(SvTYPE(slotval) == SVt_PVCV))
				;
			else if((SvGETMAGIC(slotval),
					LIKELY(isGV_with_GP(slotval)))) {
				GV *gv;
				CV *cv;
				handle_gv_for_cv:
				gv = (GV*)slotval;
				cv = GvCVu(gv);
				if(!cv) cv = newSTUB(gv, 0);
				slotval = (SV*)cv;
			} else
				DIE(aTHX_ "Not %s reference", "a subroutine");
		} break;
		case Q_OPp_SLOTVAL_RV2GV: {
			if(!LIKELY(slotval))
				DIE(aTHX_ PL_no_usym, "a symbol");
			else if(LIKELY(isGV_with_GP(slotval))) {
				if(UNLIKELY(SvFAKE(slotval))) {
					slotval =
						sv_mortalcopy_flags(slotval, 0);
					SvFAKE_off(slotval);
				}
			} else if(LIKELY(SvTYPE(slotval) == SVt_PVIO)) {
				GV *gv = (GV*)sv_newmortal();
				gv_init(gv, 0, "__ANONIO__", 10, 0);
				GvIOp(gv) = (IO*)slotval;
				SvREFCNT_inc_void_NN(slotval);
				slotval = (SV*)gv;
			} else
				DIE(aTHX_ "Not %s reference", "a GLOB");
		} break;
		default: {
			assert(0);
		} break;
	}
	finalised:
	{
		dSP;
		XPUSHs(slotval);
		PUTBACK;
	}
	return NORMAL;
}

static OP *THX_pp_tuple_slot(pTHX)
{
	dSP;
	SV *ixsv = Q_POPs_INDEX_ARG;
	SSize_t ix;
	SV *tuple = tuple_from_arg(Q_POPs_TUPLE_ARG);
	PUTBACK;
	ix = Q_GET_INDEX_VAL(ixsv);
	if(UNLIKELY(ix < 0 || ix > ObjectMAXFIELD(tuple)))
		croak("tuple slot index is out of range");
	return THX_pp2_slotval_ret(aTHX_ ObjectFIELDS(tuple)[ix]);
}

static OP *THX_pp_tuple_slots(pTHX)
{
	dSP;
	SV *tuple;
	SSize_t len;
	if(UNLIKELY(GIMME_V == G_SCALAR))
		croak("tuple slot list requested in scalar context");
	tuple = tuple_from_arg(Q_POPs_TUPLE_ARG);
	len = ObjectMAXFIELD(tuple) + 1;
	if(LIKELY(len != 0)) {
		SV **fields = ObjectFIELDS(tuple);
		SSize_t i;
		EXTEND(SP, len);
		for(i = 0; i != len; i++) SP[1+i] = slotval_as_ret(fields[i]);
		SP += len;
	}
	PUTBACK;
	return NORMAL;
}

static OP *THX_pp_tuple_set_slot(pTHX)
{
	dSP;
	SV *newslotvalarg = POPs;
	SV *ixsv = Q_POPs_INDEX_ARG;
	SSize_t ix;
	SV *tuple = tuple_from_arg(Q_POPs_TUPLE_ARG);
	SV *newslotval, *oldslotval, **fields;
	PUTBACK;
	ix = Q_GET_INDEX_VAL(ixsv);
	newslotval = slotval_from_arg(newslotvalarg);
	if(UNLIKELY(SvREADONLY(tuple))) croak_no_modify();
	if(UNLIKELY(ix < 0 || ix > ObjectMAXFIELD(tuple)))
		croak("tuple slot index is out of range");
	fields = ObjectFIELDS(tuple);
	oldslotval = fields[ix];
	fields[ix] = SvREFCNT_inc(newslotval);
	SvREFCNT_dec(oldslotval);
	return LIKELY(GIMME_V == G_VOID) ? NORMAL :
		THX_pp2_slotval_ret(aTHX_ newslotval);
}

static OP *THX_pp_tuple_set_slots(pTHX)
{
	dMARK; dSP;
	SSize_t newlen = SP - MARK, oldlen, i;
	SV *tuple;
	SP = MARK;
	tuple = tuple_from_arg(Q_POPs_TUPLE_ARG);
	for(i = 0; i != newlen; i++) MARK[1+i] = slotval_from_arg(MARK[1+i]);
	if(UNLIKELY(SvREADONLY(tuple))) croak_no_modify();
	oldlen = ObjectMAXFIELD(tuple) + 1;
	if(LIKELY(newlen == oldlen)) {
		if(LIKELY(newlen != 0)) {
			SV **fields = ObjectFIELDS(tuple);
			for(i = 0; i != newlen; i++) {
				SV *oldslotval = fields[i];
				SV *newslotval = SvREFCNT_inc(MARK[1+i]);
				fields[i] = newslotval;
				MARK[1+i] = oldslotval;
			}
			for(i = 0; i != newlen; i++) SvREFCNT_dec(MARK[1+i]);
		}
	} else {
		SV **oldfields = ObjectFIELDS(tuple), **newfields;
		if(UNLIKELY(newlen == 0)) {
			newfields = NULL;
		} else {
			Newx(newfields, newlen, SV*);
			Copy(MARK+1, newfields, newlen, SV*);
			for(i = 0; i != newlen; i++) SvREFCNT_inc(newfields[i]);
		}
		ObjectFIELDS(tuple) = newfields;
		ObjectMAXFIELD(tuple) = newlen - 1;
		for(i = 0; i != oldlen; i++) SvREFCNT_dec(oldfields[i]);
		Safefree(oldfields);
	}
	if(UNLIKELY(GIMME_V == G_SCALAR)) XPUSHs(&PL_sv_undef);
	PUTBACK;
	return NORMAL;
}

static OP *THX_pp_tuple_seal(pTHX)
{
	dSP;
	SV *tuple_arg = Q_POPs_TUPLE_ARG;
	SV *tuple = tuple_from_arg(tuple_arg);
	if(UNLIKELY(GIMME_V != G_VOID)) XPUSHs(tuple_as_ret(tuple));
	PUTBACK;
	if(UNLIKELY(SvREADONLY(tuple))) croak_no_modify();
	SvREADONLY_fully_on(tuple);
	return NORMAL;
}

struct q_func {
	char const *fqsubname;
	Perl_ppaddr_t THX_pp;
	U32 flags;
};

static void THX_xsfunc_tuple_any(pTHX_ CV *cv)
{
	struct q_func const *qf = (struct q_func const *)CvXSUBANY(cv).any_ptr;
	U32 flags = qf->flags;
	SSize_t base_arity = !!(flags & Q_ARGf_TUPLE) +
		!!(flags & Q_ARGf_INDEX) + !!(flags & Q_ARGf_REF);
	UNOP myop;
	dMARK; dSP;
	if(UNLIKELY(SP - MARK < base_arity ||
			(!(flags & Q_ARGf_LIST) && SP - MARK > base_arity))) {
		SV *argnames = sv_newmortal();
		sv_setpvs(argnames, "");
		if(flags & Q_ARGf_TUPLE) sv_catpvs_nomg(argnames, ", tuple");
		if(flags & Q_ARGf_INDEX) sv_catpvs_nomg(argnames, ", index");
		if(flags & Q_ARGf_REF) sv_catpvs_nomg(argnames, ", ref");
		if(flags & Q_ARGf_REF_LIST)
			sv_catpvs_nomg(argnames, ", ref ...");
		croak_xs_usage(cv, SvPVX(argnames) + 2);
	}
	if(UNLIKELY(flags & Q_ARGf_LIST)) PUSHMARK(MARK + base_arity);
	Zero(&myop, 1, UNOP);
	myop.op_flags = PL_op->op_flags;
	myop.op_private = (U8)flags;
	SAVEOP();
	PL_op = (OP*)&myop;
	(void) qf->THX_pp(aTHX);
}

#define is_std_op(o, type) \
	((o)->op_type == (type) && (o)->op_ppaddr == PL_ppaddr[(type)])

PERL_STATIC_INLINE OP *skip_null_ops(OP *o)
{
	while(o && (o->op_type == OP_NULL || o->op_type == OP_SCALAR ||
			o->op_type == OP_SCOPE || o->op_type == OP_LINESEQ))
		o = o->op_next;
	return o;
}

static void THX_cpeep_tuple(pTHX_ OP *first, OP *prevop)
{
	OP *second, *third;
	PERL_UNUSED_ARG(prevop);
	if((second = skip_null_ops(first->op_next)) &&
			is_std_op(second, OP_PADSV) &&
			!(second->op_private & (OPpDEREF|OPpPAD_STATE)) &&
			(third = skip_null_ops(second->op_next)) &&
			is_std_op(third, OP_SASSIGN) &&
			!(third->op_private &
				(OPpASSIGN_BACKWARDS|OPpASSIGN_CV_TO_GV))) {
		first->op_private |= Q_OPp_PAD_TUPLE;
		first->op_flags = (first->op_flags & OPf_KIDS) |
			((second->op_flags & OPf_MOD) &&
					(second->op_private & OPpLVAL_INTRO) ?
				OPf_SPECIAL : 0) |
			(third->op_flags & OPf_WANT);
		first->op_targ = second->op_targ;
		first->op_next = third->op_next;
	}
}

#define eligible_for_multideref(o) THX_eligible_for_multideref(aTHX_ o)
static bool THX_eligible_for_multideref(pTHX_ OP *o)
{
	/*
	 * The logic here is duplicating that of the core's
	 * S_maybe_multideref(), in order to determine whether core
	 * peephole optimisation would turn the ops being examined into
	 * a multideref op.  The aim is to match the core's criteria,
	 * not to decide whether it would be a good idea to turn the
	 * ops into a multideref.  Accurately predicting the behaviour
	 * of the core's multideref optimisation is not necessary in
	 * order to achieve correct behaviour, but is desired in order
	 * to produce the best possible optimisation.
	 */
	Optype reftyp = o->op_type;
	if(!(reftyp == OP_RV2AV || reftyp == OP_RV2HV)) return 0;
	if(o->op_flags != (OPf_WANT_SCALAR|OPf_KIDS|OPf_REF)) return 0;
	if(!(o = o->op_next)) return 0;
	switch(o->op_type) {
		case OP_PADSV: {
			if((o->op_flags & OPf_WANT) != OPf_WANT_SCALAR)
				return 0;
		} break;
		case OP_CONST: {
			SV *val = cSVOPo_sv;
			if(reftyp == OP_RV2HV) {
				if(!(SvFLAGS(val) & (SVf_IOK|SVf_NOK|SVf_POK)))
					return 0;
			} else {
				if(!SvIOK(val)) return 0;
			}
		} break;
		case OP_GV: {
			if((o->op_flags & ~(OPf_PARENS|OPf_SPECIAL))
					!= OPf_WANT_SCALAR)
				return 0;
			if(o->op_private) return 0;
			o = o->op_next;
			if(o->op_type != OP_RV2SV) return 0;
			if((o->op_flags & ~OPf_PARENS) !=
					(OPf_WANT_SCALAR|OPf_KIDS))
				return 0;
			if(o->op_private & ~(OPpARG1_MASK|HINT_STRICT_REFS))
				return 0;
		} break;
		default: return 0;
	}
	if(!(o = o->op_next)) return 0;
	if(o->op_type == OP_NULL && !(o = o->op_next)) return 0;
	switch(o->op_type) {
		case OP_AELEM: {
			if(reftyp != OP_RV2AV) return 0;
			aelem_or_helem:
			switch(o->op_private & OPpDEREF) {
				case OPpDEREF_AV: case OPpDEREF_HV: {
					if(!(o->op_private & OPpLVAL_INTRO)) {
						if((o->op_flags & ~OPf_PARENS)
							!= (OPf_WANT_SCALAR|
								OPf_KIDS|
								OPf_MOD))
							return 0;
						if(o->op_private &
							~(OPpDEREF|
								OPpARG2_MASK))
							return 0;
					}
				} break;
				case OPpDEREF_SV: return 0;
				default: break;
			}
		} break;
		case OP_HELEM: {
			if(reftyp != OP_RV2HV) return 0;
			goto aelem_or_helem;
		} break;
		case OP_EXISTS: {
			if(reftyp != OP_RV2HV) return 0;
			if(o->op_private & ~OPpARG1_MASK) return 0;
		} break;
		case OP_DELETE: {
			if(reftyp != OP_RV2HV) return 0;
			if(o->op_private & ~OPpARG1_MASK) return 0;
			if(OP_TYPE_IS_OR_WAS(cUNOPo->op_first, OP_AELEM) &&
					!(o->op_flags & OPf_SPECIAL))
				return 0;
		} break;
		default: return 0;
	}
	return 1;
}

static void THX_cpeep_slotval_ret(pTHX_ OP *first, OP *prevop)
{
	OP *second = skip_null_ops(first->op_next);
	Optype typ;
	bool elide_second;
	U8 pflag;
	PERL_UNUSED_ARG(prevop);
	if(!second) return;
	typ = second->op_type;
	if(second->op_ppaddr != PL_ppaddr[typ]) return;
	switch(typ) {
		case OP_RV2SV: {
			if((second->op_flags & OPf_MOD) &&
					(second->op_private &
						(OPpLVAL_INTRO|OPpDEREF)))
				return;
			pflag = ((second->op_flags & OPf_REF) ||
					(second->op_private & HINT_STRICT_REFS))
				? Q_OPp_SLOTVAL_RV2SV_STRICT :
				Q_OPp_SLOTVAL_RV2SV_LAX;
			elide_second = 1;
		} break;
		case OP_RV2AV: {
			pflag = Q_OPp_SLOTVAL_RV2AV;
			av_or_hv:
			if((second->op_flags & OPf_MOD) &&
					(second->op_private & OPpLVAL_INTRO))
				return;
			elide_second = (second->op_flags & OPf_REF) &&
				!eligible_for_multideref(second);
		} break;
		case OP_RV2HV: {
			pflag = Q_OPp_SLOTVAL_RV2HV;
			goto av_or_hv;
		} break;
		case OP_RV2CV: {
			if(PL_op->op_flags & OPf_SPECIAL) return;
			if((PL_op->op_private &
					(OPpLVAL_INTRO|OPpMAY_RETURN_CONSTANT))
					== OPpMAY_RETURN_CONSTANT)
				return;
			pflag = Q_OPp_SLOTVAL_RV2CV;
			elide_second = 1;
		} break;
		case OP_RV2GV: {
			if(second->op_private & (OPpLVAL_INTRO|OPpALLOW_FAKE))
				return;
			if(!((second->op_flags & OPf_REF) ||
					(second->op_private &
						HINT_STRICT_REFS)))
				return;
			pflag = Q_OPp_SLOTVAL_RV2GV;
			elide_second = 1;
		} break;
		default: return;
	}
	first->op_private |= pflag;
	if(elide_second) first->op_next = second->op_next;
}

#define Q_PKG_PREFIX "Tuple::Munge::"
#define Q_FUNC_SIMPLE_INIT(name, flags) \
	{ \
		Q_PKG_PREFIX #name, \
		THX_pp_##name, \
		(flags), \
	}
#define Q_FUNC_CONSTRUCTOR_INIT(name, flags) \
	{ \
		Q_PKG_PREFIX #name, \
		THX_pp_tuple, \
		Q_BTf_NO_REGISTER_XOP | (flags), \
	}
static struct q_func const q_funcs[] = {
	Q_FUNC_CONSTRUCTOR_INIT(pure_tuple,
		Q_ARGf_REF_LIST | Q_OPp_CONSTRUCT_READONLY | Q_CKf_FOLD),
	Q_FUNC_CONSTRUCTOR_INIT(constant_tuple,
		Q_ARGf_REF_LIST | Q_OPp_CONSTRUCT_READONLY),
	Q_FUNC_CONSTRUCTOR_INIT(variable_tuple, Q_ARGf_REF_LIST),
	Q_FUNC_SIMPLE_INIT(tuple_mutable, Q_ARGf_TUPLE | Q_CKf_FOLD),
	Q_FUNC_SIMPLE_INIT(tuple_length, Q_ARGf_TUPLE | Q_CKf_FOLD),
	Q_FUNC_SIMPLE_INIT(tuple_slot,
		Q_ARGf_TUPLE | Q_ARGf_INDEX | Q_CKf_FOLD | Q_BTf_SLOTVAL_RET),
	Q_FUNC_SIMPLE_INIT(tuple_slots, Q_ARGf_TUPLE | Q_CKf_NOT_SCALAR_RETURN),
	Q_FUNC_SIMPLE_INIT(tuple_set_slot,
		Q_ARGf_TUPLE | Q_ARGf_INDEX | Q_ARGf_REF | Q_BTf_SLOTVAL_RET),
	Q_FUNC_SIMPLE_INIT(tuple_set_slots,
		Q_ARGf_TUPLE | Q_ARGf_REF_LIST | Q_CKf_NOT_SCALAR_RETURN),
	Q_FUNC_SIMPLE_INIT(tuple_seal, Q_ARGf_TUPLE),
};

#define check_and_extract_args(entersubop, namegv, cv, argopl_ptr) \
	THX_check_and_extract_args(aTHX_ entersubop, namegv, cv, argopl_ptr)
PERL_STATIC_INLINE bool THX_check_and_extract_args(pTHX_ OP *entersubop,
	GV *namegv, CV *cv, OP **argopl_ptr)
{
	OP *pushop, *firstargop, *cvop, *lastargop;
	SSize_t nargs;
	entersubop = ck_entersub_args_proto(entersubop, namegv, (SV*)cv);
	if(!LIKELY(entersubop->op_flags & OPf_KIDS)) return 1;
	pushop = cUNOPx(entersubop)->op_first;
	if(!OpHAS_SIBLING(pushop)) {
		if(!LIKELY(pushop->op_flags & OPf_KIDS)) return 1;
		pushop = cUNOPx(pushop)->op_first;
	}
	if(!LIKELY(OpHAS_SIBLING(pushop))) return 1;
	firstargop = OpSIBLING(pushop);
	for(nargs = 0, cvop = firstargop, lastargop = pushop;
			OpHAS_SIBLING(cvop);
			lastargop = cvop, cvop = OpSIBLING(cvop))
		nargs++;
	{
		STRLEN protolen = CvPROTOLEN(cv);
		char const *protopv = CvPROTO(cv);
		if(!LIKELY(protopv[protolen-1] == '@' ?
				nargs >= (SSize_t)(protolen-1) :
				nargs == (SSize_t)protolen))
			return 1;
	}
	if(LIKELY(nargs != 0)) {
		*argopl_ptr = firstargop;
		OpMORESIB_set(pushop, cvop);
		OpLASTSIB_set(lastargop, NULL);
	} else {
		*argopl_ptr = NULL;
	}
	op_free(entersubop);
	return 0;
}

#define newOP_simple_custom(sz, THX_pp, argopl) \
	THX_newOP_simple_custom(aTHX_ sz, THX_pp, argopl)
PERL_STATIC_INLINE OP *THX_newOP_simple_custom(pTHX_ Size_t sz,
	Perl_ppaddr_t THX_pp, OP *argopl)
{
	OP *newop;
	NewOpSz(0, newop, sz);
	newop->op_type = OP_CUSTOM;
	newop->op_ppaddr = THX_pp;
	if(argopl) {
		OP *aop;
		newop->op_flags = OPf_KIDS;
		cUNOPx(newop)->op_first = argopl;
		for(aop = argopl; OpHAS_SIBLING(aop); aop = OpSIBLING(aop)) ;
		OpLASTSIB_set(aop, newop);
	}
	return newop;
}

#define fold_clean_optree(inop) THX_fold_clean_optree(aTHX_ inop)
PERL_STATIC_INLINE OP *THX_fold_clean_optree(pTHX_ OP *inop)
{
	SV *val;
	OP *outop;
	ENTER_with_name("fold_clean_optree");
	SAVETMPS;
	SAVEOP();
	{
		dSP;
		PUSHSTACKi(PERLSI_REQUIRE);
	}
	PL_op = LINKLIST(inop);
	inop->op_next = NULL;
	while(PL_op) PL_op = PL_op->op_ppaddr(aTHX);
	{
		dSP;
		val = POPs;
		PUTBACK;
	}
	outop = newSVOP(OP_CONST, 0, SvREFCNT_inc(val));
	POPSTACK;
	FREETMPS;
	LEAVE_with_name("fold_clean_optree");
	op_free(inop);
	return outop;
}

#define extract_scalar_arg(argopl, thisargop_ptr, have_arg_p) \
	THX_extract_scalar_arg(aTHX_ argopl, thisargop_ptr, have_arg_p)
PERL_STATIC_INLINE OP *THX_extract_scalar_arg(pTHX_ OP *argopl,
	OP **thisargop_ptr, U32 have_arg_p)
{
	if(have_arg_p) {
		OP *thisargop = argopl;
		assert(thisargop);
		argopl = OpSIBLING(argopl);
		OpLASTSIB_set(thisargop, NULL);
		*thisargop_ptr = thisargop;
	} else {
		*thisargop_ptr = NULL;
	}
	return argopl;
}

#define link_scalar_arg(argopl, thisargop) \
	THX_link_scalar_arg(aTHX_ argopl, thisargop)
PERL_STATIC_INLINE OP *THX_link_scalar_arg(pTHX_ OP *argopl, OP *thisargop)
{
	if(thisargop) {
		if(argopl) OpMORESIB_set(thisargop, argopl);
		return thisargop;
	} else {
		return argopl;
	}
}

#define op_scalar_value(op) THX_op_scalar_value(aTHX_ op)
static SV *THX_op_scalar_value(pTHX_ OP *op)
{
	if(op->op_flags & OPf_KIDS) return NULL;
	if(is_std_op(op, OP_CONST)) {
		SV *val = cSVOPx(op)->op_sv;
		return SvGMAGICAL(val) ? NULL : val;
	} else if(is_std_op(op, OP_UNDEF)) {
		return op->op_private ? NULL : &PL_sv_undef;
	} else {
		return NULL;
	}
}

#define ref_arg_list_all_constant(argopl) \
	THX_ref_arg_list_all_constant(aTHX_ argopl)
PERL_STATIC_INLINE bool THX_ref_arg_list_all_constant(pTHX_ OP *argopl)
{
	OP *argop;
	for(argop = argopl; argop; argop = OpSIBLING(argop)) {
		SV *val = op_scalar_value(argop);
		if(!(val && (SvROK(val) || sv_is_undef(val)))) return 0;
	}
	return 1;
}

static OP *THX_cksub_tuple_any(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
	CV *cv = (CV*)ckobj;
	struct q_func const *qf = (struct q_func const *)CvXSUBANY(cv).any_ptr;
	U32 flags = qf->flags;
	OP *argopl, *newop;
	OP *tuple_arg_op, *index_arg_op, *ref_arg_op;
	PADOFFSET tuple_po = 0;
	SV *tuple_sv = NULL;
	SSize_t index_val = 0;
	if(UNLIKELY(check_and_extract_args(entersubop, namegv, cv, &argopl)))
		return entersubop;
	argopl = extract_scalar_arg(argopl, &tuple_arg_op,
		flags & Q_ARGf_TUPLE);
	argopl = extract_scalar_arg(argopl, &index_arg_op,
		flags & Q_ARGf_INDEX);
	argopl = extract_scalar_arg(argopl, &ref_arg_op, flags & Q_ARGf_REF);
	assert(!argopl || (flags & Q_ARGf_LIST));
	if((flags & Q_ARGf_TUPLE) && is_std_op(tuple_arg_op, OP_PADSV) &&
			!(tuple_arg_op->op_flags & OPf_KIDS) &&
			!(tuple_arg_op->op_private & OPpLVAL_INTRO) &&
			!(tuple_arg_op->op_private & OPpDEREF)) {
		tuple_po = tuple_arg_op->op_targ;
		op_free(tuple_arg_op);
		tuple_arg_op = NULL;
		flags |= Q_OPp_PAD_TUPLE;
		flags &= ~Q_CKf_FOLD;
	}
	if((flags & Q_ARGf_TUPLE) && (flags & Q_CKf_FOLD)) {
		SV *argsv = op_scalar_value(tuple_arg_op);
		if(!(argsv && SvROK(argsv) && (tuple_sv = SvRV(argsv)) &&
				SvTYPE(tuple_sv) == SVt_PVOBJ &&
				SvREADONLY(tuple_sv)))
			flags &= ~Q_CKf_FOLD;
	}
	if(flags & Q_ARGf_INDEX) {
		SV *argsv = op_scalar_value(index_arg_op);
		if(LIKELY(argsv && SvIOK(argsv))) {
			index_val = index_from_arg(argsv);
			op_free(index_arg_op);
			index_arg_op = NULL;
			flags |= Q_OPp_FIXED_INDEX;
		}
		assert(flags & Q_ARGf_TUPLE);
		if(flags & Q_CKf_FOLD) {
			assert(tuple_sv);
			if(!((flags & Q_OPp_FIXED_INDEX) &&
					index_val >= 0 &&
					index_val <= ObjectMAXFIELD(tuple_sv)))
				flags &= ~Q_CKf_FOLD;
		}
	}
	if(UNLIKELY(flags & Q_ARGf_REF_LIST)) {
		OP *pushop;
		if((flags & Q_CKf_FOLD) && !ref_arg_list_all_constant(argopl))
			flags &= ~Q_CKf_FOLD;
		pushop = newOP(OP_PUSHMARK, 0);
		if(LIKELY(argopl)) OpMORESIB_set(pushop, argopl);
		argopl = pushop;
	}
	argopl = link_scalar_arg(argopl, ref_arg_op);
	argopl = link_scalar_arg(argopl, index_arg_op);
	argopl = link_scalar_arg(argopl, tuple_arg_op);
	newop = newOP_simple_custom(
		(flags & Q_OPp_FIXED_INDEX) ? sizeof(Q_TUPLE_OP) : sizeof(UNOP),
		qf->THX_pp, argopl);
	if(flags & Q_OPp_PAD_TUPLE) newop->op_targ = tuple_po;
	if(flags & Q_OPp_FIXED_INDEX) ((Q_TUPLE_OP*)newop)->index = index_val;
	if(!UNLIKELY(flags & Q_CKf_NOT_SCALAR_RETURN))
		newop->op_flags |= OPf_WANT_SCALAR;
	newop->op_private = (U8)flags;
	if(UNLIKELY(flags & Q_CKf_FOLD)) newop = fold_clean_optree(newop);
	return newop;
}

MODULE = Tuple::Munge PACKAGE = Tuple::Munge

PROTOTYPES: DISABLE

BOOT:
{
	int i;
	{
		XOP *xop;
		Newxz(xop, 1, XOP);
		XopENTRY_set(xop, xop_name, "tuple");
		XopENTRY_set(xop, xop_desc, "Tuple::Munge tuple construction");
		XopENTRY_set(xop, xop_class, OA_UNOP);
		XopENTRY_set(xop, xop_peep, THX_cpeep_tuple);
		Perl_custom_op_register(aTHX_ THX_pp_tuple, xop);
	}
	for(i = C_ARRAY_LENGTH(q_funcs); i--; ) {
		struct q_func const *qf = &q_funcs[i];
		CV *fcv;
		char proto[4], *p = proto;
		if(!(qf->flags & Q_BTf_NO_REGISTER_XOP)) {
			XOP *xop;
			Newxz(xop, 1, XOP);
			XopENTRY_set(xop, xop_name,
				qf->fqsubname + sizeof(Q_PKG_PREFIX)-1);
			XopENTRY_set(xop, xop_desc, qf->fqsubname);
			XopENTRY_set(xop, xop_class, OA_UNOP);
			if(qf->flags & Q_BTf_SLOTVAL_RET)
				XopENTRY_set(xop, xop_peep,
					THX_cpeep_slotval_ret);
			Perl_custom_op_register(aTHX_ qf->THX_pp, xop);
		}
		if(qf->flags & Q_ARGf_TUPLE) *p++ = '$';
		if(qf->flags & Q_ARGf_INDEX) *p++ = '$';
		if(qf->flags & Q_ARGf_REF) *p++ = '$';
		if(qf->flags & Q_ARGf_LIST) *p++ = '@';
		*p = 0;
		fcv = newXS_flags((char*)qf->fqsubname,
			THX_xsfunc_tuple_any, __FILE__, proto, 0);
		CvXSUBANY(fcv).any_ptr = (void*)qf;
		cv_set_call_checker_flags(fcv, THX_cksub_tuple_any,
			(SV*)fcv, 0);
	}
}

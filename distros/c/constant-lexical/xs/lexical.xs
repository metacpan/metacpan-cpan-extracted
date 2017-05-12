#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* In 5.18 and 5.20, intro_my is not exported.  We could just call
   Perl_intro_my, but Windows users might complain, so just copy the
   function here (and tweak it).  */
#ifndef intro_my
#define intro_my() S_intro_my(aTHX)

/* Fortunately these macros are the same in both versions (but different in
   5.22+; fortunately, 5.22 exposes intro_my).  */

#define COP_SEQ_RANGE_LOW_set(sv,val)		\
  STMT_START { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = (val); } STMT_END
#define COP_SEQ_RANGE_HIGH_set(sv,val)		\
  STMT_START { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = (val); } STMT_END


static U32
S_intro_my(pTHX)
{
    dVAR;
    SV **svp;
    I32 i;
    U32 seq;

    if (! PL_min_intro_pending)
	return PL_cop_seqmax;

    svp = AvARRAY(PL_comppad_name);
    for (i = PL_min_intro_pending; i <= PL_max_intro_pending; i++) {
	SV * const sv = svp[i];

/* 5.18 uses sv != &PL_sv_undef; 5.20 uses PadnameLEN(sv), defining it
   differently from 5.18.  The main thing is that it is neither
   &PL_sv_undef nor &PL_sv_no.  Checking that the name has length to it is
   the canonical way of deing this, but a simple SvCUR() won’t work on
   &PL_sv_undef, which has no such field.  If it is not &PL_sv_undef, then
   it has a PV and a valid SvCUR field.  */
	if (sv && sv != &PL_sv_undef && SvCUR(sv) && !SvFAKE(sv)
	    && COP_SEQ_RANGE_LOW(sv) == PERL_PADSEQ_INTRO)
	{
	    COP_SEQ_RANGE_HIGH_set(sv, PERL_PADSEQ_INTRO); /* Don't know scope end yet. */
	    COP_SEQ_RANGE_LOW_set(sv, PL_cop_seqmax);
	}
    }
    seq = PL_cop_seqmax;
    PL_cop_seqmax++;
    if (PL_cop_seqmax == PERL_PADSEQ_INTRO) /* not a legal value */
	PL_cop_seqmax++;
    PL_min_intro_pending = 0;
    PL_comppad_name_fill = PL_max_intro_pending; /* Needn't search higher */

    return seq;
}

#endif

/* Copied from XS::APItest::lexical_import.  */

MODULE = constant::lexical	PACKAGE = constant::lexical

void
install_lexical_sub(SV *name, CV *cv)
    CODE:
    {
	PADLIST *pl;
	PADOFFSET off;
	if (!PL_compcv)
	    Perl_croak(aTHX_
		 "install_lexical_sub can only be called at compile time");
	pl = CvPADLIST(PL_compcv);
	ENTER;
	SAVESPTR(PL_comppad_name); PL_comppad_name = PadlistNAMES(pl);
	SAVESPTR(PL_comppad);	   PL_comppad	   = PadlistARRAY(pl)[1];
	SAVESPTR(PL_curpad);	   PL_curpad	   = PadARRAY(PL_comppad);
	off = pad_add_name_sv(sv_2mortal(newSVpvf("&%"SVf,name)),
			      padadd_STATE, 0, 0);
	SvREFCNT_dec(PL_curpad[off]);
	PL_curpad[off] = SvREFCNT_inc(cv);
	intro_my();
	LEAVE;
    }

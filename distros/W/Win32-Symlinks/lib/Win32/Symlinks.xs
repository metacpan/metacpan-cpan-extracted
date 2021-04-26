#define PERL_IN_PP_SYS_C
#define NEED_sv_2pv_flags
#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
 
static OP *
S_ft_return_false(pTHX_ SV *ret) {
    OP *next = NORMAL;
    dSP;
    if (PL_op->op_flags & OPf_REF) XPUSHs(ret);
    else			   SETs(ret);
    PUTBACK;
    if (PL_op->op_private & OPpFT_STACKING) {
        while (OP_IS_FILETEST(next->op_type)
               && next->op_private & OPpFT_STACKED)
            next = next->op_next;
    }
    return next;
}
S_ft_return_true(pTHX_ SV *ret) {
    dSP;
    if (PL_op->op_flags & OPf_REF)
        XPUSHs(PL_op->op_private & OPpFT_STACKING ? (SV *)cGVOP_gv : (ret));
    else if (!(PL_op->op_private & OPpFT_STACKING))
        SETs(ret);
    PUTBACK;
    return NORMAL;
}
#define tryAMAGICftest_MG(chr) STMT_START { \
	if ( (SvFLAGS(*PL_stack_sp) & (SVf_ROK|SVs_GMG)) \
		&& PL_op->op_flags & OPf_KIDS) {     \
	    OP *next = S_try_amagic_ftest(aTHX_ chr);	\
	    if (next) return next;			  \
	}						   \
    } STMT_END
S_try_amagic_ftest(pTHX_ char chr) {
    SV *const arg = *PL_stack_sp;
    assert(chr != '?');
    if (!(PL_op->op_private & OPpFT_STACKING)) SvGETMAGIC(arg);
    if (SvAMAGIC(arg))
    {
	const char tmpchr = chr;
	SV * const tmpsv = amagic_call(arg,
				newSVpvn_flags(&tmpchr, 1, SVs_TEMP),
				ftest_amg, AMGf_unary);
	if (!tmpsv)
	    return NULL;
	return SvTRUE(tmpsv)
            ? S_ft_return_true(aTHX_ tmpsv) : S_ft_return_false(aTHX_ tmpsv);
    }
    return NULL;
}
PP(pp_overload_ftlink)
{
    dSP;
    I32 ok;
    SV *const svlink = *SP;
    tryAMAGICftest_MG('l');
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs( sv_2mortal( newSVsv(svlink) ) );
    PUTBACK;
    call_pv ("Win32::Symlinks::l", G_SCALAR);
    SPAGAIN;
    ok = POPi;
    FREETMPS;
    LEAVE;
  PUTBACK;
    if (ok == 1) {
        dSP;
        if (PL_op->op_flags & OPf_REF)
            XPUSHs(PL_op->op_private & OPpFT_STACKING ? (SV *)cGVOP_gv : (&PL_sv_yes));
        else if (!(PL_op->op_private & OPpFT_STACKING))
          SETs(&PL_sv_yes);
        PUTBACK;
        return PL_op->op_next;
    }
    else {    
        OP *next = PL_op->op_next;
        dSP;
    
        if (PL_op->op_flags & OPf_REF)
            XPUSHs(&PL_sv_no);
        else
            SETs(&PL_sv_no);
        PUTBACK;
    
        if (PL_op->op_private & OPpFT_STACKING) {
            while (OP_IS_FILETEST(next->op_type)
                   && next->op_private & OPpFT_STACKED)
                next = next->op_next;
        }
        return next;
    }
}
OP* (*real_pp_ftlink)(pTHX);
void _override_link_test() {
    real_pp_ftlink = PL_ppaddr[OP_FTLINK];
    PL_ppaddr[OP_FTLINK] = Perl_pp_overload_ftlink;
}
 
MODULE = Win32::Symlinks  PACKAGE = Win32::Symlinks
PROTOTYPES: ENABLE
 
 # XS code goes here
 
 # XS comments begin with " #" to avoid them being interpreted as pre-processor
 # directives
 
void
_override_link_test()

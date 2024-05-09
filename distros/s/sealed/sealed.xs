#include "EXTERN.h"
#include "perl.h"
#include "perlapi.h"
#include "XSUB.h"

/* LOTS OF CRIBBING FROM B::Generate; just avoiding its static variables */
static inline I32
op_name_to_num(SV * name)
{
    char const *s;
    char *wanted = SvPV_nolen(name);
    int i =0;
    int topop = OP_max;

#ifdef PERL_CUSTOM_OPS
    topop--;
#endif

    if (SvIOK(name) && SvIV(name) >= 0 && SvIV(name) < topop)
        return SvIV(name);			/* XXX coverage 0 */

    for (s = PL_op_name[i]; s; s = PL_op_name[++i]) {
        if (strEQ(s, wanted))
            return i;
    }
#ifdef PERL_CUSTOM_OPS
    if (PL_custom_op_names) {
        HE* ent;
        SV* value;

        /* This is sort of a hv_exists, backwards - since custom-ops
	   are stored using their pp-addr as key, we must scan the
	   values */
        (void)hv_iterinit(PL_custom_op_names);
        while ((ent = hv_iternext(PL_custom_op_names))) {
            if (strEQ(SvPV_nolen(hv_iterval(PL_custom_op_names,ent)),wanted))
                return OP_CUSTOM;
        }
    }
#endif

    croak("No such op \"%s\"", SvPV_nolen(name));	/* XXX coverage 0 */

    return -1;
}


#define NEW_SVOP(_newOPgen, B_class)                                        \
{                                                                           \
    OP *o;                                                                  \
    SV* param;                                                              \
    I32 typenum;                                                            \
    typenum = op_name_to_num(type); /* XXX More classes here! */            \
    if (typenum == OP_GVSV) {                                               \
        if (*(SvPV_nolen(sv)) == '$')                                       \
            param = (SV*)gv_fetchpv(SvPVX(sv)+1, TRUE, SVt_PV);             \
        else                                                                \
            croak("First character to GVSV was not dollar");                \
    } else                                                                  \
        param = newSVsv(sv);                                                \
    o = _newOPgen(typenum, flags, param);                                   \
    if (strEQ(B_class,"B::PADOP")) {                                    \
       PADOP* p = o;                                                        \
       PADNAME **names = PadnamelistARRAY((PADNAMELIST *)PadlistARRAY(padlist)[0]); \
       names[p->op_padix] = newPADNAMEpvn("&", 1);                          \
    }                                                                       \
  ST(0) = sv_newmortal();                                                   \
    sv_setiv(newSVrv(ST(0), B_class), PTR2IV(o));                           \
}

#define PRE_OP                                                          \
            I32 old_padix              = PL_padix;                      \
            I32 old_comppad_name_fill  = PL_comppad_name_fill;          \
            I32 old_min_intro_pending  = PL_min_intro_pending;          \
            I32 old_max_intro_pending  = PL_max_intro_pending;          \
            int old_cv_has_eval        = PL_cv_has_eval;                \
            I32 old_pad_reset_pending  = PL_pad_reset_pending;          \
            SV **old_curpad            = PL_curpad;                     \
            AV *old_comppad            = PL_comppad;                    \
            OP* old_op                 = PL_op;                         \
            PADNAMELIST *old_comppad_name = PL_comppad_name;            \
            PL_comppad_name      = PadlistNAMES(padlist);               \
            PL_comppad           = PadlistARRAY(padlist)[1];            \
            PL_curpad            = AvARRAY(PL_comppad);                 \
            PL_comppad_name_fill = 0;                                   \
            PL_min_intro_pending = 0;                                   \
	    PL_cv_has_eval       = 0;                                   \
            PL_pad_reset_pending = 0;                                   \
            PL_padix             = PadnamelistMAX(PL_comppad_name);


#define POST_OP                                                 \
            PL_padix             = old_padix;                   \
            PL_comppad_name_fill = old_comppad_name_fill;       \
            PL_min_intro_pending = old_min_intro_pending;       \
            PL_max_intro_pending = old_max_intro_pending;       \
            PL_pad_reset_pending = old_pad_reset_pending;       \
            PL_curpad            = old_curpad;                  \
            PL_comppad           = old_comppad;                 \
            PL_comppad_name      = old_comppad_name;            \
	    PL_cv_has_eval       = old_cv_has_eval;             \
            PL_op                = old_op;

MODULE = sealed    PACKAGE = sealed               PREFIX = GVOP_

SV *GVOP_new(SV *type, I32 flags, SV *sv, PADLIST* padlist)

    CODE:
         PRE_OP;
#ifdef USE_ITHREADS
         NEW_SVOP(newPADOP, "B::PADOP");
#else
         NEW_SVOP(newSVOP, "B::SVOP");
#endif
         POST_OP;

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = UNIVERSAL::has        PACKAGE = UNIVERSAL::has        

SV *
xs_has(sv)
    SV * sv
PROTOTYPE: $
PREINIT:
    HV *pkg;
    AV *linear_av;

    HV *cstash;
    SV **linear_svp;
    SV *linear_sv;

    HE *entry;
    SV *val;
    CV *cv;
    char *key;

    STRLEN len;

    AV* ret;
CODE:
    ret = newAV();

    if (!(SvROK(sv) && SvOBJECT(SvRV(sv))))
        XSRETURN_EMPTY;

    sv = MUTABLE_SV(SvRV(sv));
    if (SvOBJECT(sv))
        pkg = SvSTASH(sv);

    if (pkg) {
        linear_av = mro_get_linear_isa(pkg); /* has ourselves at the top of the list */

        linear_svp = AvARRAY(linear_av);
        items = AvFILLp(linear_av);

        while (items--) {
            linear_sv = *linear_svp++;
            cstash = gv_stashsv(linear_sv, 0);

            /* av_push(ret, newSVpv(SvPV_nolen(linear_sv), 0)); */

            if (cstash) {
                hv_iterinit(cstash);

                while (entry = hv_iternext(cstash)) {
                    val = HeVAL(entry);

                    /* av_push(ret, newSVpv(SvPV_nolen(val), 0)); */

                    if (SvTYPE(val) == SVt_PVGV) {
                        cv = GvCV(val);

                        if (cv && SvTYPE(cv) == SVt_PVCV) {
                            key = HePV(entry, len);
                            av_push(ret, newSVpv(key,0));
                        }
                    }
                }
            }
        }
    }

    RETVAL = newRV_noinc((SV *)ret);
OUTPUT:
    RETVAL

# Intervals (include/tkn/tkn_interval.h).

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

void
_interval(self, method, text)
        SV *self
        SV *method
        SV *text
    PREINIT:
        HV *info = NULL;
        SV *s = NULL, *e = NULL;
    PPCODE:
        tkn_interval(aTHX_ self, method, text, &s, &e, &info);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSVsv(s)));
        PUSHs(sv_2mortal(newSVsv(e)));
        PUSHs(sv_2mortal(newRV_inc((SV *)info)));

void
parse_interval(self, text = &PL_sv_undef, ...)
        SV *self
        SV *text
    PREINIT:
        HV *info = NULL;
        SV *obj, *s = NULL, *e = NULL;
    PPCODE:
        obj = tkn_invocant(aTHX_ "parse_interval", self, items > 2 ? &ST(2) : NULL, items > 2 ? items - 2 : 0);
        tkn_interval(aTHX_ obj, sv_2mortal(newSVpvs("parse_interval")), text, &s, &e, &info);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVsv(s)));
        PUSHs(sv_2mortal(newSVsv(e)));

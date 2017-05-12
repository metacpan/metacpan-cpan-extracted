#include "use_perl.h"
#include "mruby_pm_bridge.h"

#include "mruby.h"
#include "mruby/compile.h"

MODULE = mRuby      PACKAGE = mRuby

MODULE = mRuby      PACKAGE = mRuby::State

void
new(const char *klass)
    PPCODE:
        const mrb_state* mrb = mrb_open();
        XPUSHs(sv_bless(newRV_noinc_mortal(newSViv(PTR2IV(mrb))), gv_stashpv(klass, TRUE)));
        XSRETURN(1);

void
parse_string(mrb_state *mrb, const char *src)
    PPCODE:
        const struct mrb_parser_state* st = mrb_parse_string(mrb, src, NULL);
        XPUSHs(sv_bless(newRV_noinc_mortal(newSViv(PTR2IV(st))), gv_stashpv("mRuby::ParserState", TRUE)));
        XSRETURN(1);

void
generate_code(mrb_state *mrb, struct mrb_parser_state* st)
    PPCODE:
        const struct RProc * proc = mrb_generate_code(mrb, st);
        XPUSHs(sv_bless(newRV_noinc_mortal(newSViv(PTR2IV(proc))), gv_stashpv("mRuby::RProc", TRUE)));
        XSRETURN(1);

void
run(mrb_state *mrb, struct RProc* proc, SV *val=&PL_sv_undef)
    PPCODE:
        const mrb_value ret = mrb_toplevel_run(mrb, proc);

        SV * sv = mruby_pm_bridge_value2sv(aTHX_ mrb, ret);
        if (LIKELY(SvOK(sv))) {
          mXPUSHs(sv);
        }
        else {
          XPUSHs(sv);
        }
        XSRETURN(1);

void
funcall(mrb_state *mrb, SV* funcname, ...)
    PPCODE:
        STRLEN len;
        const char*   funcname_p   = SvPV(funcname, len);
        const mrb_sym funcname_sym = mrb_intern(mrb, funcname_p, (size_t)len);
        const mrb_int argc         = (mrb_int)items - 2;

        mrb_value *argv; Newxc(argv, argc, mrb_value, mrb_value);
        for (int i = 0; LIKELY(i<argc); i++) {
            SV *arg = ST(i+2);
            argv[i] = mruby_pm_bridge_sv2value(aTHX_ mrb, arg);
        }
        const mrb_value ret = mrb_funcall_argv(mrb, mrb_top_self(mrb), funcname_sym, argc, argv);
        Safefree(argv);

        SV * sv = mruby_pm_bridge_value2sv(aTHX_ mrb, ret);
        if (LIKELY(SvOK(sv))) {
          mXPUSHs(sv);
        }
        else {
          XPUSHs(sv);
        }
        XSRETURN(1);

void
proc_new(SV *self, SV *proc)
    PPCODE:
        warn("proc_new() is OBSOLETE. This API will be removed in the near future.");
        XPUSHs(proc);
        XSRETURN(1);

void
DESTROY(mrb_state *mrb)
    PPCODE:
        mrb_close(mrb);
        XSRETURN(0);

MODULE = mRuby      PACKAGE = mRuby::ParserState

void
pool_close(struct mrb_parser_state* st)
    PPCODE:
        warn("pool_close() is OBSOLETE. This API will be removed in the near future.");
        XSRETURN(0);

void
DESTROY(struct mrb_parser_state* st)
    PPCODE:
        mrb_parser_free(st);
        XSRETURN(0);

MODULE = mRuby      PACKAGE = mRuby::RProc

MODULE = mRuby      PACKAGE = mRuby::Exception


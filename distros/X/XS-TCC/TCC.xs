#define PERL_NO_GET_CONTEXT

/* For versions of ExtUtils::ParseXS > 3.04_02, we need to
 * explicitly enforce exporting of XSUBs since we want to
 * refer to them using XS(). This isn't strictly necessary,
 * but it's by far the simplest way to be backwards-compatible.
 */
/* #define PERL_EUPXS_ALWAYS_EXPORT */

#include "EXTERN.h"
#include "perl.h"

#include "XSUB.h"
#include "ppport.h"

#include <libtcc.h>

/* functions to be called by core typemap reimplementations */
#include "typemap_func.h"

typedef void xstcc_symbol;

typedef struct {
  TCCState *tccstate;
  CV *error_callback;
#ifdef PERL_IMPLICIT_CONTEXT
  tTHX perl_thread_context;
#endif
} xstcc_state;

void
xstcc_error_func(void *opaque, const char *msg)
{
  xstcc_state *state = (xstcc_state *)opaque;
#ifdef PERL_IMPLICIT_CONTEXT
  tTHX my_perl = state->perl_thread_context;
#endif

  if (state->error_callback != NULL) {
    dSP;
    dXSTARG;

    PUSHMARK(SP);
    XPUSHp(msg, strlen(msg));
    PUTBACK;

    call_sv((SV *)state->error_callback, G_DISCARD);
  }
  else {
    /*
     * libtcc does not provide a way to determine errors and warnings.
     */
    if (strstr(msg, "error: ")) {
      croak("%s", msg);
    }
    else {
      warn("%s", msg);
    }
  }
}

MODULE = XS::TCC        PACKAGE = XS::TCC
PROTOTYPES: DISABLE

REQUIRE: 3.18

TYPEMAP: <<HERE
TCCState * O_OBJECT
xstcc_state * O_OBJECT
xstcc_symbol * O_OBJECT

OUTPUT
O_OBJECT
  sv_setref_pv( $arg, CLASS, (void*)$var );

INPUT

O_OBJECT
  if( sv_isobject($arg) && (SvTYPE(SvRV($arg)) == SVt_PVMG) )
    $var = ($type)SvIV((SV*)SvRV( $arg ));
  else{
    warn( \"${Package}::$func_name() -- $var is not a blessed SV reference\" );
    XSRETURN_UNDEF;
  }
HERE

MODULE = XS::TCC        PACKAGE = XS::TCC::TCCState

xstcc_state *
new(const char *CLASS)
  CODE:
    Newx(RETVAL, 1, xstcc_state);
    RETVAL->tccstate = tcc_new();
    RETVAL->error_callback = NULL;
#ifdef PERL_IMPLICIT_CONTEXT
    RETVAL->perl_thread_context = aTHX;
#endif
    /* for now, always set output type to memory by default */
    tcc_set_output_type(RETVAL->tccstate, TCC_OUTPUT_MEMORY);
    /* croaks by default */
    tcc_set_error_func(RETVAL->tccstate, (void *)RETVAL, xstcc_error_func);
  OUTPUT: RETVAL

void
DESTROY(xstcc_state *self)
  CODE:
    tcc_delete(self->tccstate);
    SvREFCNT_dec(self->error_callback); /* has a NULL check */
    Safefree(self);

void
set_lib_path(xstcc_state *self, const char *path)
  CODE:
    tcc_set_lib_path(self->tccstate, path);

void
set_error_callback(xstcc_state *self, CV *callback)
  CODE:
    SvREFCNT_inc(callback);
    SvREFCNT_dec(self->error_callback); /* includes NULL check */
    self->error_callback = callback;

int
set_options(xstcc_state *self, const char *opt)
  CODE:
    RETVAL = tcc_set_options(self->tccstate, opt);
  OUTPUT: RETVAL

int
add_sysinclude_path(xstcc_state *self, const char *path)
  ALIAS:
    add_include_path = 1
  CODE:
    if (ix == 0)
      RETVAL = tcc_add_sysinclude_path(self->tccstate, path);
    else
      RETVAL = tcc_add_include_path(self->tccstate, path);
  OUTPUT: RETVAL

void
define_symbol(xstcc_state *self, const char *sym, const char *value)
  CODE:
    tcc_define_symbol(self->tccstate, sym, value);

void
undefine_symbol(xstcc_state *self, const char *sym)
  CODE:
    tcc_undefine_symbol(self->tccstate, sym);

int
add_file(xstcc_state *self, const char *filename)
  CODE:
    RETVAL = tcc_add_file(self->tccstate, filename);
  OUTPUT: RETVAL

int
compile_string(xstcc_state *self, SV *code)
  PREINIT:
    STRLEN len;
    char *cstr;
  CODE:
    cstr = SvPV(code, len);
    RETVAL = tcc_compile_string(self->tccstate, cstr);
  OUTPUT: RETVAL

int
set_output_type(xstcc_state *self, int output_type);
  CODE:
    RETVAL = tcc_set_output_type(self->tccstate, output_type);
  OUTPUT: RETVAL

int
add_library_path(xstcc_state *self, const char *pathname)
  CODE:
    RETVAL = tcc_add_library_path(self->tccstate, pathname);
  OUTPUT: RETVAL

int
add_library(xstcc_state *self, const char *libname)
  CODE:
    RETVAL = tcc_add_library(self->tccstate, libname);
  OUTPUT: RETVAL

int
add_symbol(xstcc_state *self, const char *name, const char *value)
  CODE:
    RETVAL = tcc_add_symbol(self->tccstate, name, value);
  OUTPUT: RETVAL

int
output_file(xstcc_state *self, const char *filename)
  CODE:
    RETVAL = tcc_output_file(self->tccstate, filename);
  OUTPUT: RETVAL

int
run(xstcc_state *self, int argc, AV *argv)
  PREINIT:
    unsigned int avlen, i;
    SV **elem;
    char **str_argv;
    SV *argv_ctrl;
  CODE:
    avlen = av_len(argv)+1;
    argv_ctrl = sv_2mortal(newSV(avlen * sizeof(char *)));
    str_argv = (char **)argv_ctrl;
    for (i = 0; i < avlen; ++i) {
      elem = av_fetch(argv, i, 0);
      str_argv[i] = SvPV_nolen(*elem);
    }
    RETVAL = tcc_run(self->tccstate, argc, str_argv);
  OUTPUT: RETVAL

xstcc_symbol *
get_symbol(xstcc_state *self, const char *name)
  PREINIT:
    const char *CLASS = "XS::TCC::TCCSymbol";
    /* Note: Perl symbol objects must not live longer than TCCStates
     *       or they become invalid. */
  CODE:
    RETVAL = tcc_get_symbol(self->tccstate, name);
    if (RETVAL == NULL)
      croak("Symbol '%s' not found!", name);
  OUTPUT: RETVAL

int
relocate(xstcc_state *self)
  PREINIT:
    AV *outav;
    SV *memsv;
    size_t memsize;
  CODE:
    outav = get_av("XS::TCC::TCCState::_output_memory", GV_ADD);
    memsize = tcc_relocate(self->tccstate, NULL);
    memsv = newSV(memsize);
    av_push(outav, memsv);
    RETVAL = tcc_relocate(self->tccstate, SvPVX(memsv));
  OUTPUT: RETVAL

MODULE = XS::TCC        PACKAGE = XS::TCC::TCCSymbol

CV *
as_xsub(xstcc_symbol *self)
  PREINIT:
    XSUBADDR_t sub;
  CODE:
    sub = (XSUBADDR_t)self;
    RETVAL = newXS(NULL, sub, "anon");
    sv_2mortal((SV *)RETVAL);
  OUTPUT: RETVAL

MODULE = XS::TCC        PACKAGE = XS::TCC

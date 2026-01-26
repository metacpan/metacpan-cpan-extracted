#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xs_jit_builder.h"

/* Store the builder pointer in the object's hash */
#define BUILDER_KEY "_builder_ptr"
#define BUILDER_KEY_LEN 12

static XS_JIT_Builder* get_builder(pTHX_ SV* self) {
    HV* hv;
    SV** svp;
    
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
        croak("Not a valid XS::JIT::Builder object");
    }
    
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, BUILDER_KEY, BUILDER_KEY_LEN, 0);
    
    if (!svp || !SvOK(*svp)) {
        croak("Builder object not initialized");
    }
    
    return INT2PTR(XS_JIT_Builder*, SvIV(*svp));
}

static void set_builder(pTHX_ SV* self, XS_JIT_Builder* b) {
    HV* hv = (HV*)SvRV(self);
    hv_store(hv, BUILDER_KEY, BUILDER_KEY_LEN, newSViv(PTR2IV(b)), 0);
}

MODULE = XS::JIT::Builder  PACKAGE = XS::JIT::Builder

PROTOTYPES: DISABLE

BOOT:
{
    HV* stash = gv_stashpv("XS::JIT::Builder", GV_ADD);
    
    /* Inline op type constants */
    newCONSTSUB(stash, "INLINE_NONE",      newSViv(XS_JIT_INLINE_NONE));
    newCONSTSUB(stash, "INLINE_GETTER",    newSViv(XS_JIT_INLINE_GETTER));
    newCONSTSUB(stash, "INLINE_SETTER",    newSViv(XS_JIT_INLINE_SETTER));
    newCONSTSUB(stash, "INLINE_HV_GETTER", newSViv(XS_JIT_INLINE_HV_GETTER));
    newCONSTSUB(stash, "INLINE_HV_SETTER", newSViv(XS_JIT_INLINE_HV_SETTER));
    
    /* Type check constants */
    newCONSTSUB(stash, "TYPE_ANY",       newSViv(XS_JIT_TYPE_ANY));
    newCONSTSUB(stash, "TYPE_DEFINED",   newSViv(XS_JIT_TYPE_DEFINED));
    newCONSTSUB(stash, "TYPE_INT",       newSViv(XS_JIT_TYPE_INT));
    newCONSTSUB(stash, "TYPE_NUM",       newSViv(XS_JIT_TYPE_NUM));
    newCONSTSUB(stash, "TYPE_STR",       newSViv(XS_JIT_TYPE_STR));
    newCONSTSUB(stash, "TYPE_REF",       newSViv(XS_JIT_TYPE_REF));
    newCONSTSUB(stash, "TYPE_ARRAYREF",  newSViv(XS_JIT_TYPE_ARRAYREF));
    newCONSTSUB(stash, "TYPE_HASHREF",   newSViv(XS_JIT_TYPE_HASHREF));
    newCONSTSUB(stash, "TYPE_CODEREF",   newSViv(XS_JIT_TYPE_CODEREF));
    newCONSTSUB(stash, "TYPE_OBJECT",    newSViv(XS_JIT_TYPE_OBJECT));
    newCONSTSUB(stash, "TYPE_BLESSED",   newSViv(XS_JIT_TYPE_BLESSED));
}

SV*
new(class, ...)
    const char* class
    PREINIT:
        HV* hv;
        SV* self;
        XS_JIT_Builder* b;
        int indent_width = 4;
        int use_tabs = 0;
        int i;
    CODE:
        /* Parse options */
        for (i = 1; i < items; i += 2) {
            if (i + 1 < items) {
                const char* key = SvPV_nolen(ST(i));
                if (strEQ(key, "indent_width")) {
                    indent_width = SvIV(ST(i + 1));
                } else if (strEQ(key, "use_tabs")) {
                    use_tabs = SvTRUE(ST(i + 1)) ? 1 : 0;
                }
            }
        }
        
        /* Create the builder */
        b = xs_jit_builder_new(aTHX);
        xs_jit_set_indent_width(b, indent_width);
        xs_jit_set_use_tabs(b, use_tabs);
        
        /* Create blessed hashref */
        hv = newHV();
        self = newRV_noinc((SV*)hv);
        sv_bless(self, gv_stashpv(class, GV_ADD));
        
        /* Store the pointer */
        set_builder(aTHX_ self, b);
        
        RETVAL = self;
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_builder_free(aTHX_ b);

SV*
code(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        RETVAL = xs_jit_builder_code(aTHX_ b);
    OUTPUT:
        RETVAL

SV*
reset(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_builder_reset(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
line(self, fmt, ...)
    SV* self
    const char* fmt
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_line(aTHX_ b, "%s", fmt);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
raw(self, text)
    SV* self
    const char* text
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_raw(aTHX_ b, "%s", text);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
comment(self, text)
    SV* self
    const char* text
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_comment(aTHX_ b, text);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
blank(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_blank(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
indent(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_indent(b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
dedent(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_dedent(b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
block_start(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_block_start(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
block_end(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_block_end(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
xs_function(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_xs_function(aTHX_ b, name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
xs_preamble(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_xs_preamble(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
xs_end(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_xs_end(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
xs_return(self, count)
    SV* self
    int count
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_xs_return(aTHX_ b, count);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
xs_return_undef(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_xs_return_undef(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_undef(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_xs_return_undef(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
croak_usage(self, usage)
    SV* self
    const char* usage
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_croak_usage(aTHX_ b, usage);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
if(self, cond)
    SV* self
    const char* cond
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_if(aTHX_ b, cond);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
elsif(self, cond)
    SV* self
    const char* cond
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_elsif(aTHX_ b, cond);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
else(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_else(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
endif(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_endif(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
for(self, init, cond, incr)
    SV* self
    const char* init
    const char* cond
    const char* incr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_for(aTHX_ b, init, cond, incr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
while(self, cond)
    SV* self
    const char* cond
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_while(aTHX_ b, cond);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
endloop(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_endloop(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
endfor(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_endloop(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
endwhile(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_endloop(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
block(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_block_start(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
endblock(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_block_end(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare(self, type, name, ...)
    SV* self
    const char* type
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
        const char* value = NULL;
    CODE:
        if (items > 3 && SvOK(ST(3))) {
            value = SvPV_nolen(ST(3));
        }
        b = get_builder(aTHX_ self);
        xs_jit_declare(aTHX_ b, type, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_sv(self, name, value)
    SV* self
    const char* name
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_sv(aTHX_ b, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_hv(self, name, value)
    SV* self
    const char* name
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_hv(aTHX_ b, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_av(self, name, value)
    SV* self
    const char* name
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_av(aTHX_ b, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_hv(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_hv(aTHX_ b, name, "newHV()");
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_av(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_av(aTHX_ b, name, "newAV()");
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_int(self, name, value)
    SV* self
    const char* name
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_int(aTHX_ b, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_iv(self, name, value)
    SV* self
    const char* name
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_iv(aTHX_ b, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_nv(self, name, value)
    SV* self
    const char* name
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_nv(aTHX_ b, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_pv(self, name, value)
    SV* self
    const char* name
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_pv(aTHX_ b, name, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
assign(self, var, value)
    SV* self
    const char* var
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_assign(aTHX_ b, var, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
get_self(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_get_self(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
get_self_hv(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_get_self_hv(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
get_self_av(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_get_self_av(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
hv_fetch(self, hv, key, len, result_var)
    SV* self
    const char* hv
    const char* key
    STRLEN len
    const char* result_var
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_hv_fetch(aTHX_ b, hv, key, len, result_var);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
hv_fetch_sv(self, hv, key_expr, len_expr, result_var)
    SV* self
    const char* hv
    const char* key_expr
    const char* len_expr
    const char* result_var
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_hv_fetch_sv(aTHX_ b, hv, key_expr, len_expr, result_var);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
hv_store(self, hv, key, len, value)
    SV* self
    const char* hv
    const char* key
    STRLEN len
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_hv_store(aTHX_ b, hv, key, len, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
hv_store_sv(self, hv, key_expr, len_expr, value)
    SV* self
    const char* hv
    const char* key_expr
    const char* len_expr
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_hv_store_sv(aTHX_ b, hv, key_expr, len_expr, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
hv_fetch_return(self, hv, key, len)
    SV* self
    const char* hv
    const char* key
    STRLEN len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_hv_fetch_return(aTHX_ b, hv, key, len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
av_fetch(self, av, index, result_var)
    SV* self
    const char* av
    const char* index
    const char* result_var
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_av_fetch(aTHX_ b, av, index, result_var);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
av_store(self, av, index, value)
    SV* self
    const char* av
    const char* index
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_av_store(aTHX_ b, av, index, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
av_push(self, av, value)
    SV* self
    const char* av
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_av_push(aTHX_ b, av, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
av_len(self, av, result_var)
    SV* self
    const char* av
    const char* result_var
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_av_len(aTHX_ b, av, result_var);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_sv_iv(self, result_var, value)
    SV* self
    const char* result_var
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_new_sv_iv(aTHX_ b, result_var, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_sv_nv(self, result_var, value)
    SV* self
    const char* result_var
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_new_sv_nv(aTHX_ b, result_var, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_sv_pv(self, result_var, str, len)
    SV* self
    const char* result_var
    const char* str
    STRLEN len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_new_sv_pv(aTHX_ b, result_var, str, len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
mortal(self, sv)
    SV* self
    const char* sv
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_mortal(aTHX_ b, sv);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
croak(self, message)
    SV* self
    const char* message
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_croak(aTHX_ b, message);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
warn(self, message)
    SV* self
    const char* message
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_warn(aTHX_ b, message);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
check_items(self, min, max, usage)
    SV* self
    int min
    int max
    const char* usage
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_check_items(aTHX_ b, min, max, usage);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
check_defined(self, sv, error_msg)
    SV* self
    const char* sv
    const char* error_msg
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_check_defined(aTHX_ b, sv, error_msg);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
check_hashref(self, sv, error_msg)
    SV* self
    const char* sv
    const char* error_msg
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_check_hashref(aTHX_ b, sv, error_msg);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
check_arrayref(self, sv, error_msg)
    SV* self
    const char* sv
    const char* error_msg
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_check_arrayref(aTHX_ b, sv, error_msg);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
sv_to_iv(self, result_var, sv)
    SV* self
    const char* result_var
    const char* sv
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_sv_to_iv(aTHX_ b, result_var, sv);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
sv_to_nv(self, result_var, sv)
    SV* self
    const char* result_var
    const char* sv
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_sv_to_nv(aTHX_ b, result_var, sv);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
sv_to_pv(self, result_var, len_var, sv)
    SV* self
    const char* result_var
    SV* len_var
    const char* sv
    PREINIT:
        XS_JIT_Builder* b;
        const char* len_var_str = NULL;
    CODE:
        if (SvOK(len_var)) {
            len_var_str = SvPV_nolen(len_var);
        }
        b = get_builder(aTHX_ self);
        xs_jit_sv_to_pv(aTHX_ b, result_var, len_var_str, sv);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
sv_to_bool(self, result_var, sv)
    SV* self
    const char* result_var
    const char* sv
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_sv_to_bool(aTHX_ b, result_var, sv);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_iv(self, value)
    SV* self
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_return_iv(aTHX_ b, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_nv(self, value)
    SV* self
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_return_nv(aTHX_ b, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_pv(self, str, ...)
    SV* self
    const char* str
    PREINIT:
        XS_JIT_Builder* b;
        const char* len_str = NULL;
    CODE:
        if (items > 2 && SvOK(ST(2))) {
            len_str = SvPV_nolen(ST(2));
        }
        b = get_builder(aTHX_ self);
        xs_jit_return_pv(aTHX_ b, str, len_str);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_sv(self, sv)
    SV* self
    const char* sv
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_return_sv(aTHX_ b, sv);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_yes(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_return_yes(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_no(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_return_no(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_self(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_return_self(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
method_start(self, func_name, min_args, max_args, usage)
    SV* self
    const char* func_name
    int min_args
    int max_args
    const char* usage
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_method_start(aTHX_ b, func_name, min_args, max_args, usage);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
ro_accessor(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_ro_accessor(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
rw_accessor(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_rw_accessor(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
accessor(self, attr_name, ...)
    SV* self
    const char* attr_name
    PREINIT:
        XS_JIT_Builder* b;
        int readonly = 0;
        STRLEN attr_len;
    CODE:
        b = get_builder(aTHX_ self);
        attr_len = strlen(attr_name);
        /* Check for readonly option in hash-style args */
        if (items > 2) {
            SV* opts = ST(2);
            if (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
                HV* hv = (HV*)SvRV(opts);
                SV** val = hv_fetchs(hv, "readonly", 0);
                if (val && *val && SvTRUE(*val)) {
                    readonly = 1;
                }
            }
        }
        if (readonly) {
            xs_jit_ro_accessor(aTHX_ b, attr_name, attr_name, attr_len);
        } else {
            xs_jit_rw_accessor(aTHX_ b, attr_name, attr_name, attr_len);
        }
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
predicate(self, attr_name)
    SV* self
    const char* attr_name
    PREINIT:
        XS_JIT_Builder* b;
        char func_name[256];
        STRLEN attr_len;
    CODE:
        b = get_builder(aTHX_ self);
        attr_len = strlen(attr_name);
        snprintf(func_name, sizeof(func_name), "has_%s", attr_name);
        xs_jit_predicate(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
clearer(self, attr_name)
    SV* self
    const char* attr_name
    PREINIT:
        XS_JIT_Builder* b;
        char func_name[256];
        STRLEN attr_len;
    CODE:
        b = get_builder(aTHX_ self);
        attr_len = strlen(attr_name);
        snprintf(func_name, sizeof(func_name), "clear_%s", attr_name);
        xs_jit_clearer(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
constructor(self, func_name, attrs)
    SV* self
    const char* func_name
    AV* attrs
    PREINIT:
        XS_JIT_Builder* b;
        XS_JIT_Attr* attr_array;
        int num_attrs;
        int i;
    CODE:
        b = get_builder(aTHX_ self);
        num_attrs = av_len(attrs) + 1;
        
        if (num_attrs > 0) {
            Newx(attr_array, num_attrs, XS_JIT_Attr);
            
            for (i = 0; i < num_attrs; i++) {
                SV** elem = av_fetch(attrs, i, 0);
                if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVAV) {
                    AV* pair = (AV*)SvRV(*elem);
                    SV** name_sv = av_fetch(pair, 0, 0);
                    SV** len_sv = av_fetch(pair, 1, 0);
                    
                    if (name_sv && len_sv) {
                        attr_array[i].name = SvPV_nolen(*name_sv);
                        attr_array[i].len = SvIV(*len_sv);
                    }
                } else if (elem && SvPOK(*elem)) {
                    /* Simple string attribute name */
                    attr_array[i].name = SvPV_nolen(*elem);
                    attr_array[i].len = SvCUR(*elem);
                }
            }
            
            xs_jit_constructor(aTHX_ b, func_name, NULL, attr_array, num_attrs);
            Safefree(attr_array);
        } else {
            xs_jit_constructor(aTHX_ b, func_name, NULL, NULL, 0);
        }
        
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_simple(self, func_name)
    SV* self
    const char* func_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_new_simple(aTHX_ b, func_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_hash(self, func_name)
    SV* self
    const char* func_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_new_hash(aTHX_ b, func_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_array(self, func_name, num_slots)
    SV* self
    const char* func_name
    int num_slots
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_new_array(aTHX_ b, func_name, num_slots);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_with_build(self, func_name)
    SV* self
    const char* func_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_new_with_build(aTHX_ b, func_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
clone_hash(self, func_name)
    SV* self
    const char* func_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_clone_hash(aTHX_ b, func_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
clone_array(self, func_name)
    SV* self
    const char* func_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_clone_array(aTHX_ b, func_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_with_required(self, func_name, required_av)
    SV* self
    const char* func_name
    AV* required_av
    PREINIT:
        XS_JIT_Builder* b;
        const char** required_attrs;
        STRLEN* required_lens;
        int num_required;
        int i;
    CODE:
        b = get_builder(aTHX_ self);
        num_required = av_len(required_av) + 1;
        if (num_required > 0) {
            Newx(required_attrs, num_required, const char*);
            Newx(required_lens, num_required, STRLEN);
            for (i = 0; i < num_required; i++) {
                SV** elem = av_fetch(required_av, i, 0);
                if (elem && *elem) {
                    required_attrs[i] = SvPV(*elem, required_lens[i]);
                } else {
                    required_attrs[i] = "";
                    required_lens[i] = 0;
                }
            }
            xs_jit_new_with_required(aTHX_ b, func_name, required_attrs, required_lens, num_required);
            Safefree(required_attrs);
            Safefree(required_lens);
        } else {
            xs_jit_new_with_required(aTHX_ b, func_name, NULL, NULL, 0);
        }
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
rw_accessor_typed(self, func_name, attr_name, attr_len, type, error_msg)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    int type
    const char* error_msg
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_rw_accessor_typed(aTHX_ b, func_name, attr_name, attr_len, type, error_msg);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
rw_accessor_weak(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_rw_accessor_weak(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
hv_store_weak(self, hv_name, key, key_len, value_expr)
    SV* self
    const char* hv_name
    const char* key
    int key_len
    const char* value_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_hv_store_weak(aTHX_ b, hv_name, key, key_len, value_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
new_complete(self, func_name, attrs_av, call_build)
    SV* self
    const char* func_name
    AV* attrs_av
    int call_build
    PREINIT:
        XS_JIT_Builder* b;
        XS_JIT_AttrSpec* attrs;
        int num_attrs;
        int i;
    CODE:
        b = get_builder(aTHX_ self);
        num_attrs = av_len(attrs_av) + 1;
        
        if (num_attrs > 0) {
            Newxz(attrs, num_attrs, XS_JIT_AttrSpec);
            
            for (i = 0; i < num_attrs; i++) {
                SV** elem = av_fetch(attrs_av, i, 0);
                if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                    HV* spec = (HV*)SvRV(*elem);
                    SV** val;
                    
                    /* Required: name */
                    val = hv_fetchs(spec, "name", 0);
                    if (val && SvOK(*val)) {
                        attrs[i].name = SvPV(*val, attrs[i].len);
                    }
                    
                    /* Optional: required */
                    val = hv_fetchs(spec, "required", 0);
                    if (val && SvTRUE(*val)) {
                        attrs[i].required = 1;
                    }
                    
                    /* Optional: type */
                    val = hv_fetchs(spec, "type", 0);
                    if (val && SvIOK(*val)) {
                        attrs[i].type = SvIV(*val);
                    }
                    
                    /* Optional: type_msg */
                    val = hv_fetchs(spec, "type_msg", 0);
                    if (val && SvOK(*val)) {
                        attrs[i].type_msg = SvPV_nolen(*val);
                    }
                    
                    /* Optional: weak */
                    val = hv_fetchs(spec, "weak", 0);
                    if (val && SvTRUE(*val)) {
                        attrs[i].weak = 1;
                    }
                    
                    /* Optional: coerce */
                    val = hv_fetchs(spec, "coerce", 0);
                    if (val && SvOK(*val)) {
                        attrs[i].coerce = SvPV(*val, attrs[i].coerce_len);
                    }
                    
                    /* Optional: default_iv */
                    val = hv_fetchs(spec, "default_iv", 0);
                    if (val && SvOK(*val)) {
                        attrs[i].has_default = XS_JIT_DEFAULT_IV;
                        attrs[i].default_iv = SvIV(*val);
                    }
                    
                    /* Optional: default_nv */
                    val = hv_fetchs(spec, "default_nv", 0);
                    if (val && SvOK(*val)) {
                        attrs[i].has_default = XS_JIT_DEFAULT_NV;
                        attrs[i].default_nv = SvNV(*val);
                    }
                    
                    /* Optional: default_pv */
                    val = hv_fetchs(spec, "default_pv", 0);
                    if (val && SvOK(*val)) {
                        attrs[i].has_default = XS_JIT_DEFAULT_PV;
                        attrs[i].default_pv = SvPV(*val, attrs[i].default_pv_len);
                    }
                    
                    /* Optional: default_av (creates empty []) */
                    val = hv_fetchs(spec, "default_av", 0);
                    if (val && SvTRUE(*val)) {
                        attrs[i].has_default = XS_JIT_DEFAULT_AV;
                    }
                    
                    /* Optional: default_hv (creates empty {}) */
                    val = hv_fetchs(spec, "default_hv", 0);
                    if (val && SvTRUE(*val)) {
                        attrs[i].has_default = XS_JIT_DEFAULT_HV;
                    }
                }
            }
            
            xs_jit_new_complete(aTHX_ b, func_name, attrs, num_attrs, call_build);
            Safefree(attrs);
        } else {
            xs_jit_new_complete(aTHX_ b, func_name, NULL, 0, call_build);
        }
        
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
call_sv(self, cv_expr, args_av)
    SV* self
    const char* cv_expr
    AV* args_av
    PREINIT:
        XS_JIT_Builder* b;
        const char** args;
        int num_args;
        int i;
    CODE:
        b = get_builder(aTHX_ self);
        num_args = av_len(args_av) + 1;
        
        if (num_args > 0) {
            Newxz(args, num_args, const char*);
            for (i = 0; i < num_args; i++) {
                SV** elem = av_fetch(args_av, i, 0);
                if (elem && SvOK(*elem)) {
                    args[i] = SvPV_nolen(*elem);
                } else {
                    args[i] = "NULL";
                }
            }
            xs_jit_call_sv(aTHX_ b, cv_expr, args, num_args);
            Safefree(args);
        } else {
            xs_jit_call_sv(aTHX_ b, cv_expr, NULL, 0);
        }
        
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
call_method(self, method_name, invocant, args_av)
    SV* self
    const char* method_name
    const char* invocant
    AV* args_av
    PREINIT:
        XS_JIT_Builder* b;
        const char** args;
        int num_args;
        int i;
    CODE:
        b = get_builder(aTHX_ self);
        num_args = av_len(args_av) + 1;
        
        if (num_args > 0) {
            Newxz(args, num_args, const char*);
            for (i = 0; i < num_args; i++) {
                SV** elem = av_fetch(args_av, i, 0);
                if (elem && SvOK(*elem)) {
                    args[i] = SvPV_nolen(*elem);
                } else {
                    args[i] = "NULL";
                }
            }
            xs_jit_call_method(aTHX_ b, method_name, invocant, args, num_args);
            Safefree(args);
        } else {
            xs_jit_call_method(aTHX_ b, method_name, invocant, NULL, 0);
        }
        
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
rw_accessor_trigger(self, func_name, attr_name, attr_len, trigger_method)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    const char* trigger_method
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_rw_accessor_trigger(aTHX_ b, func_name, attr_name, attr_len, trigger_method);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
accessor_lazy_builder(self, func_name, attr_name, attr_len, builder_method)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    const char* builder_method
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_accessor_lazy_builder(aTHX_ b, func_name, attr_name, attr_len, builder_method);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
destroy_with_demolish(self, func_name)
    SV* self
    const char* func_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_destroy_with_demolish(aTHX_ b, func_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
do_loop(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_do(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
end_do_while(self, condition)
    SV* self
    const char* condition
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_end_do_while(aTHX_ b, condition);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
if_list_context(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_if_list_context(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
if_scalar_context(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_if_scalar_context(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
extend_stack(self, count_expr)
    SV* self
    const char* count_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_extend_stack(aTHX_ b, count_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
return_list(self, values_av)
    SV* self
    AV* values_av
    PREINIT:
        XS_JIT_Builder* b;
        const char** values;
        int num_values;
        int i;
    CODE:
        b = get_builder(aTHX_ self);
        num_values = av_len(values_av) + 1;
        
        if (num_values > 0) {
            Newxz(values, num_values, const char*);
            for (i = 0; i < num_values; i++) {
                SV** elem = av_fetch(values_av, i, 0);
                if (elem && SvOK(*elem)) {
                    values[i] = SvPV_nolen(*elem);
                } else {
                    values[i] = "&PL_sv_undef";
                }
            }
            xs_jit_return_list(aTHX_ b, values, num_values);
            Safefree(values);
        } else {
            xs_jit_return_list(aTHX_ b, NULL, 0);
        }
        
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
declare_ternary(self, type, name, cond, true_expr, false_expr)
    SV* self
    const char* type
    const char* name
    const char* cond
    const char* true_expr
    const char* false_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_declare_ternary(aTHX_ b, type, name, cond, true_expr, false_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
assign_ternary(self, var, cond, true_expr, false_expr)
    SV* self
    const char* var
    const char* cond
    const char* true_expr
    const char* false_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_assign_ternary(aTHX_ b, var, cond, true_expr, false_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
delegate_method(self, func_name, attr_name, attr_len, target_method)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    const char* target_method
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_delegate_method(aTHX_ b, func_name, attr_name, attr_len, target_method);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
singleton_accessor(self, func_name, class_name)
    SV* self
    const char* func_name
    const char* class_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_singleton_accessor(aTHX_ b, func_name, class_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
singleton_reset(self, func_name, class_name)
    SV* self
    const char* func_name
    const char* class_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_singleton_reset(aTHX_ b, func_name, class_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
registry_add(self, func_name, registry_attr)
    SV* self
    const char* func_name
    SV* registry_attr
    PREINIT:
        XS_JIT_Builder* b;
        const char* attr_str;
        STRLEN attr_len;
    CODE:
        b = get_builder(aTHX_ self);
        attr_str = SvPV(registry_attr, attr_len);
        xs_jit_registry_add(aTHX_ b, func_name, attr_str, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
registry_get(self, func_name, registry_attr)
    SV* self
    const char* func_name
    SV* registry_attr
    PREINIT:
        XS_JIT_Builder* b;
        const char* attr_str;
        STRLEN attr_len;
    CODE:
        b = get_builder(aTHX_ self);
        attr_str = SvPV(registry_attr, attr_len);
        xs_jit_registry_get(aTHX_ b, func_name, attr_str, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
registry_remove(self, func_name, registry_attr)
    SV* self
    const char* func_name
    SV* registry_attr
    PREINIT:
        XS_JIT_Builder* b;
        const char* attr_str;
        STRLEN attr_len;
    CODE:
        b = get_builder(aTHX_ self);
        attr_str = SvPV(registry_attr, attr_len);
        xs_jit_registry_remove(aTHX_ b, func_name, attr_str, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
registry_all(self, func_name, registry_attr)
    SV* self
    const char* func_name
    SV* registry_attr
    PREINIT:
        XS_JIT_Builder* b;
        const char* attr_str;
        STRLEN attr_len;
    CODE:
        b = get_builder(aTHX_ self);
        attr_str = SvPV(registry_attr, attr_len);
        xs_jit_registry_all(aTHX_ b, func_name, attr_str, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
wrap_before(self, func_name, orig_name, before_cv_name)
    SV* self
    const char* func_name
    const char* orig_name
    const char* before_cv_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_wrap_before(aTHX_ b, func_name, orig_name, before_cv_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
wrap_after(self, func_name, orig_name, after_cv_name)
    SV* self
    const char* func_name
    const char* orig_name
    const char* after_cv_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_wrap_after(aTHX_ b, func_name, orig_name, after_cv_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
wrap_around(self, func_name, orig_name, around_cv_name)
    SV* self
    const char* func_name
    const char* orig_name
    const char* around_cv_name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_wrap_around(aTHX_ b, func_name, orig_name, around_cv_name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
op_ro_accessor(self, func_name, slot)
    SV* self
    const char* func_name
    IV slot
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_op_ro_accessor(aTHX_ b, func_name, slot);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
op_rw_accessor(self, func_name, slot)
    SV* self
    const char* func_name
    IV slot
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_op_rw_accessor(aTHX_ b, func_name, slot);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

void
inline_init()
    CODE:
        xs_jit_inline_init(aTHX);

int
inline_register(cv, type, slot, ...)
    CV* cv
    int type
    IV slot
    PREINIT:
        const char* key = NULL;
        STRLEN key_len = 0;
    CODE:
        /* Optional key for hash-based accessors */
        if (items > 3) {
            key = SvPV(ST(3), key_len);
        }
        RETVAL = xs_jit_inline_register(aTHX_ cv, (XS_JIT_InlineType)type, slot, key, key_len);
    OUTPUT:
        RETVAL

int
inline_get_type(cv)
    CV* cv
    CODE:
        RETVAL = (int)xs_jit_inline_get_type(aTHX_ cv);
    OUTPUT:
        RETVAL

# ============================================
# Custom op builder methods
# ============================================

SV*
pp_start(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_start(aTHX_ b, name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_end(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_end(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_dsp(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_dsp(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_get_self(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_get_self(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_pop_self(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_pop_self(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_pop_sv(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_pop_sv(aTHX_ b, name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_pop_nv(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_pop_nv(aTHX_ b, name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_pop_iv(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_pop_iv(aTHX_ b, name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_get_slots(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_get_slots(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_slot(self, name, slot)
    SV* self
    const char* name
    IV slot
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_slot(aTHX_ b, name, slot);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_return_sv(self, sv_expr)
    SV* self
    const char* sv_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_return_sv(aTHX_ b, sv_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_return_nv(self, nv_expr)
    SV* self
    const char* nv_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_return_nv(aTHX_ b, nv_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_return_iv(self, iv_expr)
    SV* self
    const char* iv_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_return_iv(aTHX_ b, iv_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_return_pv(self, pv_expr)
    SV* self
    const char* pv_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_return_pv(aTHX_ b, pv_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
pp_return(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_pp_return(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# Call checker builder methods
# ============================================

SV*
ck_start(self, name)
    SV* self
    const char* name
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_ck_start(aTHX_ b, name);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
ck_end(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_ck_end(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
ck_preamble(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_ck_preamble(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
ck_build_unop(self, pp_func, targ_expr)
    SV* self
    const char* pp_func
    const char* targ_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_ck_build_unop(aTHX_ b, pp_func, targ_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
ck_build_binop(self, pp_func, targ_expr)
    SV* self
    const char* pp_func
    const char* targ_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_ck_build_binop(aTHX_ b, pp_func, targ_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
ck_fallback(self)
    SV* self
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_ck_fallback(aTHX_ b);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# XOP helpers
# ============================================

SV*
xop_declare(self, name, pp_func, desc)
    SV* self
    const char* name
    const char* pp_func
    const char* desc
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_xop_declare(aTHX_ b, name, pp_func, desc);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
register_checker(self, cv_expr, ck_func, ckobj_expr)
    SV* self
    const char* cv_expr
    const char* ck_func
    const char* ckobj_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_register_checker(aTHX_ b, cv_expr, ck_func, ckobj_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# Direct AvARRAY access (Meow-style)
# ============================================

SV*
av_direct(self, result_var, av_expr)
    SV* self
    const char* result_var
    const char* av_expr
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_av_direct(aTHX_ b, result_var, av_expr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
av_slot_read(self, result_var, slots_var, slot)
    SV* self
    const char* result_var
    const char* slots_var
    IV slot
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_av_slot_read(aTHX_ b, result_var, slots_var, slot);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
av_slot_write(self, slots_var, slot, value)
    SV* self
    const char* slots_var
    IV slot
    const char* value
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_av_slot_write(aTHX_ b, slots_var, slot, value);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# Type checking
# ============================================

SV*
check_value_type(self, sv, type, ...)
    SV* self
    const char* sv
    IV type
    PREINIT:
        XS_JIT_Builder* b;
        const char* classname = NULL;
        const char* error_msg = "Type check failed";
    CODE:
        b = get_builder(aTHX_ self);
        if (items > 3) {
            classname = SvPV_nolen(ST(3));
        }
        if (items > 4) {
            error_msg = SvPV_nolen(ST(4));
        }
        xs_jit_check_value_type(aTHX_ b, sv, (XS_JIT_TypeCheck)type, classname, error_msg);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# Lazy initialization
# ============================================

SV*
lazy_init_dor(self, func_name, attr_name, attr_len, default_expr, is_mortal)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    const char* default_expr
    int is_mortal
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_lazy_init_dor(aTHX_ b, func_name, attr_name, attr_len, default_expr, is_mortal);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
lazy_init_or(self, func_name, attr_name, attr_len, default_expr, is_mortal)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    const char* default_expr
    int is_mortal
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_lazy_init_or(aTHX_ b, func_name, attr_name, attr_len, default_expr, is_mortal);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
slot_lazy_init_dor(self, func_name, slot, default_expr, is_mortal)
    SV* self
    const char* func_name
    IV slot
    const char* default_expr
    int is_mortal
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_slot_lazy_init_dor(aTHX_ b, func_name, slot, default_expr, is_mortal);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
slot_lazy_init_or(self, func_name, slot, default_expr, is_mortal)
    SV* self
    const char* func_name
    IV slot
    const char* default_expr
    int is_mortal
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_slot_lazy_init_or(aTHX_ b, func_name, slot, default_expr, is_mortal);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# Setter patterns
# ============================================

SV*
setter_chain(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_setter_chain(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
slot_setter_chain(self, func_name, slot)
    SV* self
    const char* func_name
    IV slot
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_slot_setter_chain(aTHX_ b, func_name, slot);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
setter_return_value(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_setter_return_value(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# Array attribute operations
# ============================================

SV*
attr_push(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_push(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_pop(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_pop(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_shift(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_shift(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_unshift(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_unshift(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_count(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_count(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_clear(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_clear(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ============================================
# Hash attribute operations
# ============================================

SV*
attr_keys(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_keys(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_values(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_values(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_delete(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_delete(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
attr_hash_clear(self, func_name, attr_name, attr_len)
    SV* self
    const char* func_name
    const char* attr_name
    STRLEN attr_len
    PREINIT:
        XS_JIT_Builder* b;
    CODE:
        b = get_builder(aTHX_ self);
        xs_jit_attr_hash_clear(aTHX_ b, func_name, attr_name, attr_len);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
conditional(self, struct_hv)
    SV* self
    HV* struct_hv
    PREINIT:
        XS_JIT_Builder* b;
        XS_JIT_Conditional cond;
        XS_JIT_Given given_struct;
        SV** val;
        int is_given = 0;
    CODE:
        b = get_builder(aTHX_ self);
        memset(&cond, 0, sizeof(cond));
        memset(&given_struct, 0, sizeof(given_struct));

        /* Check if this is a 'given' structure */
        val = hv_fetchs(struct_hv, "given", 0);
        if (val && SvOK(*val) && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVHV) {
            is_given = 1;
            HV* given_hv = (HV*)SvRV(*val);
            SV** key_val;
            SV** when_val;
            SV** default_val;

            /* Get key */
            key_val = hv_fetchs(given_hv, "key", 0);
            if (key_val && SvOK(*key_val)) {
                given_struct.key = SvPV_nolen(*key_val);
            }

            /* Parse 'when' - can be hash or array */
            when_val = hv_fetchs(given_hv, "when", 0);
            if (when_val && SvOK(*when_val) && SvROK(*when_val)) {
                if (SvTYPE(SvRV(*when_val)) == SVt_PVHV) {
                    /* Hash-style when: { val1 => {...}, val2 => {...}, default => {...} } */
                    HV* when_hv = (HV*)SvRV(*when_val);
                    I32 num_keys = hv_iterinit(when_hv);
                    HE* entry;
                    int i = 0;

                    /* Count non-default keys */
                    given_struct.num_when = 0;
                    hv_iterinit(when_hv);
                    while ((entry = hv_iternext(when_hv))) {
                        STRLEN klen;
                        const char* key = HePV(entry, klen);
                        if (!strEQ(key, "default")) {
                            given_struct.num_when++;
                        }
                    }

                    if (given_struct.num_when > 0) {
                        Newxz(given_struct.when_clauses, given_struct.num_when, XS_JIT_Clause*);

                        hv_iterinit(when_hv);
                        while ((entry = hv_iternext(when_hv))) {
                            STRLEN klen;
                            const char* key = HePV(entry, klen);
                            SV* val = HeVAL(entry);

                            if (strEQ(key, "default")) {
                                /* Handle default separately */
                                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                                    given_struct.default_actions = xs_jit_parse_actions(aTHX_ val, &given_struct.num_default_actions);
                                }
                            } else {
                                /* Create a clause for this when value */
                                XS_JIT_Clause* clause;
                                Newxz(clause, 1, XS_JIT_Clause);
                                clause->key = given_struct.key;
                                clause->expr_type = XS_JIT_EXPR_EQ;
                                clause->expr_value = key;
                                clause->expr_value_len = klen;

                                /* Parse actions from value */
                                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                                    clause->actions = xs_jit_parse_actions(aTHX_ val, &clause->num_actions);
                                }

                                given_struct.when_clauses[i++] = clause;
                            }
                        }
                    }
                }
                else if (SvTYPE(SvRV(*when_val)) == SVt_PVAV) {
                    /* Array-style when: [ { m => 'foo', then => {...} }, ... ] */
                    AV* when_av = (AV*)SvRV(*when_val);
                    I32 len = av_len(when_av) + 1;
                    int i;

                    if (len > 0) {
                        Newxz(given_struct.when_clauses, len, XS_JIT_Clause*);

                        for (i = 0; i < len; i++) {
                            SV** elem = av_fetch(when_av, i, 0);
                            if (elem && SvOK(*elem) && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                                given_struct.when_clauses[given_struct.num_when] =
                                    xs_jit_parse_clause(aTHX_ (HV*)SvRV(*elem));
                                given_struct.num_when++;
                            }
                        }
                    }
                }
            }

            /* Parse default if not already done */
            default_val = hv_fetchs(given_hv, "default", 0);
            if (default_val && SvOK(*default_val) && given_struct.num_default_actions == 0) {
                given_struct.default_actions = xs_jit_parse_actions(aTHX_ *default_val, &given_struct.num_default_actions);
            }

            xs_jit_given(aTHX_ b, &given_struct);
            xs_jit_free_given(aTHX_ &given_struct);
        }
        else {
            /* Standard if/elsif/else structure */

            /* Parse 'if' clause */
            val = hv_fetchs(struct_hv, "if", 0);
            if (val && SvOK(*val) && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVHV) {
                cond.if_clause = xs_jit_parse_clause(aTHX_ (HV*)SvRV(*val));
            }

            /* Parse 'elsif' - can be single hash or array */
            val = hv_fetchs(struct_hv, "elsif", 0);
            if (val && SvOK(*val) && SvROK(*val)) {
                if (SvTYPE(SvRV(*val)) == SVt_PVHV) {
                    /* Single elsif */
                    Newxz(cond.elsif_clauses, 1, XS_JIT_Clause*);
                    cond.elsif_clauses[0] = xs_jit_parse_clause(aTHX_ (HV*)SvRV(*val));
                    cond.num_elsif = 1;
                }
                else if (SvTYPE(SvRV(*val)) == SVt_PVAV) {
                    /* Array of elsif */
                    AV* elsif_av = (AV*)SvRV(*val);
                    I32 len = av_len(elsif_av) + 1;
                    int i;

                    if (len > 0) {
                        Newxz(cond.elsif_clauses, len, XS_JIT_Clause*);

                        for (i = 0; i < len; i++) {
                            SV** elem = av_fetch(elsif_av, i, 0);
                            if (elem && SvOK(*elem) && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                                cond.elsif_clauses[cond.num_elsif] =
                                    xs_jit_parse_clause(aTHX_ (HV*)SvRV(*elem));
                                cond.num_elsif++;
                            }
                        }
                    }
                }
            }

            /* Parse 'else' */
            val = hv_fetchs(struct_hv, "else", 0);
            if (val && SvOK(*val) && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVHV) {
                HV* else_hv = (HV*)SvRV(*val);
                SV** then_val = hv_fetchs(else_hv, "then", 0);
                if (then_val && SvOK(*then_val)) {
                    cond.else_actions = xs_jit_parse_actions(aTHX_ *then_val, &cond.num_else_actions);
                }
            }

            xs_jit_conditional(aTHX_ b, &cond);
            xs_jit_free_conditional(aTHX_ &cond);
        }

        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
switch(self, key, cases_av, ...)
    SV* self
    const char* key
    AV* cases_av
    PREINIT:
        XS_JIT_Builder* b;
        XS_JIT_Switch sw;
        I32 cases_len;
        I32 i;
        SV* default_sv = NULL;
    CODE:
        b = get_builder(aTHX_ self);
        memset(&sw, 0, sizeof(sw));

        sw.key = key;

        /* Check for optional default argument */
        if (items > 3 && SvOK(ST(3))) {
            default_sv = ST(3);
        }

        /* Parse cases array */
        cases_len = av_len(cases_av) + 1;
        if (cases_len > 0) {
            Newxz(sw.cases, cases_len, XS_JIT_Clause*);

            for (i = 0; i < cases_len; i++) {
                SV** elem = av_fetch(cases_av, i, 0);
                if (elem && SvOK(*elem) && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                    HV* case_hv = (HV*)SvRV(*elem);
                    XS_JIT_Clause* clause;

                    /* Parse the clause and set the key */
                    clause = xs_jit_parse_clause(aTHX_ case_hv);
                    clause->key = key;
                    sw.cases[sw.num_cases] = clause;
                    sw.num_cases++;
                }
            }
        }

        /* Parse default actions if provided */
        if (default_sv && SvROK(default_sv) && SvTYPE(SvRV(default_sv)) == SVt_PVHV) {
            sw.default_actions = xs_jit_parse_actions(aTHX_ default_sv, &sw.num_default_actions);
        }

        xs_jit_switch(aTHX_ b, &sw);
        xs_jit_free_switch(aTHX_ &sw);

        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
enum(self, name_sv, values_av, ...)
    SV* self
    SV* name_sv
    AV* values_av
    PREINIT:
        XS_JIT_Builder* b;
        XS_JIT_EnumValue* values = NULL;
        XS_JIT_EnumOpts opts;
        XS_JIT_EnumOpts* opts_ptr = NULL;
        I32 num_values;
        I32 i;
        const char* name;
    CODE:
        if (!SvOK(name_sv) || !SvPOK(name_sv) || SvCUR(name_sv) == 0) {
            croak("enum requires a name");
        }
        name = SvPV_nolen(name_sv);

        b = get_builder(aTHX_ self);

        memset(&opts, 0, sizeof(opts));

        /* Parse values array */
        num_values = av_len(values_av) + 1;
        if (num_values <= 0) {
            croak("enum requires a non-empty values array");
        }

        Newxz(values, num_values, XS_JIT_EnumValue);
        for (i = 0; i < num_values; i++) {
            SV** elem = av_fetch(values_av, i, 0);
            if (elem && SvOK(*elem)) {
                STRLEN len;
                const char* pv = SvPV(*elem, len);
                values[i].name = pv;
                values[i].name_len = len;
            }
        }

        /* Check for optional opts hash */
        if (items > 3 && SvOK(ST(3)) && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVHV) {
            HV* opts_hv = (HV*)SvRV(ST(3));
            SV** start_sv = hv_fetchs(opts_hv, "start", 0);
            SV** prefix_sv = hv_fetchs(opts_hv, "prefix", 0);

            if (start_sv && SvOK(*start_sv)) {
                opts.start = SvIV(*start_sv);
            }
            if (prefix_sv && SvOK(*prefix_sv)) {
                opts.prefix = SvPV(*prefix_sv, opts.prefix_len);
            }
            opts_ptr = &opts;
        }

        xs_jit_enum(aTHX_ b, name, values, num_values, opts_ptr);

        Safefree(values);

        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
memoize(self, func_name_sv, ...)
    SV* self
    SV* func_name_sv
    PREINIT:
        XS_JIT_Builder* b;
        XS_JIT_MemoizeOpts opts;
        XS_JIT_MemoizeOpts* opts_ptr = NULL;
        const char* func_name;
    CODE:
        if (!SvOK(func_name_sv) || !SvPOK(func_name_sv) || SvCUR(func_name_sv) == 0) {
            croak("memoize requires a function name");
        }
        func_name = SvPV_nolen(func_name_sv);
        b = get_builder(aTHX_ self);

        memset(&opts, 0, sizeof(opts));

        /* Check for optional opts hash */
        if (items > 2 && SvOK(ST(2)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            HV* opts_hv = (HV*)SvRV(ST(2));
            SV** cache_sv = hv_fetchs(opts_hv, "cache", 0);
            SV** ttl_sv = hv_fetchs(opts_hv, "ttl", 0);

            if (cache_sv && SvOK(*cache_sv)) {
                opts.cache_attr = SvPV(*cache_sv, opts.cache_attr_len);
            }
            if (ttl_sv && SvOK(*ttl_sv)) {
                opts.ttl = SvIV(*ttl_sv);
            }
            opts_ptr = &opts;
        }

        xs_jit_memoize(aTHX_ b, func_name, opts_ptr);

        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
enum_functions(self, name, package)
    SV* self
    const char* name
    const char* package
    PREINIT:
        XS_JIT_Builder* b;
        HV* result;
    CODE:
        b = get_builder(aTHX_ self);
        result = xs_jit_enum_functions(aTHX_ b, name, package);
        RETVAL = newRV_noinc((SV*)result);
    OUTPUT:
        RETVAL

SV*
memoize_functions(self, func_name, package)
    SV* self
    const char* func_name
    const char* package
    PREINIT:
        XS_JIT_Builder* b;
        HV* result;
    CODE:
        b = get_builder(aTHX_ self);
        result = xs_jit_memoize_functions(aTHX_ b, func_name, package);
        RETVAL = newRV_noinc((SV*)result);
    OUTPUT:
        RETVAL

SV*
role(self, role_name_sv, ...)
    SV* self
    SV* role_name_sv
    PREINIT:
        XS_JIT_Builder* b;
        XS_JIT_RoleType role_type;
        XS_JIT_RoleOpts opts;
        XS_JIT_RoleOpts* opts_ptr = NULL;
        const char* role_name;
    CODE:
        if (!SvOK(role_name_sv) || !SvPOK(role_name_sv) || SvCUR(role_name_sv) == 0) {
            croak("role requires a role name");
        }
        role_name = SvPV_nolen(role_name_sv);
        b = get_builder(aTHX_ self);

        /* Map role name to type */
        if (strEQ(role_name, "Comparable")) {
            role_type = XS_JIT_ROLE_COMPARABLE;
        } else if (strEQ(role_name, "Cloneable")) {
            role_type = XS_JIT_ROLE_CLONEABLE;
        } else if (strEQ(role_name, "Serializable")) {
            role_type = XS_JIT_ROLE_SERIALIZABLE;
        } else if (strEQ(role_name, "Observable")) {
            role_type = XS_JIT_ROLE_OBSERVABLE;
        } else {
            croak("Unknown role: '%s'. Valid roles: Comparable, Cloneable, Serializable, Observable", role_name);
        }

        memset(&opts, 0, sizeof(opts));

        /* Check for optional opts hash */
        if (items > 2 && SvOK(ST(2)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            HV* opts_hv = (HV*)SvRV(ST(2));
            SV** compare_key_sv = hv_fetchs(opts_hv, "compare_key", 0);
            SV** observers_attr_sv = hv_fetchs(opts_hv, "observers_attr", 0);

            if (compare_key_sv && SvOK(*compare_key_sv)) {
                opts.compare_key = SvPV(*compare_key_sv, opts.compare_key_len);
            }
            if (observers_attr_sv && SvOK(*observers_attr_sv)) {
                opts.observers_attr = SvPV(*observers_attr_sv, opts.observers_attr_len);
            }
            opts_ptr = &opts;
        }

        xs_jit_role(aTHX_ b, role_type, opts_ptr);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV*
with_roles(self, roles_av, ...)
    SV* self
    SV* roles_av
    PREINIT:
        XS_JIT_Builder* b;
        AV* roles;
        SSize_t i, len;
        HV* opts_hv = NULL;
    CODE:
        if (!SvROK(roles_av) || SvTYPE(SvRV(roles_av)) != SVt_PVAV) {
            croak("with_roles requires an arrayref of role names");
        }
        b = get_builder(aTHX_ self);
        roles = (AV*)SvRV(roles_av);
        len = av_len(roles) + 1;

        /* Check for optional opts hash */
        if (items > 2 && SvOK(ST(2)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            opts_hv = (HV*)SvRV(ST(2));
        }

        for (i = 0; i < len; i++) {
            SV** role_svp = av_fetch(roles, i, 0);
            if (role_svp && SvOK(*role_svp)) {
                const char* role_name = SvPV_nolen(*role_svp);
                XS_JIT_RoleType role_type;
                XS_JIT_RoleOpts opts;
                XS_JIT_RoleOpts* opts_ptr = NULL;

                /* Map role name to type */
                if (strEQ(role_name, "Comparable")) {
                    role_type = XS_JIT_ROLE_COMPARABLE;
                } else if (strEQ(role_name, "Cloneable")) {
                    role_type = XS_JIT_ROLE_CLONEABLE;
                } else if (strEQ(role_name, "Serializable")) {
                    role_type = XS_JIT_ROLE_SERIALIZABLE;
                } else if (strEQ(role_name, "Observable")) {
                    role_type = XS_JIT_ROLE_OBSERVABLE;
                } else {
                    croak("Unknown role: '%s'. Valid roles: Comparable, Cloneable, Serializable, Observable", role_name);
                }

                memset(&opts, 0, sizeof(opts));

                /* Apply opts if provided */
                if (opts_hv) {
                    SV** compare_key_sv = hv_fetchs(opts_hv, "compare_key", 0);
                    SV** observers_attr_sv = hv_fetchs(opts_hv, "observers_attr", 0);

                    if (compare_key_sv && SvOK(*compare_key_sv)) {
                        opts.compare_key = SvPV(*compare_key_sv, opts.compare_key_len);
                    }
                    if (observers_attr_sv && SvOK(*observers_attr_sv)) {
                        opts.observers_attr = SvPV(*observers_attr_sv, opts.observers_attr_len);
                    }
                    opts_ptr = &opts;
                }

                xs_jit_role(aTHX_ b, role_type, opts_ptr);
            }
        }
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL
#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#include <string.h>

#define NEED_newSVpvn_flags
#include "ppport.h"

#include "../../hoedown/src/document.h"
#include "../../hoedown/src/html.h"

#define XS_STRUCT2OBJ(sv, class, obj) \
    sv = newSViv(PTR2IV(obj));  \
    sv = newRV_noinc(sv); \
    sv_bless(sv, gv_stashpv(class, 1)); \
    SvREADONLY_on(sv);

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define PUSHBUF(text) \
    if (text) { \
        mXPUSHp(text->data, text->size); \
    } else { \
        XPUSHs(&PL_sv_undef); \
    }

#define CB_HEADER(key) \
    SV* cb = *rcb; \
    \
    ENTER; \
    SAVETMPS; \
    \
    PUSHMARK(SP);

#define CB_FOOTER \
    PUTBACK; \
    \
    int count = call_sv(cb, G_SCALAR); \
    \
    SPAGAIN; \
    \
    if (count == 1) { \
        SV* ret = POPs; \
        if (ret != &PL_sv_undef) { \
            STRLEN l; \
            char * p = SvPV(ret, l); \
            hoedown_buffer_grow(ob, ob->size + l); \
            hoedown_buffer_put(ob, p, l); \
        } else {\
            is_null = 1;\
        } \
    } \
    \
    PUTBACK; \
    FREETMPS; \
    LEAVE;


#include "gen.callback.c"

#define TMH_CONST(name) \
    newCONSTSUB(stash, #name, newSViv(name)); \
    av_push(get_av("Text::Markdown::Hoedown::EXPORT", GV_ADD), newSVpv(#name, 0));

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown PREFIX=hoedown_document_

BOOT:
    HV* stash = gv_stashpv("Text::Markdown::Hoedown", GV_ADD);

    /* block-level extensions */
    TMH_CONST(HOEDOWN_EXT_TABLES);
    TMH_CONST(HOEDOWN_EXT_FENCED_CODE);
    TMH_CONST(HOEDOWN_EXT_FOOTNOTES);

    /* span-level extensions */
    TMH_CONST(HOEDOWN_EXT_AUTOLINK);
    TMH_CONST(HOEDOWN_EXT_STRIKETHROUGH);
    TMH_CONST(HOEDOWN_EXT_UNDERLINE);
    TMH_CONST(HOEDOWN_EXT_HIGHLIGHT);
    TMH_CONST(HOEDOWN_EXT_QUOTE);
    TMH_CONST(HOEDOWN_EXT_SUPERSCRIPT);
    TMH_CONST(HOEDOWN_EXT_MATH);

    /* other flags */
    TMH_CONST(HOEDOWN_EXT_NO_INTRA_EMPHASIS);
    TMH_CONST(HOEDOWN_EXT_SPACE_HEADERS);
    TMH_CONST(HOEDOWN_EXT_MATH_EXPLICIT);

    /* negative flags */
    TMH_CONST(HOEDOWN_EXT_DISABLE_INDENTED_CODE);

    /* HTML */
    TMH_CONST(HOEDOWN_HTML_SKIP_HTML);
    TMH_CONST(HOEDOWN_HTML_ESCAPE);
    TMH_CONST(HOEDOWN_HTML_HARD_WRAP);
    TMH_CONST(HOEDOWN_HTML_USE_XHTML);

TYPEMAP: <<HERE

hoedown_renderer* T_H_RENDERER
hoedown_document* T_H_DOCUMENT

OUTPUT

T_H_DOCUMENT
    sv_setref_pv($arg, \"Text::Markdown::Hoedown::Markdown\", (void*)$var);

INPUT

T_H_DOCUMENT
    $var = INT2PTR($type, SvROK($arg) ? SvIV(SvRV($arg)) : SvIV($arg));

HERE

PROTOTYPES: DISABLE

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown::Markdown

hoedown_document *
new(const char* klass, unsigned int extensions, size_t max_nesting, SV* renderer_sv)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, renderer_sv);
    RETVAL = hoedown_document_new(renderer, extensions, max_nesting);
OUTPUT:
    RETVAL

SV*
render(hoedown_document *self, SV *src_sv)
PREINIT:
    struct hoedown_buffer* ob;
    const char *src;
    STRLEN src_len;
CODE:
    ob = hoedown_buffer_new(64);
    if (!ob) {
        croak("Cannot create new hoedown_buffer(malloc failed)");
    }

    src = SvPV(src_sv, src_len);
    hoedown_document_render(self, ob, src, src_len);

    SV* ret = newSVpv(hoedown_buffer_cstr(ob), 0);
    if (SvUTF8(src_sv)) {
        SvUTF8_on(ret);
    }
    hoedown_buffer_free(ob);
    RETVAL = ret;
OUTPUT:
    RETVAL

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown::Renderer::HTML

void
new(const char* klass, unsigned int render_flags, int nesting_level)
PPCODE:
    hoedown_renderer * renderer = hoedown_html_renderer_new(
        render_flags, nesting_level
    );
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), "Text::Markdown::Hoedown::Renderer::HTML", (void*)renderer);
    XSRETURN(1);

void
DESTROY(SV* this)
CODE:
    hoedown_renderer* self = INT2PTR(hoedown_renderer*, SvROK(this) ? SvIV(SvRV(this)) : SvIV(this));
    hoedown_html_renderer_free(self);

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown::Renderer::HTMLTOC

void
new(const char* klass, int nesting_level)
PPCODE:
    hoedown_renderer * renderer = hoedown_html_toc_renderer_new(
        nesting_level
    );
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), "Text::Markdown::Hoedown::Renderer::HTMLTOC", (void*)renderer);
    XSRETURN(1);

void
DESTROY(SV* this)
CODE:
    hoedown_renderer* self = INT2PTR(hoedown_renderer*, SvROK(this) ? SvIV(SvRV(this)) : SvIV(this));
    hoedown_html_renderer_free(self);

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown::Renderer::Callback

void
new(const char* klass)
PPCODE:
    hoedown_renderer * renderer;
    Newxz(renderer, 1, hoedown_renderer);
    renderer->opaque = newHV();
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), "Text::Markdown::Hoedown::Renderer::Callback", (void*)renderer);
    XSRETURN(1);

void
DESTROY(SV* this)
CODE:
    hoedown_renderer* self = INT2PTR(hoedown_renderer*, SvROK(this) ? SvIV(SvRV(this)) : SvIV(this));
    SvREFCNT_dec(self->opaque);
    Safefree(self);

INCLUDE: gen.callback.inc


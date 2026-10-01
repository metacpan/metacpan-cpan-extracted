#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include <mkdio.h>

#define MKD2_NOLINKS             0x00000001
#define MKD2_NOIMAGE             0x00000002
#define MKD2_NOPANTS             0x00000004
#define MKD2_NOHTML              0x00000008
#define MKD2_STRICT              0x00000010
#define MKD2_TAGTEXT             0x00000020
#define MKD2_NO_EXT              0x00000040
#define MKD2_CDATA               0x00000080
#define MKD2_NOSUPERSCRIPT       0x00000100
#define MKD2_NORELAXED           0x00000200
#define MKD2_NOTABLES            0x00000400
#define MKD2_NOSTRIKETHROUGH     0x00000800
#define MKD2_TOC                 0x00001000
#define MKD2_1_COMPAT            0x00002000
#define MKD2_AUTOLINK            0x00004000
#define MKD2_SAFELINK            0x00008000
#define MKD2_NOHEADER            0x00010000
#define MKD2_TABSTOP             0x00020000
#define MKD2_NODIVQUOTE          0x00040000
#define MKD2_NOALPHALIST         0x00080000
#define MKD2_NODLIST             0x00100000
#define MKD2_EXTRA_FOOTNOTE      0x00200000
#define MKD2_NOSTYLE             0x00400000
#define MKD2_NODLDISCOUNT        0x00800000
#define MKD2_DLEXTRA             0x01000000
#define MKD2_FENCEDCODE          0x02000000
#define MKD2_IDANCHOR            0x04000000
#define MKD2_GITHUBTAGS          0x08000000
#define MKD2_URLENCODEDANCHOR    0x10000000
#define MKD2_LATEX               0x40000000
#define MKD2_EXPLICITLIST        0x80000000

#define MKD3_OPTION_NORMAL_LISTITEM 0x01
#define MKD3_OPTION_ALT_AS_TITLE    0x02
#define MKD3_OPTION_EXTENDED_ATTR   0x04

static mkd_flag_t *
legacy_flags(uint32_t bits)
{
    mkd_flag_t *flags = mkd_flags();

    if (flags == NULL) {
        return NULL;
    }

    mkd_set_flag_num(flags, MKD_DLDISCOUNT);
    mkd_set_flag_num(flags, MKD_HTML5);

#define SET_LEGACY_FLAG(bit, flag) \
    if (bits & (bit)) mkd_set_flag_num(flags, (flag))
    SET_LEGACY_FLAG(MKD2_NOLINKS, MKD_NOLINKS);
    SET_LEGACY_FLAG(MKD2_NOIMAGE, MKD_NOIMAGE);
    SET_LEGACY_FLAG(MKD2_NOPANTS, MKD_NOPANTS);
    SET_LEGACY_FLAG(MKD2_NOHTML, MKD_NOHTML);
    SET_LEGACY_FLAG(MKD2_STRICT, MKD_STRICT);
    SET_LEGACY_FLAG(MKD2_TAGTEXT, MKD_TAGTEXT);
    SET_LEGACY_FLAG(MKD2_NO_EXT, MKD_NO_EXT);
    SET_LEGACY_FLAG(MKD2_CDATA, MKD_CDATA);
    SET_LEGACY_FLAG(MKD2_NOSUPERSCRIPT, MKD_NOSUPERSCRIPT);
    SET_LEGACY_FLAG(MKD2_NORELAXED, MKD_STRICT);
    SET_LEGACY_FLAG(MKD2_NOTABLES, MKD_NOTABLES);
    SET_LEGACY_FLAG(MKD2_NOSTRIKETHROUGH, MKD_NOSTRIKETHROUGH);
    SET_LEGACY_FLAG(MKD2_TOC, MKD_TOC);
    SET_LEGACY_FLAG(MKD2_1_COMPAT, MKD_1_COMPAT);
    SET_LEGACY_FLAG(MKD2_AUTOLINK, MKD_AUTOLINK);
    SET_LEGACY_FLAG(MKD2_SAFELINK, MKD_SAFELINK);
    SET_LEGACY_FLAG(MKD2_NOHEADER, MKD_NOHEADER);
    SET_LEGACY_FLAG(MKD2_TABSTOP, MKD_TABSTOP);
    SET_LEGACY_FLAG(MKD2_NODIVQUOTE, MKD_NODIVQUOTE);
    SET_LEGACY_FLAG(MKD2_NOALPHALIST, MKD_NOALPHALIST);
    SET_LEGACY_FLAG(MKD2_EXTRA_FOOTNOTE, MKD_EXTRA_FOOTNOTE);
    SET_LEGACY_FLAG(MKD2_NOSTYLE, MKD_NOSTYLE);
    SET_LEGACY_FLAG(MKD2_DLEXTRA, MKD_DLEXTRA);
    SET_LEGACY_FLAG(MKD2_FENCEDCODE, MKD_FENCEDCODE);
    SET_LEGACY_FLAG(MKD2_IDANCHOR, MKD_IDANCHOR);
    SET_LEGACY_FLAG(MKD2_GITHUBTAGS, MKD_GITHUBTAGS);
    SET_LEGACY_FLAG(MKD2_URLENCODEDANCHOR, MKD_URLENCODEDANCHOR);
    SET_LEGACY_FLAG(MKD2_LATEX, MKD_LATEX);
    SET_LEGACY_FLAG(MKD2_EXPLICITLIST, MKD_EXPLICITLIST);
#undef SET_LEGACY_FLAG

    if (bits & MKD2_NODLDISCOUNT) {
        mkd_clr_flag_num(flags, MKD_DLDISCOUNT);
    }
    if (bits & MKD2_NODLIST) {
        mkd_clr_flag_num(flags, MKD_DLDISCOUNT);
        mkd_clr_flag_num(flags, MKD_DLEXTRA);
    }

    return flags;
}

static void
set_option_flags(mkd_flag_t *flags, uint32_t bits)
{
    if (bits & MKD3_OPTION_NORMAL_LISTITEM) {
        mkd_set_flag_num(flags, MKD_NORMAL_LISTITEM);
    }
    if (bits & MKD3_OPTION_ALT_AS_TITLE) {
        mkd_set_flag_num(flags, MKD_ALT_AS_TITLE);
    }
    if (bits & MKD3_OPTION_EXTENDED_ATTR) {
        mkd_set_flag_num(flags, MKD_EXTENDED_ATTR);
    }
}

static SV *
render_markdown(SV *sv_str, uint32_t legacy_bits, uint32_t option_bits)
{
    bool is_utf8 = SvUTF8(sv_str) != 0; /* SvUTF8 does not consistently cast to bool across architectures */
    char *text = SvPV_nolen(sv_str);
    SV *result = &PL_sv_undef;
    char *html = NULL;
    int szhtml;
    MMIOT *doc;
    mkd_flag_t *discount_flags;

    discount_flags = legacy_flags(legacy_bits);
    if (discount_flags == NULL) {
        croak("failed to allocate Discount flags");
    }
    set_option_flags(discount_flags, option_bits);

    if ((doc = mkd_string(text, strlen(text), discount_flags)) == 0) {
        mkd_free_flags(discount_flags);
        croak("failed at mkd_string");
    }

    if (!mkd_compile(doc, discount_flags)) {
        mkd_cleanup(doc);
        mkd_free_flags(discount_flags);
        croak("failed at mkd_compile");
    }

    if ((szhtml = mkd_document(doc, &html)) == EOF) {
        mkd_cleanup(doc);
        mkd_free_flags(discount_flags);
        croak("failed at mkd_document");
    }

    result = newSVpvn(html, szhtml);
    if (szhtml == 0 || html[szhtml - 1] != '\n') {
        sv_catpv(result, "\n");
    }
    if (is_utf8) {
        sv_utf8_decode(result);
    }

    mkd_cleanup(doc);
    mkd_free_flags(discount_flags);
    return result;
}

MODULE = Text::Markdown::Discount		PACKAGE = Text::Markdown::Discount	PREFIX = TextMarkdown_

PROTOTYPES: DISABLE

BOOT:
    HV* stash = gv_stashpvn("Text::Markdown::Discount", strlen("Text::Markdown::Discount"), TRUE);
    newCONSTSUB(stash, "MKD_NOLINKS", newSVuv(MKD2_NOLINKS));
    newCONSTSUB(stash, "MKD_NOIMAGE", newSVuv(MKD2_NOIMAGE));
    newCONSTSUB(stash, "MKD_NOPANTS", newSVuv(MKD2_NOPANTS));
    newCONSTSUB(stash, "MKD_NOHTML", newSVuv(MKD2_NOHTML));
    newCONSTSUB(stash, "MKD_STRICT", newSVuv(MKD2_STRICT));
    newCONSTSUB(stash, "MKD_TAGTEXT", newSVuv(MKD2_TAGTEXT));
    newCONSTSUB(stash, "MKD_NO_EXT", newSVuv(MKD2_NO_EXT));
    newCONSTSUB(stash, "MKD_CDATA", newSVuv(MKD2_CDATA));
    newCONSTSUB(stash, "MKD_NOSUPERSCRIPT", newSVuv(MKD2_NOSUPERSCRIPT));
    newCONSTSUB(stash, "MKD_NORELAXED", newSVuv(MKD2_NORELAXED));
    newCONSTSUB(stash, "MKD_NOTABLES", newSVuv(MKD2_NOTABLES));
    newCONSTSUB(stash, "MKD_NOSTRIKETHROUGH", newSVuv(MKD2_NOSTRIKETHROUGH));
    newCONSTSUB(stash, "MKD_TOC", newSVuv(MKD2_TOC));
    newCONSTSUB(stash, "MKD_1_COMPAT", newSVuv(MKD2_1_COMPAT));
    newCONSTSUB(stash, "MKD_AUTOLINK", newSVuv(MKD2_AUTOLINK));
    newCONSTSUB(stash, "MKD_SAFELINK", newSVuv(MKD2_SAFELINK));
    newCONSTSUB(stash, "MKD_NOHEADER", newSVuv(MKD2_NOHEADER));
    newCONSTSUB(stash, "MKD_TABSTOP", newSVuv(MKD2_TABSTOP));
    newCONSTSUB(stash, "MKD_NODIVQUOTE", newSVuv(MKD2_NODIVQUOTE));
    newCONSTSUB(stash, "MKD_NOALPHALIST", newSVuv(MKD2_NOALPHALIST));
    newCONSTSUB(stash, "MKD_NODLIST", newSVuv(MKD2_NODLIST));
    newCONSTSUB(stash, "MKD_EXTRA_FOOTNOTE", newSVuv(MKD2_EXTRA_FOOTNOTE));
    newCONSTSUB(stash, "MKD_NOSTYLE", newSVuv(MKD2_NOSTYLE));
    newCONSTSUB(stash, "MKD_NODLDISCOUNT", newSVuv(MKD2_NODLDISCOUNT));
    newCONSTSUB(stash, "MKD_DLEXTRA", newSVuv(MKD2_DLEXTRA));
    newCONSTSUB(stash, "MKD_FENCEDCODE", newSVuv(MKD2_FENCEDCODE));
    newCONSTSUB(stash, "MKD_IDANCHOR", newSVuv(MKD2_IDANCHOR));
    newCONSTSUB(stash, "MKD_GITHUBTAGS", newSVuv(MKD2_GITHUBTAGS));
    newCONSTSUB(stash, "MKD_URLENCODEDANCHOR", newSVuv(MKD2_URLENCODEDANCHOR));
    newCONSTSUB(stash, "MKD_LATEX", newSVuv(MKD2_LATEX));
    newCONSTSUB(stash, "MKD_EXPLICITLIST", newSVuv(MKD2_EXPLICITLIST));

SV *
TextMarkdown__markdown(sv_str, flags)
        SV *sv_str
        UV flags;
    CODE:
        RETVAL = render_markdown(sv_str, (uint32_t)flags, 0);
    OUTPUT:
        RETVAL

SV *
TextMarkdown__markdown_with_options(sv_str, flags, option_flags)
        SV *sv_str
        UV flags;
        UV option_flags;
    CODE:
        RETVAL = render_markdown(
            sv_str,
            (uint32_t)flags,
            (uint32_t)option_flags
        );
    OUTPUT:
        RETVAL

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include <mkdio.h>

MODULE = Text::Markdown::Discount		PACKAGE = Text::Markdown::Discount	PREFIX = TextMarkdown_

PROTOTYPES: DISABLE

BOOT:
    HV* stash = gv_stashpvn("Text::Markdown::Discount", strlen("Text::Markdown::Discount"), TRUE);
    newCONSTSUB(stash, "MKD_NOLINKS", newSViv(MKD_NOLINKS));
    newCONSTSUB(stash, "MKD_NOIMAGE", newSViv(MKD_NOIMAGE));
    newCONSTSUB(stash, "MKD_NOPANTS", newSViv(MKD_NOPANTS));
    newCONSTSUB(stash, "MKD_NOHTML", newSViv(MKD_NOHTML));
    newCONSTSUB(stash, "MKD_STRICT", newSViv(MKD_STRICT));
    newCONSTSUB(stash, "MKD_TAGTEXT", newSViv(MKD_TAGTEXT));
    newCONSTSUB(stash, "MKD_NO_EXT", newSViv(MKD_NO_EXT));
    newCONSTSUB(stash, "MKD_CDATA", newSViv(MKD_CDATA));
    newCONSTSUB(stash, "MKD_NOSUPERSCRIPT", newSViv(MKD_NOSUPERSCRIPT));
    newCONSTSUB(stash, "MKD_NORELAXED", newSViv(MKD_NORELAXED));
    newCONSTSUB(stash, "MKD_NOTABLES", newSViv(MKD_NOTABLES));
    newCONSTSUB(stash, "MKD_NOSTRIKETHROUGH", newSViv(MKD_NOSTRIKETHROUGH));
    newCONSTSUB(stash, "MKD_TOC", newSViv(MKD_TOC));
    newCONSTSUB(stash, "MKD_1_COMPAT", newSViv(MKD_1_COMPAT));
    newCONSTSUB(stash, "MKD_AUTOLINK", newSViv(MKD_AUTOLINK));
    newCONSTSUB(stash, "MKD_SAFELINK", newSViv(MKD_SAFELINK));
    newCONSTSUB(stash, "MKD_NOHEADER", newSViv(MKD_NOHEADER));
    newCONSTSUB(stash, "MKD_TABSTOP", newSViv(MKD_TABSTOP));
    newCONSTSUB(stash, "MKD_NODIVQUOTE", newSViv(MKD_NODIVQUOTE));
    newCONSTSUB(stash, "MKD_NOALPHALIST", newSViv(MKD_NOALPHALIST));
    newCONSTSUB(stash, "MKD_NODLIST", newSViv(MKD_NODLIST));
    newCONSTSUB(stash, "MKD_EXTRA_FOOTNOTE", newSViv(MKD_EXTRA_FOOTNOTE));

SV *
TextMarkdown__markdown(sv_str, flags)
        SV *sv_str
        int flags;
    PREINIT:
        bool is_utf8 = SvUTF8(sv_str) != 0; // SvUTF8 doesn't typecast consistently to bool across various archs
        char *text = SvPV_nolen(sv_str);
        SV* r = &PL_sv_undef;
        char *html = NULL;
        int szhtml;
        MMIOT *doc;
    CODE:
        if ( (doc = mkd_string(text, strlen(text), flags)) == 0 ) {
            croak("failed at mkd_string");
        }

        if ( !mkd_compile(doc, flags) ) {
            mkd_cleanup(doc);
            croak("failed at mkd_compile");
        }

        if ( (szhtml = mkd_document(doc, &html)) == EOF ) {;
            mkd_cleanup(doc);
            croak("failed at mkd_document");
        }

        r = newSVpvn(html, szhtml);
        sv_catpv(r, "\n");
        if (is_utf8) {
            sv_utf8_decode(r);
        }

        mkd_cleanup(doc);
        RETVAL = r;
    OUTPUT:
        RETVAL

void
TextMarkdown_with_html5_tags()
    CODE:
        mkd_with_html5_tags();

#include "xh_config.h"
#include "xh_core.h"

MODULE = XML::Hash::XS PACKAGE = XML::Hash::XS

PROTOTYPES: DISABLE

xh_opts_t *
new(CLASS,...)
    PREINIT:
        xh_opts_t  *opts;
    CODE:
        dXCPT;

        if ((opts = xh_create_opts()) == NULL)
            croak("Malloc error in new()");

        XCPT_TRY_START
        {
            xh_parse_param(opts, 1, ax, items);
        } XCPT_TRY_END

        XCPT_CATCH
        {
            xh_destroy_opts(opts);
            XCPT_RETHROW;
        }

        RETVAL = opts;
    OUTPUT:
        RETVAL

SV *
hash2xml(...)
    PREINIT:
        xh_h2x_ctx_t  ctx;
        SV           *result;
    CODE:
        dXCPT;
        XCPT_TRY_START
        {
            xh_h2x_init_ctx(&ctx, ax, items);

            /* hack */
#ifdef XH_HAVE_DOM
            if (ctx.opts.doc) {
                result = xh_h2d(&ctx);
            }
            else {
                result = xh_h2x(&ctx);
            }
#else
            result = xh_h2x(&ctx);
#endif
        } XCPT_TRY_END

        XCPT_CATCH
        {
            xh_h2x_destroy_ctx(&ctx);
            XCPT_RETHROW;
        }

        if (ctx.opts.output != NULL || ctx.opts.output_cb != NULL) result = NULL;

        xh_h2x_destroy_ctx(&ctx);

        if (result == NULL) XSRETURN_UNDEF;

        RETVAL = result;

    OUTPUT:
        RETVAL

SV *
xml2hash(...)
    PREINIT:
        xh_x2h_ctx_t   ctx;
        SV            *result;
    CODE:
        dXCPT;
        XCPT_TRY_START
        {
            xh_x2h_init_ctx(&ctx, ax, items);

            result = xh_x2h(&ctx);
        } XCPT_TRY_END

        XCPT_CATCH
        {
            xh_x2h_destroy_ctx(&ctx);
            XCPT_RETHROW;
        }

        if (ctx.opts.cb != NULL) result = NULL;

        xh_x2h_destroy_ctx(&ctx);

        if (result == NULL) XSRETURN_UNDEF;

        RETVAL = result;

    OUTPUT:
        RETVAL

void
DESTROY(opts)
        xh_opts_t *opts;
    CODE:
        xh_destroy_opts(opts);
        free(opts);

MODULE = XML::Hash::XS PACKAGE = XML::Hash::XS::Parser

SV *
new(CLASS,...)
        SV *CLASS;
    PREINIT:
        xh_x2h_stream_t *stream;
    CODE:
        dXCPT;

        if ((stream = malloc(sizeof(*stream))) == NULL)
            croak("Malloc error in XML::Hash::XS::Parser->new()");
        memset(stream, 0, sizeof(*stream));

        XCPT_TRY_START
        {
            xh_x2h_stream_init(stream, NULL, ax, items);
        } XCPT_TRY_END

        XCPT_CATCH
        {
            xh_x2h_stream_destroy(stream);
            free(stream);
            XCPT_RETHROW;
        }

        RETVAL = newRV_noinc(newSViv(PTR2IV(stream)));
        sv_bless(RETVAL, gv_stashsv(CLASS, GV_ADD));
    OUTPUT:
        RETVAL

void
feed(parser, input)
        SV *parser;
        SV *input;
    PREINIT:
        xh_x2h_stream_t *stream;
        xh_char_t *data;
        STRLEN len;
    CODE:
        dXCPT;
        if (!sv_isa(parser, "XML::Hash::XS::Parser"))
            croak("feed: parser is not of type XML::Hash::XS::Parser");
        stream = INT2PTR(xh_x2h_stream_t *, SvIV(SvRV(parser)));
        if (stream == NULL)
            croak("feed: parser is already destroyed");
        if (SvROK(input)) input = SvRV(input);
        data = XH_CHAR_CAST SvPV(input, len);
        SvREFCNT_inc(parser);
        XCPT_TRY_START
        {
            xh_x2h_stream_feed(stream, data, (size_t) len, FALSE);
        } XCPT_TRY_END
        XCPT_CATCH
        {
            stream->busy = FALSE;
            stream->failed = TRUE;
            SvREFCNT_dec(parser);
            XCPT_RETHROW;
        }
        SvREFCNT_dec(parser);

SV *
finish(parser)
        SV *parser;
    PREINIT:
        xh_x2h_stream_t *stream;
    CODE:
        dXCPT;
        if (!sv_isa(parser, "XML::Hash::XS::Parser"))
            croak("finish: parser is not of type XML::Hash::XS::Parser");
        stream = INT2PTR(xh_x2h_stream_t *, SvIV(SvRV(parser)));
        if (stream == NULL)
            croak("finish: parser is already destroyed");
        SvREFCNT_inc(parser);
        XCPT_TRY_START
        {
            RETVAL = xh_x2h_stream_finish(stream);
        } XCPT_TRY_END
        XCPT_CATCH
        {
            stream->busy = FALSE;
            stream->failed = TRUE;
            SvREFCNT_dec(parser);
            XCPT_RETHROW;
        }
        SvREFCNT_dec(parser);
    OUTPUT:
        RETVAL

void
DESTROY(parser)
        SV *parser;
    PREINIT:
        xh_x2h_stream_t *stream;
    CODE:
        stream = INT2PTR(xh_x2h_stream_t *, SvIV(SvRV(parser)));
        if (stream != NULL) {
            xh_x2h_stream_destroy(stream);
            free(stream);
            sv_setiv(SvRV(parser), 0);
        }

#include "src/xh_config.h"
#include "src/xh_core.h"

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

        if (ctx.opts.output != NULL) result = NULL;

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

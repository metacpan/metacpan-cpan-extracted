#include "xh_config.h"
#include "xh_core.h"

SV *
xh_h2x(xh_h2x_ctx_t *ctx)
{
    SV *result;

    /* run */
    dXCPT;
    XCPT_TRY_START
    {
        xh_stack_init(&ctx->stash, XH_H2X_STASH_SIZE, sizeof(SV *));
        xh_writer_init(&ctx->writer, ctx->opts.encoding, ctx->opts.output, ctx->opts.buf_size, ctx->opts.indent, ctx->opts.trim);

        if (ctx->opts.xml_decl) {
            xh_xml_write_xml_declaration(&ctx->writer, ctx->opts.version, ctx->opts.encoding);
        }

        switch (ctx->opts.method) {
            case XH_METHOD_NATIVE:
                xh_h2x_native(ctx, ctx->opts.root, xh_strlen(ctx->opts.root), SvRV(ctx->hash));
                break;
            case XH_METHOD_NATIVE_ATTR_MODE:
                (void) xh_h2x_native_attr(ctx, ctx->opts.root, xh_strlen(ctx->opts.root), SvRV(ctx->hash), XH_H2X_F_COMPLEX);
                break;
            case XH_METHOD_LX:
                xh_h2x_lx(ctx, ctx->hash, NULL, 0, XH_H2X_F_NONE);
                break;
            default:
                croak("Invalid method");
        }
    } XCPT_TRY_END

    XCPT_CATCH
    {
        xh_stash_clean(&ctx->stash);
        result = xh_writer_flush(&ctx->writer);
        if (result != NULL && result != &PL_sv_undef) {
            SvREFCNT_dec(result);
        }
        xh_writer_destroy(&ctx->writer);
        XCPT_RETHROW;
    }

    xh_stash_clean(&ctx->stash);
    result = xh_writer_flush(&ctx->writer);
    if (result != NULL && ctx->opts.utf8) {
#ifdef XH_HAVE_ENCODER
        if (ctx->writer.encoder == NULL) {
            SvUTF8_on(result);
        }
#else
         SvUTF8_on(result);
#endif
    }
    xh_writer_destroy(&ctx->writer);

    return result;
}

#ifdef XH_HAVE_DOM
SV *
xh_h2d(xh_h2x_ctx_t *ctx)
{
    dXCPT;

    xmlDocPtr doc = xmlNewDoc(BAD_CAST ctx->opts.version);
    if (doc == NULL) {
        croak("Can't create new document");
    }
    if (ctx->opts.encoding[0] == '\0') {
        doc->encoding = (const xmlChar*) xmlStrdup((const xmlChar*) XH_INTERNAL_ENCODING);
    }
    else {
        doc->encoding = (const xmlChar*) xmlStrdup((const xmlChar*) ctx->opts.encoding);
    }

    XCPT_TRY_START
    {
        xh_stack_init(&ctx->stash, XH_H2X_STASH_SIZE, sizeof(SV *));
        switch (ctx->opts.method) {
            case XH_METHOD_NATIVE:
                xh_h2d_native(ctx, (xmlNodePtr) doc, ctx->opts.root, xh_strlen(ctx->opts.root), SvRV(ctx->hash));
                break;
            case XH_METHOD_NATIVE_ATTR_MODE:
                (void) xh_h2d_native_attr(ctx, (xmlNodePtr) doc, ctx->opts.root, xh_strlen(ctx->opts.root), SvRV(ctx->hash), XH_H2X_F_COMPLEX);
                break;
            case XH_METHOD_LX:
                xh_h2d_lx(ctx, (xmlNodePtr) doc, ctx->hash, NULL, 0, XH_H2X_F_NONE);
                break;
            default:
                croak("Invalid method");
        }
    } XCPT_TRY_END

    XCPT_CATCH
    {
        xh_stash_clean(&ctx->stash);
        XCPT_RETHROW;
    }

    xh_stash_clean(&ctx->stash);

    return x_PmmNodeToSv((xmlNodePtr) doc, NULL);
}
#endif

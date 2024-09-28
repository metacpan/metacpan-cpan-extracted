#include "xh_config.h"
#include "xh_core.h"

void
xh_h2x_native(xh_h2x_ctx_t *ctx, xh_char_t *key, I32 key_len, SV *value)
{
    xh_uint_t       type;
    size_t          i, len;
    SV             *item_value;
    xh_char_t      *item;
    I32             item_len;
    xh_sort_hash_t *sorted_hash;
    GV             *method;

    value = xh_h2x_resolve_value(ctx, value, &type);

    if (type & XH_H2X_T_BLESSED && (method = gv_fetchmethod_autoload(SvSTASH(value), "iternext", 0)) != NULL) {
        while (1) {
            item_value = xh_h2x_call_method(value, method);
            if (!SvOK(item_value)) break;
            (void) xh_h2x_native(ctx, key, key_len, item_value);
            SvREFCNT_dec(item_value);
        }
        goto FINISH;
    }

    if (type & XH_H2X_T_SCALAR) {
        xh_xml_write_node(&ctx->writer, key, key_len, value, type & XH_H2X_T_RAW);
    }
    else if (type & XH_H2X_T_HASH) {
        len = HvUSEDKEYS((HV *) value);
        if (len == 0) goto ADD_EMPTY_NODE;

        if (key != NULL)
            xh_xml_write_start_node(&ctx->writer, key, key_len);

        if (len > 1 && ctx->opts.canonical) {
            sorted_hash = xh_sort_hash((HV *) value, len);
            for (i = 0; i < len; i++) {
                xh_h2x_native(ctx, sorted_hash[i].key, sorted_hash[i].key_len, sorted_hash[i].value);
            }
            free(sorted_hash);
        }
        else {
            hv_iterinit((HV *) value);
            while ((item_value = hv_iternextsv((HV *) value, (char **) &item, &item_len))) {
                xh_h2x_native(ctx, item, item_len, item_value);
            }
        }

        if (key != NULL)
            xh_xml_write_end_node(&ctx->writer, key, key_len);
    }
    else if (type & XH_H2X_T_ARRAY) {
        len = av_len((AV *) value) + 1;
        for (i = 0; i < len; i++) {
            xh_h2x_native(ctx, key, key_len, *av_fetch((AV *) value, i, 0));
        }
    }
    else {
ADD_EMPTY_NODE:
        if (key != NULL)
            xh_xml_write_empty_node(&ctx->writer, key, key_len);
    }

FINISH:
    ctx->depth--;
}

#ifdef XH_HAVE_DOM
void
xh_h2d_native(xh_h2x_ctx_t *ctx, xmlNodePtr rootNode, xh_char_t *key, I32 key_len, SV *value)
{
    xh_uint_t       type;
    size_t          i, len;
    SV             *item_value;
    xh_char_t      *item;
    I32             item_len;
    xh_sort_hash_t *sorted_hash;
    GV             *method;

    value = xh_h2x_resolve_value(ctx, value, &type);

    if (type & XH_H2X_T_BLESSED && (method = gv_fetchmethod_autoload(SvSTASH(value), "iternext", 0)) != NULL) {
        while (1) {
            item_value = xh_h2x_call_method(value, method);
            if (!SvOK(item_value)) break;
            (void) xh_h2d_native(ctx, rootNode, key, key_len, item_value);
            SvREFCNT_dec(item_value);
        }
        goto FINISH;
    }

    if (type & XH_H2X_T_SCALAR) {
        (void) xh_dom_new_node(ctx, rootNode, key, key_len, value, type & XH_H2X_T_RAW);
    }
    else if (type & XH_H2X_T_HASH) {
        len = HvUSEDKEYS((HV *) value);
        if (len == 0) goto ADD_EMPTY_NODE;

        rootNode = xh_dom_new_node(ctx, rootNode, key, key_len, NULL, FALSE);

        if (len > 1 && ctx->opts.canonical) {
            sorted_hash = xh_sort_hash((HV *) value, len);
            for (i = 0; i < len; i++) {
                xh_h2d_native(ctx, rootNode, sorted_hash[i].key, sorted_hash[i].key_len, sorted_hash[i].value);
            }
            free(sorted_hash);
        }
        else {
            hv_iterinit((HV *) value);
            while ((item_value = hv_iternextsv((HV *) value, (char **) &item, &item_len))) {
                xh_h2d_native(ctx, rootNode, item, item_len, item_value);
            }
        }
    }
    else if (type & XH_H2X_T_ARRAY) {
        len = av_len((AV *) value) + 1;
        for (i = 0; i < len; i++) {
            (void) xh_h2d_native(ctx, rootNode, key, key_len, *av_fetch((AV *) value, i, 0));
        }
    }
    else {
ADD_EMPTY_NODE:
        xh_dom_new_node(ctx, rootNode, key, key_len, NULL, FALSE);
    }

FINISH:
    ctx->depth--;
}
#endif

#ifndef _XH_X2H_H_
#define _XH_X2H_H_

#include "xh_config.h"
#include "xh_core.h"

#define XH_X2H_XPATH_MAX_LEN        1023

#define XH_X2H_NORMALIZE_REF        1
#define XH_X2H_NORMALIZE_LINE_FEED  2
#define XH_X2H_FILTER_ENABLED       4
#define XH_X2H_FILTER_MATCHED       8
#define XH_X2H_ROOT_FOUND           16
#define XH_X2H_IS_NOT_BLANK         32
#define XH_X2H_DOCTYPE_FOUND        64
#define XH_X2H_TEXT_NODE            128
#define XH_X2H_TAG_EXISTS           256

#define XH_X2H_NEED_NORMALIZE       (XH_X2H_NORMALIZE_REF |             \
                                     XH_X2H_NORMALIZE_LINE_FEED)
#define XH_X2H_FILTER_SEARCH(f)     (((f) & (XH_X2H_FILTER_ENABLED | XH_X2H_FILTER_MATCHED)) ==\
                                     XH_X2H_FILTER_ENABLED)

#define XH_X2H_PARSER_STATE_LIST                                        \
    XH_X2H_PROCESS_STATE(CONTENT_START)                                 \
    XH_X2H_PROCESS_STATE(PARSE_ELEMENT_START)                           \
    XH_X2H_PROCESS_STATE(XML_COMMENT_NODE_OR_CDATA_START)               \
    XH_X2H_PROCESS_STATE(COMMENT1_START)                                \
    XH_X2H_PROCESS_STATE(END_COMMENT1_START)                            \
    XH_X2H_PROCESS_STATE(END_COMMENT2_START)                            \
    XH_X2H_PROCESS_STATE(END_COMMENT3_START)                            \
    XH_X2H_PROCESS_STATE(CDATA_1_1_START)                               \
    XH_X2H_PROCESS_STATE(CDATA_1_2_START)                               \
    XH_X2H_PROCESS_STATE(CDATA_1_3_START)                               \
    XH_X2H_PROCESS_STATE(CDATA_2_1_START)                               \
    XH_X2H_PROCESS_STATE(CDATA_2_2_START)                               \
    XH_X2H_PROCESS_STATE(CDATA_2_3_START)                               \
    XH_X2H_PROCESS_STATE(END_CDATA1_START)                              \
    XH_X2H_PROCESS_STATE(END_CDATA2_START)                              \
    XH_X2H_PROCESS_STATE(END_CDATA3_START)                              \
    XH_X2H_PROCESS_STATE(DOCTYPE_1_1_START)                             \
    XH_X2H_PROCESS_STATE(DOCTYPE_1_2_START)                             \
    XH_X2H_PROCESS_STATE(DOCTYPE_1_3_START)                             \
    XH_X2H_PROCESS_STATE(DOCTYPE_2_1_START)                             \
    XH_X2H_PROCESS_STATE(DOCTYPE_2_2_START)                             \
    XH_X2H_PROCESS_STATE(DOCTYPE_2_3_START)                             \
    XH_X2H_PROCESS_STATE(DOCTYPE_NAME_START)                            \
    XH_X2H_PROCESS_STATE(DOCTYPE_NAME_START_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_NAME_END_START)                        \
    XH_X2H_PROCESS_STATE(DOCTYPE_NAME_BLANK_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_1_1_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_1_2_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_1_3_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_2_1_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_2_2_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_LOCATION_DOCTYPE_DELIM_START)   \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_LOCATION_DOCTYPE_DELIM_SKIP_BLANK_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_1_END_OF_LITERAL_START)         \
    XH_X2H_PROCESS_STATE(DOCTYPE_SYSTEM_2_END_OF_LITERAL_START)         \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_1_1_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_1_2_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_1_3_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_2_1_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_2_2_START)                      \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_ID_DOCTYPE_DELIM_START)         \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_ID_DOCTYPE_DELIM_SKIP_BLANK_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_1_DOCTYPE_DELIM_START) \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_1_DOCTYPE_DELIM_SKIP_BLANK_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_1_1_END_OF_LITERAL_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_1_2_END_OF_LITERAL_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_2_DOCTYPE_DELIM_START) \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_2_DOCTYPE_DELIM_SKIP_BLANK_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_2_1_END_OF_LITERAL_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_LOCATION_2_2_END_OF_LITERAL_START)\
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_1_END_OF_LITERAL_START)         \
    XH_X2H_PROCESS_STATE(DOCTYPE_PUBLIC_2_END_OF_LITERAL_START)         \
    XH_X2H_PROCESS_STATE(DOCTYPE_END_START)                             \
    XH_X2H_PROCESS_STATE(DOCTYPE_INTSUBSET_START)                       \
    XH_X2H_PROCESS_STATE(DOCTYPE_INTSUBSET_START_START)                 \
    XH_X2H_PROCESS_STATE(CDATA_WITH_TRIM_1_1_START)                     \
    XH_X2H_PROCESS_STATE(CDATA_WITH_TRIM_1_2_START)                     \
    XH_X2H_PROCESS_STATE(CDATA_WITH_TRIM_1_3_START)                     \
    XH_X2H_PROCESS_STATE(CDATA_WITH_TRIM_2_1_START)                     \
    XH_X2H_PROCESS_STATE(CDATA_WITH_TRIM_2_2_START)                     \
    XH_X2H_PROCESS_STATE(CDATA_WITH_TRIM_2_3_START)                     \
    XH_X2H_PROCESS_STATE(END_CDATA_WITH_TRIM1_START)                    \
    XH_X2H_PROCESS_STATE(END_CDATA_WITH_TRIM2_START)                    \
    XH_X2H_PROCESS_STATE(END_CDATA_WITH_TRIM3_START)                    \
    XH_X2H_PROCESS_STATE(PARSE_CLOSING_TAG_START)                       \
    XH_X2H_PROCESS_STATE(SEARCH_CLOSING_END_TAG_START)                  \
    XH_X2H_PROCESS_STATE(PARSE_OPENING_TAG_START)                       \
    XH_X2H_PROCESS_STATE(SEARCH_OPENING_END_TAG_START)                  \
    XH_X2H_PROCESS_STATE(NODE_SEARCH_ATTR_START)                        \
    XH_X2H_PROCESS_STATE(SEARCH_END_TAG_START)                          \
    XH_X2H_PROCESS_STATE(NODE_PARSE_ATTR_NAME_START)                    \
    XH_X2H_PROCESS_STATE(NODE_ATTR_SKIP_BLANK_START)                    \
    XH_X2H_PROCESS_STATE(NODE_PARSE_ATTR_VALUE_START)                   \
    XH_X2H_PROCESS_STATE(NODE_1_END_ATTR_VALUE_START)                   \
    XH_X2H_PROCESS_STATE(NODE_2_END_ATTR_VALUE_START)                   \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_1_1_1_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_1_1_2_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_1_1_3_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_1_2_1_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_1_2_2_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_2_1_1_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_2_1_2_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_2_1_3_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_2_2_1_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_2_2_2_START)                     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_ATTR_START)                      \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_ATTR_SEARCH_ATTR_START)          \
    XH_X2H_PROCESS_STATE(PI_SEARCH_END_TAG2_START)                      \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_ATTR_PARSE_ATTR_NAME_START)      \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_ATTR_ATTR_SKIP_BLANK_START)      \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_ATTR_PARSE_ATTR_VALUE_START)     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_ATTR_1_END_ATTR_VALUE_START)     \
    XH_X2H_PROCESS_STATE(STYLESHEET_PI_ATTR_2_END_ATTR_VALUE_START)     \
    XH_X2H_PROCESS_STATE(XML_DECL_1_START)                              \
    XH_X2H_PROCESS_STATE(XML_DECL_2_START)                              \
    XH_X2H_PROCESS_STATE(XML_DECL_3_START)                              \
    XH_X2H_PROCESS_STATE(XML_DECL_ATTR_START)                           \
    XH_X2H_PROCESS_STATE(XML_DECL_ATTR_SEARCH_ATTR_START)               \
    XH_X2H_PROCESS_STATE(XML_DECL_SEARCH_END_TAG2_START)                \
    XH_X2H_PROCESS_STATE(XML_DECL_ATTR_PARSE_ATTR_NAME_START)           \
    XH_X2H_PROCESS_STATE(XML_DECL_ATTR_ATTR_SKIP_BLANK_START)           \
    XH_X2H_PROCESS_STATE(XML_DECL_ATTR_PARSE_ATTR_VALUE_START)          \
    XH_X2H_PROCESS_STATE(XML_DECL_ATTR_1_END_ATTR_VALUE_START)          \
    XH_X2H_PROCESS_STATE(XML_DECL_ATTR_2_END_ATTR_VALUE_START)

#define XH_X2H_PROCESS_STATE(st) st,
typedef enum {
    PARSER_ST_NONE = 0,
    XH_X2H_PARSER_STATE_LIST
    XML_DECL_FOUND,
    PARSER_ST_DONE
} xh_x2h_state_t;
#undef XH_X2H_PROCESS_STATE

#define XH_X2H_NODE_FLAG_NONE        0
#define XH_X2H_NODE_FLAG_FORCE_ARRAY 1

typedef struct {
    SV                **lval;
    unsigned int        flags;
} xh_x2h_node_t;

typedef struct {
    xh_opts_t           opts;
    SV                 *hash;
    xh_char_t           encoding[XH_PARAM_LEN];
    xh_char_t          *tmp;
    size_t              tmp_size;
    xh_char_t          *node, *end, *end_of_attr_value, *content;
    unsigned int        flags;
    xh_x2h_node_t      *nodes;
    SV                **lval;
    unsigned int        depth, real_depth, code;
    xh_x2h_state_t      state;
    xh_reader_t         reader;
    SV                 *result, *input;
    xh_char_t           xpath[XH_X2H_XPATH_MAX_LEN + 1];
} xh_x2h_ctx_t;

SV *xh_x2h(xh_x2h_ctx_t *ctx);

XH_INLINE void
xh_x2h_destroy_ctx(xh_x2h_ctx_t *ctx)
{
    if (ctx->nodes != NULL) free(ctx->nodes);
    if (ctx->tmp   != NULL) free(ctx->tmp);

    xh_destroy_opts(&ctx->opts);
}

XH_INLINE void
xh_x2h_init_ctx(xh_x2h_ctx_t *ctx, I32 ax, I32 items)
{
    xh_opts_t *opts = NULL;
    xh_int_t   nparam = 0;

    memset(ctx, 0, sizeof(xh_x2h_ctx_t));

    opts = (xh_opts_t *) xh_get_obj_param(&nparam, ax, items, "XML::Hash::XS");
    ctx->input = xh_get_str_param(&nparam, ax, items);
    xh_merge_opts(&ctx->opts, opts, nparam, ax, items);

    if ((ctx->nodes = malloc(sizeof(xh_x2h_node_t) * ctx->opts.max_depth)) == NULL) {
        croak("Memory allocation error");
    }
    memset(ctx->nodes, 0, sizeof(xh_x2h_node_t) * ctx->opts.max_depth);
}

#endif /* _XH_X2H_H_ */

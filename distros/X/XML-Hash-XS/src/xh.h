#ifndef _XH_H_
#define _XH_H_

#include "xh_config.h"
#include "xh_core.h"

#define XH_INTERNAL_ENCODING "utf-8"

/* Default opts */
#define XH_DEF_OUTPUT        NULL
#define XH_DEF_METHOD        "NATIVE"
#define XH_DEF_ROOT          "root"
#define XH_DEF_VERSION       "1.0"
#define XH_DEF_ENCODING      ""
#define XH_DEF_UTF8          TRUE
#define XH_DEF_INDENT        0
#define XH_DEF_CANONICAL     FALSE
#define XH_DEF_USE_ATTR      FALSE
#define XH_DEF_CONTENT       ""
#define XH_DEF_XML_DECL      TRUE
#define XH_DEF_KEEP_ROOT     FALSE
#ifdef XH_HAVE_DOM
#define XH_DEF_DOC           FALSE
#endif
#define XH_DEF_FORCE_ARRAY   &PL_sv_undef
#define XH_DEF_FORCE_CONTENT FALSE
#define XH_DEF_MERGE_TEXT    FALSE

#define XH_DEF_ATTR          "-"
#define XH_DEF_TEXT          "#text"
#define XH_DEF_TRIM          FALSE
#define XH_DEF_CDATA         ""
#define XH_DEF_COMM          ""

#define XH_DEF_MAX_DEPTH     1024
#define XH_DEF_BUF_SIZE      4096

typedef enum {
    XH_METHOD_NATIVE = 0,
    XH_METHOD_NATIVE_ATTR_MODE,
    XH_METHOD_LX
} xh_method_t;

typedef struct {
    xh_method_t            method;

    /* native options */
    xh_char_t              version[XH_PARAM_LEN];
    xh_char_t              encoding[XH_PARAM_LEN];
    xh_char_t              root[XH_PARAM_LEN];
    xh_bool_t              utf8;
    xh_bool_t              xml_decl;
    xh_bool_t              keep_root;
    xh_bool_t              canonical;
    xh_char_t              content[XH_PARAM_LEN];
    xh_int_t               indent;
    void                  *output;
#ifdef XH_HAVE_DOM
    xh_bool_t              doc;
#endif
    xh_int_t               max_depth;
    xh_int_t               buf_size;
    xh_pattern_t           force_array;
    xh_bool_t              force_content;
    xh_bool_t              merge_text;
    xh_pattern_t           filter;
    SV                    *cb;

    /* LX options */
    xh_char_t              attr[XH_PARAM_LEN];
    size_t                 attr_len;
    xh_char_t              text[XH_PARAM_LEN];
    xh_bool_t              trim;
    xh_char_t              cdata[XH_PARAM_LEN];
    xh_char_t              comm[XH_PARAM_LEN];
} xh_opts_t;

xh_opts_t *xh_create_opts(void);
void xh_destroy_opts(xh_opts_t *opts);
xh_bool_t xh_init_opts(xh_opts_t *opts);
void xh_parse_param(xh_opts_t *opts, xh_int_t first, I32 ax, I32 items);
void xh_copy_opts(xh_opts_t *dst, xh_opts_t *src);
void *xh_get_obj_param(xh_int_t *nparam, I32 ax, I32 items, char *class);
SV *xh_get_hash_param(xh_int_t *nparam, I32 ax, I32 items);
SV *xh_get_str_param(xh_int_t *nparam, I32 ax, I32 items);
void xh_merge_opts(xh_opts_t *ctx_opts, xh_opts_t *opts, xh_int_t nparam, I32 ax, I32 items);

#endif /* _XH_H_ */

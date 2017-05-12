#ifndef _XH_DOM_H_
#define _XH_DOM_H_

#ifdef XH_HAVE_DOM
#include "xh_config.h"
#include "xh_core.h"

#define Pmm_NO_PSVI      0
#define Pmm_PSVI_TAINTED 1

struct _ProxyNode {
    xmlNodePtr node;
    xmlNodePtr owner;
    int count;
};

struct _DocProxyNode {
    xmlNodePtr node;
    xmlNodePtr owner;
    int count;
    int encoding; /* only used for proxies of xmlDocPtr */
    int psvi_status; /* see below ... */
};

/* helper type for the proxy structure */
typedef struct _DocProxyNode DocProxyNode;
typedef struct _ProxyNode ProxyNode;

/* pointer to the proxy structure */
typedef ProxyNode* ProxyNodePtr;
typedef DocProxyNode* DocProxyNodePtr;

/* this my go only into the header used by the xs */
#define SvPROXYNODE(x) (INT2PTR(ProxyNodePtr,SvIV(SvRV(x))))
#define PmmPROXYNODE(x) (INT2PTR(ProxyNodePtr,x->_private))
#define SvNAMESPACE(x) (INT2PTR(xmlNsPtr,SvIV(SvRV(x))))

#define x_PmmREFCNT(node)      node->count
#define x_PmmREFCNT_inc(node)  node->count++
#define x_PmmNODE(xnode)       xnode->node
#define x_PmmOWNER(node)       node->owner
#define x_PmmOWNERPO(node)     ((node && x_PmmOWNER(node)) ? (ProxyNodePtr)x_PmmOWNER(node)->_private : node)

#define x_PmmENCODING(node)    ((DocProxyNodePtr)(node))->encoding
#define x_PmmNodeEncoding(node) ((DocProxyNodePtr)(node->_private))->encoding

#define x_SetPmmENCODING(node,code) x_PmmENCODING(node)=(code)
#define x_SetPmmNodeEncoding(node,code) x_PmmNodeEncoding(node)=(code)

#define x_PmmSvNode(n) x_PmmSvNodeExt(n,1)

#define x_PmmUSEREGISTRY       (x_PROXY_NODE_REGISTRY_MUTEX != NULL)
#define x_PmmREGISTRY          (INT2PTR(xmlHashTablePtr,SvIV(SvRV(get_sv("XML::LibXML::__PROXY_NODE_REGISTRY",0)))))

SV *x_PmmNodeToSv(xmlNodePtr node, ProxyNodePtr owner);

XH_INLINE xmlNodePtr
xh_dom_new_node(xh_h2x_ctx_t *ctx, xmlNodePtr rootNode, xh_char_t *name, size_t name_len, SV *value, xh_bool_t raw)
{
    xh_char_t     *tmp;
    xh_char_t     *content;
    size_t         content_len;
    STRLEN         str_len;
    xh_char_t      ch;

    if (value == NULL) {
        content     = XH_EMPTY_STRING;
        content_len = 0;
    }
    else {
        content     = XH_CHAR_CAST SvPV(value, str_len);
        content_len = str_len;
    }

    tmp = NULL;
    if (name[0] >= '1' && name[0] <= '9') {
        tmp = malloc(name_len + 2);
        if (tmp == NULL) {
            croak("Memory allocation error");
        }

        (void) xh_strcpy(&tmp[1], name);

        name    = tmp;
        name[0] = '_';
    }

    if (ctx->opts.trim && content_len) {
        content = xh_str_trim(content, &content_len);
        ch      = content[content_len];
        content[content_len] = '\0';

        if (content_len && !raw) {
            rootNode = xmlNewTextChild(rootNode, NULL, BAD_CAST name, BAD_CAST content);
        }
        else {
            rootNode = xmlNewChild(rootNode, NULL, BAD_CAST name, BAD_CAST content);
        }

        content[content_len] = ch;
    }
    else {
        if (content_len && !raw) {
            rootNode = xmlNewTextChild(rootNode, NULL, BAD_CAST name, BAD_CAST content);
        }
        else {
            rootNode = xmlNewChild(rootNode, NULL, BAD_CAST name, BAD_CAST content);
        }
    }

    if (tmp != NULL) {
        free(tmp);
    }

    return rootNode;
}

XH_INLINE void
xh_dom_new_content(xh_h2x_ctx_t *ctx, xmlNodePtr rootNode, SV *value)
{
    xh_char_t     *content;
    size_t         content_len;
    STRLEN         str_len;
    xh_char_t      ch;

    if (value == NULL) {
        content     = XH_EMPTY_STRING;
        content_len = 0;
    }
    else {
        content     = XH_CHAR_CAST SvPV(value, str_len);
        content_len = str_len;
    }

    if (ctx->opts.trim && content_len) {
        content = xh_str_trim(content, &content_len);
        ch      = content[content_len];
        content[content_len] = '\0';

        xmlNodeAddContentLen(rootNode, BAD_CAST content, content_len);

        content[content_len] = ch;
    }
    else {
        xmlNodeAddContentLen(rootNode, BAD_CAST content, content_len);
    }
}

XH_INLINE void
xh_dom_new_comment(xh_h2x_ctx_t *ctx, xmlNodePtr rootNode, SV *value)
{
    xh_char_t     *content;
    size_t         content_len;
    STRLEN         str_len;
    xh_char_t      ch;

    if (value == NULL) {
        content     = XH_EMPTY_STRING;
        content_len = 0;
    }
    else {
        content     = XH_CHAR_CAST SvPV(value, str_len);
        content_len = str_len;
    }

    if (ctx->opts.trim && content_len) {
        content = xh_str_trim(content, &content_len);
        ch      = content[content_len];
        content[content_len] = '\0';

        (void) xmlAddChild(rootNode, xmlNewDocComment(rootNode->doc, BAD_CAST content));

        content[content_len] = ch;
    }
    else {
        (void) xmlAddChild(rootNode, xmlNewDocComment(rootNode->doc, BAD_CAST content));
    }
}

XH_INLINE void
xh_dom_new_cdata(xh_h2x_ctx_t *ctx, xmlNodePtr rootNode, SV *value)
{
    xh_char_t     *content;
    size_t         content_len;
    STRLEN         str_len;

    if (value == NULL) {
        content     = XH_EMPTY_STRING;
        content_len = 0;
    }
    else {
        content     = XH_CHAR_CAST SvPV(value, str_len);
        content_len = str_len;
    }

    if (ctx->opts.trim && content_len) {
        content = xh_str_trim(content, &content_len);
    }

    (void) xmlAddChild(rootNode, xmlNewCDataBlock(rootNode->doc, BAD_CAST content, content_len));
}

XH_INLINE void
xh_dom_new_attribute(xh_h2x_ctx_t *XH_UNUSED(ctx), xmlNodePtr rootNode, xh_char_t *name, size_t name_len, SV *value)
{
    xh_char_t     *content;
    STRLEN         str_len;
    xh_char_t     *tmp;

    if (value == NULL) {
        content     = NULL;
    }
    else {
        content     = XH_CHAR_CAST SvPV(value, str_len);
    }

    tmp = NULL;
    if (name[0] >= '1' && name[0] <= '9') {
        tmp = malloc(name_len + 1);
        if (tmp == NULL) {
            croak("Memory allocation error");
        }

        (void) xh_strcpy(&tmp[1], name);

        name    = tmp;
        name[0] = '_';
    }

    (void) xmlSetProp(rootNode, BAD_CAST name, BAD_CAST content);

    if (tmp != NULL) {
        free(tmp);
    }
}

#endif

#endif /* _XH_DOM_H_ */

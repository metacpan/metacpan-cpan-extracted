#include "xh_config.h"
#include "xh_core.h"

#ifdef XH_HAVE_DOM
SV* x_PROXY_NODE_REGISTRY_MUTEX = NULL;

static const char*
x_PmmNodeTypeName( xmlNodePtr elem ){
    const char *name = "XML::LibXML::Node";

    if ( elem != NULL ) {
        switch ( elem->type ) {
        case XML_ELEMENT_NODE:
            name = "XML::LibXML::Element";
            break;
        case XML_TEXT_NODE:
            name = "XML::LibXML::Text";
            break;
        case XML_COMMENT_NODE:
            name = "XML::LibXML::Comment";
            break;
        case XML_CDATA_SECTION_NODE:
            name = "XML::LibXML::CDATASection";
            break;
        case XML_ATTRIBUTE_NODE:
            name = "XML::LibXML::Attr";
            break;
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
            name = "XML::LibXML::Document";
            break;
        case XML_DOCUMENT_FRAG_NODE:
            name = "XML::LibXML::DocumentFragment";
            break;
        case XML_NAMESPACE_DECL:
            name = "XML::LibXML::Namespace";
            break;
        case XML_DTD_NODE:
            name = "XML::LibXML::Dtd";
            break;
        case XML_PI_NODE:
            name = "XML::LibXML::PI";
            break;
        default:
            name = "XML::LibXML::Node";
            break;
        };
        return name;
    }
    return "";
}

static ProxyNodePtr
x_PmmNewNode(xmlNodePtr node)
{
    ProxyNodePtr proxy = NULL;

    if ( node == NULL ) {
        return NULL;
    }

    if ( node->_private == NULL ) {
        switch ( node->type ) {
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
        case XML_DOCB_DOCUMENT_NODE:
            proxy = (ProxyNodePtr)xmlMalloc(sizeof(struct _DocProxyNode));
            if (proxy != NULL) {
                ((DocProxyNodePtr)proxy)->psvi_status = Pmm_NO_PSVI;
                x_SetPmmENCODING(proxy, XML_CHAR_ENCODING_NONE);
            }
            break;
        default:
            proxy = (ProxyNodePtr)xmlMalloc(sizeof(struct _ProxyNode));
            break;
        }
        if (proxy != NULL) {
            proxy->node  = node;
            proxy->owner   = NULL;
            proxy->count   = 0;
            node->_private = (void*) proxy;
        }
    }
    else {
        proxy = (ProxyNodePtr)node->_private;
    }

    return proxy;
}

SV *
x_PmmNodeToSv(xmlNodePtr node, ProxyNodePtr owner)
{
    ProxyNodePtr dfProxy= NULL;
    SV * retval = &PL_sv_undef;
    const char * CLASS = "XML::LibXML::Node";

    if ( node != NULL ) {
#ifdef XML_LIBXML_THREADS
        if( x_PmmUSEREGISTRY )
            SvLOCK(x_PROXY_NODE_REGISTRY_MUTEX);
#endif
        /* find out about the class */
        CLASS = x_PmmNodeTypeName( node );

        if ( node->_private != NULL ) {
            dfProxy = x_PmmNewNode(node);
            /* warn(" at 0x%08.8X\n", dfProxy); */
        }
        else {
            dfProxy = x_PmmNewNode(node);
            /* fprintf(stderr, " at 0x%08.8X\n", dfProxy); */
            if ( dfProxy != NULL ) {
                if ( owner != NULL ) {
                    dfProxy->owner = x_PmmNODE( owner );
                    x_PmmREFCNT_inc( owner );
                    /* fprintf(stderr, "REFCNT incremented on owner: 0x%08.8X\n", owner); */
                }
            }
            else {
                warn("x_PmmNodeToSv:   proxy creation failed!\n");
            }
        }

        retval = NEWSV(0,0);
        sv_setref_pv( retval, CLASS, (void*)dfProxy );
#ifdef XML_LIBXML_THREADS
    if( x_PmmUSEREGISTRY )
        x_PmmRegistryREFCNT_inc(dfProxy);
#endif
        x_PmmREFCNT_inc(dfProxy);
        /* fprintf(stderr, "REFCNT incremented on node: 0x%08.8X\n", dfProxy); */

        switch ( node->type ) {
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
        case XML_DOCB_DOCUMENT_NODE:
            if ( ((xmlDocPtr)node)->encoding != NULL ) {
                x_SetPmmENCODING(dfProxy, (int)xmlParseCharEncoding( (const char*)((xmlDocPtr)node)->encoding ));
            }
            break;
        default:
            break;
        }
#ifdef XML_LIBXML_THREADS
        if( x_PmmUSEREGISTRY )
            SvUNLOCK(x_PROXY_NODE_REGISTRY_MUTEX);
#endif
    }
    else {
        warn( "x_PmmNodeToSv: no node found!\n" );
    }

    return retval;
}
#endif

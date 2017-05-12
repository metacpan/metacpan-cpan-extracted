#include "libxml.h"

#define PmmNODE(xnode)  xnode->node
#define SvPROXYNODE(x)  (INT2PTR(ProxyNodePtr,SvIV(SvRV(x))))
#define xs_warn(string)
#define PmmREFCNT_inc(node)  node->count++


static const char* PmmNodeTypeName( xmlNodePtr elem);
static ProxyNodePtr PmmNewNode(xmlNodePtr node);


xmlNodePtr
PmmSvNodeExt(SV *perlnode, int copy) 
{
    xmlNodePtr retval = NULL;
    ProxyNodePtr proxy = NULL;

    if ( perlnode != NULL && perlnode != &PL_sv_undef ) {
        xs_warn("PmmSvNodeExt: perlnode found\n" );
        if ( sv_derived_from(perlnode, "XML::LibXML::Node")  ) {
            proxy = SvPROXYNODE(perlnode);
            if ( proxy != NULL ) {
                xs_warn( "PmmSvNodeExt:   is a xmlNodePtr structure\n" );
                retval = PmmNODE( proxy ) ;
            }

            if ( retval != NULL
                 && ((ProxyNodePtr)retval->_private) != proxy ) {
                xs_warn( "PmmSvNodeExt:   no node in proxy node\n" );
                PmmNODE( proxy ) = NULL;
                retval = NULL;
            }
        }
#ifdef  XML_LIBXML_GDOME_SUPPORT
        else if ( sv_derived_from( perlnode, "XML::GDOME::Node" ) ) {
            GdomeNode* gnode = (GdomeNode*)SvIV((SV*)SvRV( perlnode ));
            if ( gnode == NULL ) {
                warn( "no XML::GDOME data found (datastructure empty)" );    
            }
            else {
                retval = gdome_xml_n_get_xmlNode( gnode );
                if ( retval == NULL ) {
                    xs_warn( "PmmSvNodeExt: no XML::LibXML node found in GDOME object\n" );
                }
                else if ( copy == 1 ) {
                    retval = PmmCloneNode( retval, 1 );
                }
            }
        }
#endif
    }

    return retval;
}

/* @node: the node that should be wrapped into a SV
 * @owner: perl instance of the owner node (may be NULL)
 *
 * This function will create a real perl instance of a given node.
 * the function is called directly by the XS layer, to generate a perl
 * instance of the node. All node reference counts are updated within
 * this function. Therefore this function returns a node that can
 * directly be used as output.
 *
 * if @ower is NULL or undefined, the node is ment to be the root node
 * of the tree. this node will later be used as an owner of other
 * nodes.
 */
SV*
PmmNodeToSv( xmlNodePtr node, ProxyNodePtr owner ) 
{
    ProxyNodePtr dfProxy= NULL;
    SV * retval = &PL_sv_undef;
    const char * CLASS = "XML::LibXML::Node";

    if ( node != NULL ) {
#ifdef XML_LIBXML_THREADS
      if( PmmUSEREGISTRY )
                SvLOCK(PROXY_NODE_REGISTRY_MUTEX);
#endif
        /* find out about the class */
        CLASS = PmmNodeTypeName( node );
        xs_warn("PmmNodeToSv: return new perl node of class:\n");
        xs_warn( CLASS );

        if ( node->_private != NULL ) { 
            dfProxy = PmmNewNode(node);
        }
        else {
            dfProxy = PmmNewNode(node);
            if ( dfProxy != NULL ) {
                if ( owner != NULL ) {
                    dfProxy->owner = PmmNODE( owner );
                    PmmREFCNT_inc( owner );
                }
                else {
                   xs_warn("PmmNodeToSv:   node contains itself (owner==NULL)\n");
                }
            }
            else {
                croak("XML::LibXML: failed to create a proxy node (out of memory?)\n");
            }
        }

        retval = NEWSV(0,0);
        sv_setref_pv( retval, CLASS, (void*)dfProxy );
#ifdef XML_LIBXML_THREADS
        if( PmmUSEREGISTRY )
            PmmRegistryREFCNT_inc(dfProxy);
#endif
        PmmREFCNT_inc(dfProxy); 
        /* fprintf(stderr, "REFCNT incremented on node: 0x%08.8X\n", dfProxy); */

        switch ( node->type ) {
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
        case XML_DOCB_DOCUMENT_NODE:
            if ( ((xmlDocPtr)node)->encoding != NULL ) {
                dfProxy->encoding = (int)xmlParseCharEncoding( (const char*)((xmlDocPtr)node)->encoding );
            }
            break;
        default:
            break;
        }
#ifdef XML_LIBXML_THREADS
      if( PmmUSEREGISTRY )
                SvUNLOCK(PROXY_NODE_REGISTRY_MUTEX);
#endif
    }
    else {
        xs_warn( "PmmNodeToSv: no node found!\n" );
    }

    return retval;
}


/**
 * this is a wrapper function that does the type evaluation for the 
 * node. this makes the code a little more readable in the .XS
 * 
 * the code is not really portable, but i think we'll avoid some 
 * memory leak problems that way.
 **/
static const char*
PmmNodeTypeName( xmlNodePtr elem ){
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

/* creates a new proxy node from a given node. this function is aware
 * about the fact that a node may already has a proxy structure.
 */
static ProxyNodePtr
PmmNewNode(xmlNodePtr node)
{
    ProxyNodePtr proxy = NULL;

    if ( node == NULL ) {
        xs_warn( "PmmNewNode: no node found\n" );
        return NULL;
    }

    if ( node->_private == NULL ) {
        proxy = (ProxyNodePtr)xmlMalloc(sizeof(struct _ProxyNode));
        if (proxy != NULL) {
            proxy->node  = node;
            proxy->owner   = NULL;
            proxy->count   = 0;
            proxy->encoding= 0;
            node->_private = (void*) proxy;
        }
    }
    else {
        proxy = (ProxyNodePtr)node->_private;
    }

    return proxy;
}

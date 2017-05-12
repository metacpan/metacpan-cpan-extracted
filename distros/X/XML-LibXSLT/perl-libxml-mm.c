/**
 * perl-libxml-mm.c
 * $Id$
 *
 * Basic concept:
 * perl varies in the implementation of UTF8 handling. this header (together
 * with the c source) implements a few functions, that can be used from within
 * the core module inorder to avoid cascades of c pragmas
 */
/*
 * This is free software, you may use it and distribute it under the same terms as
 * Perl itself.
 *
 * Copyright 2001-2009 AxKit.com Ltd.
*/

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>
#include <stdlib.h>

#include "perl-libxml-mm.h"

#include "XSUB.h"
#include <libxml/tree.h>

#ifdef __cplusplus
}
#endif

#ifdef XS_WARNINGS
#define xs_warn(string) warn(string)
/* #define xs_warn(string) fprintf(stderr, string) */
#else
#define xs_warn(string)
#endif

/**
 * this is a wrapper function that does the type evaluation for the
 * node. this makes the code a little more readable in the .XS
 *
 * the code is not really portable, but i think we'll avoid some
 * memory leak problems that way.
 **/
const char*
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

/*
 * registry of all current proxy nodes
 *
 * other classes like XML::LibXSLT must get a pointer
 * to this registry via XML::LibXML::__proxy_registry
 *
 */
extern SV* x_PROXY_NODE_REGISTRY_MUTEX;

#ifdef XML_LIBXML_THREADS

/*
 * returns the address of the proxy registry
 */
xmlHashTablePtr*
x_PmmProxyNodeRegistryPtr(ProxyNodePtr proxy)
{
	croak("x_PmmProxyNodeRegistryPtr: TODO!\n");
	return NULL;
	/*   return &x_PmmREGISTRY; */
}

/*
 * efficiently generate a string representation of the given pointer
 */
#define _PMM_HASH_NAME_SIZE(n) n+(n>>3)+(n%8>0 ? 1 : 0)
xmlChar *
x_PmmRegistryName(void * ptr)
{
	unsigned long int v = (unsigned long int) ptr;
	int HASH_NAME_SIZE = _PMM_HASH_NAME_SIZE(sizeof(void*));
	xmlChar * name;
	int i;

	name = (xmlChar *) safemalloc(HASH_NAME_SIZE+1);

	for(i = 0; i < HASH_NAME_SIZE; ++i)
	{
		name[i] = (xmlChar) (128 | v);
		v >>= 7;
	}
	name[HASH_NAME_SIZE] = '\0';

	return name;
}

/*
 * allocate and return a new LocalProxyNode structure
 */
LocalProxyNodePtr
x_PmmNewLocalProxyNode(ProxyNodePtr proxy)
{
	LocalProxyNodePtr lp;
	Newc(0, lp, 1, LocalProxyNode, LocalProxyNode);
	lp->proxy = proxy;
	lp->count = 0;
	return lp;
}

/*
 * @proxy: proxy node to register
 *
 * adds a proxy node to the proxy node registry
 */
LocalProxyNodePtr
x_PmmRegisterProxyNode(ProxyNodePtr proxy)
{
	xmlChar * name = x_PmmRegistryName( proxy );
	LocalProxyNodePtr lp = x_PmmNewLocalProxyNode( proxy );
        /* warn("LibXML registers proxy node with %p\n",x_PmmREGISTRY); */
	SvLOCK(x_PROXY_NODE_REGISTRY_MUTEX);
	if( xmlHashAddEntry(x_PmmREGISTRY, name, lp) )
		croak("x_PmmRegisterProxyNode: error adding node to hash, hash size is %d\n",xmlHashSize(x_PmmREGISTRY));
	SvUNLOCK(x_PROXY_NODE_REGISTRY_MUTEX);
	Safefree(name);
	return lp;
}

/*
 * lookup a LocalProxyNode in the registry
 */
LocalProxyNodePtr
x_PmmRegistryLookup(ProxyNodePtr proxy)
{
	xmlChar * name = x_PmmRegistryName( proxy );
	LocalProxyNodePtr lp = xmlHashLookup(x_PmmREGISTRY, name);
	Safefree(name);
	return lp;
}

/*
 * increment the local refcount for proxy
 */
void
x_PmmRegistryREFCNT_inc(ProxyNodePtr proxy)
{
  /* warn("Registry inc\n"); */
	LocalProxyNodePtr lp = x_PmmRegistryLookup( proxy );
	if( lp )
		lp->count++;
	else
		x_PmmRegisterProxyNode( proxy )->count++;
}

/*
 * returns the current number of proxy nodes in the registry
 */
int
x_PmmProxyNodeRegistrySize()
{
	return xmlHashSize(x_PmmREGISTRY);
}

#endif /* XML_LIBXML_THREADS */

/* creates a new proxy node from a given node. this function is aware
 * about the fact that a node may already has a proxy structure.
 */
ProxyNodePtr
x_PmmNewNode(xmlNodePtr node)
{
    ProxyNodePtr proxy = NULL;

    if ( node == NULL ) {
        xs_warn( "x_PmmNewNode: no node found\n" );
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

ProxyNodePtr
x_PmmNewFragment(xmlDocPtr doc)
{
    ProxyNodePtr retval = NULL;
    xmlNodePtr frag = NULL;

    xs_warn("x_PmmNewFragment: new frag\n");
    frag   = xmlNewDocFragment( doc );
    retval = x_PmmNewNode(frag);
    /* fprintf(stderr, "REFCNT NOT incremented on frag: 0x%08.8X\n", retval); */

    if ( doc != NULL ) {
        xs_warn("x_PmmNewFragment: inc document\n");
        /* under rare circumstances _private is not set correctly? */
        if ( doc->_private != NULL ) {
            xs_warn("x_PmmNewFragment:   doc->_private being incremented!\n");
            x_PmmREFCNT_inc(((ProxyNodePtr)doc->_private));
            /* fprintf(stderr, "REFCNT incremented on doc: 0x%08.8X\n", doc->_private); */
        }
        retval->owner = (xmlNodePtr)doc;
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
x_PmmNodeToSv( xmlNodePtr node, ProxyNodePtr owner )
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
        xs_warn("x_PmmNodeToSv: return new perl node of class:\n");
        xs_warn( CLASS );

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
                else {
                   xs_warn("x_PmmNodeToSv:   node contains itself (owner==NULL)\n");
                }
            }
            else {
                xs_warn("x_PmmNodeToSv:   proxy creation failed!\n");
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
        xs_warn( "x_PmmNodeToSv: no node found!\n" );
    }

    return retval;
}


/* extracts the libxml2 node from a perl reference
 */

xmlNodePtr
x_PmmSvNodeExt( SV* perlnode, int copy )
{
    xmlNodePtr retval = NULL;
    ProxyNodePtr proxy = NULL;

    if ( perlnode != NULL && perlnode != &PL_sv_undef ) {
/*         if ( sv_derived_from(perlnode, "XML::LibXML::Node") */
/*              && SvPROXYNODE(perlnode) != NULL  ) { */
/*             retval = x_PmmNODE( SvPROXYNODE(perlnode) ) ; */
/*         } */
        xs_warn("x_PmmSvNodeExt: perlnode found\n" );
        if ( sv_derived_from(perlnode, "XML::LibXML::Node")  ) {
            proxy = SvPROXYNODE(perlnode);
            if ( proxy != NULL ) {
                xs_warn( "x_PmmSvNodeExt:   is a xmlNodePtr structure\n" );
                retval = x_PmmNODE( proxy ) ;
            }

            if ( retval != NULL
                 && ((ProxyNodePtr)retval->_private) != proxy ) {
                xs_warn( "x_PmmSvNodeExt:   no node in proxy node\n" );
                x_PmmNODE( proxy ) = NULL;
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
                    xs_warn( "x_PmmSvNodeExt: no XML::LibXML node found in GDOME object\n" );
                }
                else if ( copy == 1 ) {
                    retval = x_PmmCloneNode( retval, 1 );
                }
            }
        }
#endif
    }

    return retval;
}

/* extracts the libxml2 owner node from a perl reference
 */
xmlNodePtr
x_PmmSvOwner( SV* perlnode )
{
    xmlNodePtr retval = NULL;
    if ( perlnode != NULL
         && perlnode != &PL_sv_undef
         && SvPROXYNODE(perlnode) != NULL  ) {
        retval = x_PmmOWNER( SvPROXYNODE(perlnode) );
    }
    return retval;
}

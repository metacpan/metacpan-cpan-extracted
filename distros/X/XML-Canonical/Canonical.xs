/* $Id: */


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libxml/tree.h>
#include <libxml/c14n.h>
#include <gdome.h>
#include <gdome-xpath.h>

typedef struct _Gdome_xml_Node Gdome_xml_Node;
struct _Gdome_xml_Node {
        GdomeNode super;
        const GdomeNodeVtab *vtab;
        int refcnt;
  xmlNode *n;
  GdomeAccessType accessType;
  void *ll;
  xmlNs *ns;
};

typedef struct _Gdome_xpath_XPathResult Gdome_xpath_XPathResult;

struct _Gdome_xpath_XPathResult {
  const GdomeXPathResultVtab *vtab;
  int refcnt;
  xmlXPathObjectPtr res;
        GdomeNode *gnode;
        int pos;
};

#ifdef __cplusplus
}
#endif

MODULE = XML::Canonical         PACKAGE = XML::Canonical

PROTOTYPES: DISABLE

char *
_canonicalize_document(doc, exclusive, with_comments, xpathres)
        GdomeDocument * doc
        int exclusive
        int with_comments
	GdomeXPathResult * xpathres
    PREINIT:
        xmlChar **doc_txt_ptr;
        Gdome_xml_Node *priv;
        xmlNodeSetPtr nodes = NULL;
        Gdome_xpath_XPathResult *priv_xpathres;
    CODE:
	doc_txt_ptr = xmlMalloc(sizeof(xmlChar **));
        priv = (Gdome_xml_Node *)doc;
	if (xpathres != NULL) {
	  priv_xpathres = (Gdome_xpath_XPathResult *)xpathres;
	  nodes = priv_xpathres->res->nodesetval;
        }
        if (xmlC14NDocDumpMemory((xmlDocPtr)priv->n, nodes, exclusive, NULL, with_comments, doc_txt_ptr) >= 0) {
          RETVAL = *doc_txt_ptr;
          free(doc_txt_ptr);
        }
    OUTPUT:
        RETVAL


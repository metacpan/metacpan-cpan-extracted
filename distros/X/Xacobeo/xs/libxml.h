#ifndef __XACOBEO_LIBXML_H__
#define __XACOBEO_LIBXML_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libxml/parser.h>

#define PmmSvNode(n)      PmmSvNodeExt(n,1)
#define PmmOWNERPO(node)  ((node && PmmOWNER(node)) ? (ProxyNodePtr)PmmOWNER(node)->_private : node)
#define PmmPROXYNODE(x)   (INT2PTR(ProxyNodePtr,x->_private))
#define PmmOWNER(node)    node->owner


struct _ProxyNode {
    xmlNodePtr node;
    xmlNodePtr owner;
    int count;
    int encoding;
};

typedef struct _ProxyNode ProxyNode;
typedef ProxyNode* ProxyNodePtr;

xmlNodePtr
PmmSvNodeExt(SV *perlnode, int copy);

SV*
PmmNodeToSv(xmlNodePtr node, ProxyNodePtr owner);

#endif

# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron::DOM module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): science+computing ag:
#                 Nicolas Trebst, n.trebst@science-computing.de
#                 Anselm Kruis,    a.kruis@science-computing.de
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

#
# ../Sablotron.xs includes this file. 
#

MODULE = XML::Sablotron		PACKAGE = XML::Sablotron::DOM
PROTOTYPES: ENABLE

BOOT:
     SDOM_setDisposeCallback(&__nodeDisposeCallback);
     SablotCreateSituation(&__sit);

SV*
parse(sit, uri)
     SV*      sit
     char*    uri
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParse(situa, uri, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

SV*
parseBuffer(sit, buff)
     SV*      sit
     char*    buff
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParseBuffer(situa, buff, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

SV*
parseStylesheet(sit, uri)
     SV*      sit
     char*    uri
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParseStylesheet(situa, uri, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

SV*
parseStylesheetBuffer(sit, buff)
     SV*      sit
     char*    buff
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_HANDLE(sit);
     DE( situa, SablotParseStylesheetBuffer(situa, buff, &doc) );
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

void
testsit(val)
     SV* val
     CODE:

#     HV* hash;
#     GV* gv;
#     SV* val;
#     hash = gv_stashpv("XML::Sablotron::DOM", 0);
#     gv = (GV*)*hv_fetch(hash, "__sit", 5, 0);
#     val = GvSV(gv);


#************************************************************
#* NODE
#************************************************************

MODULE = XML::Sablotron	        PACKAGE = XML::Sablotron::DOM::Node

int 
_clearInstanceData(object)
     SV*      object
     CODE:
     if ( __useUniqueDOMWrappers() ) 
     {
         HV * hash = (HV*)SvRV(object);
         SDOM_Node node = NODE_HANDLE(object);
         if ( node ) {
             /* The Node exists. This should only happen, if _clearInstanceData
                gets called manually */
             HV * inner = (HV*)SDOM_getNodeInstanceData( node );
             if ( inner ) {
                 __checkNodeInstanceData( node , inner );
                 /* inner == hash */
                 if ( SvREFCNT(hash) == 2 ) {
                     SDOM_setNodeInstanceData( node , NULL);
                     SvREFCNT_dec(hash);
                 }
             }
             /* set the node address to NULL */ 
             sv_setiv( *hv_fetch( hash, "_handle", 7, 0), 0 );
         }
         RETVAL = ( SvREFCNT(hash) == 1 );
     } 
     else /* not __useUniqueDOMWrappers() */
     {
     SV* inner =  *hv_fetch((HV*)SvRV(object), "_handle", 7, 0);
     if (inner && (SvREFCNT(inner) == 2) ) {
         /* I'm the last one owning the reference to inner handle */
         SvREFCNT_dec(inner);
         if ( SvIV(inner) )
             SDOM_setNodeInstanceData((SDOM_Node)SvIV(inner), NULL);
         RETVAL = 1;
     } else {
         RETVAL = 0;
     }
     }
     OUTPUT:
     RETVAL


int 
nodeType(object, ...) 
     SV*      object
     ALIAS:
     getNodeType = 1
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_NodeType type;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeType(situa, node, &type) );
     RETVAL = (int)type;
     OUTPUT:
     RETVAL


char*
getNodeName(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_char* name;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeName(situa, node, (SDOM_char**)&name) );
     RETVAL = (char*)name;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (name) SablotFree(name);

void
setNodeName(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_setNodeName(situa, node, (SDOM_char*)name) );


char*
getNodeValue(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_char* value;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeValue(situa, node, (SDOM_char**)&value) );
     /* _fix_ the null values, see spec */
     RETVAL = (char*)value; 
     OUTPUT:
     RETVAL
     CLEANUP:
     if (value) SablotFree(value);

void
setNodeValue(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     /* _fix_ check undef values */
     DE( situa, SDOM_setNodeValue(situa, node, (SDOM_char*)value) );


SV*
parentNode(object, ...)
     SV*      object
     ALIAS:
     getParentNode = 1
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node parent;
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     DE( situa, SDOM_getParentNode(situa, node, &parent) );
     if (parent) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, parent);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL


SV*
firstChild(object, ...)
     SV*      object
     ALIAS:
     getFirstChild = 1
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node child;
     CN(node);
     DE( situa, SDOM_getFirstChild(situa, node, &child) );
     if (child) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, child);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

SV*
lastChild(object, ...)
     SV*      object
     ALIAS:
     getLastChild = 1
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node child;
     CN(node);
     DE( situa, SDOM_getLastChild(situa, node, &child) );
     if (child) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, child);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

SV*
previousSibling(object, ...)
     SV*      object
     ALIAS:
     getPreviousSibling = 1
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node sibling;
     CN(node);
     DE( situa, SDOM_getPreviousSibling(situa, node, &sibling) );
     if (sibling) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, sibling);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

SV*
nextSibling(object, ...)
     SV*      object
     ALIAS:
     getNextSibling = 1
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node sibling;
     CN(node);
     DE( situa, SDOM_getNextSibling(situa, node, &sibling) );
     if (sibling) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, sibling);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL


SV*
_childIndex(index, object, ...)
     int      index
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(3);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node child;
     CN(node);
     DE( situa, SDOM_getChildNodeIndex(situa, node, index, &child) );
     if (child) {
         RETVAL = __createNode(situa, child);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

int
_childCount(object, ...)
     SV*      object
     ALIAS:
     hasChildNodes = 1
     CODE:
     int ret;
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     DE( situa, SDOM_getChildNodeCount(situa, node, &ret) );
     RETVAL = ret;
     OUTPUT:
     RETVAL


AV*
childNodesArr(object, ...)
     SV*      object
     ALIAS:
     getChildNodes = 1
     CODE:
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node foo;
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     RETVAL = (AV*)sv_2mortal( (SV*)newAV() );
     DE( situa, SDOM_getFirstChild(situa, node, &foo) );
     while ( foo ) {
         av_push(RETVAL, __createNode(situa, foo));
         DE( situa, SDOM_getNextSibling(situa, foo, &foo) );
     }
     OUTPUT:
     RETVAL


SV*
ownerDocument(object, ...)
     SV*      object
     ALIAS:
     getOwnerDocument = 1
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Document doc;
     CN(node);
     DE( situa, SDOM_getOwnerDocument(situa, node, &doc) );
     if (doc) {
         /* _fix_ check memory leaks */
         /* _fix_ check if it works at all (create node etc.) */
         RETVAL = __createNode(situa, doc);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL


void
_insertBefore(object, child, ref, ...)
     SV*      object
     SV*      child
     SV*      ref
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node refnode;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     refnode =  (ref == &PL_sv_undef) ? NULL : NODE_HANDLE(ref);
     DE( situa, SDOM_insertBefore(situa, node, 
                           NODE_HANDLE(child), refnode) );

void
_appendChild(object, child, ...)
     SV*      object
     SV*      child
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_appendChild(situa, node, NODE_HANDLE(child)) );

void
_removeChild(object, child, ...)
     SV*      object
     SV*      child
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_removeChild(situa, node, NODE_HANDLE(child)) );

void
_replaceChild(object, child, old, ...)
     SV*      object
     SV*      child
     SV*      old
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node oldnode;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     if (old == &PL_sv_undef) 
          croak ("XML::Sablotron::DOM(Code=-2, Name='NODE_REQUIRED'");
     oldnode = NODE_HANDLE(old);
     DE( situa, SDOM_replaceChild(situa, node, 
                           NODE_HANDLE(child), oldnode) );



SV* 
cloneNode(object, deep, ...)
     SV*      object
     int      deep
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node cloned;
     SDOM_Node nodehandle = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(nodehandle);
     DE( situa, SDOM_cloneNode(situa, nodehandle, deep, &cloned) );
     RETVAL = __createNode(situa, cloned);
     OUTPUT:
     RETVAL


char*
namespaceURI(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_char* name;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeNSUri(situa, node, (SDOM_char**)&name) );
     RETVAL = (char*)name;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (name) SablotFree(name);

char*
localName(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_char* name;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeLocalName(situa, node, (SDOM_char**)&name) );
     RETVAL = (char*)name;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (name) SablotFree(name);


char*
getPrefix(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_char* prefix;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodePrefix(situa, node, (SDOM_char**)&prefix) );
     RETVAL = (char*)prefix;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (prefix) SablotFree(prefix);

void
setPrefix(object, prefix, ...)
     SV*      object
     char*    prefix
     CODE:
     char* name;
     char* localname;
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     DE( situa, SDOM_getNodeLocalName(situa, node, (SDOM_char**)&localname) );
     if (prefix && strcmp(prefix, "") ) {
         name = strcat(strcat(prefix, ":"),localname);
     }
     else {
         name = localname;     
     };
     DE( situa, SDOM_setNodeName(situa, node, (SDOM_char*)name) );
     CLEANUP:
     if (localname) SablotFree(localname);



AV*
xql(object, expr, ...)
     SV*      object
     char*    expr
     CODE:
     SV* sit = SIT_PARAM(3);
     int i;
     int len;
     SDOM_NodeList list;
     SDOM_Document doc;
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     SDOM_getOwnerDocument(situa, node, &doc);
     SablotLockDocument(situa, doc ? doc : node); /* _check me_ */
     DE( situa, SDOM_xql(situa, expr, node, &list) );
     RETVAL = (AV*)sv_2mortal((SV*)newAV());
     SDOM_getNodeListLength(situa, list, &len);
     for (i = 0; i < len; i++) {
         SDOM_Node node;
         SDOM_getNodeListItem(situa, list, i, &node);
         av_push(RETVAL, __createNode(situa, node));
     }
     SDOM_disposeNodeList(situa, list);
     OUTPUT:
     RETVAL

int 
compareNodes(object, object2, ...) 
     SV*      object
     SV*      object2
     CODE:
     SV* sit = SIT_PARAM(3);
     int ret;
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node node2 = NODE_HANDLE(object2);
     SablotSituation situa = SIT_SMART(sit);
     CN(node);
     CN(node2);
     DE( situa, SDOM_compareNodes(situa, node, node2, &ret) );
     RETVAL = ret;
     OUTPUT:
     RETVAL


AV*
xql_ns(object, expr, nsmap, ...)
     SV*      object
     char*    expr
     SV*      nsmap
     CODE:
     SV* sit = SIT_PARAM(4);
     int i;
     int len;
     char** nsarr;
     int nsnum;
     HV* maph;
     SDOM_NodeList list;
     SDOM_Document doc;
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     SDOM_getOwnerDocument(situa, node, &doc);
     SablotLockDocument(situa, doc ? doc : node); /* _check me_ */

     /* create nsarr */
     if (SvOK(nsmap) && SvTYPE(SvRV(nsmap)) == SVt_PVHV) {
         int mapsize = 1;
         HE * he;
         maph = (HV*)SvRV(nsmap);
         nsarr = malloc((10*2*mapsize + 1) * sizeof(char*));
         nsnum = 0;
         i = 0;
         hv_iterinit(maph);
         while (he = hv_iternext(maph)) {
             int l;
             if (++nsnum > 10 * mapsize) {
                 mapsize++;
                 nsarr = realloc(nsarr, (10*2*mapsize + 1) * sizeof(char*));
             }
             nsarr[i++] = (char*)HePV(he, l);
             nsarr[i++] = (char*)SvPV(HeVAL(he), l);
         }
         nsarr[nsnum * 2] = NULL;
     } else {
         croak("The third parameter of xql_ns must be a HASHREF");
     }

     DE( situa, SDOM_xql_ns(situa, expr, node, nsarr, &list) );
     free(nsarr);
     /* read the result */
     RETVAL = (AV*)sv_2mortal((SV*)newAV());
     SDOM_getNodeListLength(situa, list, &len);
     for (i = 0; i < len; i++) {
         SDOM_Node foo;
         SDOM_Node node;
         SDOM_getNodeListItem(situa, list, i, &node);
         av_push(RETVAL, __createNode(situa, node));
     }
     SDOM_disposeNodeList(situa, list);
     OUTPUT:
     RETVAL

#************************************************************
#* DOCUMENT *
#************************************************************

MODULE = XML::Sablotron	        PACKAGE = XML::Sablotron::DOM::Document

SV*
_new(object, sit)
     SV*      object
     SV*      sit
     CODE:
     SDOM_Document doc;
     SablotSituation situa = SIT_SMART(sit);
     SablotCreateDocument(situa, &doc);
     RETVAL = __createNode(situa, doc);
     OUTPUT:
     RETVAL

void
_freeDocument(object, ...) 
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Document doc = DOC_HANDLE(object);
     SablotDestroyDocument(situa, doc);

char*
toString(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     char* buff;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( doc );
     SablotLockDocument(situa, doc);
     DE( situa, SDOM_docToString(situa, doc, (SDOM_char**)&buff) );
     RETVAL = buff;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (buff) SablotFree(buff);

SV* 
cloneNode(object, node, deep, ...)
     SV*      object
     SV*      node
     int      deep
     ALIAS:
     importNode = 1
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node cloned;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_cloneForeignNode(situa, doc, 
                               NODE_HANDLE(node), deep, &cloned) );
     RETVAL = __createNode(situa, cloned);
     OUTPUT:
     RETVAL

SV*
documentElement(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle;
     SDOM_NodeType type;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     RETVAL = &PL_sv_undef;
     DE( situa, SDOM_getFirstChild(situa, doc, &handle) );
     while ( handle ) {
         DE( situa, SDOM_getNodeType(situa, handle, &type) );         
         if ( type == SDOM_ELEMENT_NODE ) {
             RETVAL = __createNode(situa, handle);
             break;
         };
         DE( situa, SDOM_getNextSibling(situa, handle, &handle) );         
     };
     OUTPUT:
     RETVAL

SV*
createElement(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createElement(situa, doc, &handle, name) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createAttribute(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createAttribute(situa, doc, &handle, name) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createTextNode(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createTextNode(situa, doc, &handle, value) );     
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createCDATASection(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createCDATASection(situa, doc, &handle, value) );     
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createEntityReference(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle=NULL;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createEntity(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle=NULL;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createProcessingInstruction(object, target, data, ...)
     SV*      object
     char*    target
     char*    data
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, 
         SDOM_createProcessingInstruction(situa, doc, &handle, target, data) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createComment(object, value, ...)
     SV*      object
     char*    value
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createComment(situa, doc, &handle, value) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createDocumentType(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle=NULL;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createDocumentFragment(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle=NULL;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createNotation(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node handle=NULL;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     /* _fix_ put the API call here */
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createElementNS(object, namespaceURI, qname, ...)
     SV*      object
     char*    namespaceURI
     char*    qname
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createElementNS(situa, doc, &handle, 
                                     (SDOM_char*)namespaceURI, 
                                     (SDOM_char*)qname) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

SV*
createAttributeNS(object, namespaceURI, qname, ...)
     SV*      object
     char*    namespaceURI
     char*    qname
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node handle;
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN(doc);
     DE( situa, SDOM_createAttributeNS(situa, doc, &handle, 
                                       (SDOM_char*)namespaceURI, 
                                       (SDOM_char*)qname) );
     RETVAL = __createNode(situa, handle);
     OUTPUT:
     RETVAL

void
lockDocument(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Document doc = DOC_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( doc );
     DE( situa, SablotLockDocument(situa, doc) );

#************************************************************
#* ELEMENT *
#************************************************************

MODULE = XML::Sablotron	        PACKAGE = XML::Sablotron::DOM::Element

char*
getAttribute(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_char* value;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     /* _fix_ check null values */
     DE( situa, SDOM_getAttribute(situa, node, 
                      (SDOM_char*)name, (SDOM_char**)&value) );
     RETVAL = (char*)value;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (value) SablotFree(value);

void
setAttribute(object, name, value, ...)
     SV*      object
     char*    name
     char*    value
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     /* _fix_ check null values */
     DE( situa, SDOM_setAttribute(situa, node, 
                      (SDOM_char*)name, (SDOM_char*)value) );
    
void
removeAttribute(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     /* _fix_ check null values */
     DE( situa, SDOM_removeAttribute(situa, node, (SDOM_char*)name) );


SV*
getAttributeNode(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node att;
     CN(node);
     DE( situa, SDOM_getAttributeNode(situa, node, (SDOM_char*)name, &att) );
     if (att) {
         RETVAL = __createNode(situa, att);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL


SV*
setAttributeNode(object, att, ...)
     SV*      object
     SV*      att
     CODE:
     SV* sit = SIT_PARAM(3);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node attnode = NODE_HANDLE(att);
     SDOM_Node replaced;
     CN(node);
     CN(attnode);
     DE( situa, SDOM_setAttributeNode(situa, node, attnode, &replaced) );
     if (replaced) {
         RETVAL = __createNode(situa, replaced);
     } else {
         RETVAL = &PL_sv_undef;
     };
     OUTPUT:
     RETVAL

SV*
removeAttributeNode(object, att, ...)
     SV*      object
     SV*      att
     CODE:
     SV* sit = SIT_PARAM(3);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node attnode = NODE_HANDLE(att);
     SDOM_Node removed;
     CN(node);
     CN(attnode);
     DE( situa, SDOM_removeAttributeNode(situa, node, attnode, &removed) );
     RETVAL = __createNode(situa, removed);
     OUTPUT:
     RETVAL


char*
getAttributeNS(object, namespaceURI, localName, ...)
     SV*      object
     char*    namespaceURI
     char*    localName
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_char* value;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     DE( situa, SDOM_getAttributeNS(situa, node, 
                                    (SDOM_char*)namespaceURI, 
                                    (SDOM_char*)localName, &value) );
     RETVAL = (char*)value;
     OUTPUT:
     RETVAL

void
setAttributeNS(object, namespaceURI, qName, value, ...)
     SV*      object
     char*    namespaceURI
     char*    qName
     char*    value
     CODE:
     SV* sit = SIT_PARAM(5);
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     DE( situa, SDOM_setAttributeNS(situa, node, 
                                    (SDOM_char*)namespaceURI, 
                                    (SDOM_char*)qName,
                                    (SDOM_char*)value) );

void
removeAttributeNS(object, namespaceURI, localName, ...)
     SV*      object
     char*    namespaceURI
     char*    localName
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node attnode;
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     DE( situa, SDOM_getAttributeNodeNS(situa, node, 
                                        (SDOM_char*)namespaceURI, 
                                        (SDOM_char*)localName, &attnode) );
     if (attnode) {
         DE( situa, SDOM_removeAttributeNode(situa, node, attnode, &attnode) );
     };


SV*
getAttributeNodeNS(object, namespaceURI, localName, ...)
     SV*      object
     char*    namespaceURI
     char*    localName
     CODE:
     SV* sit = SIT_PARAM(4);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node attnode;
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     DE( situa, SDOM_getAttributeNodeNS(situa, node, 
                                        (SDOM_char*)namespaceURI, 
                                        (SDOM_char*)localName, &attnode) );
     if (attnode) {
         RETVAL = __createNode(situa, attnode);
     } else {
         RETVAL = &PL_sv_undef;
     };
     OUTPUT:
     RETVAL


SV*
setAttributeNodeNS(object, att, ...)
     SV*      object
     SV*      att
     CODE:
     SV* sit = SIT_PARAM(3);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node attnode = NODE_HANDLE(att);
     SDOM_Node replaced;
     CN(node);
     CN(attnode);
     DE( situa, SDOM_setAttributeNodeNS(situa, node, attnode, &replaced) );
     if (replaced) {
         RETVAL = __createNode(situa, replaced);
     } else {
         RETVAL = &PL_sv_undef;
     };
     OUTPUT:
     RETVAL


int
hasAttribute(object, name, ...)
     SV*      object
     char*    name
     CODE:
     SV* sit = SIT_PARAM(3);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node att;
     CN(node);
     DE( situa, SDOM_getAttributeNode(situa, node, (SDOM_char*)name, &att) );
     if (att) {
         RETVAL = 1;
     } else {
         RETVAL = 0;
     };
     OUTPUT:
     RETVAL


int
hasAttributeNS(object, namespaceURI, localName, ...)
     SV*      object
     char*    namespaceURI
     char*    localName
     CODE:
     SV* sit = SIT_PARAM(4);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node att;
     CN(node);
     DE( situa, SDOM_getAttributeNodeNS(situa, node, 
                                        (SDOM_char*)namespaceURI,
                                        (SDOM_char*)localName,
                                        &att) );
     if (att) {
         RETVAL = 1;
     } else {
         RETVAL = 0;
     };
     OUTPUT:
     RETVAL


AV* 
_getAttributes(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     int i;
     int len;
     SDOM_NodeList list;
     SDOM_Node node = NODE_HANDLE(object);
     SablotSituation situa = SIT_SMART(sit);
     CN( node );
     DE( situa, SDOM_getAttributeList(situa, node, &list) );
     RETVAL = (AV*)sv_2mortal((SV*)newAV());
     SDOM_getNodeListLength(situa, list, &len);
     for (i = 0; i < len; i++) {
         SDOM_Node node;
         SDOM_getNodeListItem(situa, list, i, &node);
         av_push(RETVAL, __createNode(situa, node));
     }
     SDOM_disposeNodeList(situa, list);
     OUTPUT:
     RETVAL

SV*
_attrIndex(index, object, ...)
     int      index
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(3);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     SDOM_Node attr;
     CN(node);
     DE( situa, SDOM_getAttributeNodeIndex(situa, node, index, &attr) );
     if (attr) {
         RETVAL = __createNode(situa, attr);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL

int
_attrCount(object, ...)
     SV*      object
     ALIAS:
     hasAttributes = 1
     CODE:
     int ret;
     SV* sit = SIT_PARAM(2);
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     DE( situa, SDOM_getAttributeNodeCount(situa, node, &ret) );
     RETVAL = ret;
     OUTPUT:
     RETVAL


char*
toString(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     char* buff;
     SDOM_Document doc;
     SablotSituation situa;
     SDOM_Node node = NODE_HANDLE(object);
     CN( node );
     situa = SIT_SMART(sit);
     SDOM_getOwnerDocument(situa, node, &doc);
     CN( doc );
     SablotLockDocument(situa, doc);
     DE( situa, SDOM_nodeToString(situa, doc, node, (SDOM_char**)&buff) );
     RETVAL = buff;
     OUTPUT:
     RETVAL
     CLEANUP:
     if (buff) SablotFree(buff);

#************************************************************
#* ATTRIBUTE *
#************************************************************

MODULE = XML::Sablotron	        PACKAGE = XML::Sablotron::DOM::Attribute


SV*
ownerElement(object, ...)
     SV*      object
     CODE:
     SV* sit = SIT_PARAM(2);
     SDOM_Node parent;
     SablotSituation situa = SIT_SMART(sit);
     SDOM_Node node = NODE_HANDLE(object);
     CN(node);
     DE( situa, SDOM_getAttributeElement(situa, node, &parent) );
     if (parent) {
         /* _fix_ check memory leaks */
         RETVAL = __createNode(situa, parent);
     } else {
         RETVAL = &PL_sv_undef;
     }
     OUTPUT:
     RETVAL


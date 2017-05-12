/*
 *  tinyxml.c
 *
 *  Created by xant on 2/17/06.
 *
 */

#include "txml.h"
#include "string.h"
#include "stdlib.h"
#include "unistd.h"
#include "ctype.h"
#ifdef USE_ICONV
#include "iconv.h"
#endif
#include "errno.h"

#define XML_ELEMENT_NONE   0
#define XML_ELEMENT_START  1
#define XML_ELEMENT_VALUE  2
#define XML_ELEMENT_END    3
#define XML_ELEMENT_UNIQUE 4

//
// INTERNAL HELPERS
//
enum {
    ENCODING_UTF8,
    ENCODING_UTF16LE,
    ENCODING_UTF16BE,
    ENCODING_UTF32LE,
    ENCODING_UTF32BE,
    ENCODING_UTF7
} XML_ENCODING;

static int
detect_encoding(char *buffer) {
    if (buffer[0] == (char)0xef &&
        buffer[1] == (char)0xbb &&
        buffer[2] == (char)0xbf) 
    {
        return ENCODING_UTF8;
    } else if (buffer[0] == (char)0xff && 
               buffer[1] == (char)0xfe && 
               buffer[3] != (char)0x00)
    {
        return ENCODING_UTF16LE; // utf-16le
    } else if (buffer[0] == (char)0xfe && 
               buffer[1] == (char)0xff)
    {
        return ENCODING_UTF16BE; // utf-16be
    } else if (buffer[0] == (char)0xff &&
               buffer[1] == (char)0xfe &&
               buffer[2] == (char)0x00 &&
               buffer[3] == (char)0x00)
    {
        return ENCODING_UTF32LE; //utf-32le
    } else if (buffer[0] == 0 &&
               buffer[1] == 0 &&
               buffer[2] == (char)0xfe &&
               buffer[3] == (char)0xff)
    {
        return ENCODING_UTF32BE; //utf-32be
    } else if (buffer[0] == (char)0x2b &&
               buffer[1] == (char)0x2f &&
               buffer[2] == (char)0x76)
    {
        return ENCODING_UTF7;
    }
    return -1;
}

int errno;

static char *
dexmlize(char *string)
{
    int i, p = 0;
    int len = strlen(string);
    char *unescaped = NULL;

    if (string) {
        unescaped = (char *)calloc(1, len+1); // inlude null-byte
        for (i = 0; i < len; i++) {
            switch (string[i]) {
                case '&':
                    if (string[i+1] == '#') {
                        char *marker;
                        i+=2;
                        marker = &string[i];
                        if (string[i] >= '0' && string[i] <= '9' &&
                            string[i+1] >= '0' && string[i+1] <= '9')
                        {
                            char chr = 0;
                            i+=2;
                            if (string[i] >= '0' && string[i] <= '9' && string[i+1] == ';')
                                i++;
                            else if (string[i] == ';')
                                ; // do nothing
                            else
                                return NULL;
                            chr = (char)strtol(marker, NULL, 0);
                            unescaped[p] = chr;
                        }
                    } else if (strncmp(&string[i], "&amp;", 5) == 0) {
                        i+=4;
                        unescaped[p] = '&';
                    } else if (strncmp(&string[i], "&lt;", 4) == 0) {
                        i+=3;
                        unescaped[p] = '<';
                    } else if (strncmp(&string[i], "&gt;", 4) == 0) {
                        i+=3;
                        unescaped[p] = '>';
                    } else if (strncmp(&string[i], "&quot;", 6) == 0) {
                        i+=5;
                        unescaped[p] = '"';
                    } else if (strncmp(&string[i], "&apos;", 6) == 0) {
                        i+=5;
                        unescaped[p] = '\'';
                    } else {
                        return NULL;
                    }
                    p++;
                    break;
                default:
                    unescaped[p] = string[i];
                    p++;
            }
        }
    }
    return unescaped;
}

static char *
xmlize(char *string)
{
    int i, p = 0;
    int len;
    int bufsize;
    char *escaped = NULL;

    len = strlen(string);
    if (string) {
        bufsize = len+1;
        escaped = (char *)calloc(1, bufsize); // inlude null-byte
        for (i = 0; i < len; i++) {
            switch (string[i]) {
                case '&':
                    bufsize += 5;
                    escaped = realloc(escaped, bufsize);
                    memset(escaped+p, 0, bufsize-p);
                    strcpy(&escaped[p], "&amp;");
                    p += 5;
                    break;
                case '<':
                    bufsize += 4;
                    escaped = realloc(escaped, bufsize);
                    memset(escaped+p, 0, bufsize-p);
                    strcpy(&escaped[p], "&lt;");
                    p += 4;
                    break;
                case '>':
                    bufsize += 4;
                    escaped = realloc(escaped, bufsize);
                    memset(escaped+p, 0, bufsize-p);
                    strcpy(&escaped[p], "&gt;");
                    p += 4;
                    break;
                case '"':
                    bufsize += 6;
                    escaped = realloc(escaped, bufsize);
                    memset(escaped+p, 0, bufsize-p);
                    strcpy(&escaped[p], "&quot;");
                    p += 6;
                    break;
                case '\'':
                    bufsize += 6;
                    escaped = realloc(escaped, bufsize);
                    memset(escaped+p, 0, bufsize-p);
                    strcpy(&escaped[p], "&apos;");
                    p += 6;
                    break;
/*
                    bufsize += 5;
                    escaped = realloc(escaped, bufsize);
                    memset(escaped+p, 0, bufsize-p);
                    sprintf(&escaped[p], "&#%02d;", string[i]);
                    p += 5;
                    break;
*/
                default:
                    escaped[p] = string[i];
                    p++;
            }
        }
    }
    return escaped;
}

// reimplementing strcasestr since it's not present on all systems
// and we still need to be portable.
static char *txml_strcasestr (char *h, char *n)
{
   char *hp, *np = n, *match = 0;
   if(!*np) {
       return hp;
   }

   for (hp = h; *hp; hp++) {
       if (toupper(*hp) == toupper(*np)) {
           if (!match) {
               match = hp;
           }
               if(!*++np) {
                   return match;
           }
       } else {
           if (match) { 
               match = 0;
               np = n;
           }
       }
   }

   return NULL; 
}

//
// TXML IMPLEMENTATION
//

TXml *
XmlCreateContext()
{
    TXml *xml;

    xml = (TXml *)calloc(1, sizeof(TXml));
    xml->cNode = NULL;
    xml->ignoreWhiteSpaces = 1; // defaults to old behaviour (all blanks are not taken into account)
    xml->ignoreBlanks = 1; // defaults to old behaviour (all blanks are not taken into account)
    TAILQ_INIT(&xml->rootElements);
    xml->head = NULL;
    // default is UTF-8
    sprintf(xml->outputEncoding, "utf-8");
    sprintf(xml->documentEncoding, "utf-8");
    return xml;
}

void
XmlResetContext(TXml *xml)
{
    XmlNode *rNode, *tmp;
    TAILQ_FOREACH_SAFE(rNode, &xml->rootElements, siblings, tmp) {
        TAILQ_REMOVE(&xml->rootElements, rNode, siblings);
        XmlDestroyNode(rNode);
    }
    if(xml->head)
        free(xml->head);
    xml->head = NULL;
}

TXml *
XmlGetContext(XmlNode *node)
{
    XmlNode *p = node;
    do {
        if (!p->parent)
            return p->context;
        p = p->parent;
    } while (p);
    return NULL; // should never arrive here
}

void
XmlSetDocumentEncoding(TXml *xml, char *encoding)
{
    strncpy(xml->documentEncoding, encoding, sizeof(xml->documentEncoding)-1);
}

void
XmlSetOutputEncoding(TXml *xml, char *encoding)
{
    strncpy(xml->outputEncoding, encoding, sizeof(xml->outputEncoding)-1);
}

void
XmlDestroyContext(TXml *xml)
{
    XmlResetContext(xml);
    free(xml);
}

static void
XmlSetNodePath(XmlNode *node, XmlNode *parent)
{
    unsigned int pathLen;

    if (node->path)
        free(node->path);

    if(parent) {
        if(parent->path) {
            pathLen = (unsigned int)strlen(parent->path)+1+strlen(node->name)+1;
            node->path = (char *)calloc(1, pathLen);
            sprintf(node->path, "%s/%s", parent->path, node->name);
        } else {
            pathLen = (unsigned int)strlen(parent->name)+1+strlen(node->name)+1;
            node->path = (char *)calloc(1, pathLen);
            sprintf(node->path, "%s/%s", parent->name, node->name);
        }
    } else { /* root node */
        node->path = (char *)calloc(1, strlen(node->name)+2);
        sprintf(node->path, "/%s", node->name);
    }

}

XmlNode *
XmlCreateNode(char *name, char *value, XmlNode *parent)
{
    XmlNode *node = NULL;
    node = (XmlNode *)calloc(1, sizeof(XmlNode));
    if(!node || !name)
        return NULL;

    TAILQ_INIT(&node->attributes);
    TAILQ_INIT(&node->children);
    TAILQ_INIT(&node->namespaces);
    TAILQ_INIT(&node->knownNamespaces);

    node->name = strdup(name);

    if (parent)
        XmlAddChildNode(parent, node);
    else
        XmlSetNodePath(node, NULL);

    if(value && strlen(value) > 0)
        node->value = strdup(value);
    else
        node->value = (char *)calloc(1, 1);
    return node;
}

void
XmlDestroyNode(XmlNode *node)
{
    XmlNodeAttribute *attr, *attrTmp;
    XmlNode *child, *childTmp;
    XmlNamespace *ns, *nsTmp;
    XmlNamespaceSet *item, *itemTmp;

    TAILQ_FOREACH_SAFE(attr, &node->attributes, list, attrTmp) {
        TAILQ_REMOVE(&node->attributes, attr, list);
        if(attr->name)
            free(attr->name);
        if(attr->value)
            free(attr->value);
        free(attr);
    }

    TAILQ_FOREACH_SAFE(child, &node->children, siblings, childTmp) {
        TAILQ_REMOVE(&node->children, child, siblings);
        XmlDestroyNode(child);
    }

    TAILQ_FOREACH_SAFE(item, &node->knownNamespaces, next, itemTmp) {
        TAILQ_REMOVE(&node->knownNamespaces, item, next);
        free(item);
    }

    TAILQ_FOREACH_SAFE(ns, &node->namespaces, list, nsTmp) {
        TAILQ_REMOVE(&node->namespaces, ns, list);
        XmlDestroyNamespace(ns);
    }

    if(node->name)
        free(node->name);
    if(node->path)
        free(node->path);
    if(node->value)
        free(node->value);
    free(node);
}

XmlErr
XmlSetNodeValue(XmlNode *node, char *val)
{
    if(!val)
        return XML_BADARGS;

    if(node->value)
        free(node->value);
    node->value = strdup(val);
    return XML_NOERR;
}

/* quite useless */
char *
XmlGetNodeValue(XmlNode *node)
{
    if(!node)
        return NULL;
    return node->value;
}

static void
XmlRemoveChildNode(XmlNode *parent, XmlNode *child)
{
    int i;
    XmlNode *p, *tmp;
    TAILQ_FOREACH_SAFE(p, &parent->children, siblings, tmp) {
        if (p == child) {
            TAILQ_REMOVE(&parent->children, p, siblings);
            p->parent = NULL;
            XmlSetNodePath(p, NULL);
            break;
        }
    }
}

static void
XmlUpdateKnownNamespaces(XmlNode *node)
{
    XmlNode *p;
    XmlNamespace *ns;
    XmlNamespaceSet *newItem;
    
    // first empty actual list
    if (!TAILQ_EMPTY(&node->knownNamespaces)) {
        XmlNamespaceSet *oldItem;
        while((oldItem = TAILQ_FIRST(&node->knownNamespaces))) {
            TAILQ_REMOVE(&node->knownNamespaces, oldItem, next);
            free(oldItem);
        }
    }

    // than start populating the list with actual default namespace
    if (node->cns) {
        newItem = (XmlNamespaceSet *)calloc(1, sizeof(XmlNamespaceSet));
        newItem->ns = node->cns;
        TAILQ_INSERT_TAIL(&node->knownNamespaces, newItem, next);
    } else if (node->hns) {
        newItem = (XmlNamespaceSet *)calloc(1, sizeof(XmlNamespaceSet));
        newItem->ns = node->hns;
        TAILQ_INSERT_TAIL(&node->knownNamespaces, newItem, next);
    }

    // add all namespaces defined by this node
    TAILQ_FOREACH(ns, &node->namespaces, list) {
        if (ns->name) { // skip an eventual default namespace since has been handled earlier
            newItem = (XmlNamespaceSet *)calloc(1, sizeof(XmlNamespaceSet));
            newItem->ns = ns;
            TAILQ_INSERT_TAIL(&node->knownNamespaces, newItem, next);
        }
    }

    // and now import namespaces already valid in the scope of our parent
    if (node->parent) {
        if (!TAILQ_EMPTY(&node->parent->knownNamespaces)) {
            XmlNamespaceSet *parentItem;
            TAILQ_FOREACH(parentItem, &node->parent->knownNamespaces, next) {
                if (parentItem->ns->name) { // skip the default namespace
                    newItem = (XmlNamespaceSet *)calloc(1, sizeof(XmlNamespaceSet));
                    newItem->ns = parentItem->ns;
                    TAILQ_INSERT_TAIL(&node->knownNamespaces, newItem, next);
                }
            }
        } else { // this shouldn't happen until knownNamespaces is properly kept synchronized
            TAILQ_FOREACH(ns, &node->parent->namespaces, list) {
                if (ns->name) { // skip the default namespace
                    newItem = (XmlNamespaceSet *)calloc(1, sizeof(XmlNamespaceSet));
                    newItem->ns = ns;
                    TAILQ_INSERT_TAIL(&node->knownNamespaces, newItem, next);
                }
            }
        }
    }
}

// update the hinerited namespace across a branch.
// This happens if a node (with all its childnodes) is moved across
// 2 different documents. The hinerited namespace must be updated
// accordingly to the new context, so we traverse the branches
// under the moved node to update the the hinerited namespace where
// necessary.
// NOTE: if a node defines a new default itself, it's not necessary
//       to go deeper in that same branch
static void
XmlUpdateBranchNamespace(XmlNode *node, XmlNamespace *ns)
{
    XmlNode *child;
    XmlNamespaceSet *nsItem;

    if (node->hns != ns && !node->cns) // skip update if not necessary
        node->hns = ns; 

    XmlUpdateKnownNamespaces(node);

    if (node->ns) { // we are bound to a specific ns.... let's see if it's known
        int missing = 1;

        TAILQ_FOREACH(nsItem, &node->knownNamespaces, next) 
            if (strcmp(node->ns->uri, nsItem->ns->uri) == 0) 
                if (!(node->ns->name && !nsItem->ns->name) && strcmp(node->ns->name, nsItem->ns->name) == 0)
                    missing = 0;

        if (missing) {
            XmlNamespace *newNS;
            XmlNamespaceSet *newItem;
            char *newAttr;

            newNS = XmlAddNamespace(node, node->ns->name, node->ns->uri);
            node->ns = newNS;
            newItem = (XmlNamespaceSet *)calloc(1, sizeof(XmlNamespaceSet));
            newItem->ns = newNS;
            TAILQ_INSERT_TAIL(&node->knownNamespaces, newItem, next);
            newAttr = malloc(strlen(newNS->name)+7); // prefix + xmlns + :
            sprintf(newAttr, "xmlns:%s", node->ns->name);
            // enforce the definition for our namepsace in the new context
            XmlAddAttribute(node, newAttr, node->ns->uri); 
            free(newAttr);
        }
    }

    TAILQ_FOREACH(child, &node->children, siblings) // update our descendants
        XmlUpdateBranchNamespace(child, node->cns?node->cns:node->hns); // recursion here
}

XmlErr
XmlAddChildNode(XmlNode *parent, XmlNode *child)
{
    TXml *srcCtx, *dstCtx;
    if(!child)
        return XML_BADARGS;

    // now we can update the parent
    if (child->parent)
        XmlRemoveChildNode(child->parent, child);

    TAILQ_INSERT_TAIL(&parent->children, child, siblings);
    child->parent = parent;

    // udate/propagate the default namespace (if any) to the newly attached node 
    // (and all its descendants)
    // Also scan for unknown namespaces defined/used in the newly attached branch
    XmlUpdateBranchNamespace(child, parent->cns?parent->cns:parent->hns);
    XmlSetNodePath(child, parent);
    return XML_NOERR;
}

XmlNode *
XmlNextSibling(XmlNode *node)
{
    return TAILQ_NEXT(node, siblings);
}

XmlNode *
XmlPrevSibling(XmlNode *node)
{
    return TAILQ_PREV(node, nodelistHead, siblings);
}

XmlErr
XmlAddRootNode(TXml *xml, XmlNode *node)
{
    if(!node)
        return XML_BADARGS;

    if (!TAILQ_EMPTY(&xml->rootElements) && !xml->allowMultipleRootNodes) {
        return XML_MROOT_ERR;
    }

    TAILQ_INSERT_TAIL(&xml->rootElements, node, siblings);
    node->context = xml;
    XmlUpdateKnownNamespaces(node);
    return XML_NOERR;
}

XmlErr
XmlAddAttribute(XmlNode *node, char *name, char *val)
{
    XmlNodeAttribute *attr;

    if(!name || !node)
        return XML_BADARGS;

    attr = (XmlNodeAttribute *)calloc(1, sizeof(XmlNodeAttribute));
    attr->name = strdup(name);
    attr->value = val?strdup(val):strdup("");
    attr->node = node;

    TAILQ_INSERT_TAIL(&node->attributes, attr, list);
    return XML_NOERR;
}

int
XmlRemoveAttribute(XmlNode *node, unsigned long index)
{
    XmlNodeAttribute *attr, *tmp;
    int count = 0;

    TAILQ_FOREACH_SAFE(attr, &node->attributes, list, tmp) {
        if (count++ == index) {
            TAILQ_REMOVE(&node->attributes, attr, list);
            free(attr->name);
            free(attr->value);
            free(attr);
            return XML_NOERR;
        }
    }
    return XML_GENERIC_ERR;
}

void
XmlClearAttributes(XmlNode *node)
{
    XmlNodeAttribute *attr, *tmp;
    unsigned int nAttrs = 0;
    int i;

    TAILQ_FOREACH_SAFE(attr, &node->attributes, list, tmp) {
        TAILQ_REMOVE(&node->attributes, attr, list);
        free(attr->name);
        free(attr->value);
        free(attr);
    }
}

XmlNodeAttribute
*XmlGetAttributeByName(XmlNode *node, char *name)
{
    int i;
    XmlNodeAttribute *attr;
    TAILQ_FOREACH(attr, &node->attributes, list) {
        if (strcmp(attr->name, name) == 0)
            return attr;
    }
    return NULL;
}

XmlNodeAttribute
*XmlGetAttribute(XmlNode *node, unsigned long index)
{
    XmlNodeAttribute *attr;
    int count = 0;
    TAILQ_FOREACH(attr, &node->attributes, list) {
        if (count++ == index)
            return attr;
    }
    return NULL;
}

static XmlErr
XmlExtraNodeHandler(TXml *xml, char *content, char type)
{
    XmlNode *newNode = NULL;
    XmlErr res = XML_NOERR;
    char fakeName[256];

    sprintf(fakeName, "_fakenode_%d_", type);
    newNode = XmlCreateNode(fakeName, content, xml->cNode);
    newNode->type = type;
    if(!newNode || !newNode->name) {
        /* XXX - ERROR MESSAGES HERE */
        res = XML_GENERIC_ERR;
        goto _node_done;
    }
    if(xml->cNode) {
        res = XmlAddChildNode(xml->cNode, newNode);
        if(res != XML_NOERR) {
            XmlDestroyNode(newNode);
            goto _node_done;
        }
    } else {
        res = XmlAddRootNode(xml, newNode) ;
        if(res != XML_NOERR) {
            XmlDestroyNode(newNode);
            goto _node_done;
        }
    }
_node_done:
    return res;
}

static XmlErr
XmlStartHandler(TXml *xml, char *element, char **attr_names, char **attr_values)
{
    XmlNode *newNode = NULL;
    unsigned int offset = 0;
    XmlErr res = XML_NOERR;
    char *nodename = NULL;
    char *nssep = NULL;
    char *cnsUri = NULL;
    XmlNamespace *cns = NULL;

    if(!element || strlen(element) == 0)
        return XML_BADARGS;

    // unescape read element to be used as nodename
    nodename = dexmlize(element);
    if (!nodename)
        return XML_BAD_CHARS;

    if ((nssep = strchr(nodename, ':'))) { // a namespace is defined
        XmlNamespace *ns = NULL;
        *nssep = 0; // nodename now starts with the null-terminated namespace 
                    // followed by the real name (nssep + 1)
        newNode = XmlCreateNode(nssep+1, NULL, xml->cNode);
        if (xml->cNode)
            ns = XmlGetNamespaceByName(xml->cNode, nodename);
        if (!ns) { 
            // TODO - Error condition
        }
        newNode->ns = ns;
    } else {
        newNode = XmlCreateNode(nodename, NULL, xml->cNode);
    }
    free(nodename);
    if(!newNode || !newNode->name) {
        /* XXX - ERROR MESSAGES HERE */
        return XML_MEMORY_ERR;
    }
    /* handle attributes if present */
    if(attr_names && attr_values) {
        while(attr_names[offset] != NULL) {
            char *nsp = NULL;
            res = XmlAddAttribute(newNode, attr_names[offset], attr_values[offset]);
            if(res != XML_NOERR) {
                XmlDestroyNode(newNode);
                goto _start_done;
            }
            if ((nsp = txml_strcasestr(attr_names[offset], "xmlns"))) {
                if ((nssep = strchr(nsp, ':'))) {  // declaration of a new namespace
                    *nssep = 0;
                    XmlAddNamespace(newNode, nssep+1, attr_values[offset]);
                } else { // definition of the default ns
                    newNode->cns = XmlAddNamespace(newNode, NULL, attr_values[offset]);
                }
            }
            offset++;
        }
    }
    if(xml->cNode) {
        res = XmlAddChildNode(xml->cNode, newNode);
        if(res != XML_NOERR) {
            XmlDestroyNode(newNode);
            goto _start_done;
        }
    } else {
        res = XmlAddRootNode(xml, newNode) ;
        if(res != XML_NOERR) {
            XmlDestroyNode(newNode);
            goto _start_done;
        }
    }
    xml->cNode = newNode;

_start_done:
    return res;
}

static XmlErr
XmlEndHandler(TXml *xml, char *element)
{
    XmlNode *parent;
    if(xml->cNode) {
        parent = xml->cNode->parent;
        xml->cNode = parent;
        return XML_NOERR;
    }
    return XML_GENERIC_ERR;
}

static XmlErr
XmlValueHandler(TXml *xml, char *text)
{
    char *p;
    if(text) {
        // remove heading blanks
        if (xml->ignoreWhiteSpaces) { // first check if we want to ignore any kind of whitespace between nodes
                                      // (which means : 'no whitespace-only values' and 'any value will be trimmed')
            while((*text == ' ' || *text == '\t' || *text == '\r' || *text == '\n') &&
                   *text != 0)
            {
                text++;
            }
        } else if (xml->ignoreBlanks) { // or if perhaps we want to consider pure whitespaces: ' '
                                        // as part of the value. (but we still want to skip newlines and
                                        // tabs, which are assumed to be there to prettify the text layout
            while((*text == '\t' || *text == '\r' || *text == '\n') && 
                   *text != 0)
            {
                text++;
            }
        }

        p = text+strlen(text)-1;

        // remove trailing blanks
        if (xml->ignoreWhiteSpaces) { // XXX - read above
            while((*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') &&
                    p != text)
            {
                *p = 0;
                p--;
            }
        } else if (xml->ignoreBlanks) { // XXX = read above
            while((*p == '\t' || *p == '\r' || *p == '\n') &&
                    p != text)
            {
                *p = 0;
                p--;
            }
        }

        if(xml->cNode)  {
            char *rtext = dexmlize(text);
            if (!rtext)
                return XML_BAD_CHARS;
            XmlSetNodeValue(xml->cNode, rtext);
            free(rtext);
        } else {
            fprintf(stderr, "cTag == NULL while handling a value!!");
        }
        return XML_NOERR;
    }
    return XML_GENERIC_ERR;
}


XmlErr
XmlParseBuffer(TXml *xml, char *buf)
{
    XmlErr err = XML_NOERR;
    int state = XML_ELEMENT_NONE;
    char *p = buf;
    unsigned int i;
    char *start = NULL;
    char *end = NULL;
    char **attrs = NULL;
    char **values = NULL;
    unsigned int nAttrs = 0;
    char *mark = NULL;
    int quote = 0;

    XmlResetContext(xml); // reset the context if we are parsing a new document

    //unsigned int offset = fileStat.st_size;

#define XML_FREE_ATTRIBUTES \
    if(nAttrs>0) {\
        for(i = 0; i < nAttrs; i++) {\
            if(attrs[i]) \
                free(attrs[i]);\
            if(values[i]) \
                free(values[i]);\
        }\
        free(attrs);\
        attrs = NULL;\
        free(values);\
        values = NULL;\
        nAttrs = 0;\
    }\

// skip tabs and new-lines
#define SKIP_BLANKS(__p) \
    while((*__p == '\t' || *__p == '\r' || *__p == '\n') && *__p != 0) __p++;

// skip any kind of whitespace
#define SKIP_WHITESPACES(__p) \
    SKIP_BLANKS(__p); \
    while(*__p == ' ') {\
        __p++;\
        SKIP_BLANKS(__p);\
        if(*__p == 0) break;\
    }

#define ADVANCE_ELEMENT(__p) \
    while(*__p != '>' && *__p != ' ' && *__p != '\t' && *__p != '\r' && *__p != '\n' && *__p != 0) __p++;

#define ADVANCE_TO_ATTR_VALUE(__p) \
    while(*__p != '=' && *__p != ' ' && *__p != '\t' && *__p != '\r' && *__p != '\n' && *__p != 0) __p++;\
    SKIP_WHITESPACES(__p);

    while(*p != 0) {
        if (xml->ignoreWhiteSpaces) {
            SKIP_WHITESPACES(p);
        } else if (xml->ignoreBlanks) {
            SKIP_BLANKS(p);
        }
        if(*p == '<') { // an xml entity starts here
            p++;
            if(*p == '/') { // check if this is a closing node
                p++;
                SKIP_WHITESPACES(p);
                mark = p;
                while(*p != '>' && *p != 0)
                    p++;
                if(*p == '>') {
                    end = (char *)malloc(p-mark+1);
                    if(!end) {
                        err = XML_MEMORY_ERR;
                        goto _parser_err;
                    }
                    strncpy(end, mark, p-mark);
                    end[p-mark] = 0;
                    p++;
                    state = XML_ELEMENT_END;
                    err = XmlEndHandler(xml, end);
                    free(end);
                    if(err != XML_NOERR)
                        goto _parser_err;
                }
            } else if(strncmp(p, "!ENTITY", 8) == 0) { // XXX - IGNORING !ENTITY NODES
                p += 8;
                mark = p;
                p = strstr(mark, ">");
                if(!p) {
                    fprintf(stderr, "Can't find where the !ENTITY element ends\n");
                    err = XML_PARSER_GENERIC_ERR;
                    goto _parser_err;
                }
                p++;
            } else if(strncmp(p, "!NOTATION", 9) == 0) { // XXX - IGNORING !NOTATION NODES
                p += 9;
                mark = p;
                p = strstr(mark, ">");
                if(!p) {
                    fprintf(stderr, "Can't find where the !NOTATION element ends\n");
                    err = XML_PARSER_GENERIC_ERR;
                    goto _parser_err;
                }
                p++;
            } else if(strncmp(p, "!ATTLIST", 8) == 0) { // XXX - IGNORING !ATTLIST NODES
                p += 8;
                mark = p;
                p = strstr(mark, ">");
                if(!p) {
                    fprintf(stderr, "Can't find where the !NOTATION element ends\n");
                    err = XML_PARSER_GENERIC_ERR;
                    goto _parser_err;
                }
                p++;
            } else if(strncmp(p, "!--", 3) == 0) { /* comment */
                char *comment = NULL;
                p += 3; /* skip !-- */
                mark = p;
                p = strstr(mark, "-->");
                if(!p) {
                    /* XXX - TODO - This error condition must be handled asap */
                }
                comment = (char *)calloc(1, p-mark+1);
                if(!comment) {
                    err = XML_MEMORY_ERR;
                    goto _parser_err;
                }
                strncpy(comment, mark, p-mark);
                err = XmlExtraNodeHandler(xml, comment, XML_NODETYPE_COMMENT);
                free(comment);
                p+=3;
            } else if(strncmp(p, "![", 2) == 0) {
                mark = p;
                p += 2; /* skip ![ */
                SKIP_WHITESPACES(p);
                //mark = p;
                if(strncmp(p, "CDATA", 5) == 0) {
                    char *cdata = NULL;
                    p+=5;
                    SKIP_WHITESPACES(p);
                    if(*p != '[') {
                        fprintf(stderr, "Unsupported entity type at \"... -->%15s\"", mark);
                        err = XML_PARSER_GENERIC_ERR;
                        goto _parser_err;
                    }
                    mark = ++p;
                    p = strstr(mark, "]]>");
                    if(!p) {
                        /* XXX - TODO - This error condition must be handled asap */
                    }
                    cdata = (char *)calloc(1, p-mark+1);
                    if(!cdata) {
                        err = XML_MEMORY_ERR;
                        goto _parser_err;
                    }
                    strncpy(cdata, mark, p-mark);
                    err = XmlExtraNodeHandler(xml, cdata, XML_NODETYPE_CDATA);
                    free(cdata);
                    p+=3;
                } else {
                    fprintf(stderr, "Unsupported entity type at \"... -->%15s\"", mark);
                    err = XML_PARSER_GENERIC_ERR;
                    goto _parser_err;
                }
            } else if(*p =='?') { /* head */
                char *encoding = NULL;
                p++;
                mark = p;
                p = strstr(mark, "?>");
                if(xml->head) // we are going to overwrite existing head (if any)
                    free(xml->head); /* XXX - should notify this behaviour? */
                xml->head = (char *)calloc(1, p-mark+1);
                strncpy(xml->head, mark, p-mark);
                encoding = strstr(xml->head, "encoding=");
                if (encoding) {
                    encoding += 9;
                    if (*encoding == '"' || *encoding == '\'') {
                        int encoding_length = 0;
                        quote = *encoding;
                        encoding++;
                        end = (char *)strchr(encoding, quote);
                        if (!end) {
                            fprintf(stderr, "Unquoted encoding string in the <?xml> section");
                            err = XML_PARSER_GENERIC_ERR;
                            goto _parser_err;
                        }
                        encoding_length = end - encoding;
                        if (encoding_length < sizeof(xml->documentEncoding)) {
                            strncpy(xml->documentEncoding, encoding, encoding_length);
                            // ensure to terminate it, if we are reusing a context we 
                            // could have still the old encoding there possibly with a 
                            // longer name (so poisoning the buffer)
                            xml->documentEncoding[encoding_length] = 0; 
                        }
                    }
                } else {
                }
                p+=2;
            } else { /* start tag */
                attrs = NULL;
                values = NULL;
                nAttrs = 0;
                state = XML_ELEMENT_START;
                SKIP_WHITESPACES(p);
                mark = p;
                ADVANCE_ELEMENT(p);
                start = (char *)malloc(p-mark+2);
                if(start == NULL)
                    return XML_MEMORY_ERR;
                strncpy(start, mark, p-mark);

                if(*p == '>' && *(p-1) == '/') {
                    start[p-mark-1] = 0;
                    state = XML_ELEMENT_UNIQUE;
                } else {
                    start[p-mark] = 0;
                }

                SKIP_WHITESPACES(p);
                if(*p == '>' || (*p == '/' && *(p+1) == '>')) {
                    if (*p == '/') {
                        state = XML_ELEMENT_UNIQUE;
                        p++;
                    }
                }
                while(*p != '>' && *p != 0) {
                    mark = p;
                    ADVANCE_TO_ATTR_VALUE(p);
                    if(*p == '=') {
                        char *tmpAttr = (char *)malloc(p-mark+1);
                        strncpy(tmpAttr, mark, p-mark);
                        tmpAttr[p-mark] = 0;
                        p++;
                        SKIP_WHITESPACES(p);
                        if(*p == '"' || *p == '\'') {
                            quote = *p;
                            p++;
                            mark = p;
                            while(*p != 0) {
                                if (*p == quote) {
                                    if (*(p+1) != quote) // handle quote escaping
                                        break;
                                    else
                                        p++;
                                }
                                p++;
                            }
                            if(*p == quote) {
                                char *dexmlized;
                                char *tmpVal = (char *)malloc(p-mark+2);
                                int i, j=0;
                                for (i = 0; i < p-mark; i++) {
                                    if ( mark[i] == quote && mark[i+1] == mark[i] )
                                        i++;
                                    tmpVal[j++] = mark[i]; 
                                }
                                tmpVal[p-mark] = 0;
                                /* add new attribute */
                                nAttrs++;
                                attrs = (char **)realloc(attrs, sizeof(char *)*(nAttrs+1));
                                attrs[nAttrs-1] = tmpAttr;
                                attrs[nAttrs] = NULL;
                                values = (char **)realloc(values, sizeof(char *)*(nAttrs+1));
                                dexmlized = dexmlize(tmpVal);
                                free(tmpVal);
                                values[nAttrs-1] = dexmlized;
                                values[nAttrs] = NULL;
                                p++;
                                SKIP_WHITESPACES(p);
                            }
                            else {
                                free(tmpAttr);
                            }
                        } /* if(*p == '"' || *p == '\'') */
                        else {
                            free(tmpAttr);
                        }
                    } /* if(*p=='=') */
                    if(*p == '/' && *(p+1) == '>') {
                        p++;
                        state = XML_ELEMENT_UNIQUE;
                    }
                } /* while(*p != '>' && *p != 0) */
                err = XmlStartHandler(xml, start, attrs, values);
                if(err != XML_NOERR) {
                    XML_FREE_ATTRIBUTES
                    free(start);
                    return err;
                }
                if(state == XML_ELEMENT_UNIQUE) {
                    err = XmlEndHandler(xml, start);
                    if(err != XML_NOERR) {
                        XML_FREE_ATTRIBUTES
                        free(start);
                        return err;
                    }
                }
                XML_FREE_ATTRIBUTES
                free(start);
                p++;
            } /* end of start tag */
        } /* if(*p == '<') */
        else if(state == XML_ELEMENT_START) {
            state = XML_ELEMENT_VALUE;
            mark = p;
            while(*p != '<' && *p != 0)
                p++;
            if(*p == '<') { // p now points to the beginning of next node
                char *value = (char *)malloc(p-mark+1);
                strncpy(value, mark, p-mark);
                value[p-mark] = 0;
                err = XmlValueHandler(xml, value);
                if(value)
                    free(value);
                if(err != XML_NOERR)
                    return(err);
                //p++;
            }
        }
        else {
            /* XXX */
            p++;
        }
    } // while(*p != 0)

_parser_err:
    return err;
}

#ifdef WIN32
//************************************************************************
// BOOL W32LockFile (FILE* filestream)
//
// locks the specific file for exclusive access, nonblocking
//
// returns 0 on success
//************************************************************************
static BOOL
W32LockFile (FILE* filestream)
{
    BOOL res = TRUE;
    HANDLE hFile = INVALID_HANDLE_VALUE;
    unsigned long size = 0;
    int fd = 0;

    // check params
    if (!filestream)
        goto __exit;

    // get handle from stream
    fd = _fileno (filestream);
    hFile = (HANDLE)_get_osfhandle(fd);

    // lock file until access is permitted
    size = GetFileSize(hFile, NULL);
    res = LockFile (hFile, 0, 0, size, 0);
    if (res)
        res = 0;
__exit:
    return res;
}

//************************************************************************
// BOOL W32UnlockFile (FILE* filestream)
//
// unlocks the specific file locked by W32LockFile
//
// returns 0 on success
//************************************************************************
static BOOL
W32UnlockFile (FILE* filestream)
{
    BOOL res = TRUE;
    HANDLE hFile = INVALID_HANDLE_VALUE;
    unsigned long size = 0;
    int tries = 0;
    int fd = 0;

    // check params
    if (!filestream)
        goto __exit;

    // get handle from stream
    fd = _fileno (filestream);
    hFile = (HANDLE)_get_osfhandle(fd);

    // unlock
    size = GetFileSize(hFile, NULL);
    res = UnlockFile (hFile, 0, 0, size, 0);
    if (res)
        res = 0;

__exit:
    return res;
}
#endif // #ifdef WIN32

static XmlErr
XmlFileLock(FILE *file)
{
    int tries = 0;
    if(file) {
#ifdef WIN32
        while(W32LockFile(file) != 0) {
#else
        while(ftrylockfile(file) != 0) {
#endif
    // warning("can't obtain a lock on xml file %s... waiting (%d)", xmlFile, tries);
            tries++;
            if(tries>5) {
                fprintf(stderr, "sticky lock on xml file!!!");
                return XML_GENERIC_ERR;
            }
            sleep(1);
        }
        return XML_NOERR;
    }
    return XML_GENERIC_ERR;
}

static XmlErr
XmlFileUnlock(FILE *file)
{
    if(file) {
#ifdef WIN32
        if(W32UnlockFile(file) == 0)
#else
        funlockfile(file);

#endif
        return XML_NOERR;
    }
    return XML_GENERIC_ERR;
}

XmlErr
XmlParseFile(TXml *xml, char *path)
{
    FILE *inFile;
    char *buffer;
    XmlErr err;
    struct stat fileStat;
    int rc = 0;

    inFile = NULL;
    err = XML_NOERR;
    if(!path)
        return XML_BADARGS;
    rc = stat(path, &fileStat);
    if (rc != 0)
        return XML_BADARGS;
    xml->cNode = NULL;
    if(fileStat.st_size>0) {
        inFile = fopen(path, "r");
        if(inFile) {
#ifdef USE_ICONV
            iconv_t ich;
            char *iconvIn, *iconvOut;
#endif
            char *out;
            size_t rb, cb, ilen, olen;
            char *encoding_from = NULL;

            if(XmlFileLock(inFile) != XML_NOERR) {
                fprintf(stderr, "Can't lock %s for opening ", path);
                return -1;
            }
            olen = ilen = fileStat.st_size;
            buffer = (char *)malloc(ilen+1);
            rb = fread(buffer, 1, ilen, inFile);
            if (ilen != rb) {
                fprintf(stderr, "Can't read %s content", path);
                return -1;
            }
            buffer[ilen] = 0;
            switch(detect_encoding(buffer)) {
                case ENCODING_UTF16LE:
                    encoding_from = "UTF-16LE";
                    break;
                case ENCODING_UTF16BE:
                    encoding_from = "UTF-16BE";
                    break;
                case ENCODING_UTF32LE:
                    encoding_from = "UTF-32LE";
                    break;
                case ENCODING_UTF32BE:
                    encoding_from = "UTF-32BE";
                    break;
                case ENCODING_UTF7:
                    encoding_from = "UTF-7";
                    olen = ilen*2; // we need a bigger output buffer
                    break;
            }
            if (encoding_from) {
#ifdef USE_ICONV
                ich = iconv_open ("UTF-8", encoding_from);
                if (ich == (iconv_t)(-1)) {
                    fprintf(stderr, "Can't init iconv: %s\n", strerror(errno));
                    free(buffer);
                    XmlFileUnlock(inFile);
                    fclose(inFile);
                    return -1;
                }
                out = (char *)calloc(1, olen);
                iconvIn = buffer;
                iconvOut = out;
                cb = iconv(ich, &iconvIn, &ilen, &iconvOut, &olen);
                if (cb == -1) {
                    fprintf(stderr, "Can't convert encoding: %s\n", strerror(errno));
                    free(buffer);
                    free(out);
                    XmlFileUnlock(inFile);
                    fclose(inFile);
                    return -1;
                }
                free(buffer); // release initial buffer
                buffer = out; // point to the converted buffer
                iconv_close(ich);
#else
                fprintf(stderr, "Iconv missing: can't open file %s encoded in %s. Convert it to utf8 and try again\n",
                        path, encoding_from);
                free(buffer);
                XmlFileUnlock(inFile);
                fclose(inFile);
                return -1;
#endif
            }
            err = XmlParseBuffer(xml, buffer);
            free(buffer); // release either the initial or the converted buffer
            XmlFileUnlock(inFile);
            fclose(inFile);
        } else {
            fprintf(stderr, "Can't open xmlfile %s\n", path);
            return -1;
        }
    } else {
        fprintf(stderr, "Can't stat xmlfile %s\n", path);
        return -1;
    }
    return XML_NOERR;
}

char *
XmlDumpBranch(TXml *xml, XmlNode *rNode, unsigned int depth)
{
    unsigned int i, n;
    char *out = NULL;
    int outOffset = 0;
    char *startTag;
    int startOffset = 0;
    char *endTag;
    int endOffset = 0;
    char *childDump;
    int childOffset = 0;
    char *value = NULL;
    int nameLen = 0;
    int nsNameLen = 0;
    XmlNodeAttribute *attr;
    XmlNode *child;
    unsigned long nAttrs;


    if (rNode->value) {
        if (rNode->type == XML_NODETYPE_SIMPLE) {
            value = xmlize(rNode->value);
        } else {
            value = strdup(rNode->value);
        }
    }

    if(rNode->name)
        nameLen = (unsigned int)strlen(rNode->name);
    else
        return NULL;

    /* First check if this is a special node (a comment or a CDATA) */
    if(rNode->type == XML_NODETYPE_COMMENT) {
        out = malloc(strlen(value)+depth+9);
        *out = 0;
        if (xml->ignoreBlanks) {
            for(n = 0; n < depth; n++)
                out[n] = '\t';
            sprintf(out+depth, "<!--%s-->\n", value);
        } else {
            sprintf(out+depth, "<!--%s-->", value);
        }
        return out;
    } else if(rNode->type == XML_NODETYPE_CDATA) {
        out = malloc(strlen(value)+depth+14);
        *out = 0;
        if (xml->ignoreBlanks) {
            for(n = 0; n < depth; n++)
                out[n] = '\t';
            sprintf(out+depth, "<![CDATA[%s]]>\n", value);
        } else {
            sprintf(out+depth, "<![CDATA[%s]]>", value);
        }
        return out;
    }

    childDump = (char *)calloc(1, 1);

    if (rNode->ns && rNode->ns->name)
        nsNameLen = (unsigned int)strlen(rNode->ns->name)+1;
    startTag = (char *)calloc(1, depth+nameLen+nsNameLen+7); // :/<>\n
    endTag = (char *)calloc(1, depth+nameLen+nsNameLen+7);

    if (xml->ignoreBlanks) {
        for(startOffset = 0; startOffset < depth; startOffset++)
            startTag[startOffset] = '\t';
    }
    startTag[startOffset++] = '<';
    if (rNode->ns && rNode->ns->name) {
        // TODO - optimize
        strcpy(startTag + startOffset, rNode->ns->name);
        startOffset += nsNameLen;
        startTag[startOffset-1] = ':';
    }
    memcpy(startTag + startOffset, rNode->name, nameLen);
    startOffset += nameLen;
    nAttrs = XmlCountAttributes(rNode);
    if(nAttrs>0) {
        for(i = 0; i < nAttrs; i++) {
            attr = XmlGetAttribute(rNode, i);
            if(attr) {
                int anLen, avLen;
                char *attr_value;

                attr_value = xmlize(attr->value);
                anLen = strlen(attr->name);
                avLen = strlen (attr_value);
                startTag = (char *)realloc(startTag, startOffset + anLen + avLen + 8);
                sprintf(startTag + startOffset, " %s=\"%s\"", attr->name, attr_value);
                startOffset += anLen + avLen + 4;
                if (attr_value)
                    free(attr_value);
            }
        }
    }
    if((value && *value) || !TAILQ_EMPTY(&rNode->children)) {
        if(!TAILQ_EMPTY(&rNode->children)) {
            if (xml->ignoreBlanks) {
                strcpy(startTag + startOffset, ">\n");
                startOffset += 2;
                for(endOffset = 0; endOffset < depth; endOffset++)
                    endTag[endOffset] = '\t';
            } else {
                startTag[startOffset++] = '>';
            }
            TAILQ_FOREACH(child, &rNode->children, siblings) {
                char *childBuff = XmlDumpBranch(xml, child, depth+1); /* let's recurse */
                if(childBuff) {
                    int childBuffLen = strlen(childBuff);
                    childDump = (char *)realloc(childDump, childOffset+childBuffLen+1);
                    // ensure copying the null-terminating byte as well
                    memcpy(childDump + childOffset, childBuff, childBuffLen + 1);
                    childOffset += childBuffLen;
                    free(childBuff);
                }
            }
        } else {
            // TODO - allow to specify a flag to determine if we want white spaces or not
            startTag[startOffset++] = '>';
        }
        startTag[startOffset] = 0; // ensure null-terminating the start-tag
        strcpy(endTag + endOffset, "</");
        endOffset += 2;
        if (rNode->ns && rNode->ns->name) {
            // TODO - optimize
            strcpy(endTag + endOffset, rNode->ns->name);
            endOffset += nsNameLen;
            endTag[endOffset-1] = ':';
        }
        sprintf(endTag + endOffset, "%s>", rNode->name);
        endOffset += nameLen + 1;
        if (xml->ignoreBlanks)
            endTag[endOffset++] = '\n';
        endTag[endOffset] = 0; // ensure null-terminating
        out = (char *)malloc(depth+strlen(startTag)+strlen(endTag)+
            (value?strlen(value)+1:1)+strlen(childDump)+3);
        strcpy(out, startTag);
        outOffset += startOffset;
        if(value && *value) { // skip also if value is an empty string (not only if it's a null pointer)
            if(!TAILQ_EMPTY(&rNode->children)) {
                if (xml->ignoreBlanks) {
                    for(; outOffset < depth; outOffset++)
                        out[outOffset] = '\t';
                }
                if (value) {
                    sprintf(out + outOffset, "%s", value);
                    outOffset += strlen(value);
                    if (xml->ignoreBlanks)
                        out[outOffset++] = '\n';
                }
            }
            else {
                if (value)
                    strcpy(out + outOffset, value);
                    outOffset += strlen(value);
            }
        }
        memcpy(out + outOffset, childDump, childOffset);
        outOffset += childOffset;
        strcpy(out + outOffset, endTag);
    }
    else {
        strcpy(startTag + startOffset, "/>");
        startOffset += 2;
        if (xml->ignoreBlanks)
            startTag[startOffset++] = '\n';
        startTag[startOffset] = 0;
        out = strdup(startTag);
    }
    free(startTag);
    free(endTag);
    free(childDump);
    if (value)
        free(value);
    return out;
}

char *
XmlDump(TXml *xml, int *outlen)
{
    char *dump;
    XmlNode *rNode;
    char *branch;
    unsigned int i;
#ifdef USE_ICONV
    int doConversion = 0;
#endif
    char head[256]; // should be enough
    int hLen;
    unsigned int offset;

    memset(head, 0, sizeof(head));
    if (xml->head) {
        int quote;
        char *start, *end, *encoding;
        char *initial = strdup(xml->head);
        start = strstr(initial, "encoding=");
        if (start) {
            *start = 0;
            encoding = start+9;
            if (*encoding == '"' || *encoding == '\'') {
                quote = *encoding;
                encoding++;
                end = (char *)strchr(encoding, quote);
                if (!end) {
                    /* TODO - Error Messages */
                } else if ((end-encoding) >= sizeof(xml->outputEncoding)) {
                    /* TODO - Error Messages */
                }
                *end = 0;
                // check if document encoding matches
                if (strncasecmp(encoding, xml->documentEncoding, end-encoding) != 0) {
                    /* TODO - Error Messages */
                } 
                if (strncasecmp(encoding, xml->outputEncoding, end-encoding) != 0) {
#ifdef USE_ICONV
                    snprintf(head, sizeof(head), "%sencoding=\"%s\"%s",
                        initial, xml->outputEncoding, ++end);
                    doConversion = 1;
#else
                    fprintf(stderr, "Iconv missing: will not convert output to %s\n", xml->outputEncoding);
                    snprintf(head, sizeof(head), "%s", xml->head);
#endif
                } else {
                    snprintf(head, sizeof(head), "%s", xml->head);
                }

            }
        } else {
#ifdef USE_ICONV
            if (xml->outputEncoding && strcasecmp(xml->outputEncoding, "utf-8") != 0) {
                doConversion = 1;
                fprintf(stderr, "Iconv missing: will not convert output to %s\n", xml->outputEncoding);
            }
            snprintf(head, sizeof(head), "xml version=\"1.0\" encoding=\"%s\"", 
                xml->outputEncoding?xml->outputEncoding:"utf-8");
#else
            if (xml->outputEncoding && strcasecmp(xml->outputEncoding, "utf-8") != 0) {
                fprintf(stderr, "Iconv missing: will not convert output to %s\n", xml->outputEncoding);
            }
            snprintf(head, sizeof(head), "xml version=\"1.0\" encoding=\"utf-8\"");
#endif
        }
        free(initial);
    } else {
#ifdef USE_ICONV
        if (xml->outputEncoding && strcasecmp(xml->outputEncoding, "utf-8") != 0) {
            doConversion = 1;
        }
        snprintf(head, sizeof(head), "xml version=\"1.0\" encoding=\"%s\"", 
            xml->outputEncoding?xml->outputEncoding:"utf-8");
#else
        if (xml->outputEncoding && strcasecmp(xml->outputEncoding, "utf-8") != 0) {
            fprintf(stderr, "Iconv missing: will not convert output to %s\n", xml->outputEncoding);
        }
        snprintf(head, sizeof(head), "xml version=\"1.0\" encoding=\"utf-8\"");
#endif
    }
    hLen = strlen(head);
    dump = malloc(hLen+6);
    sprintf(dump, "<?%s?>\n", head);
    offset = hLen +5;
    TAILQ_FOREACH(rNode, &xml->rootElements, siblings) {
        branch = XmlDumpBranch(xml, rNode, 0);
        if(branch) {
            int bLen = strlen(branch);
            dump = (char *)realloc(dump, offset + bLen + 1);
            // ensure copying the null-terminating byte as well
            memcpy(dump + offset, branch, bLen + 1); 
            offset += bLen;
            free(branch);
        }
    }
    if (outlen) // check if we need to report the output size
        *outlen = strlen(dump);
#ifdef USE_ICONV
    if (doConversion) {
        iconv_t ich;
        size_t ilen, olen, cb;
        char *out;
        char *iconvIn;
        char *iconvOut;
        ilen = strlen(dump);
        // the most expensive conversion would be from ascii to utf-32/ucs-4
        // ( 4 bytes for each char )
        olen = ilen * 4; 
        // we still don't know how big the output buffer is going to be
        // we will update outlen later once iconv tell us the size
        if (outlen) 
            *outlen = olen;
        out = (char *)calloc(1, olen);
        ich = iconv_open (xml->outputEncoding, xml->documentEncoding);
        if (ich == (iconv_t)(-1)) {
            free(dump);
            free(out);
            fprintf(stderr, "Can't init iconv: %s\n", strerror(errno));
            return NULL;
        }
        iconvIn = dump;
        iconvOut = out;
        cb = iconv(ich, &iconvIn, &ilen, &iconvOut, &olen);
        if (cb == -1) {
            free(dump);
            free(out);
            fprintf(stderr, "Error from iconv: %s\n", strerror(errno));
            return NULL;
        }
        iconv_close(ich);
        free(dump); // release the old buffer (in the original encoding)
        dump = out;
        if (outlen) // update the outputsize if we have to
            *outlen -= olen;
    }
#endif
    return(dump);
}

XmlErr
XmlSave(TXml *xml, char *xmlFile)
{
    size_t rb;
    struct stat fileStat;
    FILE *saveFile = NULL;
    char *dump = NULL;
    int dumpLen = 0;
    char *backup = NULL;
    char *backupPath = NULL;
    FILE *backupFile = NULL;


    if (stat(xmlFile, &fileStat) == 0) {
        if(fileStat.st_size>0) { /* backup old profiles */
            saveFile = fopen(xmlFile, "r");
            if(!saveFile) {
                fprintf(stderr, "Can't open %s for reading !!", xmlFile);
                return XML_GENERIC_ERR;
            }
            if(XmlFileLock(saveFile) != XML_NOERR) {
                fprintf(stderr, "Can't lock %s for reading ", xmlFile);
                return XML_GENERIC_ERR;
            }
            backup = (char *)malloc(fileStat.st_size+1);
            rb = fread(backup, 1, fileStat.st_size, saveFile);
            if (rb != fileStat.st_size) {
                fprintf(stderr, "Can't read %s content", xmlFile);
                return -1;
            }
            backup[fileStat.st_size] = 0;
            XmlFileUnlock(saveFile);
            fclose(saveFile);
            backupPath = (char *)malloc(strlen(xmlFile)+5);
            sprintf(backupPath, "%s.bck", xmlFile);
            backupFile = fopen(backupPath, "w+");
            if(backupFile) {
                if(XmlFileLock(backupFile) != XML_NOERR) {
                    fprintf(stderr, "Can't lock %s for writing ", backupPath);
                    free(backupPath);
                    free(backup);
                    return XML_GENERIC_ERR;
                }
                fwrite(backup, 1, fileStat.st_size, backupFile);
                XmlFileUnlock(backupFile);
                fclose(backupFile);
            }
            else {
                fprintf(stderr, "Can't open backup file (%s) for writing! ", backupPath);
                free(backupPath);
                free(backup);
                return XML_GENERIC_ERR;
            }
            free(backupPath);
            free(backup);
        } /* end of backup */
    }
    dump = XmlDump(xml, &dumpLen);
     if(dump && dumpLen) {
        saveFile = fopen(xmlFile, "w+");
        if(saveFile) {
            if(XmlFileLock(saveFile) != XML_NOERR) {
                fprintf(stderr, "Can't lock %s for writing ", xmlFile);
                free(dump);
                return XML_GENERIC_ERR;
            }
            fwrite(dump, 1, dumpLen, saveFile);
            free(dump);
            XmlFileUnlock(saveFile);
            fclose(saveFile);
        }
        else {
            fprintf(stderr, "Can't open output file %s", xmlFile);
            if(!saveFile) {
                free(dump);
                return XML_GENERIC_ERR;
            }
        }
    }
    return XML_NOERR;
}

unsigned long
XmlCountAttributes(XmlNode *node)
{
    XmlNodeAttribute *attr;
    int cnt = 0;
    TAILQ_FOREACH(attr, &node->attributes, list) 
        cnt++;
    return cnt;
}

unsigned long
XmlCountChildren(XmlNode *node)
{
    XmlNode *child;
    int cnt = 0; 
    TAILQ_FOREACH(child, &node->children, siblings)
        cnt++;
    return cnt;
}

unsigned long
XmlCountBranches(TXml *xml)
{
    XmlNode *node;
    int cnt = 0;
    TAILQ_FOREACH(node, &xml->rootElements, siblings)
        cnt++;
    return cnt;
}

XmlErr
XmlRemoveNode(TXml *xml, char *path)
{
    /* XXX - UNIMPLEMENTED */
    return XML_GENERIC_ERR;
}

XmlErr
XmlRemoveBranch(TXml *xml, unsigned long index)
{
    int count = 0;
    XmlNode *branch, *tmp;
    TAILQ_FOREACH_SAFE(branch, &xml->rootElements, siblings, tmp) {
        if (count++ == index) {
            TAILQ_REMOVE(&xml->rootElements, branch, siblings);
            XmlDestroyNode(branch);
            return XML_NOERR;
        }
    }
    return XML_GENERIC_ERR;
}

XmlNode
*XmlGetChildNode(XmlNode *node, unsigned long index)
{
    XmlNode *child;
    int count = 0;
    if(!node)
        return NULL;
    TAILQ_FOREACH(child, &node->children, siblings) {
        if (count++ == index) {
            return child;
            break;
        }
    }
    return NULL;
}

/* XXX - if multiple children shares the same name, only the first is returned */
XmlNode
*XmlGetChildNodeByName(XmlNode *node, char *name)
{
    XmlNode *child;
    unsigned int i = 0;
    char *attrName = NULL;
    char *attrVal = NULL;
    char *nodeName = NULL;
    int nameLen = 0;
    char *p;

    if(!node)
        return NULL;

    nodeName = strdup(name); // make a copy to avoid changing the provided buffer
    nameLen = strlen(nodeName);

    if (nodeName[nameLen-1] == ']') {
        p = strchr(nodeName, '[');
        *p = 0;
        p++;
        if (sscanf(p, "%d]", &i) == 1) {
            i--;
        } else if (*p == '@') {
            p++;
            p[strlen(p)-1] = 0;
            attrName = p;
            attrVal = strchr(p, '=');
            if (attrVal) {
                *attrVal = 0;
                attrVal++;
                if (*attrVal == '\'' || *attrVal == '"') {
                    char quote = *attrVal;
                    int n, j=0;
                    // inplace dequoting
                    attrVal++;
                    for (n = 0; attrVal[n] != 0; n++) {
                        if (attrVal[n] == quote) {
                            if (n && attrVal[n-1] == quote) { // quote escaping (XXX - perhaps out of spec)
                                if (j)
                                    j--;
                            } else {
                                attrVal[n] = 0;
                                break;
                            }
                        }
                        if (j != n)
                            attrVal[j] = attrVal[n];
                        j++;
                    }

                }
            }
        }
    }

    TAILQ_FOREACH(child, &node->children, siblings) {
        if(strcmp(child->name, nodeName) == 0) {
            if (attrName) {
                XmlNodeAttribute *attr = XmlGetAttributeByName(child, attrName);
                if (attr) {
                    if (attrVal) {
                        char *dexmlized = dexmlize(attrVal);
                        if (strcmp(attr->value, dexmlized) != 0) {
                            free(dexmlized);
                            continue; // the attr value doesn't match .. let's skip to next matching node
                        }
                        free(dexmlized);
                    }
                    free(nodeName);
                    return child;
                }
            } else if (i == 0) {
                free(nodeName);
                return child;
            } else {
                i--;
            }
        }
    }
    free(nodeName);
    return NULL;
}

XmlNode *
XmlGetNode(TXml *xml, char *path)
{
    char *buff, *walk;
    char *tag;
    unsigned long i = 0;
    XmlNode *cNode = NULL;
    XmlNode *wNode = NULL;
//#ifndef WIN32
    char *brkb;
//#endif
    if(!path)
        return NULL;

    buff = strdup(path);
    walk = buff;

    // check if we are allowing multiple rootnodes to determine
    // if it's included in the path or not
    if (xml->allowMultipleRootNodes) {
        /* skip leading slashes '/' */
        while(*walk == '/')
            walk++;

        /* select the root node */
#ifndef WIN32
        tag  = strtok_r(walk, "/", &brkb);
#else
        tag = strtok(walk, "/");
#endif
        if(!tag) {
            free(buff);
            return NULL;
        }

        for(i = 0; i < XmlCountBranches(xml); i++) {
            wNode = XmlGetBranch(xml, i);
            if(strcmp(wNode->name, tag) == 0) {
                cNode = wNode;
                break;
            }
        }
        /* now cNode points to the root node ... let's find requested node */
#ifndef WIN32
        tag = strtok_r(NULL, "/", &brkb);
#else
        tag = strtok(NULL, "/");
#endif
    } else { // no multiple rootnodes
        cNode = XmlGetBranch(xml, 0);
        // TODO - this could be done in a cleaner and more efficient way
        if (*walk != '/') {
            buff = malloc(strlen(walk)+2);
            sprintf(buff, "/%s", walk);
            free(walk);
            walk = buff;
        }
#ifndef WIN32
        tag = strtok_r(walk, "/", &brkb);
#else
        tag = strtok(walk, "/");
#endif
    }

    if(!cNode) {
        free(buff);
        return NULL;
    }

    while(tag) {
        XmlNode *tmp;
        wNode = XmlGetChildNodeByName(cNode, tag);
        if(!wNode) {
            free(buff);
            return NULL;
        }
        cNode = wNode; // update current node
#ifndef WIN32
        tag = strtok_r(NULL, "/", &brkb);
#else
        tag = strtok(NULL, "/");
#endif
    }

    free(buff);
    return cNode;
}

XmlNode
*XmlGetBranch(TXml *xml, unsigned long index)
{
    XmlNode *node;
    int cnt = 0;
    if(!xml)
        return NULL;
    TAILQ_FOREACH(node, &xml->rootElements, siblings) {
        if (cnt++ == index)
            return node;
    }
    return NULL;
}

XmlErr
XmlSubstBranch(TXml *xml, unsigned long index, XmlNode *newBranch)
{
    XmlNode *branch, *tmp;
    int cnt = 0;
    TAILQ_FOREACH_SAFE(branch, &xml->rootElements, siblings, tmp) {
        if (cnt++ == index) {
            TAILQ_INSERT_BEFORE(branch, newBranch, siblings);
            TAILQ_REMOVE(&xml->rootElements, branch, siblings);
            return XML_NOERR;
        }
    }
    return XML_LINKLIST_ERR;
}

XmlNamespace *
XmlCreateNamespace(char *nsName, char *nsUri) {
    XmlNamespace *newNS;
    newNS = (XmlNamespace *)calloc(1, sizeof(XmlNamespace));
    if (nsName)
        newNS->name = strdup(nsName);
    newNS->uri = strdup(nsUri);
    return newNS;
}

void
XmlDestroyNamespace(XmlNamespace *ns)
{
    if (ns) {
        if (ns->name)
            free(ns->name);
        if (ns->uri)
            free(ns->uri);
        free(ns);
    }
}

XmlNamespace *
XmlAddNamespace(XmlNode *node, char *nsName, char *nsUri) {
    XmlNamespace *newNS = NULL;
    if (!node || !nsUri)
        return NULL;

    if ((newNS = XmlCreateNamespace(nsName, nsUri)))
        TAILQ_INSERT_TAIL(&node->namespaces, newNS, list);
    return newNS;
}

XmlNamespace *
XmlGetNamespaceByName(XmlNode *node, char *nsName) {
    XmlNamespaceSet *item;
    // TODO - check if node->knownNamespaces needs to be updated
    TAILQ_FOREACH(item, &node->knownNamespaces, next) {
        if (item->ns->name && strcmp(item->ns->name, nsName) == 0)
            return item->ns;
    }
    return NULL;
}

XmlNamespace *
XmlGetNamespaceByUri(XmlNode *node, char *nsUri) {
    XmlNamespaceSet *item;
    // TODO - check if node->knownNamespaces needs to be updated
    TAILQ_FOREACH(item, &node->knownNamespaces, next) {
        if (strcmp(item->ns->uri, nsUri) == 0)
            return item->ns;
    }
    return NULL;
}

XmlNamespace *
XmlGetNodeNamespace(XmlNode *node) {
    XmlNode *p = node->parent;
    if (node->ns) // my namespace
        return node->ns;
    if (node->hns) // hinerited namespace
        return node->hns;
    // search for a default naspace defined in our hierarchy
    // this should happen only if a node has been moved across 
    // multiple documents and it's hinerited namespace has been lost
    while (p) { 
        if (p->cns)
            return p->cns;
        p = p->parent;
    }
    return NULL;
}

XmlErr
XmlSetNodeCNamespace(XmlNode *node, XmlNamespace *ns) {
    if (!node || !ns)
        return XML_BADARGS;
    
    node->cns = ns;
    return XML_NOERR;
}

XmlErr
XmlSetNodeNamespace(XmlNode *node, XmlNamespace *ns) {
    if (!node || !ns)
        return XML_BADARGS;
    
    node->ns = ns;
    return XML_NOERR;
}


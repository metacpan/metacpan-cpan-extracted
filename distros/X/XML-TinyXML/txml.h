/*
 *  tinyxml.h
 *
 *  Created by xant on 2/17/06.
 *
 */

#ifndef __TINYXML_H__
#define __TINYXML_H__

#define XmlErr int
#define XML_NOERR 0
#define XML_GENERIC_ERR -1
#define XML_BADARGS -2
#define XML_UPDATE_ERR -2
#define XML_OPEN_FILE_ERR -3
#define XML_PARSER_GENERIC_ERR -4
#define XML_MEMORY_ERR -5
#define XML_LINKLIST_ERR -6
#define XML_BAD_CHARS -7
#define XML_MROOT_ERR -8

#include "bsd_queue.h"
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifdef WIN32
#include <winsock2.h> // for w32lock/unlock functions
#include <io.h>
/* strings */
#if !defined snprintf
#define snprintf _snprintf
#endif

#if !defined strncasecmp
#define strncasecmp _strnicmp
#endif

#if !defined strcasecmp
#define strcasecmp _stricmp
#endif

#if !defined strdup
#define strdup _strdup
#endif

/* files */
#if !defined stat
#define stat _stat
#endif

/* time */
#if !defined sleep
#define sleep(_duration) (Sleep(_duration * 1000))
#endif

#endif // WIN32

struct __XmlNode;
struct __Txml;

typedef struct __XmlNamespace {
    char *name;
    char *uri;
    TAILQ_ENTRY(__XmlNamespace) list;
} XmlNamespace;

/**
    @type XmlNodeAttribute
    @brief One attribute associated to an element 
*/
typedef struct __XmlNodeAttribute {
    char *name; ///< the attribute name
    char *value; ///< the attribute value
    struct __XmlNode *node;
    TAILQ_ENTRY(__XmlNodeAttribute) list;
} XmlNodeAttribute;

typedef struct __XmlNamespaceSet {
    XmlNamespace *ns;
    TAILQ_ENTRY(__XmlNamespaceSet) next;
} XmlNamespaceSet;

typedef struct __XmlNode {
    char *path;
    char *name;
    struct __XmlNode *parent;
    char *value;
    TAILQ_HEAD(,__XmlNode) children;
    TAILQ_HEAD(,__XmlNodeAttribute) attributes;
#define XML_NODETYPE_SIMPLE 0
#define XML_NODETYPE_COMMENT 1
#define XML_NODETYPE_CDATA 2
    char type;
    XmlNamespace *ns;  // namespace of this node (if any)
    XmlNamespace *cns; // new default namespace defined by this node
    XmlNamespace *hns; // hinerited namespace (if any)
    // all namespaces valid in this scope ( implicit namespaces )
    TAILQ_HEAD(,__XmlNamespaceSet) knownNamespaces; 
    // storage for newly defined namespaces 
    // (needed keep track of allocated XmlNamspace structures for later release)
    TAILQ_HEAD(,__XmlNamespace) namespaces; 
    TAILQ_ENTRY(__XmlNode) siblings;
    struct __TXml *context; // set only if rootnode (otherwise it's always NULL)
} XmlNode;

TAILQ_HEAD(nodelistHead, __XmlNode);

typedef struct __TXml {
    XmlNode *cNode;
    TAILQ_HEAD(,__XmlNode) rootElements;
    char *head;
    char outputEncoding[64];  /* XXX probably oversized, 24 or 32 should be enough */
    char documentEncoding[64];
    int useNamespaces;
    int allowMultipleRootNodes;
    int ignoreWhiteSpaces;
    int ignoreBlanks;
} TXml;

/***
    @brief access next sibling of a node (if any)
    @arg pointer to a valid XmlNode structure
    @return pointer to next sibling if existing, NULL otherwise
*/
XmlNode *XmlNextSibling(XmlNode *node);

/***
    @brief access previous sibling of a node (if any)
    @arg pointer to a valid XmlNode structure
    @return pointer to previous sibling if existing, NULL otherwise
*/
XmlNode *XmlPrevSibling(XmlNode *node);

void XmlSetOutputEncoding(TXml *xml, char *encoding);
/***
    @brief allocates memory for an XmlNode. In case of errors NULL is returned 
    @arg name of the new node
    @arg value associated to the new node (can be NULL and specified later through XmlSetNodeValue function)
    @arg parent of the new node if present, NULL if this will be a root node
    @return the newly created node 
 */
XmlNode *XmlCreateNode(char *name,char *val,XmlNode *parent);
/*** 
    @brief associate a value to XmlNode *node. XML_NOERR is returned if no error occurs 
    @arg the node we want to modify
    @arg the value we want to set for node
    @return XML_NOERR if success , error code otherwise
 */
XmlErr XmlSetNodeValue(XmlNode *node,char *val);
/***
    @brief get value for an XmlNode
    @arg the XmlNode containing the value we want to access.
    @return returns value associated to XmlNode *node 
 */
char *XmlGetNodeValue(XmlNode *node);
/****
    @brief free resources for XmlNode *node and all its subnodes 
    @arg the XmlNode we want to destroy
 */
void XmlDestroyNode(XmlNode *node);
/*** 
    @brief Adds XmlNode *child to the children list of XmlNode *node 
    @arg the parent node
    @arg the new child
    @return return XML_NOERR on success, error code otherwise 
*/
XmlErr XmlAddChildNode(XmlNode *parent,XmlNode *child);
/***
    @brief Makes XmlNode *node a root node in context represented by TXml *xml 
    @arg the xml context pointer
    @arg the new root node
    @return XML_NOERR on success, error code otherwise
 */
XmlErr XmlAddRootNode(TXml *xml,XmlNode *node);
/***
    @brief add an attribute to XmlNode *node 
    @arg the XmlNode that we want to set attributes to 
    @arg the name of the new attribute
    @arg the value of the new attribute
    @return XML_NOERR on success, error code otherwise
 */
XmlErr XmlAddAttribute(XmlNode *node,char *name,char *val);
/***
    @brief substitute an existing branch with a new one
    @arg the xml context pointer
    @arg the index of the branch we want to substitute
    @arg the root of the new branch
    @reurn XML_NOERR on success, error code otherwise
 */
XmlErr XmlSubstBranch(TXml *xml,unsigned long index, XmlNode *newBranch);
/***
    @brief Remove a specific node from the xml structure
    XXX - UNIMPLEMENTED
 */
XmlErr XmlRemoveNode(TXml *xml,char *path);
/***
    XXX - UNIMPLEMENTED
 */
XmlErr XmlRemoveBranch(TXml *xml,unsigned long index);
/***
    @brief Returns the number of root nodes in the xml context 
    @arg the xml context pointer
    @return the number of root nodes found in the xml context
 */
unsigned long XmlCountBranches(TXml *xml);
/***
    @brief Returns the number of children of the given XmlNode
    @arg the node we want to query
    @return the number of children of queried node
 */
unsigned long XmlCountChildren(XmlNode *node);
/***
    @brief Returns the number of attributes of the given XmlNode
    @arg the node we want to query
    @return the number of attributes that are set for queried node
 */
unsigned long XmlCountAttributes(XmlNode *node);
/***
    @brief Returns the XmlNode at specified path
    @arg the xml context pointer
    @arg the path that references requested node. 
        This must be of formatted as a slash '/' separated list
        of node names ( ex. "tag_A/tag_B/tag_C" )
    @return the node at specified path
 */
XmlNode *XmlGetNode(TXml *xml, char *path);
/***
    @brief get the root node at a specific index
    @arg the xml context pointer
    @arg the index of the requested root node
    @return the root node at requested index

 */
XmlNode *XmlGetBranch(TXml *xml,unsigned long index);
/***
    @brief get the child at a specific index inside a node
    @arg the node 
    @arg the index of the child we are interested in
    @return the selected child node 
 */
XmlNode *XmlGetChildNode(XmlNode *node,unsigned long index);
/***
    @brief get the first child of an XmlNode whose name is 'name'
    @arg the parent node
    @arg the name of the desired child node
    @return the requested child node
 */
XmlNode *XmlGetChildNodeByName(XmlNode *node,char *name);

/***
    @brief parse a string buffer containing an xml profile and fills internal structures appropriately
    @arg the null terminated string buffer containing the xml profile
    @return true if buffer is parsed successfully , false otherwise)
*/
XmlErr XmlParseBuffer(TXml *xml,char *buf);

/***
    @brief parse an xml file containing the profile and fills internal structures appropriately
    @arg a null terminating string representing the path to the xml file
    @return an XmlErr error status (XML_NOERR if buffer was parsed successfully)
*/
XmlErr XmlParseFile(TXml *xml,char *path);

char *XmlDumpBranch(TXml *xml,XmlNode *rNode,unsigned int depth);
/***
    @brief dump the entire xml configuration tree that reflects the status of internal structures
    @arg pointer to a valid xml context
    @arg if not NULL, here will be stored the bytelength of the returned buffer
    @return a null terminated string containing the xml representation of the configuration tree.
    The memory allocated for the dump-string must be freed by the user when no more needed
*/
char *XmlDump(TXml *xml, int *outlen);

/***
    @brief Create a new xml context
    @return a point to a valid xml context
*/

TXml *XmlCreateContext();


/***
    @brief Resets/cleans an existing context
    @arg pointer to a valid xml context
*/
void XmlResetContext(TXml *xml);

/***
    @brief release all resources associated to an xml context
    @arg pointer to a valid xml context
*/
void XmlDestroyContext(TXml *xml);


/***
    @brief get node attribute at specified index
    @arg pointer to a valid XmlNode strucutre
    @arg of the the attribute we want to access (starting by 1)
    @return a pointer to a valid XmlNodeAttribute structure if found at
    the specified offset, NULL otherwise
*/
XmlNodeAttribute *XmlGetAttribute(XmlNode *node,unsigned long index);

/***
    @brief get node attribute with specified name
    @arg pointer to a valid XmlNode strucutre
    @arg the name of the desired attribute
    @return a pointer to a valid XmlNodeAttribute structure if found, NULL otherwise
*/
XmlNodeAttribute *XmlGetAttributeByName(XmlNode *node, char *name);

/***
    @brief remove attribute at specified index
    @arg pointer to a valid XmlNode strucutre
    @arg of the the attribute we want to access (starting by 1)
    @return XML_NOERR on success, XML_GENERIC_ERR otherwise
*/
int XmlRemoveAttribute(XmlNode *node, unsigned long index);

/***
    @brief remove all attributes of a node
    @arg pointer to a valid XmlNode structure
*/
void XmlClearAttributes(XmlNode *node);


/***
    @brief save the configuration stored in the xml file containing the current profile
           the xml file name is obtained appending '.xml' to the category name . The xml file is stored 
           in the repository directory specified during object construction.
    @arg pointer to a valid xml context
    @arg the path where to save the file
    @return an XmlErr error status (XML_NOERR if buffer was parsed successfully)
*/
XmlErr XmlSave(TXml *xml,char *path);

/***
    @brief allocate resources for a new namespace 
    @arg the shortname of the new namespace
    @arg the complete uri of the new namspace
    @return a valid XmlNamespace pointer on success, NULL otherwise
*/
XmlNamespace *XmlCreateNamespace(char *nsName, char *nsUri);

/***
 
*/
void XmlDestroyNamespace(XmlNamespace *ns);

/***
    @brief search for a specific namespace defined within the current document
    @arg pointer to a valid XmlNode structure
    @arg the shortname of the new namespace
*/
XmlNamespace *XmlGetNamespaceByName(XmlNode *node, char *nsName);

/***
    @brief search for a specific namespace defined within the current document
    @arg pointer to a valid XmlNode structure
    @arg the complete uri of the new namspace
    @return a valid XmlNamespace pointer if found, NULL otherwise
*/
XmlNamespace *XmlGetNamespaceByUri(XmlNode *node, char *nsUri);

/***
    @brief create a new namespace and link it to current document/context
    @arg pointer to a valid XmlNode structure
    @arg the shortname of the new namespace
    @arg the complete uri of the new namspace
    @return a valid XmlNamespace pointer if found, NULL otherwise
*/
XmlNamespace *XmlAddNamespace(XmlNode *node, char *nsName, char *nsUri);

/***
    @brief get the namespace of a node , if any
    @arg pointer to a valid XmlNode strucutre
    @return a pointer to the XmlNamespace of the node if defined or inherited, NULL otherwise
*/
XmlNamespace *XmlGetNodeNamespace(XmlNode *node);

/***
    @brief set the namespace of a node
    @arg pointer to a valid XmlNode structure
    @return XML_NOERR on success, any other xml error code otherwise
*/ 
XmlErr XmlSetNodeNamespace(XmlNode *node, XmlNamespace *ns);

/***
    @brief set the default namespace of a node 
           (which will be inherited by all descendant, unless overridden)
    @arg pointer to a valid XmlNode structure
    @arg pointer to a valid XmlNamespace structure
    @return XML_NOERR on success, any other xml error code otherwise
*/ 
XmlErr XmlSetNodeCNamespace(XmlNode *node, XmlNamespace *ns);

/***
    @brief set the default namespace for the current node (xml->cNode)
    @arg pointer to a valid XmlNode structure
    @arg the namespace uri
    @return XML_NOERR on success, any other xml error code otherwise
*/ 
XmlErr XmlSetCurrentNamespace(TXml *xml, char *nsuri);

static inline int XmlHasIconv()
{
#ifdef USE_ICONV
    return 1;
#else
    return 0;
#endif
}

#endif

#include "canon.h"
#include <stdio.h>
#include <string.h>
#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <libxml/xmlmemory.h>
#include <libxml/xpathInternals.h>

int exclusive = 1;
int with_comments = 0;
/*
 * Macro used to grow the current buffer.
 */
#define growBufferReentrant() {						\
    buffer_size *= 2;							\
    buffer = (xmlChar **)						\
    		xmlRealloc(buffer, buffer_size * sizeof(xmlChar*));	\
    if (buffer == NULL) {						\
	perror("realloc failed");					\
	return(NULL);							\
    }									\
}

static xmlChar ** parse_list(xmlChar *str) {
  xmlChar **buffer;
  xmlChar **out = NULL;
  int buffer_size = 1000;
  int len;

  if(str == NULL) {
    return(NULL);
  }

  len = xmlStrlen(str);
 
  if((str[0] == '\'') && (str[len - 1] == '\'')) {
    str[len - 1] = '\0';
    str++;
    len -= 2;
  }
  buffer = (xmlChar **) xmlMalloc(buffer_size * sizeof(xmlChar*));
  if (buffer == NULL) {
    perror("malloc failed");
    return(NULL);
  }
  out = buffer;
  
  while(*str != '\0') {
    if (out - buffer > buffer_size - 10) {
      int indx = out - buffer;
      
      growBufferReentrant();
      out = &buffer[indx];
    }
    (*out++) = str;
    while(*str != ',' && *str != '\0') ++str;
    if(*str == ',') *(str++) = '\0';
  }
  (*out) = NULL;
  //free(*out);
  return buffer;
}

static xmlXPathObjectPtr load_xpath_expr (xmlDocPtr parent_doc, char* xpathstring) {
  xmlXPathObjectPtr xpath; 
  xmlDocPtr doc;
  xmlChar *expr;
  xmlXPathContextPtr ctx; 
  xmlNodePtr node;
  xmlNsPtr ns;
  
  /*
   * load XPath expr as a file
   */
  xmlLoadExtDtdDefaultValue = XML_DETECT_IDS | XML_COMPLETE_ATTRS;
  xmlSubstituteEntitiesDefault(1);
  
  doc = xmlParseMemory(xpathstring, strlen(xpathstring));
  if (doc == NULL) {
    fprintf(stderr, "Error: unable to parse xpath\n");
    return(NULL);
  }
  
  /*
   * Check the document is of the right kind
   */    
  if(xmlDocGetRootElement(doc) == NULL) {
    fprintf(stderr,"Error: empty document for file \n");
    xmlFreeDoc(doc);
    return(NULL);
  }
  
  node = doc->children;
  while(node != NULL && !xmlStrEqual(node->name, (const xmlChar *)"XPath")) {
    node = node->next;
  }
  
  if(node == NULL) {   
    fprintf(stderr,"Error: XPath element expected in the file\n");
    xmlFreeDoc(doc);
    return(NULL);
  }
  
  expr = xmlNodeGetContent(node);
  if(expr == NULL) {
    fprintf(stderr,"Error: XPath content element is NULL\n");
    xmlFreeDoc(doc);
    return(NULL);
  }
  
  ctx = xmlXPathNewContext(parent_doc);
  if(ctx == NULL) {
    fprintf(stderr,"Error: unable to create new context\n");
    xmlFree(expr); 
    xmlFreeDoc(doc); 
    return(NULL);
  }
  
  /*
   * Register namespaces
   */
  ns = node->nsDef;
  while(ns != NULL) {
    if(xmlXPathRegisterNs(ctx, ns->prefix, ns->href) != 0) {
      fprintf(stderr,"Error: unable to register NS with prefix=\"%s\" and href=\"%s\"\n", ns->prefix, ns->href);
      xmlFree(expr); 
      xmlXPathFreeContext(ctx); 
      xmlFreeDoc(doc); 
      return(NULL);
    }
    ns = ns->next;
  }

  /*  
   * Evaluate xpath
   */
  xpath = xmlXPathEvalExpression(expr, ctx);
  if(xpath == NULL) {
    fprintf(stderr,"Error: unable to evaluate xpath expression\n");
    xmlFree(expr); 
    xmlXPathFreeContext(ctx); 
    xmlFreeDoc(doc); 
    return(NULL);
  }
  
  /* print_xpath_nodes(xpath->nodesetval); */
  
  xmlFree(expr); 
  xmlXPathFreeContext(ctx); 
  xmlFreeDoc(doc); 
  return(xpath);
}

int canonicalize (char *xmlString, char *xpathString, char *nameSpace, int exc, int comm, char *output) {
  xmlDocPtr myXmlDoc;
  xmlXPathObjectPtr xpath;
  xmlChar **list;
  exclusive = exc;
  with_comments = comm;
  //xmlNodeSetPtr nodes;
  
  //this function is not actually called!
  list=parse_list(nameSpace);

  myXmlDoc = xmlParseMemory(xmlString, strlen(xmlString));
  if (myXmlDoc == NULL) {
    fprintf(stderr, "Failed to parse string\n");
  }
  //      int i = xmlSaveFile ("-", myXmlDoc); //spew to stdout
  
  xpath = load_xpath_expr(myXmlDoc, xpathString);
  if (xpath == NULL) {
    fprintf(stderr, "Failed to parse Xpath\n");
    return -1;
  }

  

  int i = xmlC14NDocDumpMemory (myXmlDoc,  (xpath) ? xpath->nodesetval : NULL, 
				exclusive, 
				list, 
				with_comments, 
				output);   
				
  xmlXPathFreeObject(xpath);
  xmlFreeDoc(myXmlDoc); 
  xmlFree(list);  
  xmlMemoryDump();
  
  return i;
} // end canonicalize


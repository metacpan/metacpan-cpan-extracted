#include <xmlsec/xmlsec.h>
#include <xmlsec/xmldsig.h>
#include <xmlsec/openssl/app.h>
#include <xmlsec/xmltree.h>
#include <xmlsec/errors.h>
#include <xmlsec/templates.h>

#include "perl-libxml-mm.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <xmlsec/app.h>
#include "crypto.h"

#define XMLSEC_ERRORS_BUFFER_SIZE       1024


xmlSecKeyPtr FindKey(xmlSecKeysMngrPtr mngr, xmlChar* name) {
  
   xmlSecKeyPtr r;
   xmlSecKeyInfoCtxPtr ctx=xmlSecKeyInfoCtxCreate(mngr);
   xmlSecKeyInfoCtxInitialize(ctx,mngr);
   r= xmlSecKeysMngrFindKey(mngr, name, ctx);
   xmlSecKeyInfoCtxDestroy(ctx);
   return r;

}

/* extracts the libxml2 node from a perl reference
 */

xmlNodePtr
PmmSvNodeExt( SV* perlnode, int copy )
{
    xmlNodePtr retval = NULL;
    ProxyNodePtr proxy = NULL;
    dTHX;

    if ( perlnode != NULL && perlnode != &PL_sv_undef ) {
/*         if ( sv_derived_from(perlnode, "XML::LibXML::Node") */
/*              && SvPROXYNODE(perlnode) != NULL  ) { */
/*             retval = PmmNODE( SvPROXYNODE(perlnode) ) ; */
/*         } */
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


/**
 * xmlSecGetNextElementNode:
 * @cur:                the pointer to an XML node.
 *
 * Seraches for the next element node.
 *
 * Returns: the pointer to next element node or NULL if it is not found.
 */
xmlNodePtr
xmlSecGetNextElementNode(xmlNodePtr cur) {

    while((cur != NULL) && (cur->type != XML_ELEMENT_NODE)) {
        cur = cur->next;
    }
    return(cur);
}

#define MY_CXT_KEY "XML::LibXML::xmlsec::_guts" XS_VERSION

typedef struct {
   char sLastMsg[XMLSEC_ERRORS_BUFFER_SIZE];
} my_cxt_t;

START_MY_CXT

/**************************************************************
   myErrorsCallback()

   xmlsec provides for an error callback function.
   Since the xmlsig verification can fail for a number
   of applicatio-related reasons, an error hook is supplied
   in order for the lastmsg member to work
**************************************************************/
void
MyErrorsCallback (const char *file,
                         int line,
                         const char *func,
                         const char *errorObject,
                         const char *errorSubject,
                         int reason,
                         const char *msg) {

   xmlSecSize i;
   char* error_msg = NULL;
   dMY_CXT;

   for(i = 0; (i < XMLSEC_ERRORS_MAX_NUMBER) && (xmlSecErrorsGetMsg(i) != NULL); ++i) {
      if(xmlSecErrorsGetCode(i) == reason) {
          error_msg = xmlSecErrorsGetMsg(i);
          break;
      }
   }

   switch(reason) {
   case XMLSEC_ERRORS_R_INVALID_DATA:
      sprintf(MY_CXT.sLastMsg,"%d:%s:%s",reason,error_msg,msg);
       break;

   default:
      xmlSecErrorsDefaultCallback(file,line,func,errorObject,errorSubject,reason,msg);
   }
}



/**************************************************************************************
   xmlSecAppAddIDAttr()

   Scans the xml document for id nodes

   This is copied verbatim from xmlsec sample application. 
   It's a utility function in order to scans for ID nodes and
   then call libxml's xmlAddID() on each. This way,
   the reference #something will work on a DTD-less document

   Args:
      node:     starting node for the scanning
      attrName: name of the attribute that's supposed to hold
                the id. Normally "id" or "ID"
      nodeName: the scan only search for this node tags
      nsHref:   namespace in case one is set
   
   Copyright (C) 2002-2016 Aleksey Sanin <aleksey@aleksey.com>. All Rights Reserved.
***************************************************************************************/
static int  
xmlSecAppAddIDAttr(xmlNodePtr node, const xmlChar* attrName, const xmlChar* nodeName, const xmlChar* nsHref) {
    xmlAttrPtr attr, tmpAttr;
    xmlNodePtr cur;
    xmlChar* id;
    
    if((node == NULL) || (attrName == NULL) || (nodeName == NULL)) {
        return(-1);
    }
    
    /* process children first because it does not matter much but does simplify code */
    cur = xmlSecGetNextElementNode(node->children);
    while(cur != NULL) {
        if(xmlSecAppAddIDAttr(cur, attrName, nodeName, nsHref) < 0) {
            return(-1);
        }
        cur = xmlSecGetNextElementNode(cur->next);
    }
    
    /* node name must match */
    if(!xmlStrEqual(node->name, nodeName)) {
        return(0);
    }
        
    /* if nsHref is set then it also should match */    
    if((nsHref != NULL) && (node->ns != NULL) && (!xmlStrEqual(nsHref, node->ns->href))) {
        return(0);
    }
    
    /* the attribute with name equal to attrName should exist */
    for(attr = node->properties; attr != NULL; attr = attr->next) {
        if(xmlStrEqual(attr->name, attrName)) {
            break;
        }
    }
    if(attr == NULL) {
        return(0);
    }
    
    /* and this attr should have a value */
    id = xmlNodeListGetString(node->doc, attr->children, 1);
    if(id == NULL) {
        return(0);
    }
    
    /* check that we don't have same ID already */
    tmpAttr = xmlGetID(node->doc, id);
    if(tmpAttr == NULL) {
        xmlAddID(NULL, node->doc, id, attr);
    } else if(tmpAttr != attr) {
        fprintf(stderr, "Error: duplicate ID attribute \"%s\"\n", id);  
        xmlFree(id);
        return(-1);
    }
    xmlFree(id);
    return(0);
}

MODULE = XML::LibXML::xmlsec		PACKAGE = XML::LibXML::xmlsec		

PROTOTYPES: ENABLE

BOOT:
{
   // No libxml initialization here. XML::LibXML should handle that
   LIBXML_TEST_VERSION

   int ret=xmlSecOpenSSLAppInit (NULL);
   if(ret < 0) {
        croak("Error: xmlsec crypto OpenSSL app engine intialization failed");
   }
   ret=xmlSecInit();
   if(ret < 0) {
        croak("Error: xmlsec intialization failed");
   }

       /* Init crypto library */
    if(xmlSecCryptoAppInit(NULL) < 0) {
        croak( "Error: crypto initialization failed.\n");
    }

   ret=xmlSecCryptoInit();
   if(ret < 0) {
        croak("Error: xmlsec crypto engine intialization failed");
   }

   MY_CXT_INIT;
   MY_CXT.sLastMsg[0]=(char)0;
}

int
InitPerlXmlSec(self)
      SV * self
   CODE:
/********************************************************************
   InitPerlXmlSec()

   Placeholder for general xmlsec initialization
*********************************************************************/
   // No libxml initialization here. XML::LibXML should handle that
      int ret=0;
	  ret = xmlSecCheckVersion();
	  if (ret != 1) {
        croak("Error: xmlsec version mismatch.\n");
        ret=0;
	  }

	  RETVAL=ret;

   OUTPUT:
      RETVAL


IV 
InitKeyMgr(self)
      SV * self
   CODE:
/********************************************************************
   InitPerlXmlSec()

   Setup the main KeyMgr object. This is needed for further method
   calls
*********************************************************************/
      xmlSecKeysMngrPtr pkm = NULL;
      pkm=xmlSecKeysMngrCreate(); 
	  if (pkm == NULL) {
		  croak("xmlSecKeysMngrCreate fail\n");
		  RETVAL=0;
	  } 

	  if (xmlSecCryptoAppDefaultKeysMngrInit(pkm) < 0) {
		  croak("xmlSecCryptoAppDefaultKeysMngrInit fail\n");
		  RETVAL=0;
	  }
       
	  RETVAL=PTR2IV(pkm);
   OUTPUT:
      RETVAL

IV
XmlSecKeyLoad(self,mngr,file,pass,name,format)
      SV * self
      IV mngr
      xmlChar * file
      xmlChar * pass
      xmlChar * name
      xmlSecKeyDataFormat format
   CODE:
/********************************************************************
   XmlSecKeyLoad()

   Loads a key from a file into the keymanager. This mainly maps
   to xmlsec's xmlSecCryptoAppDefaultKeysMngrAdoptKey()
		 Args:
		    self
			mngr: the key manager attached to us
			file: the external file name
			pass: the password for key decryption
			name: an optional name
         Return value:
		    whatever xmlSecCryptoAppDefaultKeysMngrAdoptKey
*********************************************************************/
      xmlSecKeysMngrPtr pkm = INT2PTR(xmlSecKeysMngrPtr, mngr);
	  xmlSecKeyPtr key;
      int ret=0;

      key = xmlSecCryptoAppKeyLoad(file, format, pass, 
                xmlSecCryptoAppGetDefaultPwdCallback(), (void*)file);
      if (key == NULL)
      {
		  croak ("xmlSecCryptoAppKeyLoad fail");
      }
      
	  ret = xmlSecKeySetName(key,  name);
	  ret = xmlSecCryptoAppDefaultKeysMngrAdoptKey(pkm, key);
	  if (ret < 0) {
		  croak ("xmlSecCryptoAppDefaultKeysMngrAdoptKey fail");
	  }
	  RETVAL=ret;
   OUTPUT:
      RETVAL

IV
xmlSecKeyLoadString(self,mngr,data,pass,name,format)
      SV * self
      IV mngr
      xmlChar * data
      xmlChar * pass
      xmlChar * name
      xmlSecKeyDataFormat format
   CODE:
/********************************************************************
   xmlSecKeyLoadString()

   This is the in-memory version of XmlSecKeyLoad()
*********************************************************************/
      xmlSecKeysMngrPtr pkm = INT2PTR(xmlSecKeysMngrPtr, mngr);
	   xmlSecKeyPtr key;
      xmlSecSize s = strlen(data);
	   int ret;

      //printf ("len=%d pass=%s format=%d\n",s,pass,format);
      key=xmlSecOpenSSLAppKeyLoadMemory (data,s,format,pass,NULL , NULL);

      if (key == NULL)
      {
		  die ("xmlSecOpenSSLAppKeyLoadMemory fail");
      }
	  ret = xmlSecCryptoAppDefaultKeysMngrAdoptKey(pkm, key);
     ret = xmlSecKeySetName(key,  name);
	  if (ret < 0) {
		  die ("xmlSecCryptoAppDefaultKeysMngrAdoptKey fail");
	  }
	  RETVAL=ret;

   OUTPUT:
      RETVAL


char *
XmlSecVersion(self)
      SV * self
   CODE:
/********************************************************************
   XmlSecVersion()

   Returns the underlying xmlsec version. Please note that this is 
   a static call based on a cpp macro. xmlsec doesn't provide a 
   dynamic link to the version, only cleverly setup MACROS and a 
   xmlSecCheckVersion function call
*********************************************************************/
      RETVAL = XMLSEC_VERSION;
   OUTPUT:
      RETVAL

int
xmlSecIdAttrTweak(self,doc,id_attr, id_name)
   HV * self        
   SV * doc
   xmlChar * id_attr
   xmlChar * id_name
CODE:
/********************************************************************
   xmlSecIdAttrTweak()

   This is a wrapper for xmlSecAppAddIDAttr().
   Args:
      doc: a readely parsed LibXML document
      id_attr: the name of the  attribute blessed as id. i.e.:id, ID, name, etc
      id_name: the name of the tag blessed with ids
*********************************************************************/
   xmlChar* buf;
   xmlChar* nodeName;
   xmlChar* nsHref;
   xmlNodePtr cur;
   xmlDocPtr real_doc;

   if (id_attr == NULL) {
	   croak( "id-attr must be specified");
   }
   real_doc=(xmlDocPtr) PmmSvNode(doc);
   if (real_doc == NULL)  {
	   croak("Error: failed to get libxml doc");
   }

   /* set id atribute */
   buf = xmlStrdup(id_name);
   nodeName = (xmlChar*)strrchr((char*)buf, ':');
   if(nodeName != NULL) {
	   (*(nodeName++)) = '\0';
	   nsHref = buf;
	} else {
	   nodeName = buf;
	   nsHref = NULL;
	}
   cur = xmlSecGetNextElementNode(real_doc->children);
	while(cur != NULL) {
		if(xmlSecAppAddIDAttr(cur, id_attr, nodeName, nsHref) < 0) {
			xmlFree(buf);
			croak ("Error: xmlSecAppAddIDAttr failed");
		}
		cur = xmlSecGetNextElementNode(cur->next);
	}
    xmlFree(buf);
   RETVAL=0;

   OUTPUT:
   RETVAL


int
XmlSecSignDoc(self,doc,mgr, id)
   HV * self        
   SV * doc
   IV mgr
   xmlChar * id
  CODE:
/********************************************************************
   XmlSecSignDoc()

   Entry point for signing process with a given id

   Args:
      doc: the libxml doc to sign
      mgr: the previously setup key mgr
      id: the id value of the node subject to signature
*********************************************************************/
   int ret=0;
   xmlDocPtr real_doc;
   xmlAttrPtr attr;
   xmlNodePtr startNode;

   if (id == NULL) {
	   croak( "id must be specified");
   }

   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);
   
   xmlSecDSigCtx dsigCtx;

   ret=xmlSecDSigCtxInitialize(&dsigCtx, pkm);
   if (ret < 0)   {
	   croak("Error xmlSecDSigCtxInitialize fail");
   }


   real_doc=(xmlDocPtr) PmmSvNode(doc);
   if (real_doc == NULL)  {
	   croak("Error: failed to get libxml doc");
   }


    /* find starting node by id */
    attr = xmlGetID(real_doc, id);
	if (attr == NULL)	{
		croak("Error: xmlsec fail to find starting node");
	}
	
	startNode = xmlSecFindNode(attr->parent, "Signature", "http://www.w3.org/2000/09/xmldsig#");
	if (startNode == NULL)
	{
		croak( "Error: xmlsec fail to find Signature node");
	}
	ret=xmlSecDSigCtxSign(&dsigCtx, startNode);
	if (ret < 0)
	{
		croak("Error xmlsec signature failed");
	}

    xmlSecDSigCtxFinalize(&dsigCtx);

   RETVAL=ret;

   OUTPUT:
   RETVAL

int 
XmlSecSign(self,doc,mgr,node)
   HV * self        
   SV * doc        
   IV mgr          
   SV * node 
CODE:
/********************************************************************
   xmlSecSign()

   Document signing with a given starting node

   Args:
      doc: the libxml doc to sign
      mgr: the previously setup key mgr
      node: the signature node
*********************************************************************/

   int ret=0;
   xmlNodePtr startNode= PmmSvNodeExt(node,0);
   if (node == NULL)   {
	   croak("Starting node missing");
   }
   xmlDocPtr real_doc=(xmlDocPtr) PmmSvNode(doc);
   if (real_doc == NULL)  {
	   croak("Error: failed to get libxml doc");
   }
   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);

   xmlSecDSigCtx dsigCtx;

   ret=xmlSecDSigCtxInitialize(&dsigCtx, pkm);
   if (ret < 0)   {
	   croak("Error xmlSecDSigCtxInitialize fail");
   }
   ret=xmlSecDSigCtxSign(&dsigCtx, startNode);
   if (ret < 0)
   {
      croak("Error xmlsec signature failed");
   }

   xmlSecDSigCtxFinalize(&dsigCtx);

   RETVAL=ret;

   OUTPUT:
   RETVAL


int 
XmlSecVerify(self,doc,mgr, id)
   HV * self        
   SV * doc
   IV mgr
   xmlChar * id
PREINIT:
   dMY_CXT;
CODE:
/********************************************************************
   XmlSecVerify()

   This is the main signature verifying function

   Args:
      doc: the already signed XML document handle
      mgr: the previously setup key manager
      id:  the id of the node we are to verify
********************************************************************/
   int ret=0;
   xmlDocPtr real_doc;
   xmlAttrPtr attr;
   xmlNodePtr startNode;

   if (id == NULL) {
	   croak( "id must be specified");
   }

   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);
   
   xmlSecDSigCtx dsigCtx;

   ret=xmlSecDSigCtxInitialize(&dsigCtx, pkm);
   if (ret < 0)   {
	   croak("Error xmlSecDSigCtxInitialize fail");
   }

   real_doc=(xmlDocPtr) PmmSvNode(doc);
   if (real_doc == NULL)  {
	   croak("Error: failed to get libxml doc");
   }

   attr = xmlGetID(real_doc, id);
	if (attr == NULL)	{
		croak("Error: xmlsec fail to find starting node");
	}

   startNode = xmlSecFindNode(attr->parent, "Signature", "http://www.w3.org/2000/09/xmldsig#");

   if (startNode == NULL)
   {
    	croak( "Error: xmlsec fail to find Signature node");
   }

   //I reset the error msg
   MY_CXT.sLastMsg[0]=(char)0;
   xmlSecErrorsSetCallback (&MyErrorsCallback); 

   ret=xmlSecDSigCtxVerify(&dsigCtx, startNode);
   xmlSecErrorsSetCallback(&xmlSecErrorsDefaultCallback);
   if (ret < 0)
   {   croak("Error: xmlSecDSigCtxVerify fail");
       RETVAL=ret;
   } else {
      ret=dsigCtx.status;
   }
   
   RETVAL=ret;
OUTPUT:
   RETVAL
  
char *
lastmsg(self)
   SV * self
PREINIT:
   dMY_CXT;
CODE:
   RETVAL=MY_CXT.sLastMsg;
OUTPUT:
   RETVAL

int
KeyCertLoad(self,mgr,name,secret,file,format) 
   SV * self    
   IV mgr          
   xmlChar * name  
   xmlChar * secret
   xmlChar * file 
   xmlSecKeyDataFormat format 
CODE:
/********************************************************************
   KeyCertLoad()

   Entry point for x509 certificate loading

   Args:
      mgr:    The key manager ptr, IV packed
      secret: The password for decrypting the certificate
      file:   Certificate filename
      format: The format of the certificate file
*********************************************************************/

   int ret=0;
   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);
   xmlSecKeyPtr key=FindKey(pkm,name);
   if (key==NULL)  { /* There's no key yet */
      key=xmlSecCryptoAppKeyLoad (file,format,secret,xmlSecCryptoAppGetDefaultPwdCallback(),file);
      //printf ("Loaded cert as new key\n");
	  if (key == NULL) {
		  croak ("Can't load certificate file");
	  }
      ret = xmlSecKeySetName(key,  name);
	  ret = xmlSecCryptoAppDefaultKeysMngrAdoptKey(pkm, key);
      
   } else { /* we attach the certificate to the previously loaded key */
      ret=xmlSecCryptoAppKeyCertLoad (key,file,xmlSecKeyDataFormatPem);
      //printf ("Loaded cert as attribute\n");
	  if (ret<0) {
		  croak("Can't load certificate file");
	  }

   }

   RETVAL=ret;
OUTPUT:
   RETVAL


int
KeyCertLoadString(self,mgr,name,secret,data,format) 
   SV * self    
   IV mgr          
   xmlChar * name  
   xmlChar * secret
   xmlChar * data 
   xmlSecKeyDataFormat format 
CODE:
/********************************************************************
   KeyCertLoadString()

   Entry point for x509 certificate loading

   Args:
      mgr:    The key manager ptr, IV packed
      secret: The password for decrypting the certificate
      data:   Certificate data
      format: The format of the certificate file
*********************************************************************/

   int ret=0;
   int s=strlen(data);
   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);
   xmlSecKeyPtr key=FindKey(pkm,name);
   if (key==NULL)  { /* There's no key yet */
      key=xmlSecOpenSSLAppKeyLoadMemory (data,s,format,secret,NULL , NULL);
      //printf ("Loaded cert as new key\n");
	  if (key == NULL) {
		  croak ("Can't load certificate file");
	  }
      ret = xmlSecKeySetName(key,  name);
	  ret = xmlSecCryptoAppDefaultKeysMngrAdoptKey(pkm, key);
      
   } else { /* we attach the certificate to the previously loaded key */
      ret=xmlSecCryptoAppKeyCertLoadMemory  (key,data,s,format);
      //printf ("Loaded cert as attribute\n");
	  if (ret<0) {
		  croak("Can't load certificate file");
	  }

   }

   RETVAL=ret;
OUTPUT:
   RETVAL


int
_CACertLoad(self,mgr,filename,format,type)
   SV * self
   IV mgr
   char * filename
   xmlSecKeyDataFormat format
   int type
CODE:
/********************************************************************
   _CACertLoad()

   This is a wrapper for xmlSecAppCryptoSimpleKeysMngrCertLoad()
   This will load trusted root CA certificate or untrusted blacklisted
   certificates in order to veriry signatures
*********************************************************************/
   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);
   RETVAL=xmlSecAppCryptoSimpleKeysMngrCertLoad(pkm,filename,format,type);
OUTPUT:
   RETVAL

int
_KeysStoreSave (self, mgr,filename,type)
   SV * self
   IV mgr
   char * filename
   int type
CODE:
/********************************************************************
   _KeysStoreSave()

   Dumps the contents of the key manager for further use
   This maps to xmlSecCryptoAppDefaultKeysMngrSave()
*********************************************************************/
   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);
   RETVAL=xmlSecCryptoAppDefaultKeysMngrSave  (pkm,filename,type);
OUTPUT:
   RETVAL

int
_KeysStoreLoad (self, mgr,filename)
   SV * self;
   IV mgr;
   char * filename;
CODE:
/********************************************************************
   _KeysStoreSave()

   Dumps the contents of the key manager for further use
   This maps to xmlSecCryptoAppDefaultKeysMngrLoad()
*********************************************************************/
   xmlSecKeysMngrPtr pkm=INT2PTR(xmlSecKeysMngrPtr, mgr);
   RETVAL=xmlSecCryptoAppDefaultKeysMngrLoad   (pkm,filename);
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRsaSha224Id(self)
   HV * self;
CODE:
   /*******************************************************************
   PerlxmlSecTransformRsaSha224Id(),
   PerlxmlSecTransformRsaSha256Id(),
   PerlxmlSecTransformRsaSha1Id() et all...

   are helper functions for xmlsec transformation profile classes.
   This way we can use the handy app.h macros
   ********************************************************************/
   RETVAL=xmlSecTransformRsaSha224Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformDsaSha1Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformDsaSha1Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformDsaSha256Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformDsaSha256Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformEcdsaSha1Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformEcdsaSha1Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformEcdsaSha224Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformEcdsaSha224Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformEcdsaSha256Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformEcdsaSha256Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformEcdsaSha384Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformEcdsaSha384Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformEcdsaSha512Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformEcdsaSha512Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformHmacMd5Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformHmacMd5Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformHmacRipemd160Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformHmacRipemd160Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformHmacSha1Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformHmacSha1Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformHmacSha224Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformHmacSha224Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformHmacSha256Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformHmacSha256Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformHmacSha384Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformHmacSha384Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformHmacSha512Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformHmacSha512Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformMd5Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformMd5Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRipemd160Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformRipemd160Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRsaMd5Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformRsaMd5Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRsaRipemd160Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformRsaRipemd160Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRsaSha1Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformRsaSha1Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRsaSha256Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformRsaSha256Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRsaSha384Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformRsaSha384Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformRsaSha512Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformRsaSha512Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformSha1Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformSha1Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformSha224Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformSha224Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformSha256Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformSha256Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformSha384Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformSha384Id;
OUTPUT:
   RETVAL

xmlSecTransformId
PerlxmlSecTransformSha512Id(self)
   HV * self;
CODE:
   RETVAL=xmlSecTransformSha512Id;
OUTPUT:
   RETVAL



int XMLCreateSignTemplate(self,doc,opt,dig,id)
   HV * self;
   SV * doc;
   xmlSecTransformId opt;
   xmlSecTransformId dig;
   xmlChar * id;
CODE:
/***************************************
   XMLCreateSignTemplate()

   This is the main template signature
   generation call

   Args:
     doc: the already parsed LibXML for adding the Signature artifacts
     opt: a tranform klass id for the main Signature attribute
     opt: a transform class for the Digest atribute
     id: the node id to be signed
****************************************/
   xmlDocPtr real_doc;
   xmlNodePtr signNode = NULL;
   xmlNodePtr refNode = NULL;
   xmlNodePtr keyInfoNode = NULL;

   real_doc=(xmlDocPtr) PmmSvNode(doc);
   if (real_doc == NULL)  {
	   croak("Error: failed to get libxml doc");
   }
   signNode = xmlSecTmplSignatureCreate(real_doc, xmlSecTransformExclC14NId,opt, NULL);
   if(signNode == NULL) {
      croak( "Error: failed to create signature template");
   }
   xmlAddChild(xmlDocGetRootElement(real_doc), signNode);
   refNode = xmlSecTmplSignatureAddReference(signNode, dig,NULL, id, NULL);
   if(refNode == NULL) {
        croak("Error: failed to add reference to signature template");
   }
   if(xmlSecTmplReferenceAddTransform(refNode, xmlSecTransformEnvelopedId) == NULL) {
        croak("Error: failed to add enveloped transform to reference");
   }
   keyInfoNode = xmlSecTmplSignatureEnsureKeyInfo(signNode, NULL);
   if(keyInfoNode == NULL) {
      croak("Error: failed to add key info");
   }

   if(xmlSecTmplKeyInfoAddKeyName(keyInfoNode, NULL) == NULL) {
      croak( "Error: failed to add key name\n");
    }

   RETVAL=0;
OUTPUT:
   RETVAL


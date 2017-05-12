/* generated automatically from generate.pl */
#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*#include <libxml/hash.h>*/
#include <libxml/xmlerror.h>
#include "gdome.h"
#include "gdome-xpath.h"
/*#include "gdome-traversal.h"
#include "gdome-events.h"*/

#include "dom.h"

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

xmlNs * gdome_xmlGetNsDeclByAttr (xmlAttr *a);

#ifdef __cplusplus
}
#endif

char *errorMsg[101];

#define SET_CB(cb, fld) \
    RETVAL = cb ? newSVsv(cb) : &PL_sv_undef;\
    if (SvOK(fld)) {\
        if (cb) {\
            if (cb != fld) {\
                sv_setsv(cb, fld);\
            }\
        }\
        else {\
            cb = newSVsv(fld);\
        }\
    }\
    else {\
        if (cb) {\
            SvREFCNT_dec(cb);\
            cb = NULL;\
        }\
    }

static SV * GDOMEPerl_match_cb = NULL;
static SV * GDOMEPerl_read_cb = NULL;
static SV * GDOMEPerl_open_cb = NULL;
static SV * GDOMEPerl_close_cb = NULL;
static SV * GDOMEPerl_error = NULL;

/* Shamelessly cribbed straight from LibXML.xs */
/* This handler function appends 
   an error message to the GDOMEPerl_error global */
void
GDOMEPerl_error_handler(void * ctxt, const char * msg, ...) 
{ 
    va_list args; 
    SV * sv; 
     
    sv = NEWSV(0,512); 
     
    va_start(args, msg); 
    sv_vsetpvfn(sv, msg, strlen(msg), &args, NULL, 0, NULL); 
    va_end(args); 
     
    sv_catsv(GDOMEPerl_error, sv); /* remember the last error */ 
    SvREFCNT_dec(sv); 
} 

int 
GDOMEPerl_input_match(char const * filename)
{
    int results = 0;
    SV * global_cb;
    SV * callback = NULL;

    if ((global_cb = perl_get_sv("XML::GDOME::match_cb", FALSE))
            && SvTRUE(global_cb)) {
        callback = global_cb;
    }
    else if (GDOMEPerl_match_cb && SvTRUE(GDOMEPerl_match_cb)) {
        callback = GDOMEPerl_match_cb;
    }

    if (callback) {
        int count;
        SV * res;

        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpv((char*)filename, 0)));
        PUTBACK;

        count = perl_call_sv(callback, G_SCALAR);

        SPAGAIN;
        
        if (count != 1) {
            croak("match callback must return a single value");
        }
        
        res = POPs;

        if (SvTRUE(res)) {
            results = 1;
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    return results;
}

void * 
GDOMEPerl_input_open(char const * filename)
{
    SV * results;
    SV * global_cb;
    SV * callback = NULL;

    if ((global_cb = perl_get_sv("XML::GDOME::open_cb", FALSE))
            && SvTRUE(global_cb)) {
        callback = global_cb;
    }
    else if (GDOMEPerl_open_cb && SvTRUE(GDOMEPerl_open_cb)) {
        callback = GDOMEPerl_open_cb;
    }

    if (callback) {
        int count;

        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpv((char*)filename, 0)));
        PUTBACK;

        count = perl_call_sv(callback, G_SCALAR);

        SPAGAIN;
        
        if (count != 1) {
            croak("open callback must return a single value");
        }

        results = POPs;

        SvREFCNT_inc(results);

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    return (void *)results;
}

int 
GDOMEPerl_input_read(void * context, char * buffer, int len)
{
    SV * results = NULL;
    STRLEN res_len = 0;
    const char * output;
    SV * global_cb;
    SV * callback = NULL;
    SV * ctxt = (SV *)context;

    if ((global_cb = perl_get_sv("XML::GDOME::read_cb", FALSE))
            && SvTRUE(global_cb)) {
        callback = global_cb;
    }
    else if (GDOMEPerl_read_cb && SvTRUE(GDOMEPerl_read_cb)) {
        callback = GDOMEPerl_read_cb;
    }
    
    if (callback) {
        int count;

        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(ctxt);
        PUSHs(sv_2mortal(newSViv(len)));
        PUTBACK;

        count = perl_call_sv(callback, G_SCALAR);

        SPAGAIN;
        
        if (count != 1) {
            croak("read callback must return a single value");
        }

        output = POPp;
        if (output != NULL) {
            res_len = strlen(output);
            if (res_len) {
                strncpy(buffer, output, res_len);
            }
            else {
                buffer[0] = 0;
            }
        }
        
        FREETMPS;
        LEAVE;
    }
    
    /* warn("read, asked for: %d, returning: [%d] %s
", len, res_len, buffer); */
    return res_len;
}

void 
GDOMEPerl_input_close(void * context)
{
    SV * global_cb;
    SV * callback = NULL;
    SV * ctxt = (SV *)context;

    if ((global_cb = perl_get_sv("XML::GDOME::close_cb", FALSE))
            && SvTRUE(global_cb)) {
        callback = global_cb;
    }
    else if (GDOMEPerl_close_cb && SvTRUE(GDOMEPerl_close_cb)) {
        callback = GDOMEPerl_close_cb;
    }

    if (callback) {
        int count;

        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(ctxt);
        PUTBACK;

        count = perl_call_sv(callback, G_SCALAR);

        SPAGAIN;

        SvREFCNT_dec(ctxt);
        
        if (!count) {
            croak("close callback failed");
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

void
GDOMEPerl_load_error_strings() {
  errorMsg[0] = "GDOME_NOEXCEPTION_ERR";
  errorMsg[1] = "INDEX_SIZE_ERR";
  errorMsg[2] = "DOMSTRING_SIZE_ERR";
  errorMsg[3] = "HIERARCHY_REQUEST_ERR";
  errorMsg[4] = "WRONG_DOCUMENT_ERR";
  errorMsg[5] = "INVALID_CHARACTER_ERR";
  errorMsg[6] = "NO_DATA_ALLOWED_ERR";
  errorMsg[7] = "NO_MODIFICATION_ALLOWED_ERR";
  errorMsg[8] = "NOT_FOUND_ERR";
  errorMsg[9] = "NOT_SUPPORTED_ERR";
  errorMsg[10] = "INUSE_ATTRIBUTE_ERR";
  errorMsg[11] = "INVALID_STATE_ERR";
  errorMsg[12] = "SYNTAX_ERR";
  errorMsg[13] = "INVALID_MODIFICATION_ERR";
  errorMsg[14] = "NAMESPACE_ERR";
  errorMsg[15] = "INVALID_ACCESS_ERR";
  errorMsg[100] = "GDOME_NULL_POINTER_ERR";
  errorMsg[101] = "INVALID_EXPRESSION_ERR";
  errorMsg[102] = "TYPE_ERR";
}

MODULE = XML::GDOME       PACKAGE = XML::GDOME::DOMImplementation

PROTOTYPES: DISABLE

BOOT:
    GDOMEPerl_load_error_strings();
    xmlInitParser();
    xmlRegisterInputCallbacks((xmlInputMatchCallback) GDOMEPerl_input_match,
                              (xmlInputOpenCallback) GDOMEPerl_input_open,
                              (xmlInputReadCallback) GDOMEPerl_input_read,
                              (xmlInputCloseCallback) GDOMEPerl_input_close);
    xmlSetGenericErrorFunc(PerlIO_stderr(),
                           (xmlGenericErrorFunc)GDOMEPerl_error_handler);

GdomeDOMImplementation *
mkref()
    PREINIT:
        char * CLASS = "XML::GDOME::DOMImplementation";
    CODE:
        RETVAL = gdome_di_mkref();
    OUTPUT:
        RETVAL

void
ref(self)
        GdomeDOMImplementation * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_di_ref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
unref(self)
        GdomeDOMImplementation * self
    ALIAS:
        XML::GDOME::DOMImplementation::DESTROY = 1
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_di_unref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeDocument *
createDocument(self,namespaceURI,qualifiedName,doctype)
        GdomeDOMImplementation * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * qualifiedName
        GdomeDocumentType * doctype
    PREINIT:
        char * CLASS = "XML::GDOME::Document";
        GdomeException exc;
        char * errstr;
        STRLEN len = 0;
    CODE:
        GDOMEPerl_error = NEWSV(0, 512);
        sv_setpvn(GDOMEPerl_error, "", 0);
        RETVAL = gdome_di_createDocument(self,namespaceURI,qualifiedName,doctype,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(qualifiedName != NULL)
          gdome_str_unref(qualifiedName);
        sv_2mortal(GDOMEPerl_error);

        errstr = SvPV(GDOMEPerl_error, len);
        if (len > 0){
          croak("%s",errstr);
        }
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDocumentType *
createDocumentType(self,qualifiedName,publicId,systemId)
        GdomeDOMImplementation * self
        GdomeDOMString * qualifiedName
        GdomeDOMString * publicId
        GdomeDOMString * systemId
    PREINIT:
        char * CLASS = "XML::GDOME::DocumentType";
        GdomeException exc;
        char * errstr;
        STRLEN len = 0;
    CODE:
        GDOMEPerl_error = NEWSV(0, 512);
        sv_setpvn(GDOMEPerl_error, "", 0);
        RETVAL = gdome_di_createDocumentType(self,qualifiedName,publicId,systemId,&exc);
        if(qualifiedName != NULL)
          gdome_str_unref(qualifiedName);
        if(publicId != NULL)
          gdome_str_unref(publicId);
        if(systemId != NULL)
          gdome_str_unref(systemId);
        sv_2mortal(GDOMEPerl_error);

        errstr = SvPV(GDOMEPerl_error, len);
        if (len > 0){
          croak("%s",errstr);
        }
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
hasFeature(self,feature,version)
        GdomeDOMImplementation * self
        GdomeDOMString * feature
        GdomeDOMString * version
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_di_hasFeature(self,feature,version,&exc);
        if(feature != NULL)
          gdome_str_unref(feature);
        if(version != NULL)
          gdome_str_unref(version);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
freeDoc(self,doc)
        GdomeDOMImplementation * self
        GdomeDocument * doc
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_di_freeDoc(self,doc,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeDocument *
createDocFromURI(self,uri,mode)
        GdomeDOMImplementation * self
        const char * uri
        unsigned int mode
    PREINIT:
        char * CLASS = "XML::GDOME::Document";
        GdomeException exc;
        char * errstr;
        STRLEN len = 0;
    CODE:
        GDOMEPerl_error = NEWSV(0, 512);
        sv_setpvn(GDOMEPerl_error, "", 0);
        RETVAL = gdome_di_createDocFromURI(self,uri,mode,&exc);
        sv_2mortal(GDOMEPerl_error);

        errstr = SvPV(GDOMEPerl_error, len);
        if (len > 0){
          croak("%s",errstr);
        }
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDocument *
createDocFromMemory(self,str,mode)
        GdomeDOMImplementation * self
        char * str
        unsigned int mode
    PREINIT:
        char * CLASS = "XML::GDOME::Document";
        GdomeException exc;
        char * errstr;
        STRLEN len = 0;
    CODE:
        GDOMEPerl_error = NEWSV(0, 512);
        sv_setpvn(GDOMEPerl_error, "", 0);
        RETVAL = gdome_di_createDocFromMemory(self,str,mode,&exc);
        sv_2mortal(GDOMEPerl_error);

        errstr = SvPV(GDOMEPerl_error, len);
        if (len > 0){
          croak("%s",errstr);
        }
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
saveDocToFile(self,doc,filename,mode)
        GdomeDOMImplementation * self
        GdomeDocument * doc
        const char * filename
        GdomeSavingCode mode
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_di_saveDocToFile(self,doc,filename,mode,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
saveDocToFileEnc(self,doc,filename,encoding,mode)
        GdomeDOMImplementation * self
        GdomeDocument * doc
        const char * filename
        const char * encoding
        GdomeSavingCode mode
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_di_saveDocToFileEnc(self,doc,filename,encoding,mode,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

char *
saveDocToString(self,doc,mode)
        GdomeDOMImplementation * self
        GdomeDocument * doc
        GdomeSavingCode mode
    PREINIT:
        char ** mem = malloc(sizeof(char *));
        GdomeException exc;
    CODE:
        if ( gdome_di_saveDocToMemory(self,doc,mem,mode,&exc) ) {
          RETVAL = *mem;
          free(mem);
        }
    OUTPUT:
        RETVAL

char *
saveDocToStringEnc(self,doc,encoding,mode)
        GdomeDOMImplementation * self
        GdomeDocument * doc
        const char * encoding
        GdomeSavingCode mode
    PREINIT:
        char ** mem = malloc(sizeof(char *));
        GdomeException exc;
    CODE:
        if ( gdome_di_saveDocToMemoryEnc(self,doc,mem,encoding,mode,&exc) ) {
          RETVAL = *mem;
          free(mem);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Node

int
gdome_ref(self)
        GdomeNode * self
    PREINIT:
        Gdome_xml_Node *priv;
        xmlNs *ns;
    CODE:
        priv = (Gdome_xml_Node *)self;
        if (priv->n->type == XML_ATTRIBUTE_NODE) {
          ns = gdome_xmlGetNsDeclByAttr((xmlAttr *)priv->n);
          if (ns != NULL)
            RETVAL = (int) ns;
          else
            RETVAL = (int) priv->n;
        } else if (priv->n->type == XML_NAMESPACE_DECL)
          RETVAL = (int) priv->n->ns;
        else
          RETVAL = (int) priv->n;
    OUTPUT:
        RETVAL

char *
toString( self )
        GdomeNode * self
    PREINIT:
        Gdome_xml_Node *priv;
        xmlBufferPtr buffer;
        char *ret = NULL;
    CODE:
        priv = (Gdome_xml_Node *)self;
        buffer = xmlBufferCreate();
        xmlNodeDump( buffer, priv->n->doc, priv->n, 0, 0 );
        if ( buffer->content != 0 ) {
            ret= xmlStrdup( buffer->content );
        }
        xmlBufferFree( buffer );

        if ( priv->n->doc != NULL ) {
            xmlChar *retDecoded = domDecodeString( priv->n->doc->encoding, ret );
            xmlFree( ret );
            RETVAL = retDecoded;
        } else {
            RETVAL = ret;
        }

    OUTPUT:
        RETVAL

char *
string_value ( self )
	GdomeNode * self
    ALIAS:
        to_literal = 1
    PREINIT:
	Gdome_xml_Node *priv;
	char *ret = NULL;
    CODE:
	priv = (Gdome_xml_Node *)self;
	ret = (char *)xmlXPathCastNodeToString(priv->n);

        if ( priv->n->doc != NULL ) {
            xmlChar *retDecoded = domDecodeString( priv->n->doc->encoding, ret );
            xmlFree( ret );
            RETVAL = retDecoded;
        } else {
            RETVAL = ret;
        }
    OUTPUT:
        RETVAL

GdomeNamedNodeMap *
_attributes(self)
        GdomeNode * self
    PREINIT:
        char * CLASS = "XML::GDOME::NamedNodeMap";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_attributes(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNodeList *
_childNodes(self)
        GdomeNode * self
    PREINIT:
        char * CLASS = "XML::GDOME::NodeList";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_childNodes(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
firstChild(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getFirstChild = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_firstChild(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
lastChild(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getLastChild = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_lastChild(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
localName(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getLocalName = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_localName(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
namespaceURI(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getNamespaceURI = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_namespaceURI(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
nextSibling(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getNextSibling = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_nextSibling(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
nodeName(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getNodeName = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_nodeName(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

unsigned short
nodeType(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getNodeType = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_nodeType(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
setNodeValue(self, val)
        GdomeNode * self
        GdomeDOMString * val
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_set_nodeValue(self, val, &exc);
        if (val != NULL)
          gdome_str_unref(val);

GdomeDOMString *
nodeValue(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getNodeValue = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_nodeValue(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDocument *
ownerDocument(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getOwnerDocument = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Document";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_ownerDocument(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
parentNode(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getParentNode = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_parentNode(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
setPrefix(self, val)
        GdomeNode * self
        GdomeDOMString * val
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_set_prefix(self, val, &exc);
        if (val != NULL)
          gdome_str_unref(val);

GdomeDOMString *
prefix(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getPrefix = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_prefix(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
previousSibling(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::getPreviousSibling = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_previousSibling(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
ref(self)
        GdomeNode * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_ref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
unref(self)
        GdomeNode * self
    ALIAS:
        XML::GDOME::Node::DESTROY = 1
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_unref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeNode *
appendChild(self,newChild)
        GdomeNode * self
        GdomeNode * newChild
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_appendChild(self,newChild,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
cloneNode(self,deep)
        GdomeNode * self
        GdomeBoolean deep
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_cloneNode(self,deep,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
hasAttributes(self)
        GdomeNode * self
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_hasAttributes(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
hasChildNodes(self)
        GdomeNode * self
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_hasChildNodes(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
insertBefore(self,newChild,refChild)
        GdomeNode * self
        GdomeNode * newChild
        GdomeNode * refChild
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_insertBefore(self,newChild,refChild,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
isSupported(self,feature,version)
        GdomeNode * self
        GdomeDOMString * feature
        GdomeDOMString * version
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_isSupported(self,feature,version,&exc);
        if(feature != NULL)
          gdome_str_unref(feature);
        if(version != NULL)
          gdome_str_unref(version);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
normalize(self)
        GdomeNode * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_normalize(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeNode *
removeChild(self,oldChild)
        GdomeNode * self
        GdomeNode * oldChild
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_removeChild(self,oldChild,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
replaceChild(self,newChild,oldChild)
        GdomeNode * self
        GdomeNode * newChild
        GdomeNode * oldChild
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_replaceChild(self,newChild,oldChild,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
addEventListener(self,type,listener,useCapture)
        GdomeNode * self
        GdomeDOMString * type
        GdomeEventListener * listener
        GdomeBoolean useCapture
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_addEventListener(self,type,listener,useCapture,&exc);
        if(type != NULL)
          gdome_str_unref(type);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
removeEventListener(self,type,listener,useCapture)
        GdomeNode * self
        GdomeDOMString * type
        GdomeEventListener * listener
        GdomeBoolean useCapture
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_removeEventListener(self,type,listener,useCapture,&exc);
        if(type != NULL)
          gdome_str_unref(type);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeBoolean
dispatchEvent(self,evt)
        GdomeNode * self
        GdomeEvent * evt
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_dispatchEvent(self,evt,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
subTreeDispatchEvent(self,evt)
        GdomeNode * self
        GdomeEvent * evt
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_n_subTreeDispatchEvent(self,evt,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeBoolean
canAppend(self,newChild)
        GdomeNode * self
        GdomeNode * newChild
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_n_canAppend(self,newChild,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::DocumentFragment

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Document

void
process_xinclude(self)
        GdomeDocument* self
    PREINIT:
        Gdome_xml_Node *priv;        
    CODE:
        priv = (Gdome_xml_Node *)self;
        xmlXIncludeProcess((xmlDocPtr)priv->n);

GdomeDocumentType *
doctype(self)
        GdomeDocument * self
    ALIAS:
        XML::GDOME::Document::getDoctype = 1
    PREINIT:
        char * CLASS = "XML::GDOME::DocumentType";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_doctype(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeElement *
documentElement(self)
        GdomeDocument * self
    ALIAS:
        XML::GDOME::Document::getDocumentElement = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Element";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_documentElement(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMImplementation *
implementation(self)
        GdomeDocument * self
    ALIAS:
        XML::GDOME::Document::getImplementation = 1
    PREINIT:
        char * CLASS = "XML::GDOME::DOMImplementation";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_implementation(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeAttr *
_createAttribute(self,name)
        GdomeDocument * self
        GdomeDOMString * name
    PREINIT:
        char * CLASS = "XML::GDOME::Attr";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createAttribute(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeAttr *
createAttributeNS(self,namespaceURI,qualifiedName)
        GdomeDocument * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * qualifiedName
    PREINIT:
        char * CLASS = "XML::GDOME::Attr";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createAttributeNS(self,namespaceURI,qualifiedName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(qualifiedName != NULL)
          gdome_str_unref(qualifiedName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeCDATASection *
createCDATASection(self,data)
        GdomeDocument * self
        GdomeDOMString * data
    PREINIT:
        char * CLASS = "XML::GDOME::CDATASection";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createCDATASection(self,data,&exc);
        if(data != NULL)
          gdome_str_unref(data);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeComment *
createComment(self,data)
        GdomeDocument * self
        GdomeDOMString * data
    PREINIT:
        char * CLASS = "XML::GDOME::Comment";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createComment(self,data,&exc);
        if(data != NULL)
          gdome_str_unref(data);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDocumentFragment *
createDocumentFragment(self)
        GdomeDocument * self
    PREINIT:
        char * CLASS = "XML::GDOME::DocumentFragment";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createDocumentFragment(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeElement *
createElement(self,tagName)
        GdomeDocument * self
        GdomeDOMString * tagName
    PREINIT:
        char * CLASS = "XML::GDOME::Element";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createElement(self,tagName,&exc);
        if(tagName != NULL)
          gdome_str_unref(tagName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeElement *
createElementNS(self,namespaceURI,qualifiedName)
        GdomeDocument * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * qualifiedName
    PREINIT:
        char * CLASS = "XML::GDOME::Element";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createElementNS(self,namespaceURI,qualifiedName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(qualifiedName != NULL)
          gdome_str_unref(qualifiedName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeEntityReference *
createEntityReference(self,name)
        GdomeDocument * self
        GdomeDOMString * name
    PREINIT:
        char * CLASS = "XML::GDOME::EntityReference";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createEntityReference(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeProcessingInstruction *
createProcessingInstruction(self,target,data)
        GdomeDocument * self
        GdomeDOMString * target
        GdomeDOMString * data
    PREINIT:
        char * CLASS = "XML::GDOME::ProcessingInstruction";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createProcessingInstruction(self,target,data,&exc);
        if(target != NULL)
          gdome_str_unref(target);
        if(data != NULL)
          gdome_str_unref(data);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeText *
createTextNode(self,data)
        GdomeDocument * self
        GdomeDOMString * data
    PREINIT:
        char * CLASS = "XML::GDOME::Text";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createTextNode(self,data,&exc);
        if(data != NULL)
          gdome_str_unref(data);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeElement *
getElementById(self,elementId)
        GdomeDocument * self
        GdomeDOMString * elementId
    PREINIT:
        char * CLASS = "XML::GDOME::Element";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_getElementById(self,elementId,&exc);
        if(elementId != NULL)
          gdome_str_unref(elementId);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNodeList *
_getElementsByTagName(self,tagname)
        GdomeDocument * self
        GdomeDOMString * tagname
    PREINIT:
        char * CLASS = "XML::GDOME::NodeList";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_getElementsByTagName(self,tagname,&exc);
        if(tagname != NULL)
          gdome_str_unref(tagname);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNodeList *
_getElementsByTagNameNS(self,namespaceURI,localName)
        GdomeDocument * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        char * CLASS = "XML::GDOME::NodeList";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_getElementsByTagNameNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
importNode(self,importedNode,deep)
        GdomeDocument * self
        GdomeNode * importedNode
        GdomeBoolean deep
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_importNode(self,importedNode,deep,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeEvent *
createEvent(self,eventType)
        GdomeDocument * self
        GdomeDOMString * eventType
    PREINIT:
        char * CLASS = "XML::GDOME::Event";
        GdomeException exc;
    CODE:
        RETVAL = gdome_doc_createEvent(self,eventType,&exc);
        if(eventType != NULL)
          gdome_str_unref(eventType);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::CharacterData

void
setData(self, val)
        GdomeCharacterData * self
        GdomeDOMString * val
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_cd_set_data(self, val, &exc);
        if (val != NULL)
          gdome_str_unref(val);

GdomeDOMString *
data(self)
        GdomeCharacterData * self
    ALIAS:
        XML::GDOME::CharacterData::getData = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_cd_data(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

gulong
length(self)
        GdomeCharacterData * self
    ALIAS:
        XML::GDOME::CharacterData::getLength = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_cd_length(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
appendData(self,arg)
        GdomeCharacterData * self
        GdomeDOMString * arg
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_cd_appendData(self,arg,&exc);
        if(arg != NULL)
          gdome_str_unref(arg);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
deleteData(self,offset,count)
        GdomeCharacterData * self
        gulong offset
        gulong count
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_cd_deleteData(self,offset,count,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
insertData(self,offset,arg)
        GdomeCharacterData * self
        gulong offset
        GdomeDOMString * arg
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_cd_insertData(self,offset,arg,&exc);
        if(arg != NULL)
          gdome_str_unref(arg);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
replaceData(self,offset,count,arg)
        GdomeCharacterData * self
        gulong offset
        gulong count
        GdomeDOMString * arg
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_cd_replaceData(self,offset,count,arg,&exc);
        if(arg != NULL)
          gdome_str_unref(arg);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeDOMString *
substringData(self,offset,count)
        GdomeCharacterData * self
        gulong offset
        gulong count
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_cd_substringData(self,offset,count,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Text

GdomeText *
splitText(self,offset)
        GdomeText * self
        gulong offset
    PREINIT:
        char * CLASS = "XML::GDOME::Text";
        GdomeException exc;
    CODE:
        RETVAL = gdome_t_splitText(self,offset,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::CDATASection

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Comment

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Attr

GdomeDOMString *
name(self)
        GdomeAttr * self
    ALIAS:
        XML::GDOME::Attr::getName = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_a_name(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeElement *
ownerElement(self)
        GdomeAttr * self
    ALIAS:
        XML::GDOME::Attr::getOwnerElement = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Element";
        GdomeException exc;
    CODE:
        RETVAL = gdome_a_ownerElement(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
specified(self)
        GdomeAttr * self
    ALIAS:
        XML::GDOME::Attr::getSpecified = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_a_specified(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
setValue(self, val)
        GdomeAttr * self
        GdomeDOMString * val
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_a_set_value(self, val, &exc);
        if (val != NULL)
          gdome_str_unref(val);

GdomeDOMString *
value(self)
        GdomeAttr * self
    ALIAS:
        XML::GDOME::Attr::getValue = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_a_value(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Element

GdomeDOMString *
tagName(self)
        GdomeElement * self
    ALIAS:
        XML::GDOME::Element::getTagName = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_tagName(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
getAttribute(self,name)
        GdomeElement * self
        GdomeDOMString * name
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_getAttribute(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
getAttributeNS(self,namespaceURI,localName)
        GdomeElement * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_getAttributeNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeAttr *
getAttributeNode(self,name)
        GdomeElement * self
        GdomeDOMString * name
    PREINIT:
        char * CLASS = "XML::GDOME::Attr";
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_getAttributeNode(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeAttr *
getAttributeNodeNS(self,namespaceURI,localName)
        GdomeElement * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        char * CLASS = "XML::GDOME::Attr";
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_getAttributeNodeNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNodeList *
_getElementsByTagName(self,name)
        GdomeElement * self
        GdomeDOMString * name
    PREINIT:
        char * CLASS = "XML::GDOME::NodeList";
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_getElementsByTagName(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNodeList *
_getElementsByTagNameNS(self,namespaceURI,localName)
        GdomeElement * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        char * CLASS = "XML::GDOME::NodeList";
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_getElementsByTagNameNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
hasAttribute(self,name)
        GdomeElement * self
        GdomeDOMString * name
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_hasAttribute(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
hasAttributeNS(self,namespaceURI,localName)
        GdomeElement * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_hasAttributeNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
removeAttribute(self,name)
        GdomeElement * self
        GdomeDOMString * name
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_el_removeAttribute(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
removeAttributeNS(self,namespaceURI,localName)
        GdomeElement * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_el_removeAttributeNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeAttr *
removeAttributeNode(self,oldAttr)
        GdomeElement * self
        GdomeAttr * oldAttr
    PREINIT:
        char * CLASS = "XML::GDOME::Attr";
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_removeAttributeNode(self,oldAttr,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
setAttribute(self,name,value)
        GdomeElement * self
        GdomeDOMString * name
        GdomeDOMString * value
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_el_setAttribute(self,name,value,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if(value != NULL)
          gdome_str_unref(value);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
setAttributeNS(self,namespaceURI,qualifiedName,value)
        GdomeElement * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * qualifiedName
        GdomeDOMString * value
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_el_setAttributeNS(self,namespaceURI,qualifiedName,value,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(qualifiedName != NULL)
          gdome_str_unref(qualifiedName);
        if(value != NULL)
          gdome_str_unref(value);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeAttr *
setAttributeNode(self,newAttr)
        GdomeElement * self
        GdomeAttr * newAttr
    PREINIT:
        char * CLASS = "XML::GDOME::Attr";
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_setAttributeNode(self,newAttr,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeAttr *
setAttributeNodeNS(self,newAttr)
        GdomeElement * self
        GdomeAttr * newAttr
    PREINIT:
        char * CLASS = "XML::GDOME::Attr";
        GdomeException exc;
    CODE:
        RETVAL = gdome_el_setAttributeNodeNS(self,newAttr,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::DocumentType

GdomeNamedNodeMap *
entities(self)
        GdomeDocumentType * self
    ALIAS:
        XML::GDOME::DocumentType::getEntities = 1
    PREINIT:
        char * CLASS = "XML::GDOME::NamedNodeMap";
        GdomeException exc;
    CODE:
        RETVAL = gdome_dt_entities(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
internalSubset(self)
        GdomeDocumentType * self
    ALIAS:
        XML::GDOME::DocumentType::getInternalSubset = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_dt_internalSubset(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
name(self)
        GdomeDocumentType * self
    ALIAS:
        XML::GDOME::DocumentType::getName = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_dt_name(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNamedNodeMap *
notations(self)
        GdomeDocumentType * self
    ALIAS:
        XML::GDOME::DocumentType::getNotations = 1
    PREINIT:
        char * CLASS = "XML::GDOME::NamedNodeMap";
        GdomeException exc;
    CODE:
        RETVAL = gdome_dt_notations(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
publicId(self)
        GdomeDocumentType * self
    ALIAS:
        XML::GDOME::DocumentType::getPublicId = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_dt_publicId(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
systemId(self)
        GdomeDocumentType * self
    ALIAS:
        XML::GDOME::DocumentType::getSystemId = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_dt_systemId(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Notation

GdomeDOMString *
publicId(self)
        GdomeNotation * self
    ALIAS:
        XML::GDOME::Notation::getPublicId = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_not_publicId(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
systemId(self)
        GdomeNotation * self
    ALIAS:
        XML::GDOME::Notation::getSystemId = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_not_systemId(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::Entity

GdomeDOMString *
publicId(self)
        GdomeEntity * self
    ALIAS:
        XML::GDOME::Entity::getPublicId = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_ent_publicId(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
systemId(self)
        GdomeEntity * self
    ALIAS:
        XML::GDOME::Entity::getSystemId = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_ent_systemId(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
notationName(self)
        GdomeEntity * self
    ALIAS:
        XML::GDOME::Entity::getNotationName = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_ent_notationName(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::EntityReference

MODULE = XML::GDOME       PACKAGE = XML::GDOME::ProcessingInstruction

void
setData(self, val)
        GdomeProcessingInstruction * self
        GdomeDOMString * val
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_pi_set_data(self, val, &exc);
        if (val != NULL)
          gdome_str_unref(val);

GdomeDOMString *
data(self)
        GdomeProcessingInstruction * self
    ALIAS:
        XML::GDOME::ProcessingInstruction::getData = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_pi_data(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
target(self)
        GdomeProcessingInstruction * self
    ALIAS:
        XML::GDOME::ProcessingInstruction::getTarget = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_pi_target(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::XPath::Namespace

GdomeElement *
ownerElement(self)
        GdomeXPathNamespace * self
    ALIAS:
        XML::GDOME::XPathNamespace::getOwnerElement = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Element";
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpns_ownerElement(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::NodeList

gulong
length(self)
        GdomeNodeList * self
    ALIAS:
        XML::GDOME::NodeList::getLength = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_nl_length(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
ref(self)
        GdomeNodeList * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_nl_ref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
unref(self)
        GdomeNodeList * self
    ALIAS:
        XML::GDOME::NodeList::DESTROY = 1
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_nl_unref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeNode *
item(self,index)
        GdomeNodeList * self
        gulong index
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nl_item(self,index,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::NamedNodeMap

gulong
length(self)
        GdomeNamedNodeMap * self
    ALIAS:
        XML::GDOME::NamedNodeMap::getLength = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_length(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
ref(self)
        GdomeNamedNodeMap * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_nnm_ref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
unref(self)
        GdomeNamedNodeMap * self
    ALIAS:
        XML::GDOME::NamedNodeMap::DESTROY = 1
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_nnm_unref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeNode *
getNamedItem(self,name)
        GdomeNamedNodeMap * self
        GdomeDOMString * name
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_getNamedItem(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
getNamedItemNS(self,namespaceURI,localName)
        GdomeNamedNodeMap * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_getNamedItemNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
item(self,index)
        GdomeNamedNodeMap * self
        gulong index
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_item(self,index,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
removeNamedItem(self,name)
        GdomeNamedNodeMap * self
        GdomeDOMString * name
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_removeNamedItem(self,name,&exc);
        if(name != NULL)
          gdome_str_unref(name);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
removeNamedItemNS(self,namespaceURI,localName)
        GdomeNamedNodeMap * self
        GdomeDOMString * namespaceURI
        GdomeDOMString * localName
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_removeNamedItemNS(self,namespaceURI,localName,&exc);
        if(namespaceURI != NULL)
          gdome_str_unref(namespaceURI);
        if(localName != NULL)
          gdome_str_unref(localName);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
setNamedItem(self,arg)
        GdomeNamedNodeMap * self
        GdomeNode * arg
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_setNamedItem(self,arg,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
setNamedItemNS(self,arg)
        GdomeNamedNodeMap * self
        GdomeNode * arg
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_nnm_setNamedItemNS(self,arg,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::XPath::Evaluator

GdomeXPathEvaluator *
mkref()
    PREINIT:
        char * CLASS = "XML::GDOME::XPath::Evaluator";
    CODE:
        RETVAL = gdome_xpeval_mkref();
    OUTPUT:
        RETVAL

void
ref(self)
        GdomeXPathEvaluator * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_xpeval_ref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
unref(self)
        GdomeXPathEvaluator * self
    ALIAS:
        XML::GDOME::XPath::Evaluator::DESTROY = 1
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_xpeval_unref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeXPathNSResolver *
createNSResolver(self,nodeResolver)
        GdomeXPathEvaluator * self
        GdomeNode * nodeResolver
    PREINIT:
        char * CLASS = "XML::GDOME::XPath::NSResolver";
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpeval_createNSResolver(self,nodeResolver,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeXPathResult *
createResult(self)
        GdomeXPathEvaluator * self
    PREINIT:
        char * CLASS = "XML::GDOME::XPath::Result";
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpeval_createResult(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeXPathResult *
evaluate(self,expression,contextNode,resolver,type,result)
        GdomeXPathEvaluator * self
        GdomeDOMString * expression
        GdomeNode * contextNode
        GdomeXPathNSResolver * resolver
        unsigned int type
        GdomeXPathResult * result
    PREINIT:
        char * CLASS = "XML::GDOME::XPath::Result";
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpeval_evaluate(self,expression,contextNode,resolver,type,result,&exc);
        if(expression != NULL)
          gdome_str_unref(expression);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::XPath::NSResolver

void
ref(self)
        GdomeXPathNSResolver * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_xpnsresolv_ref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
unref(self)
        GdomeXPathNSResolver * self
    ALIAS:
        XML::GDOME::XPath::NSResolver::DESTROY = 1
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_xpnsresolv_unref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeDOMString *
lookupNamespaceURI(self,prefix)
        GdomeXPathNSResolver * self
        GdomeDOMString * prefix
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpnsresolv_lookupNamespaceURI(self,prefix,&exc);
        if(prefix != NULL)
          gdome_str_unref(prefix);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME       PACKAGE = XML::GDOME::XPath::Result

unsigned short
resultType(self)
        GdomeXPathResult * self
    ALIAS:
        XML::GDOME::XPathResult::getResultType = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpresult_resultType(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeBoolean
booleanValue(self)
        GdomeXPathResult * self
    ALIAS:
        XML::GDOME::XPathResult::getBooleanValue = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpresult_booleanValue(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

double
numberValue(self)
        GdomeXPathResult * self
    ALIAS:
        XML::GDOME::XPathResult::getNumberValue = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpresult_numberValue(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeDOMString *
stringValue(self)
        GdomeXPathResult * self
    ALIAS:
        XML::GDOME::XPathResult::getStringValue = 1
    PREINIT:
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpresult_stringValue(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

GdomeNode *
singleNodeValue(self)
        GdomeXPathResult * self
    ALIAS:
        XML::GDOME::XPathResult::getSingleNodeValue = 1
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpresult_singleNodeValue(self, &exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL

void
ref(self)
        GdomeXPathResult * self
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_xpresult_ref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

void
unref(self)
        GdomeXPathResult * self
    ALIAS:
        XML::GDOME::XPath::Result::DESTROY = 1
    PREINIT:
        GdomeException exc;
    CODE:
        gdome_xpresult_unref(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }

GdomeNode *
iterateNext(self)
        GdomeXPathResult * self
    PREINIT:
        char * CLASS = "XML::GDOME::Node";
        GdomeException exc;
    CODE:
        RETVAL = gdome_xpresult_iterateNext(self,&exc);
        if (exc>0){
          croak("%s",errorMsg[exc]);
        }
    OUTPUT:
        RETVAL



MODULE = XML::GDOME         PACKAGE = XML::GDOME

SV *
_match_callback(self, ...)
        SV * self
    CODE:
        if (items > 1) {
            SET_CB(GDOMEPerl_match_cb, ST(1));
        }
        else {
            RETVAL = GDOMEPerl_match_cb ? sv_2mortal(GDOMEPerl_match_cb) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
_open_callback(self, ...)
        SV * self
    CODE:
        if (items > 1) {
            SET_CB(GDOMEPerl_open_cb, ST(1));
        }
        else {
            RETVAL = GDOMEPerl_open_cb ? sv_2mortal(GDOMEPerl_open_cb) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
_read_callback(self, ...)
        SV * self
    CODE:
        if (items > 1) {
            SET_CB(GDOMEPerl_read_cb, ST(1));
        }
        else {
            RETVAL = GDOMEPerl_read_cb ? sv_2mortal(GDOMEPerl_read_cb) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
_close_callback(self, ...)
        SV * self
    CODE:
        if (items > 1) {
            SET_CB(GDOMEPerl_close_cb, ST(1));
        }
        else {
            RETVAL = GDOMEPerl_close_cb ? sv_2mortal(GDOMEPerl_close_cb) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL


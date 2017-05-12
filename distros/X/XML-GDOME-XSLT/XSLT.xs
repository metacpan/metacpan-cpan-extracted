#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libxml/xmlversion.h>
#include <libxml/xmlmemory.h>
#include <libxml/HTMLtree.h>
#include <libxml/xmlIO.h>
#include <libxml/tree.h>
#include <libxml/parserInternals.h>
#include <libxslt/xsltconfig.h>
#include <libxslt/xslt.h>
#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>
#include <libxslt/imports.h>
#ifdef HAVE_EXSLT
#include <libexslt/exslt.h>
#include <libexslt/exsltconfig.h>
#endif

#include "gdome.h"

typedef struct _Gdome_xml_Document Gdome_xml_Document;
struct _Gdome_xml_Document {
        GdomeDocument super;
        const GdomeDocumentVtab *vtab;
        int refcnt;
        xmlDoc *n;
  GdomeAccessType accessType;
};

GdomeNode * gdome_xml_n_mkref(xmlNode *n);

#ifdef __cplusplus
}
#endif

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

#define SET_CB2(cb, fld) cb=fld;

static SV * LibXSLT_debug_cb = NULL;

void
LibXSLT_free_all_callbacks(void)
{
    if (LibXSLT_debug_cb) {
        SvREFCNT_dec(LibXSLT_debug_cb);
    }
}

int
LibXSLT_iowrite_scalar(void * context, const char * buffer, int len)
{
    SV * scalar;
    
    scalar = (SV *)context;

    sv_catpvn(scalar, (char*)buffer, len);
    
    return len;
}

int
LibXSLT_ioclose_scalar(void * context)
{
    return 0;
}

int
LibXSLT_iowrite_fh(void * context, const char * buffer, int len)
{
    dSP;
    
    SV * ioref;
    SV * tbuff;
    SV * results;
    int cnt;
    
    ENTER;
    SAVETMPS;
    
    ioref = (SV *)context;
    
    tbuff = newSVpvn((char*)buffer, len);

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(ioref);
    PUSHs(sv_2mortal(tbuff));
    PUTBACK;
    
    cnt = perl_call_method("print", G_SCALAR);
    
    SPAGAIN;
    
    if (cnt != 1) {
        croak("fh->print() method call failed");
    }
    
    results = POPs;
    
    if (!SvOK(results)) {
        croak("print to fh failed");
    }
    
    PUTBACK;
    
    FREETMPS;
    LEAVE;
    
    return len;
}

int
LibXSLT_ioclose_fh(void * context)
{
    return 0; /* we let Perl close the FH */
}

void
LibXSLT_error_handler(void * ctxt, const char * msg, ...)
{
    va_list args;
    SV * sv;
    STRLEN n_a;
    
    sv = NEWSV(0,512);

    va_start(args, msg);
    sv_vsetpvfn(sv, msg, strlen(msg), &args, NULL, 0, NULL);
    va_end(args);

    sv_2mortal(sv);
    croak(SvPV(sv, n_a));
}

void
LibXSLT_debug_handler(void * ctxt, const char * msg, ...)
{
    dSP;
    
    va_list args;
    SV * sv;
    STRLEN n_a;
    
    sv = NEWSV(0,512);

    va_start(args, msg);
    sv_vsetpvfn(sv, msg, strlen(msg), &args, NULL, 0, NULL);
    va_end(args);

    if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
        int cnt = 0;
    
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv);
        PUTBACK;

        cnt = perl_call_sv(LibXSLT_debug_cb, G_SCALAR);

        SPAGAIN;

        if (cnt != 1) {
            croak("debug handler call failed");
        }

        PUTBACK;

        FREETMPS;
        LEAVE;
    }
    
    SvREFCNT_dec(sv);
}

MODULE = XML::GDOME::XSLT         PACKAGE = XML::GDOME::XSLT

PROTOTYPES: DISABLE

BOOT:
    LIBXML_TEST_VERSION
    xsltMaxDepth = 250;
#ifdef HAVE_EXSLT
    exsltRegisterAll();
#endif


int
max_depth(self, ...)
        SV * self
    CODE:
        RETVAL = xsltMaxDepth;
        if (items > 1) {
            xsltMaxDepth = SvIV(ST(1));
        }
    OUTPUT:
        RETVAL

SV *
debug_callback(self, ...)
        SV * self
    CODE:
        if (items > 1) {
            SV * debug_cb = ST(1);
            if (debug_cb && SvTRUE(debug_cb)) {
                SET_CB(LibXSLT_debug_cb, ST(1));
            }
            else {
                LibXSLT_debug_cb = NULL;
            }
        }
        else {
            RETVAL = LibXSLT_debug_cb ? sv_2mortal(LibXSLT_debug_cb) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

xsltStylesheetPtr
_parse_stylesheet(self, doc)
        SV * self
        GdomeDocument *doc
    PREINIT:
        char * CLASS = "XML::GDOME::XSLT::Stylesheet";
        xmlDocPtr doc_copy;
    CODE:
        if (doc == NULL) {
            XSRETURN_UNDEF;
        }
        doc_copy = xmlCopyDoc(((Gdome_xml_Document *)doc)->n, 1);
        doc_copy->URL = xmlStrdup(((Gdome_xml_Document *)doc)->n->URL);

        if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
            xsltSetGenericDebugFunc(PerlIO_stderr(), (xmlGenericErrorFunc)LibXSLT_debug_handler);
        }
        else {
            xsltSetGenericDebugFunc(NULL, NULL);
        }
        RETVAL = xsltParseStylesheetDoc(doc_copy);
        if (RETVAL == NULL) {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

xsltStylesheetPtr
_parse_stylesheet_file(self, filename)
        SV * self
        const char * filename
    PREINIT:
        char * CLASS = "XML::GDOME::XSLT::Stylesheet";
    CODE:
        if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
            xsltSetGenericDebugFunc(PerlIO_stderr(), (xmlGenericErrorFunc)LibXSLT_debug_handler);
        }
        else {
            xsltSetGenericDebugFunc(NULL, NULL);
        }
        RETVAL = xsltParseStylesheetFile(filename);
        if (RETVAL == NULL) {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

MODULE = XML::GDOME::XSLT         PACKAGE = XML::GDOME::XSLT::Stylesheet

PROTOTYPES: DISABLE

GdomeDocument *
transform(self, doc, ...)
        xsltStylesheetPtr self
        GdomeDocument * doc
    PREINIT:
        char * CLASS = "XML::GDOME::Document";
        # note really only 254 entries here - last one is NULL
        const char *xslt_params[255];
        xmlDocPtr real_dom;
    CODE:
        if (doc == NULL) {
            XSRETURN_UNDEF;
        }
        xslt_params[0] = 0;
        if (items > 256) {
            croak("Too many parameters in transform()");
        }
        if (items % 2) {
            croak("Odd number of parameters");
        }
        if (items > 2) {
            int i;
            for (i = 2; (i < items && i < 256); i++) {
                xslt_params[i - 2] = (char *)SvPV(ST(i), PL_na);
            }
            # set last entry to NULL
            xslt_params[i - 2] = 0;
        }

        if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
            xsltSetGenericDebugFunc(PerlIO_stderr(), (xmlGenericErrorFunc)LibXSLT_debug_handler);
        }
        else {
            xsltSetGenericDebugFunc(NULL, NULL);
        }
        real_dom = xsltApplyStylesheet(self, ((Gdome_xml_Document *)doc)->n, xslt_params);
        if (real_dom == NULL) {
            XSRETURN_UNDEF;
        }
        if (real_dom->type == XML_HTML_DOCUMENT_NODE) {
            if (self->method != NULL) {
                xmlFree(self->method);
            }
            self->method = xmlMalloc(5);
            strcpy(self->method, "html");
        }
        RETVAL = (GdomeDocument *)gdome_xml_n_mkref((xmlNode *)real_dom);
    OUTPUT:
        RETVAL

GdomeDocument *
transform_file(self, filename, ...)
        xsltStylesheetPtr self
        char * filename
    PREINIT:
        char * CLASS = "XML::GDOME::Document";
        # note really only 254 entries here - last one is NULL
        const char *xslt_params[255];
        xmlDocPtr real_dom;
    CODE:
        xslt_params[0] = 0;
        if (items > 256) {
            croak("Too many parameters in transform()");
        }
        if (items % 2) {
            croak("Odd number of parameters");
        }
        if (items > 2) {
            int i;
            for (i = 2; (i < items && i < 256); i++) {
                xslt_params[i - 2] = (char *)SvPV(ST(i), PL_na);
            }
            # set last entry to NULL
            xslt_params[i - 2] = 0;
        }
        if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
            xsltSetGenericDebugFunc(PerlIO_stderr(), (xmlGenericErrorFunc)LibXSLT_debug_handler);
        }
        else {
            xsltSetGenericDebugFunc(NULL, NULL);
        }
        real_dom = xsltApplyStylesheet(self, xmlParseFile(filename), xslt_params);
        if (real_dom == NULL) {
            XSRETURN_UNDEF;
        }
        if (real_dom->type == XML_HTML_DOCUMENT_NODE) {
            if (self->method != NULL) {
                xmlFree(self->method);
            }
            self->method = xmlMalloc(5);
            strcpy(self->method, "html");
        }
        RETVAL = (GdomeDocument *)gdome_xml_n_mkref((xmlNode *)real_dom);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        xsltStylesheetPtr self
    CODE:
        if (self == NULL) {
            XSRETURN_UNDEF;
        }
        xsltFreeStylesheet(self);

SV *
output_string(self, doc)
        xsltStylesheetPtr self
        GdomeDocument * doc
    PREINIT:
        xmlOutputBufferPtr output;
        SV * results = newSVpv("", 0);
        const xmlChar *encoding = NULL;
	xmlCharEncodingHandlerPtr encoder = NULL;
    CODE:
        XSLT_GET_IMPORT_PTR(encoding, self, encoding)
        if (encoding != NULL) {
            encoder = xmlFindCharEncodingHandler((char *)encoding);
	    if ((encoder != NULL) &&
                 (xmlStrEqual((const xmlChar *)encoder->name,
                              (const xmlChar *) "UTF-8")))
                encoder = NULL;
        }

        if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
            xsltSetGenericDebugFunc(PerlIO_stderr(), (xmlGenericErrorFunc)LibXSLT_debug_handler);
        }
        else {
            xsltSetGenericDebugFunc(NULL, NULL);
        }
        output = xmlOutputBufferCreateIO( 
            (xmlOutputWriteCallback) LibXSLT_iowrite_scalar,
            (xmlOutputCloseCallback) LibXSLT_ioclose_scalar,
            (void*)results,
            encoder
            );
        if (xsltSaveResultTo(output, ((Gdome_xml_Document *)doc)->n, self) == -1) {
            croak("output to scalar failed");
        }
        xmlOutputBufferClose(output);
        RETVAL = results;
    OUTPUT:
        RETVAL

void
output_fh(self, doc, fh)
        xsltStylesheetPtr self
        GdomeDocument * doc
        SV * fh
    PREINIT:
        xmlOutputBufferPtr output;
        const xmlChar *encoding = NULL;
	xmlCharEncodingHandlerPtr encoder = NULL;
    CODE:
        XSLT_GET_IMPORT_PTR(encoding, self, encoding)
        if (encoding != NULL) {
            encoder = xmlFindCharEncodingHandler((char *)encoding);
	    if ((encoder != NULL) &&
                 (xmlStrEqual((const xmlChar *)encoder->name,
                              (const xmlChar *) "UTF-8")))
                encoder = NULL;
        }

        if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
            xsltSetGenericDebugFunc(PerlIO_stderr(), (xmlGenericErrorFunc)LibXSLT_debug_handler);
        }
        else {
            xsltSetGenericDebugFunc(NULL, NULL);
        }
        output = xmlOutputBufferCreateIO( 
            (xmlOutputWriteCallback) LibXSLT_iowrite_fh,
            (xmlOutputCloseCallback) LibXSLT_ioclose_fh,
            (void*)fh,
            encoder
            );
        if (xsltSaveResultTo(output, ((Gdome_xml_Document *)doc)->n, self) == -1) {
            croak("output to fh failed");
        }
        xmlOutputBufferClose(output);
        
void
output_file(self, doc, filename)
        xsltStylesheetPtr self
        GdomeDocument * doc
        char * filename
    CODE:
        if (LibXSLT_debug_cb && SvTRUE(LibXSLT_debug_cb)) {
            xsltSetGenericDebugFunc(PerlIO_stderr(), (xmlGenericErrorFunc)LibXSLT_debug_handler);
        }
        else {
            xsltSetGenericDebugFunc(NULL, NULL);
        }
        xsltSaveResultToFilename(filename, ((Gdome_xml_Document *)doc)->n, self, 0);

char *
media_type(self)
        xsltStylesheetPtr self
    CODE:
        RETVAL = (char *)self->mediaType;
        if (RETVAL == NULL) {
            /* OK, that was borked. Try finding xsl:output tag manually... */
            xmlNodePtr child;
            child = self->doc->children->children;
            while ( child != NULL && 
                    strcmp(child->name, "output") != 0 &&
                    child->ns && child->ns->href &&
                    strcmp(child->ns->href, 
                    "http://www.w3.org/1999/XSL/Transform") != 0) {
                child = child->next;
            }
            
            if (child != NULL) {
                 RETVAL = xmlGetProp(child, "media-type");
            }
            
            if (RETVAL == NULL) {
                RETVAL = "text/xml";
                /* this below is rather simplistic, but should work for most cases */
                if (self->method != NULL) {
                    if (strcmp(self->method, "html") == 0) {
                        RETVAL = "text/html";
                    }
                    else if (strcmp(self->method, "text") == 0) {
                        RETVAL = "text/plain";
                    }
                }
            }
        }
    OUTPUT:
        RETVAL

char *
output_encoding(self)
        xsltStylesheetPtr self
    CODE:
        RETVAL = (char *)self->encoding;
        if (RETVAL == NULL) {
            RETVAL = "UTF-8";
        }
    OUTPUT:
        RETVAL

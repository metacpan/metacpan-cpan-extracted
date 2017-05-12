#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* libxml2 configuration properties */
#include <libxml/xmlversion.h>

#if LIBXML_VERSION >= 20621
#include <libxml/xmlreader.h>
#endif

#define PREINIT_SAVED_ERROR   SV* saved_error = sv_2mortal(newSV(0));

#define CLEANUP_ERROR_HANDLER  xmlSetGenericErrorFunc(NULL,NULL); \
                               xmlSetStructuredErrorFunc(NULL,NULL)

#define INIT_ERROR_HANDLER                                                      \
     xmlSetGenericErrorFunc(NULL,NULL);                                         \
     xmlSetStructuredErrorFunc((void *)saved_error,			        \
			    (xmlStructuredErrorFunc)LibXML_struct_error_handler)

#define REPORT_ERROR(recover) LibXML_report_error_ctx(saved_error, recover)

#define XCT_IGNORE_WS                         1 << 0
#define XCT_IGNORE_SIGNIFICANT_WS             1 << 1
#define XCT_IGNORE_PROCESSING_INSTRUCTIONS    1 << 2
#define XCT_IGNORE_COMMENTS                   1 << 3
#define XCT_USE_QNAMES                        1 << 4  /* not yet implemented */
#define XCT_KEEP_NS_DECLS                     1 << 5
#define XCT_TEXT_AS_STRING                    1 << 6  /* not yet implemented */
#define XCT_ATTRIBUTE_ARRAY                   1 << 7
#define XCT_PRESERVE_PARENT                   1 << 8  /* not yet implemented */
#define XCT_MERGE_TEXT_NODES                  1 << 9  /* not yet implemented */
#define XCT_LINE_NUMBERS                      1 << 10
#define XCT_DOCUMENT_ROOT                     1 << 11

static SV*
Char2SV( const xmlChar *string )
{
    SV *retval = &PL_sv_undef;
    if ( string != NULL ) {
        retval = newSVpvn( (const char *)string, (STRLEN) xmlStrlen( string ));
	SvUTF8_on(retval);
    }
    return retval;
}

static void
LibXML_report_error_ctx(SV * saved_error, int recover)
{
  if( saved_error!=NULL && SvOK( saved_error ) ) {
    if (!recover || recover==1) {
      dTHX;
      dSP;
      
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      EXTEND(SP, 1);
      PUSHs(saved_error);
      PUTBACK;
      if (recover==1) {
	call_pv( "XML::LibXML::Error::_report_warning", G_SCALAR | G_DISCARD);
      } else {
	call_pv( "XML::LibXML::Error::_report_error", G_SCALAR | G_DISCARD);
      }
      SPAGAIN;
      
      PUTBACK;
      FREETMPS;
      LEAVE;
    }
  }
}

static void
LibXML_struct_error_callback(SV * saved_error, SV * libErr )
{

    dTHX;
    dSP;

    if ( saved_error == NULL ) {
        warn( "have no save_error\n" );
    }
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    
    XPUSHs(sv_2mortal(libErr));
    if ( saved_error != NULL && SvOK(saved_error) ) {
        XPUSHs(saved_error);
    }
    PUTBACK;
    
    if ( saved_error != NULL ) {
      call_pv( "XML::LibXML::Error::_callback_error", G_SCALAR | G_EVAL );
    } else {
      call_pv( "XML::LibXML::Error::_instant_error_callback", G_SCALAR );
    }
    SPAGAIN;

    if ( SvTRUE(ERRSV) ) {
      (void) POPs;
      croak( "DIE: %s", SvPV_nolen(ERRSV) );
    } else {
      sv_setsv(saved_error, POPs);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
}

static void
LibXML_struct_error_handler(SV * saved_error, xmlErrorPtr error )
{
    const char * CLASS = "XML::LibXML::LibError";
    SV* libErr;

    libErr = NEWSV(0,0);
    sv_setref_pv( libErr, CLASS, (void*)error );
    LibXML_struct_error_callback( saved_error, libErr);
}

MODULE = XML::CompactTree::XS		PACKAGE = XML::CompactTree::XS		

PROTOTYPES: DISABLE

SV*
_readSubtreeToPerl(reader, flags, ns_map, free_ns_index, read_siblings)
	xmlTextReaderPtr reader
	int flags
        HV * ns_map
        int free_ns_index
        int read_siblings
   PREINIT:
	AV* av = NULL;
	AV* top = NULL;
	AV* prev = NULL;
	AV* kids = NULL;
	AV* parents = NULL;
	HV* attrs = NULL;
        AV* attrs_av = NULL;
	SV* sv = NULL;
	SV** svp = NULL;
	int start_depth;
	int prev_depth;
	int cur_depth;
	int ret;
	int type;
	const xmlChar* name;
	PREINIT_SAVED_ERROR
    CODE:
	INIT_ERROR_HANDLER;
        cur_depth=xmlTextReaderDepth(reader);
	start_depth = cur_depth;
	prev_depth = start_depth;
	top = newAV();
	parents = newAV();
	if (xmlTextReaderNodeType(reader)==0) {
 	  if (xmlTextReaderRead(reader)!=1) XSRETURN_UNDEF;
	  if (XCT_DOCUMENT_ROOT) {
	    prev=newAV();
	    av_extend(prev,2);
	    av_push(prev, newSViv(XML_READER_TYPE_DOCUMENT));
	    av_push(prev, Char2SV(xmlTextReaderConstEncoding(reader)));
	    start_depth --;
	    prev_depth --;
	    av_push(top, newRV_noinc((SV*)prev));
	    av_push(parents, newRV_inc((SV*)prev));
	  }
        }
	do {
	  type = xmlTextReaderNodeType(reader);
	  /* warn("%d, %d %s\n", type, cur_depth, xmlTextReaderConstName(reader)); */
	  switch(type) {
	  case XML_READER_TYPE_NONE:
	  case XML_READER_TYPE_ATTRIBUTE:
	  case XML_READER_TYPE_DOCUMENT_TYPE:
	  case XML_READER_TYPE_END_ELEMENT:
	  case XML_READER_TYPE_ENTITY:
	  case XML_READER_TYPE_END_ENTITY:
	  case XML_READER_TYPE_XML_DECLARATION:
	    /* LIBXML_READER_NEXT_SIBLING(ret, reader); */
	    ret = xmlTextReaderRead(reader);
	    break;
	  case XML_READER_TYPE_WHITESPACE:
	    if (flags & (XCT_IGNORE_WS|XCT_IGNORE_SIGNIFICANT_WS)) {
	      ret = xmlTextReaderRead(reader);
	      break;
	    }
	    goto DEFAULT;
	  case XML_READER_TYPE_SIGNIFICANT_WHITESPACE:
	    if (flags & XCT_IGNORE_SIGNIFICANT_WS) {
	      ret = xmlTextReaderRead(reader);
	      break;
	    }
	    goto DEFAULT;
	  case XML_READER_TYPE_COMMENT:
	    if (flags & XCT_IGNORE_COMMENTS) {
	      ret = xmlTextReaderRead(reader);
	      break;
	    }
	    goto DEFAULT;
	  case XML_READER_TYPE_PROCESSING_INSTRUCTION:
	    if (flags & XCT_IGNORE_PROCESSING_INSTRUCTIONS) {
	      ret = xmlTextReaderRead(reader);
	      break;
	    }
	  default:
	  DEFAULT:
	    av=newAV();
	    av_extend(av,2);
	    av_push(av, newSViv(type));
	    switch (type) {
	    case XML_READER_TYPE_ELEMENT:
	      /* warn("  element\n"); */
	      av_push(av, Char2SV(xmlTextReaderConstLocalName(reader)));
              name = xmlTextReaderConstNamespaceUri(reader);
              if (name) {
                  int klen = xmlStrlen(name);
                  if (hv_exists(ns_map,(const char*)name,klen)) {
                      svp = hv_fetch(ns_map,(const char*)name,klen,0);
                      if (svp) {
                          av_push(av, newSVsv(*svp));
                      } else {
			  av_push(av, newSViv(0)); /* no namespace */
                      }
                  } else {
		      /* warn("storing namespace %s as %d\n",name,free_ns_index); */
                      sv = newSViv(free_ns_index);
                      av_push(av, sv);
                      sv = newSViv(free_ns_index);
                      if (hv_store(ns_map, (const char*) name, klen, sv, 0)==NULL) {
                          SvREFCNT_dec(sv); /* not stored */
                      }
                      free_ns_index++;
                  }
              } else {
		  av_push(av, newSViv(0)); /* no namespace */
              }
	      if (xmlTextReaderHasAttributes(reader) && xmlTextReaderMoveToFirstAttribute(reader)==1) {
                if (flags & XCT_ATTRIBUTE_ARRAY) {
                    attrs_av=newAV();
                    do {
                        name = xmlTextReaderConstName(reader);
                        if ((flags & XCT_KEEP_NS_DECLS) 
                            || xmlStrncmp((xmlChar*)"xmlns",name,5)!=0 ) {
                            av_push(attrs_av, Char2SV(name));
                            av_push(attrs_av, Char2SV(xmlTextReaderConstValue(reader)));
                        }
                    } while (xmlTextReaderMoveToNextAttribute(reader)==1);
                    /* xmlTextReaderMoveToElement(reader); */
                    av_push(av, newRV_noinc((SV*)attrs_av));
                } else {
                    attrs=newHV();
                    do {
                        name = xmlTextReaderConstName(reader);
                        if ((flags & XCT_KEEP_NS_DECLS)
                            || xmlStrncmp((xmlChar*)"xmlns",name,5)!=0 ) {
                            sv = Char2SV(xmlTextReaderConstValue(reader));
                            if (sv && hv_store(attrs, (const char*) name, xmlStrlen(name), sv, 0)==NULL) {
                                SvREFCNT_dec(sv);  /* free if not needed by hv_stores */
                            }
                        }
                    } while (xmlTextReaderMoveToNextAttribute(reader)==1);
                    xmlTextReaderMoveToElement(reader);
                    av_push(av, newRV_noinc((SV*)attrs));
                }
	      } else {
                av_push(av, newSV(0)); /* no attributes */

	      }
	      if (flags & XCT_LINE_NUMBERS)
		av_push(av, newSViv(xmlTextReaderGetParserLineNumber(reader)));
	      break;
	    case XML_READER_TYPE_TEXT:
	    case XML_READER_TYPE_CDATA:
	    case XML_READER_TYPE_COMMENT:
	    case XML_READER_TYPE_WHITESPACE:
	    case XML_READER_TYPE_SIGNIFICANT_WHITESPACE:
	      av_push(av, Char2SV(xmlTextReaderConstValue(reader)));
	      break;
	    case XML_READER_TYPE_ENTITY_REFERENCE:
	    case XML_READER_TYPE_PROCESSING_INSTRUCTION:
	    case XML_READER_TYPE_NOTATION:
	      av_push(av, Char2SV(xmlTextReaderConstLocalName(reader)));
	      av_push(av, Char2SV(xmlTextReaderConstValue(reader)));
	      break;
	    case XML_READER_TYPE_DOCUMENT:
	    case XML_READER_TYPE_DOCUMENT_FRAGMENT:
	      av_push(av, Char2SV(xmlTextReaderConstEncoding(reader)));
	      break;
	      /* do nothing */
	    }
	    if (cur_depth==start_depth) { 
	      av_push(top, newRV_noinc((SV*)av));
	      prev = av;
	      prev_depth = cur_depth;
	      kids = NULL;
	    } else if (cur_depth > prev_depth) {
	      kids=newAV();
	      av_push(prev, newRV_noinc((SV*)kids));
	      av_push(kids, newRV_noinc((SV*)av));
	      av_push(parents, newRV_inc((SV*)prev));
	      prev_depth = cur_depth;
	    } else if (cur_depth == prev_depth) {
	      if (kids) {
		av_push(kids, newRV_noinc((SV*)av));
	      }
	    } else {
	      do {
		prev_depth--;
		SvREFCNT_dec(av_pop(parents));
	      } while (cur_depth < prev_depth);
	      svp = av_fetch(parents,-1,0);
	      if (svp) {
		prev = (AV*) SvRV(*svp);
		svp = av_fetch(prev,-1,0);
		if (svp) {
		  kids = (AV*) SvRV(*svp);
		  if (kids) {
		    av_push(kids, newRV_noinc((SV*)av));
		  }
		}
	      }
	    }
	    prev = av;
	    ret = xmlTextReaderRead(reader);
	  }
	} while (ret == 1 && (cur_depth = xmlTextReaderDepth(reader)) > (start_depth - (read_siblings ? 1 : 0)));
        /* while (SvOK(av_pop(parents))) { } / * empty without SvREFCNT_dec on elements*/
        SvREFCNT_dec(parents);
        if (ret == 1) {
	  if (xmlTextReaderDepth(reader) == start_depth &&
	      xmlTextReaderNodeType(reader) == XML_READER_TYPE_END_ELEMENT) {
	    (void) xmlTextReaderRead(reader);
	  }
	}
        RETVAL=newRV_noinc((SV*)top);
        CLEANUP_ERROR_HANDLER;
	REPORT_ERROR(0);
    OUTPUT:
        RETVAL

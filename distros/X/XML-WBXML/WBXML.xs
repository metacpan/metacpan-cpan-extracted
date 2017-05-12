#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <wbxml.h>


MODULE = XML::WBXML		PACKAGE = XML::WBXML		

PROTOTYPES: disable

SV *
xml_to_wbxml(in_xml)
	WB_UTINY *in_xml
    CODE:
	WB_UTINY * outwbxml = NULL;
	WB_ULONG outwbxml_len = 0;
	WBXMLError ret;
	WBXMLConvXML2WBXMLParams params;
	
	params.wbxml_version = WBXML_VERSION_12;
	params.keep_ignorable_ws = FALSE;
	params.use_strtbl = TRUE;
	
	ret = wbxml_conv_xml2wbxml(in_xml, &outwbxml, &outwbxml_len, &params);
	if (ret == WBXML_OK) {
	    RETVAL = newSVpvn((char *)outwbxml, outwbxml_len);
	} else {
	    XSRETURN_UNDEF;
	} 
    OUTPUT:
    	RETVAL

SV *
wbxml_to_xml(in_wbxml)
	WB_UTINY *in_wbxml
    CODE:
	WB_ULONG inwbxml_len; 
	WB_UTINY *outxml = NULL;
	WBXMLError ret;
	WBXMLConvWBXML2XMLParams params;

	params.gen_type = WBXML_ENCODER_XML_GEN_COMPACT;
	params.lang = WBXML_LANG_UNKNOWN;
	params.indent = 1;
	params.keep_ignorable_ws = TRUE;

	inwbxml_len = SvCUR(ST(0));
	ret = wbxml_conv_wbxml2xml(in_wbxml, inwbxml_len, &outxml, &params);
	if (ret == WBXML_OK) {
	    RETVAL = newSVpv((char *)outxml, 0);
	} else {
	    RETVAL = newSViv(inwbxml_len);
	} 
    OUTPUT:
    	RETVAL

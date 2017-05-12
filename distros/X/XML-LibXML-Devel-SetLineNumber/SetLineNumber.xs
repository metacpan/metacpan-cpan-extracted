#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* libxml2 stuff */
#include <libxml/xmlversion.h>
#include <libxml/globals.h>
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>
#include <libxml/c14n.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/xmlIO.h>
/* #include <libxml/debugXML.h> */
#include <libxml/xmlerror.h>
#include <libxml/xinclude.h>
#include <libxml/valid.h>

#include "libxml.h"

MODULE = XML::LibXML::Devel::SetLineNumber		PACKAGE = XML::LibXML::Devel::SetLineNumber		

PROTOTYPES: disable

void
_set_line_number( sv, ln )
		SV *sv
		int ln
	PREINIT:
		xmlNode *node = PmmSvNode(sv);
	CODE:
		/* this is stupidly easy ... */
		node->line = ln;


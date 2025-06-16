#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Textblock_Node_Format EvasTextblockNodeFormat;


MODULE = pEFL::Evas::TextblockNodeFormat		PACKAGE = pEFL::Evas::TextblockNodeFormat



MODULE = pEFL::Evas::TextblockNodeFormat		PACKAGE = EvasTextblockNodeFormatPtr     PREFIX = evas_textblock_node_format_


EvasTextblockNodeFormat *
evas_textblock_node_format_next_get(n)
	const EvasTextblockNodeFormat *n


EvasTextblockNodeFormat *
evas_textblock_node_format_prev_get(n)
	const EvasTextblockNodeFormat *n
	
char *
evas_textblock_node_format_text_get(fnode)
	const EvasTextblockNodeFormat *fnode

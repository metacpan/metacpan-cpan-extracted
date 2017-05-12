extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

//required because of namespace collision between perl's <embed.h> 
//a private macro in gcc's <iostream>
#ifdef do_open
  #undef do_open
#endif
#ifdef do_close
  #undef do_close
#endif

#include "diff.hh"
#include "merge.hh"
#include "nspace.hh"
#include "perl-libxml-mm.h"
#include <string>

MODULE = XML::DifferenceMarkup		PACKAGE = XML::DifferenceMarkup

PROTOTYPES: ENABLE

SV *
_make_diff(de1, de2)
        SV *de1;
        SV *de2;
        CODE:
        {
	
	if (!de1 || !de2)
	{
		croak("XML::DifferenceMarkup diff: _make_diff called without arguments");
	}

	xmlDocPtr rv = 0;
	try
	{
		xmlNodePtr m = PmmSvNode(de1);
		xmlNodePtr n = PmmSvNode(de2);

		Diff dm(diffmark::get_unique_prefix(m, n),
			diffmark::nsurl);
		rv = dm.diff_nodes(m, n);
	}
	catch (std::string &x)
	{
		std::string msg("XML::DifferenceMarkup diff: ");
		msg += x;
		croak("%s", msg.c_str());
	}

	RETVAL = PmmNodeToSv(reinterpret_cast<xmlNodePtr>(rv), 0);
        }
        OUTPUT:
        RETVAL


SV *
_merge_diff(src_doc, diff_elem)
        SV *src_doc;
        SV *diff_elem;
        CODE:
        {
	
	if (!src_doc || !diff_elem)
	{
		croak("XML::DifferenceMarkup merge: _merge_diff called without arguments");
	}

	xmlDocPtr rv = 0;
	try
	{
		xmlDocPtr src = reinterpret_cast<xmlDocPtr>(
			PmmSvNode(src_doc));
		Merge builder(diffmark::nsurl, src);
		rv = builder.merge(PmmSvNode(diff_elem));
	}
	catch (std::string &x)
	{
		std::string msg("XML::DifferenceMarkup merge: ");
		msg += x;
		croak("%s", msg.c_str());
	}

	RETVAL = PmmNodeToSv(reinterpret_cast<xmlNodePtr>(rv), 0);
        }
        OUTPUT:
        RETVAL

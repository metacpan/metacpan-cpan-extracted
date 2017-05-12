//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Option parsing to be used from the XS code.

// ###################################################################################

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsOpt.h"
#include <sched/FnReturn.h>

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

void checkLabelList(const char *funcName, const char *optName, Unit *&u, AV *labels)
{
	int len, i;

	len = av_len(labels)+1; // av_len returns the index of last element
	if (len % 2 != 0 || len == 0)
		throw Exception::f("%s: option '%s' must contain elements in pairs, has %d elements", funcName, optName, len);
	for (i = 0; i < len; i+=2) {
		SV *svname, *svval;
		WrapLabel *wl;
		WrapRowType *wrt;
		svname = *av_fetch(labels, i, 0);
		svval = *av_fetch(labels, i+1, 0);

		if (!SvPOK(svname))
			throw Exception::f("%s: in option '%s' element %d name must be a string", funcName, optName, i/2+1);

		TRICEPS_GET_WRAP2(Label, wl, RowType, wrt, svval, "%s: in option 'labels' element %d with name '%s'", 
			funcName, i/2+1, SvPV_nolen(svname));

		if (wl != NULL) {
			Label *lb = wl->get();
			Unit *lbu = lb->getUnitPtr();

			if (lbu == NULL)
				throw Exception::f("%s: a cleared label in option '%s' element %d with name '%s' can not be used", 
					funcName, optName, i/2+1, SvPV_nolen(svname));

			if (u == NULL)
				u = lbu;
			else if (u != lbu)
				throw Exception::f(
					"%s: label in option '%s' element %d with name '%s' has a mismatching unit '%s', previously seen unit '%s'", 
					funcName, optName, i/2+1, SvPV_nolen(svname), lbu->getName().c_str(), u->getName().c_str());
		}
	}
}

void addFnReturnLabels(const char *funcName, const char *optName, Unit *u, AV *labels, bool front, FnReturn *fret)
{
	int len, i;

	len = av_len(labels)+1; // av_len returns the index of last element
	for (i = 0; i < len; i+=2) {
		SV *svname, *svval;
		WrapRowType *wrt;
		WrapLabel *wl;
		svname = *av_fetch(labels, i, 0);
		svval = *av_fetch(labels, i+1, 0);

		string lbname;
		GetSvString(lbname, svname, "%s: option '%s' element %d name", funcName, optName, i+1);

		TRICEPS_GET_WRAP2(Label, wl, RowType, wrt, svval, "%s: in option '%s' element %d with name '%s'", 
			funcName, optName, i/2+1, SvPV_nolen(svname));

		if (wl != NULL) {
			Label *lb = wl->get();
			fret->addFromLabel(lbname, lb, front);
		} else {
			RowType *rt = wrt->get();
			fret->addLabel(lbname, rt);
		}
	}

}

}; // Triceps::TricepsPerl
}; // Triceps


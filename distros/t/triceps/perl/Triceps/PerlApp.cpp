//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The Triceps aggregator for Perl calls and the wrapper for it.

#include <typeinfo>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlApp.h"

// ###################################################################################

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

void parseApp(const char *func, const char *var, SV *arg, Autoref<App> &res)
{
	if ( sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG) ) {
		WrapApp *wa = (WrapApp *)SvIV((SV*)SvRV( arg ));
		if (wa == 0 || wa->badMagic()) {
			throw Exception::f("%s: %s has an incorrect magic for App", func, var);
		}
		res = wa->get();
	} else if (SvPOK(arg)) {
		STRLEN len;
		char *s = SvPV(arg, len);
		string appname(s, len);
		res = App::find(appname); // will throw if can't find
	} else {
		throw Exception::f("%s: %s is not an App reference nor a string", func, var);
	}
}

}; // Triceps::TricepsPerl
}; // Triceps


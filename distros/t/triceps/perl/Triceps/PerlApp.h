//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Helpers for the App/Triead control.

// Include TricepsPerl.h before this one.

// ###################################################################################

#ifndef __TricepsPerl_PerlApp_h__
#define __TricepsPerl_PerlApp_h__

#include <common/Conf.h>
#include <app/App.h>

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

// Parse the App argument as either a WrapApp or a string name of the
// app.
// Will throw an Exception if the argument is of the wrong type or
// if the app at that name is not found.
//
// @param func - calling function name, for error messages
// @param var - variable name in the calling function, for error messages
// @param arg - argument to be parsed
// @param res - place to return the result
void parseApp(const char *func, const char *var, SV *arg, Autoref<App> &res);

}; // Triceps::TricepsPerl
}; // Triceps


#endif // __TricepsPerl_PerlApp_h__

//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Option parsing to be used from the XS code.

// ###################################################################################

#ifndef __TricepsPerl_TricepsOpt_h__
#define __TricepsPerl_TricepsOpt_h__

#include "TricepsPerl.h"

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

// Check the option "labels" from FnReturn and such.
// The option contains an array of data in pairs, a name and either a label or row type.
// See FnReturn::new() for details.
//
// Throws an Exception on errors.
//
// @param funcName - name of the calling function, for error messages
// @param optName - name of the function's option being checked
// @param u - the unit; if initially set to NULL then will be filled with
//        a deduced value from the labels (or will throw an exception if can't);
//        all the labels will be checked to belong to the same unit
// @param labels - the label array to check
void checkLabelList(const char *funcName, const char *optName, Unit *&u, AV *labels);

// Add the contents of the option "labels" to an FnReturn.
// The option contains an array of data in pairs, a name and either a label or row type.
// See FnReturn::new() for details.
// The data must be checked first with checkLabelList().
//
// Throws an Exception on errors.
//
// @param funcName - name of the calling function, for error messages
// @param optName - name of the function's option being checked
// @param u - the unit for automatic construction of labels from row types
// @param labels - the label array to construct from
// @param front - flag: when creating labels from other labels, chain at the front
// @param fret - FnReturn where to add the labels
void addFnReturnLabels(const char *funcName, const char *optName, Unit *u, AV *labels, bool front, FnReturn *fret);

}; // Triceps::TricepsPerl
}; // Triceps

using namespace TRICEPS_NS::TricepsPerl;

#endif // __TricepsPerl_TricepsOpt_h__

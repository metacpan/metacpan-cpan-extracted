#define WIN32_LEAN_AND_MEAN


#ifndef __ACCESS_CPP
#define __ACCESS_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "access.h"
#include "wstring.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////

// NetAccess* functions are not supported by NT, you can call them, but they 
// return always error 50



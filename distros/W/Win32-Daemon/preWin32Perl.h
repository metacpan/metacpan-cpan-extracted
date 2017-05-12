#ifndef _PREWIN32_PERL_H
#define _PREWIN32_PERL_H

#   define _PREWIN32PERL_H_VERSION     20080321

//////////////////////////////////////////////////////////////////////////
//
//  preWin32Perl.h
//  --------------
//  This is a header to use *before* using the Win32Perl.h header.
//  This header file defines macros that in turn will enable
//  appropriate Perl macros that the default Win32 Perl
//  builds from ActiveState.com use.
//
//  TO USE THIS:
//      Refer to the Win32Perl.h header for details on use.
//

	//////////////////////////////////////////////////////////////////////////
	//
	//  Load Perl Headers
	//  -----------------
	//	If we are building with the core distribution headers we can not define
	//	the function names using C++ because of name mangling
	#if defined(__cplusplus) 
		extern "C" {
	#endif

		#include "EXTERN.h"
		#include "perl.h"
		#include "XSub.h"

	#if defined(__cplusplus) 
		}
	#endif

#endif // _PREWIN32_PERL_H

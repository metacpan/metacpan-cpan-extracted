//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _EXPORTS_H
#define _EXPORTS_H

#ifndef WIN32SHELLEXTAPI
#ifdef WIN32SHELLEXTAPI_IMPORT
#define WIN32SHELLEXTAPI __declspec(dllimport)
#else
#define WIN32SHELLEXTAPI __declspec(dllexport)
#endif
#endif

#endif
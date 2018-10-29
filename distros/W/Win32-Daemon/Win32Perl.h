//  Win32Perl.h
//  -----------
//  This header is used exclusively to provide seemless support for Perl extensions
//  under the Win32 platform.  It could easily be adapted to other platforms as well.
//   
//  The bulk of this header is to provide extension development without necesitating 
//  the need to adopt XS or other meta language formats.
//  We prefer to use our own C/C++ coding styles than that which XS dictates.
//  
//  This file adapts to the version of Perl being used: 5.003, 5.004, 5.005, 5.006
//  5.008 with or without support for PERL_OBJECT.
//  
//  1999.11.14 roth   
//
//
//  TO USE THIS:
//      This header is intended to be used in conjunction with the
//      preWin32Perl.h header.
//      Simply add the follwing line to your Perl extension:
//
//          #include <Win32Perl.h>
//
//      That is it. DO NOT add references to extern.h, Perl.h or XSub.h in
//      your extension. The preWin32Perl.h already does this. It is important
//      to abide by this because the order of defining macros and including
//      headers is important!
//  2003.03.01 roth
//
//  (c) 1998-2003 Dave Roth
//  Courtesy of Roth Consulting
//  http://www.roth.net/

#ifndef _WIN32PERL_H_

#ifndef _PREWIN32_PERL_H
    #include <PreWin32Perl.h>
#endif // _PREWIN32_PERL_H

#include <tchar.h>
#include "patchlevel.h"

//
//  Various macro definitions for various Perl builds (refer to preWin32Perl.h):
//  --------------------------------------------------
//      v5.008 Core (default from ActiveState.com)
//          WIN32,_WINDOWS,EMBED,MSWIN32,HAVE_DES_FCRYPT,MULTIPLICITY,PERL_IMPLICIT_CONTEXT,PERL_IMPLICIT_SYS,PERL_MSVCRT_READFIX,PERL_NO_GET_CONTEXT,PERL_POLLUTE,USE_ITHREADS,NO_STRICT,USE_PERLIO,USE_ITHREADS,USE_LARGE_FILES
//
//      v5.006 Core (default from ActiveState.com)
//          WIN32,_WINDOWS,EMBED,MSWIN32,HAVE_DES_FCRYPT,MULTIPLICITY,PERL_IMPLICIT_CONTEXT,PERL_IMPLICIT_SYS,PERL_MSVCRT_READFIX,PERL_NO_GET_CONTEXT,PERL_POLLUTE,USE_ITHREADS
//          
//      v5.005 ActiveState
//          EMBED,MSWIN32,PERL_OBJECT
//
//      v5.005 Core
//          EMBED,MSWIN32
//
//      v5.004 ActiveState
//          EMBED,MSWIN32,PERL_OBJECT

#   define _WIN32PERL_H_
#   define _WIN32PERL_H_VERSION     20080321
#   ifdef PERLVER
//#       undef PERLVER
#   endif // PERLVER


// Update REVISION and VERSION values. Some older versions did not set this
#ifndef PERL_VERSION
//  Now test for version 5.005 of perl...
#	if PATCHLEVEL == 5
#       define  PERL_REVISION           5
#       define  PERL_VERSION            5
#   else
#       ifdef PERL_OBJECT
#           define PERL_REVISION        5
#           define PERL_VERSION         4   
#       else
#           define PERL_REVISION        5
#           define PERL_VERSION         3
#       endif // PERL_OBJECT
#   endif // PATCHLEVEL == 5    
#endif // ! PERL_VERSION


#define PERL_OBJECT_INSTANCE_DELIMITER      ,

#if PERL_VERSION == 10
#   define  PERL_VER_STRING                 "5.10"
#   define	FILE_EXTENSION	                "DLL"
//#   ifdef PERL_OBJECT
//  v5.8 handled things as 5.6 did:
//      The pTHX macro is the FULL prototype such as: register PerlInterpreter *my_perl
//      and aTHX macro is the argument such as: my_perl
//  Then under certain screwed up conditions pTHX becomes void. Yes void. Sigh. So
//  this, of course, breaks everything since void itself is not a valid arguement. Idiots.
//  Luckily if this occurs USE_THREADS is defined so we can use this to test...
#   ifdef USE_THREADS
#       define  PERL_OBJECT_CLASS           perl_thread*
#		define  PERL_OBJECT_CLASS_STRING   "pTHX"
#       define  PERL_OBJECT_PROTO           pTHXo_
#       define  PERL_OBJECT_PROTO1          perl_thread *thr
#		define  PERL_OBJECT_ARGS            aTHXo_
#       define  PERL_OBJECT_ARG             aTHXo
#       define  PERL_OBJECT_INSTANCE        aTHX
#	  else
#       define  PERL_OBJECT_INSTANCE        my_perl
#       define  PERL_OBJECT_CLASS           PerlInterpreter*
#       define  PERL_OBJECT_CLASS_STRING    "PerlInterpreter"
#   endif
#   pragma message( "...using the " PERL_OBJECT_CLASS_STRING )
#endif

#if PERL_VERSION == 8
#   define  PERL_VER_STRING                 "5.8"
#   define	FILE_EXTENSION	                "DLL"
//#   ifdef PERL_OBJECT
//  v5.8 handled things as 5.6 did:
//      The pTHX macro is the FULL prototype such as: register PerlInterpreter *my_perl
//      and aTHX macro is the argument such as: my_perl
//  Then under certain screwed up conditions pTHX becomes void. Yes void. Sigh. So
//  this, of course, breaks everything since void itself is not a valid arguement. Idiots.
//  Luckily if this occurs USE_THREADS is defined so we can use this to test...
#   ifdef USE_THREADS
#       define  PERL_OBJECT_CLASS           perl_thread*
#		define  PERL_OBJECT_CLASS_STRING   "pTHX"
#       define  PERL_OBJECT_PROTO           pTHXo_
#       define  PERL_OBJECT_PROTO1          perl_thread *thr
#		define  PERL_OBJECT_ARGS            aTHXo_
#       define  PERL_OBJECT_ARG             aTHXo
#       define  PERL_OBJECT_INSTANCE        aTHX
#	  else
#       define  PERL_OBJECT_INSTANCE        my_perl
#       define  PERL_OBJECT_CLASS           PerlInterpreter*
#       define  PERL_OBJECT_CLASS_STRING    "PerlInterpreter"
#   endif
#   pragma message( "...using the " PERL_OBJECT_CLASS_STRING )
#endif

#if PERL_VERSION == 6
#   define  PERL_VER_STRING                 "5.6"
#   define	FILE_EXTENSION	                "DLL"
//#   ifdef PERL_OBJECT
//  Starting with 5.6 this is really screwy:
//      The pTHX macro is the FULL prototype such as: register PerlInterpreter *my_perl
//      and aTHX macro is the argument such as: my_perl
//  Then under certain screwed up conditions pTHX becomes void. Yes void. Sigh. So
//  this, of course, breaks everything since void itself is not a valid arguement. Idiots.
//  Luckily if this occurs USE_THREADS is defined so we can use this to test...
#   ifdef USE_THREADS
#       define  PERL_OBJECT_CLASS          perl_thread*
#		define  PERL_OBJECT_CLASS_STRING   "pTHX"
// Original before hacking on 20030228...
//#       define  PERL_OBJECT_PROTO           pTHXo_
//#       define  PERL_OBJECT_PROTO1          perl_thread *thr
//#		define  PERL_OBJECT_ARGS            aTHXo_
//#       define  PERL_OBJECT_ARG             aTHXo
#       define  PERL_OBJECT_PROTO           pTHXo_     
#       define  PERL_OBJECT_PROTO1          pTHX
#		define  PERL_OBJECT_ARGS            aTHXo_
#       define  PERL_OBJECT_ARG             aTHXo
#       define  PERL_OBJECT_INSTANCE        aTHX
#	else 
#       define  PERL_OBJECT_INSTANCE        my_perl
#       define  PERL_OBJECT_CLASS           PerlInterpreter*
#       define  PERL_OBJECT_CLASS_STRING    "PerlInterpreter"
#   endif
#   pragma message( "...using the " PERL_OBJECT_CLASS_STRING )
#endif

#if PERL_VERSION == 5
#   define  PERL_VER_STRING                 "5.005"
#   define	FILE_EXTENSION	                "DLL"
#   ifdef PERL_OBJECT
#       define  PERL_OBJECT_INSTANCE        pPerl
#       define  PERL_OBJECT_CLASS           CPerlObj*
#       define  PERL_OBJECT_CLASS_STRING    "CPerlObj"
#   else
//      NOTE: Do not define the PERL_CLASS_OBJECT since it is used
//            to determine what class is used for the Perl interpreter.
//            Here we don't use one.
#       define  PERL_OBJECT_PROTO
#       define  PERL_OBJECT_PROTO1
#		define  PERL_OBJECT_ARGS
#       define  PERL_OBJECT_ARG
#   endif // PERL_OBJECT
#endif

#if PERL_VERSION == 4
#   define  PERL_VER_STRING                 "5.004"
#   define  FILE_EXTENSION                  "DLL"
    //  Define our own macros here for v5.004.  This way
    //  we won't get the comma char messed with anything since these macros
    //  must not resolve to anything
#   define  PERL_BRAND                      "Core Distribution"
//      NOTE: Do not define the PERL_CLASS_OBJECT since it is used
//            to determine what class is used for the Perl interpreter.
//            Here we don't use one.
#       define  PERL_OBJECT_PROTO
#       define  PERL_OBJECT_PROTO1
#		define  PERL_OBJECT_ARGS
#       define  PERL_OBJECT_ARG
#endif

#if PERL_VERSION == 3
#   define  PERL_VER_STRING                 "5.003"
#   ifdef PERL_OBJECT
#       define  FILE_EXTENSION              "PLL"
#       define  PERL_OBJECT_INSTANCE        pPerl
#       define  PERL_OBJECT_CLASS           CPerl*
#       define  PERL_OBJECT_CLASS_STRING    "CPerl"
#   else // ! PERL_OBJECT
#       define  FILE_EXTENSION              "DLL"
//      NOTE: Do not define the PERL_CLASS_OBJECT since it is used
//            to determine what class is used for the Perl interpreter.
//            Here we don't use one.
#       define  PERL_OBJECT_PROTO
#       define  PERL_OBJECT_PROTO1
#		define  PERL_OBJECT_ARGS
#       define  PERL_OBJECT_ARG
#   endif // PERL_OBJECT
#endif // SUB_VERSION


//  Now we test for PERL_OBJECT again to create the object macros...

#ifdef PERL_OBJECT
#   define  PERL_BRAND          "ActiveState"
#else // PERL_OBJECT
#   define  PERL_BRAND          "Core Distribution"
#endif // PERL_OBJECT

#ifndef PERL_OBJECT_PROTO
#   define  PERL_OBJECT_PROTO   PERL_OBJECT_CLASS PERL_OBJECT_INSTANCE PERL_OBJECT_INSTANCE_DELIMITER
#   define  PERL_OBJECT_PROTO1  PERL_OBJECT_CLASS PERL_OBJECT_INSTANCE
#   define  PERL_OBJECT_ARGS    PERL_OBJECT_INSTANCE PERL_OBJECT_INSTANCE_DELIMITER
#   define  PERL_OBJECT_ARG     PERL_OBJECT_INSTANCE
#endif

#define PERLVER  "v" PERL_VER_STRING " (" PERL_BRAND ") Win32 Perl"

#ifdef H_PERL    //  Do this only if Perl.h was called
#   pragma message ( "  * Using " PERLVER )
#   ifdef PERL_OBJECT_CLASS
#       pragma message( "    - Perl Class: " PERL_OBJECT_CLASS_STRING )
#   endif   //  PERL_OBJECT_CLASS
#   pragma message( "\n  ================================================================================\n\n" )
#endif // H_PERL

//  Some macros are no longer defined unless 
//  PERL_POLLUTE is defined. By default v5.006 does *not*
//  define this macro.
#ifndef PERL_POLLUTE
# ifndef na
#   define na			PL_na
# endif

# ifndef sv_no
#   define sv_no  PL_sv_no
# endif

# ifndef sv_undef
#   define sv_undef		PL_sv_undef
# endif

# ifndef sv_yes
#   define sv_yes     PL_sv_yes
# endif

#endif


    ///////////////////////////////////////////////////////////////////////////////
    //  Declare our standard extension macros for easy Perl extension coding... 
    //
    //  To use these macros it is best to declare the EXTENSION_VARS macro
    //  somewhere in the beginning of the Perl function.
    //  For example:
    //  XS( XS_DecodeBuffer )
    //  {
	//      dXSARGS;            //  Standard Perl extension delcaration
    //      EXTENSION_VARS;     //  Win32Perl.h declaration
	//      
	//      ...process code where you may be pushing values onto the retyurn stack...
    //      PUSH_IV( 32 );
    //      PUSH_PV( "Hello" );
    //         
    //      EXTENSION_RETURN;   //  Win32Perl.h return declaration
    //  }
	  
	// Number of elements we can push onto the return stack
	// before having to extend the stack.
    #define DEFAULT_PERL_STACK_SIZE		5		

    //  Set up the default extension variables what we need...
    #define	EXTENSION_VARS		int    iNumOfReturnStackElements = 0;			\
							    int    iStackCount = DEFAULT_PERL_STACK_SIZE;	

	//	Routine to use every time we push a value onto the return stack.  This will monitor
	//	the stack's size and extend it every time it needs to be extended.
    #define CHECK_PERL_STACK_SIZE	if( 0 <= iStackCount )					    \
								    {											\
									    iStackCount = DEFAULT_PERL_STACK_SIZE;	\
									    EXTEND( sp, iStackCount );				\
								    }

    /////////////////////////////////////////////////////////////
    //  Return Stack Macros
    //
    //  Pop an SV off of the stack and update the return stack. This is called when we have
    //  accidently pushed a value onto the return stack...
    //  
    //  The following macros are defined to push elements onto the return stack:
    //      POP_SV............Pop the top SV off the stack. The SV is lost (not returned)
    //
    //  These macros all push their respective values onto the stack. Each macro will
    //  create a new SV and tag it as mortal before pushing onto the stack.
    //  
    //      PUSH_IV(x)........Push a 32 bit value onto the return stack.
    //      PUSH_NV(x)........Push a floating point value (a double) onto the stack
    //      PUSH_PV(x)........Push a nul terminated string onto the stack.
    //      PUSH_PNV(x,y).....Push a binary object onto the return stack. X=LPBYTE; Y=Length in bytes.
    //      PUSH_NOREF(x).....Push the specified SV* onto the stack as is.
    //      PUSH_REF(x).......Create a reference to (x), tag it as mortal then push it onto the return stack.
    //      PUSH_AV(x)........Push an array onto the return stack.
    //      PUSH_HV(x)........Push a hash onto the return stack.


    #define POP_SV              POPs;                                           \
                                iNumOfReturnStackElements--
                                
    //  Push an IV value onto the return stack...
    #define PUSH_IV(x)          CHECK_PERL_STACK_SIZE;                                                      \
                                ST( iNumOfReturnStackElements ) = sv_2mortal( newSViv( (IV) (x) ) );        \
                                iNumOfReturnStackElements++

    //  Push an NV (double) value onto the return stack...
    #define PUSH_NV(x)          CHECK_PERL_STACK_SIZE;                                                      \
                                ST( iNumOfReturnStackElements ) = sv_2mortal( newSVnv( (double) (x) ) );         \
                                iNumOfReturnStackElements++
    
    //  Push a string value onto the stack...
    #define PUSH_PV(x)          if( NULL != (x) )                                                               \
                                {                                                                               \
                                    CHECK_PERL_STACK_SIZE;                                                      \
                                    ST( iNumOfReturnStackElements ) = sv_2mortal( newSVpv( (LPTSTR)(x), 0 ) );   \
                                    iNumOfReturnStackElements++;                                                \
                                }

    //  Push a string value onto the stack...
    #define PUSH_PNV(x,y)       if( NULL != (x) )                                                                       \
                                {                                                                                       \
                                    CHECK_PERL_STACK_SIZE;                                                              \
                                    ST( iNumOfReturnStackElements ) = sv_2mortal( newSVpv( (LPTSTR)(x), (int) (y) ) );   \
                                    iNumOfReturnStackElements++;                                                        \
                                }


    //  Push an SV value onto the stack...
    #define PUSH_NOREF(x)       if( NULL != (x) )                                                           \
                                {                                                                           \
                                    CHECK_PERL_STACK_SIZE;                                                  \
                                    ST( iNumOfReturnStackElements ) = (SV*)(x);                             \
                                    iNumOfReturnStackElements++;                                            \
                                }

    //  All PUSH_SV() macros need to reference PUSH_REF() or PUSH_NOREF() instead.
    //  #define PUSH_SV(x)          PUSH_REF(x)

    //  Create and push a new reference onto the stack...
    #define PUSH_REF(x)         if( NULL != (x) )                                                           \
                                {                                                                           \
                                    CHECK_PERL_STACK_SIZE;                                                  \
                                    ST( iNumOfReturnStackElements ) = sv_2mortal( newRV( (SV*)(x) ) );      \
                                    iNumOfReturnStackElements++;                                            \
                                }
    
    //  Push an array onto the stack...
    #define PUSH_AV(x)          PUSH_REF(x)
    
    //  Push a hash onto the stack...
    #define PUSH_HV(x)          PUSH_REF(x)


    // Return a boolean yes or no...
    #define XSRETURN_BOOL(x)    ST( 0 ) = sv_2mortal( newSViv( (FALSE != (x))? 1 : 0 ) );       \
                                XSRETURN( 1 )            
    
    #define EXTENSION_RETURN_BOOL(x)    XSRETURN_BOOL( (x) )

    // Return with the return stack...
    #define EXTENSION_RETURN    XSRETURN( iNumOfReturnStackElements )

    /////////////////////////////////////////////////////////////
    //  HASH Macros

    //  The hash retrieval macros. These all have a prototype of: HASH_GET_xx( pHash, szKeyName )
    #define HASH_GET_SV(x,y)    HashGetSV( PERL_OBJECT_ARGS (x), (y) )
    #define HASH_GET_PV(x,y)    HashGetPV( PERL_OBJECT_ARGS (x), (y) )
    #define HASH_GET_IV(x,y)    HashGetIV( PERL_OBJECT_ARGS (x), (y) )
    #define HASH_GET_NV(x,y)    HashGetNV( PERL_OBJECT_ARGS (x), (y) )
    #define HASH_GET_AV(x,y)    EXTRACT_AV( HashGetSV( PERL_OBJECT_ARGS (x), (y) ) )
    #define HASH_GET_HV(x,y)    EXTRACT_HV( HashGetSV( PERL_OBJECT_ARGS (x), (y) ) )
	
    //	Extract a hash reference from an SV: SV *pSv = ST( 0 );
    //                                       HV *pHv = EXTRACT_HV( pSv );
    #define EXTRACT_HV(x)       _EXTRACT_HV( (SV*) (x) )

    inline HV *_EXTRACT_HV( SV *pSv )
    {
        HV *pHv = NULL;
        if( NULL == pSv )
        {
            return( NULL );
        }

        if( SvROK( pSv ) )
	    {
            pSv = SvRV( pSv );
        }
	    if( SVt_PVHV == SvTYPE( pSv ) )
	    {
	        pHv = (HV*) pSv;
	    }
        return( pHv );
    }

    //  Delete a key from a hash: HASH_DELETE( pHash, szKeyName )
    #define HASH_DELETE(x,y)            if( hv_exists( (HV*) (x), (LPTSTR)(y), _tcslen( (LPTSTR)(y) ) ) )                \
                                        {                                                                               \
		                                    hv_delete( (HV*) (x), (LPTSTR)(y), _tcslen( (LPTSTR)(y) ), G_DISCARD );      \
	                                    }

    // Store a hash (HV*) or array (AV*) into a hash. This will create a reference then store that
    // into the hash. 
    // --------------
    // The storing of an AV* or HV* is special. We need to create a reference WITHOUT increasing the
    // references reference count. Silly but this is what happens:
    //      a) Reference is made creating a ref count of 1 and increasing the AV or HV's ref count
    //      b) Reference is added to a hash increasing it's ref count to 2
    //  When the array is undefed the reference ref count is decremented, of course.
    //  so it now becomes 1.  Since it is not zero it is not purged however nothing points to it so
    //  it has become an orphan hence a memory leak.
    #define HASH_STORE_AV(x,y,z)        HASH_STORE_HV(x,y,z)
    #define HASH_STORE_HV(x,y,z)        if( ( NULL != (x) ) && ( NULL != (y) ) && ( NULL != (z) ) )                         \
                                        {                                                                                   \
                                            SV* P_SV_TEMP = newRV_noinc( (SV*) (z) );                                       \
                                            if( NULL != P_SV_TEMP )                                                         \
                                            {                                                                               \
                                                hv_store( (HV*) (x), (LPTSTR) (y), _tcslen( (LPTSTR) (y) ), P_SV_TEMP, 0 ); \
                                            }                                                                               \
                                        }


    //  Store an SV into a hash: HASH_STORE_SV( pHash, szKeyName, pSv );
    //  This will auto create a reference to the SV and store that reference in the hash.
    #define HASH_STORE_SV(x,y,z)        if( ( NULL != (x) ) && ( NULL != (y) ) && ( NULL != (z) ) )                         \
                                        {                                                                                   \
                                            SV* P_SV_TEMP = newRV( (SV*) (z) );                                             \
                                            if( NULL != P_SV_TEMP )                                                         \
                                            {                                                                               \
                                                hv_store( (HV*) (x), (LPTSTR) (y), _tcslen( (LPTSTR) (y) ), P_SV_TEMP, 0 );    \
                                            }                                                                               \
                                        }

    //  Store an SV into a hash without any references: HASH_STORE_SVNOREF( pHash, szKeyName, pSv );
    //  Typically you don't do this unless you already have a reference you need to store in the hash.
    //  You would normally call HASH_STORE_SV() which auto creates the reference for you.
    #define HASH_STORE_SVNOREF(x,y,z)   if( ( NULL != (x) ) && ( NULL != (y) ) && ( NULL != (z) ) )                         \
                                        {                                                                                   \
                                            hv_store( (HV*) (x), (LPTSTR) (y), _tcslen( (LPTSTR) (y) ), (SV*)(z), 0 );      \
                                        }

    //  Store a data array into a hash (storing a string but specify the number of elements hence it can
    //  contain nul chars: HASH_STORE_PNV( pHv, szKeyName, pData, dwDataBufferSize )
    #define HASH_STORE_PNV(x,y,z,size)  if( ( NULL != (x) ) && ( NULL != (y) ) && ( NULL != (z) ) )                         \
                                        {                                                                                   \
                                            SV* P_SV_TEMP = newSVpv( (LPTSTR)(z), (int)(size) );                             \
                                            if( NULL != P_SV_TEMP )                                                         \
                                            {                                                                               \
                                                hv_store( (HV*) (x), (LPTSTR) (y), _tcslen( (LPTSTR) (y) ), P_SV_TEMP, 0 );    \
                                            }                                                                               \
                                        } 
    //  Store a C string into a hash: HASH_STORE_PV( pHash, szKeyName, szString )
    #define HASH_STORE_PV(x,y,z)        HASH_STORE_PNV(x,y,z, _tcslen( (LPTSTR)(z) ) )

    //  Store a floating point number into a hash: HASH_STORE_NV( pHash, szKeyName, dFloatingPoint )
    #define HASH_STORE_NV(x,y)          if( ( NULL != (x) ) && ( NULL != (y) ) )                                            \
                                        {                                                                                   \
                                            SV* P_SV_TEMP = newSVnv( (NV)(z) );                                             \
                                            if( NULL != P_SV_TEMP )                                                         \
                                            {                                                                               \
                                                hv_store( (HV*) (x), (LPTSTR) (y), _tcslen( (LPTSTR) (y) ), P_SV_TEMP, 0 );    \
                                            }                                                                               \
                                        } 

    //  Store a 32 bit integer into a hash: HASH_STORE_IV( pHash, szKeyName, dwNumber )
    #define HASH_STORE_IV(x,y,z)        if( ( NULL != (x) ) && ( NULL != (y) ) )                                            \
                                        {                                                                                   \
                                            SV* P_SV_TEMP = newSViv( (IV)(z) );                                             \
                                            if( NULL != P_SV_TEMP )                                                         \
                                            {                                                                               \
                                                hv_store( (HV*) (x), (LPTSTR) (y), _tcslen( (LPTSTR) (y) ), P_SV_TEMP, 0 );    \
                                            }                                                                               \
                                        } 
    
    // Check that a hash key exists: HASH_KEY_EXISTS( pHash, szKeyName )
    #define HASH_KEY_EXISTS(x,y)        ( 0 != hv_exists( (HV*)(x), (LPTSTR)(y), _tcslen( (LPTSTR)(y) ) ) )

    //  Define the inline hash extraction prototypes...
    char *HashGetPV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName );
    IV HashGetIV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName );
    double HashGetNV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName );
    SV *HashGetSV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName );

    //  Now define the inline functions used by the hash macros
    inline LPTSTR HashGetPV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName )
    {
        SV *pSv = HashGetSV( PERL_OBJECT_ARGS pHv, pszKeyName );
        if( NULL != pSv )
        {
            return( SvPV( pSv, na ) );
        }
        else
        {
            return( "" );
        }
    }

    inline IV HashGetIV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName )
    {
        SV *pSv = HashGetSV( PERL_OBJECT_ARGS pHv, pszKeyName );
        if( NULL != pSv )
        {
            return( SvIV( pSv) );
        }
        else
        {
            return( 0 );
        }
    }

    inline double HashGetNV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName )
    {
        SV *pSv = HashGetSV( PERL_OBJECT_ARGS pHv, pszKeyName );
        if( NULL != pSv )
        {
            return( SvNV( pSv) );
        }
        else
        {
            return( 0.0 );
        }
    }

    inline SV * HashGetSV( PERL_OBJECT_PROTO HV *pHv, LPTSTR pszKeyName )
    {
        SV *pSv = NULL;
        if( ( NULL == pszKeyName ) || ( NULL == pHv ) )
            return( NULL );

        if( hv_exists( pHv, pszKeyName, _tcslen( pszKeyName ) ) )
        {
            pSv = (SV*) hv_fetch( pHv, pszKeyName, _tcslen( pszKeyName ), 0 );
            if( NULL != pSv )
            {
                pSv = *(SV**) pSv;
            }
        }
        return( pSv );
    }
   

    /////////////////////////////////////////////////////////////
    //  ARRAY Macros
    //
    //  Push a given type into an array. The all follow the format:
    //      ARRAY_PUSH_xx( pAv, value )
    //  eg: ARRAY_PUSH_NV( pAv, 3.14 );

    #define ARRAY_PUSH_PV(x,y)          av_push( (AV*) (x), newSVpv( (LPTSTR) (y), 0 ) )
    #define ARRAY_PUSH_PNV(x,y,z)       av_push( (AV*) (x), newSVpv( (LPTSTR) (y), (int) (z) ) )
    #define ARRAY_PUSH_IV(x,y)          av_push( (AV*) (x), newSViv( (IV) (y) ) )
    #define ARRAY_PUSH_NV(x,y)          av_push( (AV*) (x), newSVnv( (NV) (y) ) )
    #define ARRAY_PUSH_SV(x,y)          av_push( (AV*) (x), newSVsv( (SV*)(y) ) )
    #define ARRAY_PUSH_RV(x,y)          av_push( (AV*) (x), newRV( (SV*)(y) ) )
    #define ARRAY_PUSH(x,y)             av_push( (AV*) (x), (SV*) (y) )
    // The pushing of AV* and HV* is special. We need to create a reference WITHOUT increasing the
    // references reference count. Silly but this is what happens:
    //      a) Reference is made creating a ref count of 1 and increasing the AV or HV's ref count
    //      b) Reference is added to an array increasing it's ref count to 2
    //  When the array is undefed the reference ref count is decremented, of course.
    //  so it now becomes 1.  Since it is not zero it is not purged however nothing points to it so
    //  it has become an orphan hence a memory leak.
    #define ARRAY_PUSH_AV(x,y)          av_push( (AV*) (x), newRV_noinc( (SV*)(y) ) )
    #define ARRAY_PUSH_HV(x,y)          ARRAY_PUSH_AV(x,y)


    //  Get a particular value from a specified index in an array.  Format is:
    //      ARRAY_GET_xx( pAv, dwIndex )
    //  eg: (char*) pszString = ARRAY_GET_PV( pAv, 18 );
    //  One exception is the ARRAY_GET_PVN( pAv, dwIndex, dwLength )
    //  This will return a string of dwLength bytes long ignoring any embedded nul chars.
    #define ARRAY_GET(x,y)          (SV*) _ARRAY_FETCH( PERL_OBJECT_ARGS (AV*)(x), (I32)(y) )
    #define ARRAY_GET_SV(x,y)       (SV*) _ARRAY_FETCH( PERL_OBJECT_ARGS (AV*)(x), (I32)(y) )
    #define ARRAY_GET_PV(x,y)       SvPV( _ARRAY_FETCH( PERL_OBJECT_ARGS (AV*)(x), (I32)(y) ), na )
    #define ARRAY_GET_PVN(x,y,z)    SvPV( _ARRAY_FETCH( PERL_OBJECT_ARGS (AV*)(x), (I32)(y) ), (I32)(z) )
    #define ARRAY_GET_IV(x,y)       SvIV( _ARRAY_FETCH( PERL_OBJECT_ARGS (AV*)(x), (I32)(y) ) )
    #define ARRAY_GET_NV(x,y)       SvNV( _ARRAY_FETCH( PERL_OBJECT_ARGS (AV*)(x), (I32)(y) ) )
    #define ARRAY_GET_AV(x,y)       EXTRACT_AV( ARRAY_GET_SV( (x), (y) ) )
    #define ARRAY_GET_HV(x,y)       EXTRACT_HV( ARRAY_GET_SV( (x), (y) ) )

    ////////////////////////////////////////////////////////////////////////////
    //  Extract AV from an SV:  SV *pSv = ST( 0 );
    //                          AV *pAv = EXTRACT_AV( pSv );
    #define EXTRACT_AV(x)           _EXTRACT_AV( (SV*) (x) )    
    inline AV *_EXTRACT_AV( SV *pSv  )
    {
        AV *pAv = NULL;
        if( NULL == pSv )
        {
            return( NULL );
        }

        if( SvROK( pSv ) )
	    {
            pSv = SvRV( pSv );
        }
	    if( SVt_PVAV == SvTYPE( pSv ) )
	    {
	        pAv = (AV*) pSv;
	    }
        return( pAv );
    }

    ////////////////////////////////////////////////////////////////////////////
    // Extract an SV* from an array 
    //
    inline SV* _ARRAY_FETCH( PERL_OBJECT_PROTO AV *pAv, I32 Index )
    {
        SV *pSv = NULL;
        if( NULL != pAv )
        {
            SV **ppSvTemp = av_fetch( pAv, Index, 0 );
            if( NULL != ppSvTemp )
            {
                pSv = ppSvTemp[ 0 ];
            }
        }
        return( pSv );
    }

#endif  //  _WIN32PERL_H_




/* 
/////////////////////////////////////////////////////////////

	HISTORY
	
	20080321	roth
		-Added support for Perl v5.10

*/
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  This is part of ebbl 1.1.0 barcode library                                //
//  ebblapi.h 2004-11-03                                                      //
//  Copyright (c) 2003-2004, Edgars Binans                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/** \file
 * \brief Platform specific API's and macroses
 *
 * Multi-threading support and automatic linkage
 */

#ifndef EBBL_API_HEADER
#define EBBL_API_HEADER

#ifdef _WIN32

#ifndef EBBL_NAL

  #include "ebblver.h"

  #ifdef EBBL_LIB
    #define LIBSUFX "s"
  #else
    #define LIBSUFX ""
  #endif

  #ifdef EBBL_MT
    #define MTSUFX "mt"
  #else
    #define MTSUFX ""
  #endif

  #ifdef __BORLANDC__
    #ifdef EBBL_VCL
      #define EBBL_MT
      #pragma comment(lib, "ebbl" VER "bcv.lib")
    #else
      #pragma comment(lib, "ebbl" VER "bc" MTSUFX LIBSUFX ".lib")
    #endif
  #endif

  #ifdef _MSC_VER
    #pragma comment(lib, "ebbl" VER "vc" MTSUFX LIBSUFX ".lib")
  #endif

#endif

#define WIN32_LEAN_AND_MEAN
#define VC_EXTRALEAN

#include <windows.h>

  #define EBBL_CALLCONV __stdcall

  #ifdef EBBL_EXPORTS
    #define EBBL_API __declspec(dllexport)
  #else // EBBL_EXPORTS
    #ifdef EBBL_LIB
      #define EBBL_API
    #else //  EBBL_LIB
      #define EBBL_API __declspec(dllimport)
    #endif //  EBBL_LIB
  #endif // EBBL_EXPORTS

#ifdef EBBL_MT
namespace ebbl {
  /** \brief	Critical section class for multi-threading
   *
   * Wrapper for platform specific multi-threading support (Win32)
   */
  class mt_critical {
    private:
      CRITICAL_SECTION* CriticalSection;      ///< Critical section identifier
    public:
      EBBL_API EBBL_CALLCONV mt_critical();   ///< Construction and initialisation
      EBBL_API void EBBL_CALLCONV enter();    ///< Enter critical section
      EBBL_API void EBBL_CALLCONV leave();    ///< Leave critical section
      EBBL_API EBBL_CALLCONV ~mt_critical();  ///< Release aquired resources
  };
}
#endif // EBBL_MT

#else  // _WIN32

  #define EBBL_API
  #define EBBL_CALLCONV

#endif // _WIN32

#endif // EBBL_API_HEADER

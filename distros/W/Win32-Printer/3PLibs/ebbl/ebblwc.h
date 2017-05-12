////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  This is part of ebbl 1.1.0 barcode library                                //
//  ebblwc.h 2004-11-03                                                       //
//  Copyright (c) 2003-2004, Edgars Binans                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/** \file
 * \brief Win32 drawing implementation (extern "C")
 *
 * Implements drawing on Win32 GDI as "C" API
 */

#ifndef EBBL_WIN_HEADERC_FILE
#define EBBL_WIN_HEADERC_FILE

#include "ebblapi.h"

#define EB_ESUCCESS 0
#define EB_ESELECT  1
#define EB_ECHAR    2
#define EB_ESIZE    4
#define EB_EGDI     8
#define EB_EMEM     16
#define EB_EUNKNOWN 32

#define EB_25MATRIX 0x00000001
#define EB_25INTER  0x00000002
#define EB_25IND    0x00000004
#define EB_25IATA   0x00000008

#define EB_27       0x00000010

#define EB_39STD    0x00000020
#define EB_39EXT    0x00000040
#define EB_39DUMB   0x00000080

#define EB_93       0x00000100

#define EB_128SMART 0x00000200
#define EB_128A     0x00000400
#define EB_128B     0x00000800
#define EB_128C     0x00001000
#define EB_128SHFT  0x00002000
#define EB_128EAN   0x00004000

#define EB_EAN13    0x00008000
#define EB_UPCA     0x00010000
#define EB_EAN8     0x00020000
#define EB_UPCE     0x00040000
#define EB_ISBN     0x00080000
#define EB_ISBN2    0x00100000
#define EB_ISSN     0x00200000
#define EB_AD2      0x00400000
#define EB_AD5      0x00800000

#define EB_CHK      0x01000000
#define EB_TXT      0x02000000

/** \brief	Barcode options ("C"-style)
 *
 * Structure that describes barcode for "C"-style function.
 * @see ebbl
 */
typedef struct ebc_tag {
  HDC       hdc;    ///< Device context
  unsigned  flags;  ///< Barcode mode
  int       baw;    ///< Bar width ratio
  int       bah;    ///< Bar height
} ebc_t, *pebc_t;

#ifdef __cplusplus
extern "C" {
#endif
  /** \brief	Draw barcode ("C"-style)
   *
   * Draw barcode in "C"-style
   * @param ebc - barcode options
   * @param enstr - "C"-style string
   * @param x - coordinate
   * @param y - coordinate
   * @return error code
   * @see ebc_tag
   */
  EBBL_API int __stdcall EBbl(pebc_t ebc, char* enstr, int x, int y);
  /** \brief	Get ebbl version string ("C"-style)
   * @return pointer to const null-terminated string of ebbl version
   */
  EBBL_API const char* __stdcall EBblVersion();
#ifdef __cplusplus
}
#endif

#endif

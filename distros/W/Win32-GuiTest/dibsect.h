/* 
 *  $Id: dibsect.h,v 1.1 2004/03/16 01:37:20 ctrondlp Exp $
 *
 *  Adapted from code submitted by Jarek Jurasz
 * <jurasz@imb.uni-karlsruhe.de>. Thanks!
 *  
 *  This file is part of the Win32::GuiTest Perl module.
 * 
 *  You may distribute under the terms of either the GNU General Public
 *  License or the Artistic License.
 *
 */
#ifndef DIBSECT_H
#define DIBSECT_H 1

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

/* 
  JJ DibSection wrapper 
  Currently only 24bit bitmaps fully supported
*/
class DibSect
: public BITMAPINFOHEADER
{
public:
  DibSect();
  ~DibSect() { Destroy(); }

  bool Destroy();

  bool Load  (const char * szFile);  
  bool SaveAs(const char * szFile);
  bool Invert();
  bool ToGrayScale();
  
  HBITMAP CopyWndClient
  (
    HWND hWnd,
    RECT * pr       = NULL
  );
  bool      ToClipboard();

  // copy BMIH only, no result on created DibSection
  DibSect& operator=(const DibSect & rhs)
  {
    CopyMemory(this, &rhs, sizeof(BITMAPINFOHEADER));
    return *this;
  }
  operator HBITMAP() const
  {
    return hBitmap;
  }

  HBITMAP Create(HDC hDC);

  // the C++ object loses the ownership over DIB object
  HBITMAP StealBitmap()
  {
    HBITMAP hbm = hBitmap;
    hBitmap = NULL;
    return hbm;
  }

  PBYTE GetBits() const
  {
    return pBits;
  }
  UINT GetWidthBytes() const
  {
    return cWidthBytes;
  }

  HMETAFILE AsMetafile();
  
protected:
  // returns variable size of BITMAPINFO depending on color depth
  UINT    GetBmiSize() const;

private:
  HBITMAP       hBitmap;
  PBYTE         pBits;                  // bitmap's bytes
  int           cySize;                 // also in biHeight, but may be inverted
  UINT          cWidthBytes;            // bitmap width in bytes
};//class DibSect---------------------------------------------------------------

#endif // DIBSECT_H

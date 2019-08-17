/* 
 *  $Id: DibSect.cpp,v 1.1 2007/10/23 11:25:25 pkaluski Exp $
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


#include "dibsect.h"
#include <stdio.h>
#include <stdlib.h>

/* JJ Some environment */
#define unless(x) if(!(x))
#define SelectBitmap (HBITMAP)SelectObject

DibSect::DibSect()
{
  ZeroMemory(this, sizeof(*this));

  biSize        = sizeof(BITMAPINFOHEADER);
  biPlanes      = 1; // Must always be 1 according to docs
  biBitCount    = 8; // by default
  biCompression = BI_RGB;
}//DibSect::DibSect()-----------------------------------------------------------


bool DibSect::Destroy()
{
  if (hBitmap)
  {
    DeleteObject(hBitmap);
    hBitmap = NULL;
    pBits = NULL;
  }
  return true;
}//DibSect::Destroy()----------------------------------------------------------

/*
  The hDC seems to be needed for DIB_PAL_COLORS only.
*/
HBITMAP DibSect::Create
(
  HDC hDC       // a DC with the right palette
)
{
  Destroy();

  // rounded up to full DWORDs
  cWidthBytes = (((biWidth * biBitCount) >> 3) + 3) & (~3);
  cySize      = abs(biHeight);


  PBITMAPINFO pbmi;
  BOOL fDelete;
  UINT uUsage;

  if (biCompression == BI_RGB && biBitCount >= 16)
  {
    /*
      - for now works only for 24 bit case
      - in 16 and 32 bit case 3 DWORD masks are needed!
      - no color table needed
    */
    pbmi = (PBITMAPINFO) this;
    fDelete = FALSE;
    uUsage = DIB_RGB_COLORS;
  }
  else
  {
    int nColors = 1 << biBitCount;
    uUsage = DIB_PAL_COLORS;
    // for DIB_PAL_COLORS only
    pbmi = (PBITMAPINFO) new char [GetBmiSize()];
    fDelete = TRUE;

    // copy out the Bmih
    CopyMemory(pbmi, this, biSize);

    // put palette indices
    // use DIB_PAL_COLORS, 1:1 for speed
    USHORT *pPal = (USHORT *) pbmi->bmiColors;
    for (int i = 0; i < nColors; )
      *pPal++ = (USHORT) i++;

    // with DIB_RGB_COLORS could use GetSystemPaletteEntries() or
    // GetDIBColorTable()
  }
  biSizeImage = cySize * cWidthBytes;
 
  // no file mapping given
  hBitmap = CreateDIBSection(hDC, pbmi, uUsage, (void **) &pBits, NULL, 0);

  if (fDelete)
    delete [] pbmi;

  return hBitmap;
}//DibSect::Create()------------------------------------------------------------

// or better just a number of colors?
UINT DibSect::GetBmiSize() const
{
  switch(biBitCount)
  {
    case 16:
    case 32:
      // include the definition of bit distribution
      return sizeof(BITMAPINFOHEADER) + 3 * sizeof(DWORD);

    case 24:
      return sizeof(BITMAPINFOHEADER);

    default:
      return sizeof(BITMAPINFOHEADER) + (1 << biBitCount) * sizeof(RGBQUAD);
  }
}//DibSect::GetBmiSize()--------------------------------------------------------

/*
  Copies a rect from window's client area into a current (not yet created) DIB
  - depends on visibility
*/
HBITMAP DibSect::CopyWndClient
(
  HWND hWnd,
  RECT * pr // = NULL
)
{
  RECT r;
  if (pr && !IsRectEmpty(pr))
    r = *pr;
  else
    GetClientRect(hWnd, &r);

  HDC hdcWnd = GetDC(hWnd);
  HDC hdcMem = CreateCompatibleDC(hdcWnd);

  HBITMAP hbmOld;

  biWidth = r.right - r.left;
  biHeight = r.bottom - r.top;
  // always true color - could use palette for gray
  biBitCount = 24;
  HBITMAP hbm;
  unless (hbm = Create(hdcWnd))
    return hbm;

  hbmOld = SelectBitmap(hdcMem, hbm);
  BitBlt(hdcMem, 0, 0, biWidth, biHeight, hdcWnd, r.left, r.top, SRCCOPY);

  SelectObject(hdcMem, hbmOld);
  DeleteObject(hdcMem);
  ReleaseDC(hWnd, hdcWnd);

  return hbm;
}//DibSect::CopyWndClient()----------------------------------------------------


bool DibSect::Invert()
{
  // would work also for 32 bit
  unless (pBits && biBitCount == 24 || biBitCount == 32)
    return false;

  for (int y = 0; y < biHeight; y++)
  {
    PBYTE prgb = pBits + y * cWidthBytes;
    for (int x = 0; x < biWidth; x++)
    {
      prgb[0] = 255 - prgb[0];
      prgb[1] = 255 - prgb[1];
      prgb[2] = 255 - prgb[2];
      prgb += biBitCount/8;
    }
  }
  return true;
}//DibSect::Invert()-----------------------------------------------------------


bool DibSect::ToGrayScale()
{
  // would work also for 32 bit
  unless (pBits && biBitCount == 24 || biBitCount == 32)
    return false;

  for (int y = 0; y < biHeight; y++)
  {
    PBYTE prgb = pBits + y * cWidthBytes;
    for (int x = 0; x < biWidth; x++)
    {
      BYTE r = prgb[0];
      BYTE g = prgb[1];
      BYTE b = prgb[2];
      prgb[0] = prgb[1] = prgb[2] = (r + g + b) / 3;
      prgb += biBitCount/8;
    }
  }
  return true;
}//DibSect::ToGrayScale()------------------------------------------------------


const unsigned short DS_BITMAP_FILEMARKER = 0x4d42; // 'BM'


// not tested
bool DibSect::Load(const char *szFileName)
{
  hBitmap = (HBITMAP) LoadImage(NULL, szFileName, IMAGE_BITMAP, 0, 0, 
    LR_LOADFROMFILE | LR_CREATEDIBSECTION);
  return hBitmap != NULL;
}

// currently 256 colors not supported
bool DibSect::SaveAs(const char *szFileName)
{
  unless (pBits && biBitCount == 24)
    return false;

  BITMAPFILEHEADER   hdr;

  unless (szFileName)
    return false;

  // Perl redefines fopen etc.
  FILE * pf = fopen(szFileName, "w+b");
  
  unless (pf)
    return false;

  DWORD dwBitmapInfoSize = GetBmiSize();
  DWORD dwFileHeaderSize = dwBitmapInfoSize + sizeof(hdr);

  // Fill in the fields of the file header 
  hdr.bfType       = DS_BITMAP_FILEMARKER;
  hdr.bfSize       = dwFileHeaderSize + biSizeImage;
  hdr.bfReserved1  = 0;
  hdr.bfReserved2  = 0;
  hdr.bfOffBits    = dwFileHeaderSize;

  // Write the file header 
  bool fOk = (sizeof(hdr) == fwrite(&hdr, 1, sizeof(hdr), pf));

  // Write the DIB header
  unless (dwBitmapInfoSize == fwrite(this, 1, dwBitmapInfoSize, pf))
    fOk = false;
 
  // Write DIB bits
  unless (biSizeImage == fwrite(GetBits(), 1, biSizeImage, pf))
    fOk = false;

  unless(fclose(pf))
    fOk = false;

  return fOk;
}//DibSect::SaveAs()-----------------------------------------------------------


/*
 - see old MSDN note "DIBs and Their Use"
 - ENHMETAFILE some other day
*/
HMETAFILE DibSect::AsMetafile()
{
  // not a wmf file format...
  HDC hMetaDC = CreateMetaFile((LPSTR) NULL);
  // requires bitmapinfo (header + colors), but we cheat it to live with header only
  StretchDIBits(hMetaDC, 0, 0, biWidth, biHeight, 0, 0, biWidth, 
    biHeight, GetBits(), (BITMAPINFO * )this, DIB_RGB_COLORS, SRCCOPY);
  HMETAFILE hMetafile = CloseMetaFile(hMetaDC);
  return hMetafile;
}

bool DibSect::ToClipboard()
{
  unless (hBitmap)
    return FALSE;

  BOOL fAsDIB = FALSE;
  

  // CF_DIB needs a packed DIB with header, color table and bits in one memory block
  // CF_BITMAP somehow doesn't work with DIB handles
  // -> use metafile

  HANDLE h = GlobalAlloc(GMEM_MOVEABLE | GMEM_DDESHARE, sizeof(METAFILEPICT));
  METAFILEPICT * pmfp = (METAFILEPICT *) GlobalLock(h);

  pmfp->mm = MM_TEXT;
  pmfp->xExt = biWidth;
  pmfp->yExt = cySize;
  pmfp->hMF = AsMetafile();

  GlobalUnlock(h);

  bool fSuccess = 
       OpenClipboard(NULL)
    && EmptyClipboard()
    && SetClipboardData(CF_METAFILEPICT, h);

  unless (fSuccess)
    GlobalFree(h);

  // we try to close it even if opening failed
  CloseClipboard();

  return fSuccess;
}//DibSect::ToClipboard()-------------------------------------------------------



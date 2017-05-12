/**********************************************************************/
/*                    D I B i t m a p . x s                           */
/**********************************************************************/

/* $Id: DIBitmap.xs,v 1.4 2007/07/15 19:19:44 robertemay Exp $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define FREEIMAGE_LIB
#include ".\extlib\FreeImage.h"

/*--------------------------------------------------------------------*/

// #define IO_HANDLER_DEBUG

#define BREAK_POINT __asm { int 3 };

/*--------------------------------------------------------------------*/

typedef FIBITMAP *       Win32__GUI__DIBitmap;
typedef FIBITMAP *       Win32__GUI__DIBitmap__Ext; // For MDIBitmap
typedef FIMULTIBITMAP *  Win32__GUI__MDIBitmap;

#define IOHANDLE_READ  0
#define IOHANDLE_WRITE 1
#define IOHANDLE_SIZE  2

typedef struct {
          char * data;
          char * ptr;
          long   size;
          int    mode;
        } Memory_IO_Handle;

/*--------------------------------------------------------------------*/

#define gdMaxColors 256

typedef struct gdImageStruct
  {
    /* Palette-based image pixels */
    unsigned char **pixels;
    int sx;
    int sy;
    /* These are valid in palette images only. See also
       'alpha', which appears later in the structure to
       preserve binary backwards compatibility */
    int colorsTotal;
    int red[gdMaxColors];
    int green[gdMaxColors];
    int blue[gdMaxColors];
    int open[gdMaxColors];
    /* For backwards compatibility, this is set to the
       first palette entry with 100% transparency,
       and is also set and reset by the
       gdImageColorTransparent function. Newer
       applications can allocate palette entries
       with any desired level of transparency; however,
       bear in mind that many viewers, notably
       many web browsers, fail to implement
       full alpha channel for PNG and provide
       support for full opacity or transparency only. */
    int transparent;
    int *polyInts;
    int polyAllocated;
    struct gdImageStruct *brush;
    struct gdImageStruct *tile;
    int brushColorMap[gdMaxColors];
    int tileColorMap[gdMaxColors];
    int styleLength;
    int stylePos;
    int *style;
    int interlace;
    /* New in 2.0: thickness of line. Initialized to 1. */
    int thick;
    /* New in 2.0: alpha channel for palettes. Note that only
       Macintosh Internet Explorer and (possibly) Netscape 6
       really support multiple levels of transparency in
       palettes, to my knowledge, as of 2/15/01. Most
       common browsers will display 100% opaque and
       100% transparent correctly, and do something
       unpredictable and/or undesirable for levels
       in between. TBB */
    int alpha[gdMaxColors];
    /* Truecolor flag and pixels. New 2.0 fields appear here at the
       end to minimize breakage of existing object code. */
    int trueColor;
    int **tpixels;
    /* Should alpha channel be copied, or applied, each time a
       pixel is drawn? This applies to truecolor images only.
       No attempt is made to alpha-blend in palette images,
       even if semitransparent palette entries exist.
       To do that, build your image as a truecolor image,
       then quantize down to 8 bits. */
    int alphaBlendingFlag;
    /* Should the alpha channel of the image be saved? This affects
       PNG at the moment; other future formats may also
       have that capability. JPEG doesn't. */
    int saveAlphaFlag;

    /* 2.0.12: anti-aliased globals */
    int AA;
    int AA_color;
    int AA_dont_blend;
    unsigned char **AA_opacity;
    int AA_polygon;
    /* Stored and pre-computed variables for determining the perpendicular
       distance from a point to the anti-aliased line being drawn: */
    int AAL_x1;
    int AAL_y1;
    int AAL_x2;
    int AAL_y2;
    int AAL_Bx_Ax;
    int AAL_By_Ay;
    int AAL_LAB_2;
    float AAL_LAB;

    /* 2.0.12: simple clipping rectangle. These values
      must be checked for safety when set; please use
      gdImageSetClip */
    int cx1;
    int cy1;
    int cx2;
    int cy2;
} gdImage;

typedef gdImage *  gdImagePtr;
typedef gdImagePtr GD__Image;

/**********************************************************************/
/**********************************************************************/
/**********************************************************************/

/*====================================================================*/
/*  FreeImage Memory handler functions                                */
/*====================================================================*/

unsigned Memory_ReadProc (void *buffer, unsigned size, unsigned count,
                          fi_handle handle)
{
    Memory_IO_Handle * ioh = (Memory_IO_Handle *) handle;

#ifdef IO_HANDLER_DEBUG
    printf ("Memory_ReadProc : size = %d\tcount = %d\n", size, count);
    printf ("      Handler   : mode = %d\tsize  = %d\tpos = %d\n",
                           ioh->mode, ioh->size, ioh->ptr - ioh->data);
#endif

    if (ioh->mode == IOHANDLE_READ)
    {
      memcpy (buffer, ioh->ptr, size * count);
      ioh->ptr += size * count;
    }
    else
    {
      count = 0;
    }

    return count;
}

int Memory_SeekProc (fi_handle handle, long offset, int origin)
{
    Memory_IO_Handle * ioh = (Memory_IO_Handle *) handle;

#ifdef IO_HANDLER_DEBUG
    printf ("Memory_SeekProc : offset = %d\torigin = %d\n", offset, origin);
    printf ("      Handler   : mode = %d\tsize  = %d\tpos = %d\n",
                           ioh->mode, ioh->size, ioh->ptr - ioh->data);
#endif

    switch (origin)
    {
      case SEEK_SET :
          ioh->ptr = ioh->data + offset;
          break;
      case SEEK_CUR :
          ioh->ptr = ioh->ptr  + offset;
          break;
      case SEEK_END :
          ioh->ptr = (ioh->data  + ioh->size) - offset;
    }

    return 0;
}

long Memory_TellProc (fi_handle handle)
{
  Memory_IO_Handle * ioh = (Memory_IO_Handle *) handle;

#ifdef IO_HANDLER_DEBUG
    printf ("Memory_TellProc : \n");
    printf ("      Handler   : mode = %d\tsize  = %d\tpos = %d\n",
                           ioh->mode, ioh->size, ioh->ptr - ioh->data);
#endif

  return (ioh->ptr - ioh->data);
}

unsigned Memory_WriteProc (void *buffer, unsigned size, unsigned count,
                           fi_handle handle)
{
    Memory_IO_Handle * ioh = (Memory_IO_Handle *) handle;

#ifdef IO_HANDLER_DEBUG
    printf ("Memory_WriteProc : size = %d\tcount = %d\n", size, count);
    printf ("      Handler   : mode = %d\tsize  = %d\tpos = %d\n",
                           ioh->mode, ioh->size, ioh->ptr - ioh->data);
#endif

    switch (ioh->mode)
    {
      case IOHANDLE_WRITE :
          memcpy (ioh->ptr, buffer, size * count);
      case IOHANDLE_SIZE :
          ioh->ptr  += size * count;
          if (ioh->size < (ioh->ptr - ioh->data))
          {
            ioh->size = (ioh->ptr - ioh->data);
          }
          break;
      default :
          printf ("Mode incorrect in write\n");
          count = -1;
    }

    return count;
}

/*====================================================================*/
/*  FreeImage Constant                                                */
/*====================================================================*/

#define CONSTANT(x) if(strEQ(name, #x)) return x

int constant (char * name, int arg)
{
  errno = 0;
  switch(*name)
  {
    case 'B' :
            CONSTANT(BMP_DEFAULT);
            CONSTANT(BMP_SAVE_RLE);
    case 'C' :
            CONSTANT(CUT_DEFAULT);
    case 'D' :
            CONSTANT(DDS_DEFAULT);
    case 'F' :
      switch (name[2])
      {
        // FREE_IMAGE_FORMAT
        case 'F' :
            CONSTANT(FIF_UNKNOWN);
            CONSTANT(FIF_BMP);
            CONSTANT(FIF_CUT);
            CONSTANT(FIF_ICO);
            CONSTANT(FIF_JPEG);
            CONSTANT(FIF_JNG);
            CONSTANT(FIF_KOALA);
            CONSTANT(FIF_LBM);
            CONSTANT(FIF_IFF);
            CONSTANT(FIF_MNG);
            CONSTANT(FIF_PBM);
            CONSTANT(FIF_PBMRAW);
            CONSTANT(FIF_PCD);
            CONSTANT(FIF_PCX);
            CONSTANT(FIF_PGM);
            CONSTANT(FIF_PGMRAW);
            CONSTANT(FIF_PNG);
            CONSTANT(FIF_PPM);
            CONSTANT(FIF_PPMRAW);
            CONSTANT(FIF_PSD);
            CONSTANT(FIF_RAS);
            CONSTANT(FIF_TARGA);
            CONSTANT(FIF_TIFF);
            CONSTANT(FIF_WBMP);
            CONSTANT(FIF_XBM);
            CONSTANT(FIF_XPM);
            CONSTANT(FIF_DDS);
        // FREE_IMAGE_COLOR_TYPE
        case 'C' :
            CONSTANT(FIC_MINISWHITE);
            CONSTANT(FIC_MINISBLACK);
            CONSTANT(FIC_RGB);
            CONSTANT(FIC_PALETTE);
            CONSTANT(FIC_RGBALPHA);
            CONSTANT(FIC_CMYK);
            // Color channel
            CONSTANT(FICC_RGB);
            CONSTANT(FICC_RED);
            CONSTANT(FICC_GREEN);
            CONSTANT(FICC_BLUE);
            CONSTANT(FICC_ALPHA);
            CONSTANT(FICC_BLACK);
            CONSTANT(FICC_REAL);
            CONSTANT(FICC_IMAG);
            CONSTANT(FICC_MAG);
            CONSTANT(FICC_PHASE);
        // FREE_IMAGE_DITHER
        case 'D' :
            CONSTANT(FID_FS);
            CONSTANT(FID_BAYER4x4);
            CONSTANT(FID_BAYER8x8);
            CONSTANT(FID_CLUSTER6x6);
            CONSTANT(FID_CLUSTER8x8);
            CONSTANT(FID_CLUSTER16x16);
        // Sampling
        case 'L' :
            CONSTANT(FILTER_BOX);
            CONSTANT(FILTER_BICUBIC);
            CONSTANT(FILTER_BILINEAR);
            CONSTANT(FILTER_BSPLINE);
            CONSTANT(FILTER_CATMULLROM);
            CONSTANT(FILTER_LANCZOS3);
        // FREE_IMAGE_QUANTIZE
        case 'Q' :
            CONSTANT(FIQ_WUQUANT);
            CONSTANT(FIQ_NNQUANT);
        // FREE_IMAGE_TYPE
        case 'T' :
            CONSTANT(FIT_UNKNOWN);
            CONSTANT(FIT_BITMAP);
            CONSTANT(FIT_UINT16);
            CONSTANT(FIT_INT16);
            CONSTANT(FIT_UINT32);
            CONSTANT(FIT_INT32);
            CONSTANT(FIT_FLOAT);
            CONSTANT(FIT_DOUBLE);
            CONSTANT(FIT_COMPLEX);
      }
    case 'G' :
            CONSTANT(GIF_DEFAULT);
    case 'I' :
            CONSTANT(ICO_DEFAULT);
            CONSTANT(ICO_MAKEALPHA);
            CONSTANT(IFF_DEFAULT);
    case 'J' :
            CONSTANT(JPEG_DEFAULT);
            CONSTANT(JPEG_FAST);
            CONSTANT(JPEG_ACCURATE);
            CONSTANT(JPEG_QUALITYSUPERB);
            CONSTANT(JPEG_QUALITYGOOD);
            CONSTANT(JPEG_QUALITYNORMAL);
            CONSTANT(JPEG_QUALITYAVERAGE);
            CONSTANT(JPEG_QUALITYBAD);
    case 'K' :
            CONSTANT(KOALA_DEFAULT);
    case 'L' :
            CONSTANT(LBM_DEFAULT);
    case 'M' :
            CONSTANT(MNG_DEFAULT);
    case 'P' :
            CONSTANT(PCD_DEFAULT);
            CONSTANT(PCD_BASE);
            CONSTANT(PCD_BASEDIV4);
            CONSTANT(PCD_BASEDIV16);

            CONSTANT(PCX_DEFAULT);

            CONSTANT(PNG_DEFAULT);
            CONSTANT(PNG_IGNOREGAMMA);

            CONSTANT(PNM_DEFAULT);
            CONSTANT(PNM_SAVE_RAW);
            CONSTANT(PNM_SAVE_ASCII);

            CONSTANT(PSD_DEFAULT);
    case 'R' :
            CONSTANT(RAS_DEFAULT);
    case 'T' :
            CONSTANT(TARGA_DEFAULT);
            CONSTANT(TARGA_LOAD_RGB888);

            CONSTANT(TIFF_DEFAULT);
            CONSTANT(TIFF_CMYK);
            CONSTANT(TIFF_PACKBITS);
            CONSTANT(TIFF_DEFLATE);
            CONSTANT(TIFF_ADOBE_DEFLATE);
            CONSTANT(TIFF_NONE);
            CONSTANT(TIFF_CCITTFAX3);
            CONSTANT(TIFF_CCITTFAX4);
            CONSTANT(TIFF_LZW);
    case 'W' :
            CONSTANT(WBMP_DEFAULT);
    case 'X' :
            CONSTANT(XBM_DEFAULT);
            CONSTANT(XPM_DEFAULT);
  }
  errno = EINVAL;
  return 0;
}

/**********************************************************************/
/**********************************************************************/
/**********************************************************************/

MODULE = Win32::GUI::DIBitmap     PACKAGE = Win32::GUI::DIBitmap

PROTOTYPES: ENABLE

  ##################################################################
  #                                                                #
  #              Win32::GUI::DIBitmap  package                     #
  #                                                                #
  ##################################################################

  #
  # _Initialise (internal)
  #

void
_Initialise()
CODE:
  FreeImage_Initialise (TRUE);

  #
  # _DeInitialise (internal)
  #

void
_DeInitialise()
CODE:
  FreeImage_DeInitialise();

  ##################################################################
  #
  #  FreeImage Informations routines
  #

  #
  # constant
  #

int
constant(name,arg)
        char *          name
        int             arg

  #
  # GetVersion
  #

void
GetVersion()
PREINIT:
    char * version;
PPCODE:
    version = (char *) FreeImage_GetVersion();
    EXTEND(SP, 1);
    XST_mPV(0, version);
    XSRETURN(1);


  #
  # GetCopyright
  #

void
GetCopyright()
PREINIT:
    char * message;
PPCODE:
    message = (char *) FreeImage_GetCopyrightMessage();
    EXTEND(SP, 1);
    XST_mPV(0, message);
    XSRETURN(1);

  #
  #
  ##################################################################


  ##################################################################
  #
  #  Max format
  #

  #
  # GetFIFCount
  #

int
GetFIFCount()
CODE:
    RETVAL = FreeImage_GetFIFCount();
OUTPUT:
    RETVAL

  #
  #
  ##################################################################


  ##################################################################
  #
  #  Format information routine
  #

  #
  # GetFormatFromFIF
  #

void
GetFormatFromFIF(fif)
    FREE_IMAGE_FORMAT  fif
PREINIT:
    char * string;
PPCODE:
    string = (char *) FreeImage_GetFormatFromFIF(fif);
    if (string == NULL)
    {
      XSRETURN_UNDEF;
    }
    else
    {
      EXTEND(SP, 1);
      XST_mPV(0, string);
      XSRETURN(1);
    }

  #
  #
  ##################################################################

  ##################################################################
  #
  #  FIF detections routines
  #

  #
  # GetFIFFromFormat
  #

int
GetFIFFromFormat(format)
    LPCTSTR format
CODE:
    RETVAL = FreeImage_GetFIFFromFormat(format);
OUTPUT:
    RETVAL

  #
  # GetFIFFromMime
  #

int
GetFIFFromMime(format)
    LPCTSTR format
CODE:
    RETVAL = FreeImage_GetFIFFromMime(format);
OUTPUT:
    RETVAL


  #
  # GetFIFFromFilename
  #

int
GetFIFFromFilename(filename)
    LPCTSTR filename
CODE:
    RETVAL = FreeImage_GetFIFFromFilename (filename);
OUTPUT:
    RETVAL

  #
  # GetFIFFromFile
  #

int
GetFIFFromFile(filename,size=0)
    LPCTSTR filename
    int     size
CODE:
    RETVAL = FreeImage_GetFileType(filename, size);
OUTPUT:
    RETVAL

  #
  # GetFIFFromData
  #

int
GetFIFFromData(imagedata,size=16)
    SV *    imagedata
    int     size
PREINIT:
    Memory_IO_Handle handle;
    FreeImageIO      io;
    STRLEN           len;
CODE:

    io.read_proc  = Memory_ReadProc;
    io.write_proc = Memory_WriteProc;
    io.seek_proc  = Memory_SeekProc;
    io.tell_proc  = Memory_TellProc;

    handle.data = SvPV(imagedata,len);
    handle.ptr  = handle.data;
    handle.size = len;
    handle.mode = IOHANDLE_READ;

    RETVAL = FreeImage_GetFileTypeFromHandle(&io, (fi_handle) &handle, size);
OUTPUT:
    RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  #  FIF informations routines
  #


  #
  # FIFExtensionList
  #

void
FIFExtensionList(fif)
    FREE_IMAGE_FORMAT  fif
PREINIT:
    char * string;
PPCODE:
    string = (char *) FreeImage_GetFIFExtensionList(fif);
    if (string == NULL)
    {
      XSRETURN_UNDEF;
    }
    else
    {
      EXTEND(SP, 1);
      XST_mPV(0, string);
      XSRETURN(1);
    }

  #
  # FIFDescription
  #

void
FIFDescription(fif)
    FREE_IMAGE_FORMAT  fif
PREINIT:
    char * string;
PPCODE:
    string = (char *) FreeImage_GetFIFDescription(fif);
    if (string == NULL)
    {
      XSRETURN_UNDEF;
    }
    else
    {
      EXTEND(SP, 1);
      XST_mPV(0, string);
      XSRETURN(1);
    }

  #
  # FIFRegExpr
  #

void
FIFRegExpr(fif)
    FREE_IMAGE_FORMAT  fif
PREINIT:
    char * string;
PPCODE:
    string = (char *) FreeImage_GetFIFRegExpr(fif);
    if (string == NULL)
    {
      XSRETURN_UNDEF;
    }
    else
    {
      EXTEND(SP, 1);
      XST_mPV(0, string);
      XSRETURN(1);
    }

  #
  # FIFMimeType
  #

void
FIFMimeType(fif)
    FREE_IMAGE_FORMAT  fif
PREINIT:
    char * string;
PPCODE:
    string = (char *) FreeImage_GetFIFMimeType(fif);
    if (string == NULL)
    {
      XSRETURN_UNDEF;
    }
    else
    {
      EXTEND(SP, 1);
      XST_mPV(0, string);
      XSRETURN(1);
    }

  #
  # FIFSupportsReading
  #

BOOL
FIFSupportsReading(fif)
    FREE_IMAGE_FORMAT fif
CODE:
    RETVAL = FreeImage_FIFSupportsReading (fif);
OUTPUT:
    RETVAL

  #
  # FIFSupportsWriting
  #

BOOL
FIFSupportsWriting(fif)
    FREE_IMAGE_FORMAT fif
CODE:
    RETVAL = FreeImage_FIFSupportsWriting (fif);
OUTPUT:
    RETVAL

  #
  # FIFSupportsExportBPP
  #

BOOL
FIFSupportsExportBPP(fif,bpp)
    FREE_IMAGE_FORMAT fif
    int bpp
CODE:
    RETVAL = FreeImage_FIFSupportsExportBPP (fif,bpp);
OUTPUT:
    RETVAL

  #
  # FIFSupportsExportType
  #

BOOL
FIFSupportsExportType(fif,type)
    FREE_IMAGE_FORMAT fif
    FREE_IMAGE_TYPE type
CODE:
    RETVAL = FreeImage_FIFSupportsExportType(fif,type);
OUTPUT:
    RETVAL

  #
  # FIFSupportsICCProfiles
  #

BOOL
FIFSupportsICCProfiles(fif)
    FREE_IMAGE_FORMAT fif
CODE:
    RETVAL = FreeImage_FIFSupportsICCProfiles (fif);
OUTPUT:
    RETVAL


  #
  #
  ##################################################################


  ##################################################################
  #
  #  Win32::GUI::DIBitmap new routine
  #

  #
  # new
  #

Win32::GUI::DIBitmap
new (packname="Win32::GUI::DIBitmap",width=100,height=100,bpp=24,red_mask=0,green_mask=0,blue_mask=0,type=FIT_BITMAP)
    char * packname
    int  width
    int  height
    int  bpp
    UINT red_mask
    UINT green_mask
    UINT blue_mask
    FREE_IMAGE_TYPE type
CODE:
    RETVAL = FreeImage_AllocateT(type,width,height,bpp,red_mask,green_mask,blue_mask);
OUTPUT:
    RETVAL

  #
  # _newFromFile (internal)
  #

Win32::GUI::DIBitmap
_newFromFile (packname="Win32::GUI::DIBitmap", fif, filename, flag=0)
    char *   packname
    FREE_IMAGE_FORMAT      fif
    LPCTSTR  filename
    int      flag
CODE:
    RETVAL = FreeImage_Load (fif, filename, flag);
OUTPUT:
    RETVAL


  #
  # _newFromData (internal)
  #

Win32::GUI::DIBitmap
_newFromData (packname="Win32::GUI::DIBitmap", fif, imagedata, flag=0)
    char *   packname
    FREE_IMAGE_FORMAT      fif
    SV *     imagedata
    int      flag
PREINIT:
    Memory_IO_Handle handle;
    FreeImageIO      io;
    STRLEN           len;
CODE:

    io.read_proc  = Memory_ReadProc;
    io.write_proc = Memory_WriteProc;
    io.seek_proc  = Memory_SeekProc;
    io.tell_proc  = Memory_TellProc;

    handle.data = SvPV(imagedata,len);
    handle.ptr  = handle.data;
    handle.size = len;
    handle.mode = IOHANDLE_READ;

    RETVAL = FreeImage_LoadFromHandle (fif, &io, (fi_handle) &handle, flag);
OUTPUT:
    RETVAL

  #
  # _newFromRawData (internal)
  #

  # DLL_API FIBITMAP *DLL_CALLCONV FreeImage_ConvertFromRawBits(BYTE *bits, int width, int height, int pitch, unsigned bpp, unsigned red_mask, unsigned green_mask, unsigned blue_mask, BOOL topdown FI_DEFAULT(FALSE));

  #
  # newFromBitmap
  #

Win32::GUI::DIBitmap
newFromBitmap (packname="Win32::GUI::DIBitmap", hbitmap)
    char *   packname
    HBITMAP  hbitmap
PREINIT:
    BITMAP   bmp;
    HDC      hdc;
    int      cClrBits;
    Win32__GUI__DIBitmap dib;
CODE:

    if (!GetObject (hbitmap, sizeof(BITMAP), (LPSTR)&bmp))
      XSRETURN_EMPTY;

    /* Force 24 bits copy */
    cClrBits = 24;

    dib = FreeImage_Allocate (bmp.bmWidth, bmp.bmHeight, cClrBits, 0, 0, 0 );
    if (dib == NULL)
      XSRETURN_EMPTY;

    hdc = GetDC(NULL);

    GetDIBits (hdc, hbitmap, 0, bmp.bmHeight, FreeImage_GetBits(dib),
               FreeImage_GetInfo(dib), DIB_RGB_COLORS);

    ReleaseDC (NULL,hdc);

    RETVAL = dib;
OUTPUT:
    RETVAL

  #
  # newFromDC
  #

Win32::GUI::DIBitmap
newFromDC (packname="Win32::GUI::DIBitmap", hdc, x=0, y=0, w=0, h=0)
    char *   packname
    HDC      hdc
    int      x
    int      y
    int      w
    int      h
PREINIT:
    HDC      hdcCompatible;
    HBITMAP  hbitmap, hold;
    RECT     rect;
    BITMAP   bmp;
    int      cClrBits;
    Win32__GUI__DIBitmap dib;
CODE:

    if (w == 0 || h == 0)
    {
      if (GetClipBox (hdc, &rect) != SIMPLEREGION)
        XSRETURN_EMPTY;

      w = rect.right  - rect.left;
      h = rect.bottom - rect.top;
    }

    hdcCompatible = CreateCompatibleDC (hdc);

    hbitmap       = CreateCompatibleBitmap (hdc, w, h);

    if (hbitmap == 0)
    {
      DeleteDC (hdcCompatible);
      XSRETURN_EMPTY;
    }
    hold = SelectObject(hdcCompatible, hbitmap);
    if (!hold)
    {
      DeleteObject(hbitmap);
      DeleteDC (hdcCompatible);
      XSRETURN_EMPTY;
    }

    if (!GetObject (hbitmap, sizeof(BITMAP), (LPSTR)&bmp))
    {
      SelectObject(hdcCompatible, hold);
      DeleteObject(hbitmap);
      DeleteDC (hdcCompatible);
      XSRETURN_EMPTY;
    }

    /* Force 24 bits copy */
    cClrBits = 24;

    dib = FreeImage_Allocate (bmp.bmWidth, bmp.bmHeight, cClrBits, 0, 0, 0 );
    if (dib == NULL)
    {
      SelectObject(hdcCompatible, hold);
      DeleteObject(hbitmap);
      DeleteDC (hdcCompatible);
      XSRETURN_EMPTY;
    }

    BitBlt(hdcCompatible, 0,0, bmp.bmWidth, bmp.bmHeight, hdc, x, y, SRCCOPY);

    GetDIBits (hdcCompatible, hbitmap, 0, bmp.bmHeight, FreeImage_GetBits(dib),
               FreeImage_GetInfo(dib), DIB_RGB_COLORS);

    RETVAL = dib;

    SelectObject(hdcCompatible, hold);
    DeleteDC (hdcCompatible);
    DeleteObject(hbitmap);
OUTPUT:
    RETVAL

  #
  # newFromWindow
  #

Win32::GUI::DIBitmap
newFromWindow (packname="Win32::GUI::DIBitmap", hwnd, flag=0)
    char *   packname
    HWND     hwnd
    int      flag
PREINIT:
    HDC      hdc;
    HDC      hdcCompatible;
    HBITMAP  hbitmap, hold;
    RECT     rect;
    BITMAP   bmp;
    int      cClrBits;
    Win32__GUI__DIBitmap dib;
CODE:

    if (flag == 0)
    {
      hdc = GetWindowDC(hwnd);
      GetWindowRect(hwnd, &rect);
    }
    else
    {
      hdc = GetDC(hwnd);
      GetClientRect(hwnd, &rect);
    }

    hdcCompatible = CreateCompatibleDC(hdc);

    hbitmap       = CreateCompatibleBitmap(hdc,
                                           rect.right  - rect.left,
                                           rect.bottom - rect.top);

    if (hbitmap == 0)
    {
      DeleteDC (hdcCompatible);
      ReleaseDC(hwnd, hdc);
      XSRETURN_EMPTY;
    }

    hold = SelectObject(hdcCompatible, hbitmap);
    if (!hold)
    {
      DeleteObject(hbitmap);
      DeleteDC (hdcCompatible);
      ReleaseDC(hwnd, hdc);
      XSRETURN_EMPTY;
    }

    if (!GetObject (hbitmap, sizeof(BITMAP), (LPSTR)&bmp))
    {
      SelectObject(hdcCompatible, hold);
      DeleteObject(hbitmap);
      DeleteDC (hdcCompatible);
      ReleaseDC(hwnd, hdc);
      XSRETURN_EMPTY;
    }

    /* Force 24 bits copy */
    cClrBits = 24;

    dib = FreeImage_Allocate (bmp.bmWidth, bmp.bmHeight, cClrBits, 0, 0, 0 );
    if (dib == NULL)
    {
      SelectObject(hdcCompatible, hold);
      DeleteObject(hbitmap);
      DeleteDC (hdcCompatible);
      ReleaseDC(hwnd, hdc);
      XSRETURN_EMPTY;
    }

    BitBlt(hdcCompatible, 0,0, bmp.bmWidth, bmp.bmHeight, hdc, 0,0, SRCCOPY);

    GetDIBits (hdcCompatible, hbitmap, 0, bmp.bmHeight, FreeImage_GetBits(dib),
               FreeImage_GetInfo(dib), DIB_RGB_COLORS);

    RETVAL = dib;

    SelectObject(hdcCompatible, hold);
    DeleteObject(hbitmap);
    DeleteDC (hdcCompatible);
    ReleaseDC(hwnd, hdc);
OUTPUT:
    RETVAL

  #
  #
  ##################################################################


  ##################################################################
  #
  #  GD function
  #

  #
  # newFromGD
  #

Win32::GUI::DIBitmap
newFromGD (packname="Win32::GUI::DIBitmap", gd, newGD=0)
    char *   packname
    GD::Image gd
    int newGD
PREINIT:
    Win32__GUI__DIBitmap dib;
    RGBQUAD * pal;
    int y;
CODE:
  dib = FreeImage_Allocate (gd->sx, gd->sy, (newGD && gd->trueColor ? 32 : 8), 0, 0, 0);
  if (dib != NULL)
  {
    if (newGD && gd->trueColor)
    {
      for (y = 0; y < gd->sy; y++)
        memcpy(FreeImage_GetScanLine(dib,gd->sy-y-1), gd->tpixels[y], gd->sx*sizeof(int));
    }
    else
    {
      for (y = 0; y < gd->sy; y++)
        memcpy(FreeImage_GetScanLine(dib,gd->sy-y-1), gd->pixels[y], gd->sx*sizeof(char));
      pal = FreeImage_GetPalette(dib);
      for (y = 0; y < gdMaxColors; y++)
      {
        pal[y].rgbRed   = gd->red   [y];
        pal[y].rgbGreen = gd->green [y];
        pal[y].rgbBlue  = gd->blue  [y];
      }
    }

    RETVAL = dib;
  }
  else
    XSRETURN_EMPTY;
OUTPUT:
    RETVAL

  #
  # CopyFromGD
  #

BOOL
CopyFromGD (dib, gd, newGD=0)
    Win32::GUI::DIBitmap     dib
    GD::Image gd
    int newGD
PREINIT:
    RGBQUAD * pal;
    int y;
CODE:
  if (gd->sx == (int) FreeImage_GetWidth(dib) &&
      gd->sy == (int) FreeImage_GetHeight(dib) &&
      FreeImage_GetBPP(dib) == (UINT) (newGD && gd->trueColor ? 32 : 8))
  {
    if (newGD && gd->trueColor)
    {
      for (y = 0; y < gd->sy; y++)
        memcpy(FreeImage_GetScanLine(dib,gd->sy-y-1), gd->tpixels[y], gd->sx*sizeof(int));

    }
    else
    {
      for (y = 0; y < gd->sy; y++)
        memcpy(FreeImage_GetScanLine(dib,gd->sy-y-1), gd->pixels[y], gd->sx*sizeof(char));

      pal = FreeImage_GetPalette(dib);
      for (y = 0; y < gdMaxColors; y++)
      {
        pal[y].rgbRed   = gd->red[y];
        pal[y].rgbGreen = gd->green[y];
        pal[y].rgbBlue  = gd->blue[y];
      }
    }

    RETVAL = TRUE;
  }
  else
    RETVAL = FALSE;
OUTPUT:
    RETVAL

  #
  # CopyToGD
  #

BOOL
CopyToGD (dib, gd, newGD=0)
    Win32::GUI::DIBitmap     dib
    GD::Image gd
    int newGD
PREINIT:
    RGBQUAD * pal;
    int y;
CODE:
  if (gd->sx == (int) FreeImage_GetWidth(dib) &&
      gd->sy == (int) FreeImage_GetHeight(dib) &&
      FreeImage_GetBPP(dib) == (UINT) (newGD && gd->trueColor ? 32 : 8))
  {
    if (newGD && gd->trueColor)
    {
      for (y = 0; y < gd->sy; y++)
        memcpy(gd->tpixels[y], FreeImage_GetScanLine(dib,gd->sy-y-1), gd->sx*sizeof(int));

    }
    else
    {
      for (y = 0; y < gd->sy; y++)
        memcpy(gd->pixels[y], FreeImage_GetScanLine(dib,gd->sy-y-1), gd->sx*sizeof(char));

      pal = FreeImage_GetPalette(dib);
      for (y = 0; y < gdMaxColors; y++)
      {
        gd->red[y]   = pal[y].rgbRed;
        gd->green[y] = pal[y].rgbGreen;
        gd->blue[y]  = pal[y].rgbBlue;
      }
    }

    RETVAL = TRUE;
  }
  else
    RETVAL = FALSE;
OUTPUT:
    RETVAL

  #
  #
  ##################################################################


  ##################################################################
  #
  #  Win32::GUI::DIBitmap save routine
  #

  #
  # _saveToFile (internal)
  #

BOOL
_saveToFile (dib, fif, filename, flag=0)
    Win32::GUI::DIBitmap     dib
    FREE_IMAGE_FORMAT        fif
    LPCTSTR                  filename
    int                      flag
CODE:
    RETVAL = FreeImage_Save (fif, dib, filename, flag);
OUTPUT:
    RETVAL

  #
  # _saveToData (internal)
  #

SV*
_saveToData (dib, fif, flag=0)
    Win32::GUI::DIBitmap  dib
    FREE_IMAGE_FORMAT     fif
    int                   flag
CODE:
  {
    Memory_IO_Handle handle;
    FreeImageIO      io;
    BOOL             res;
    long             size;


    io.read_proc  = Memory_ReadProc;
    io.write_proc = Memory_WriteProc;
    io.seek_proc  = Memory_SeekProc;
    io.tell_proc  = Memory_TellProc;

    handle.mode   = IOHANDLE_SIZE;
    handle.size   = 0;
    handle.data   = NULL;
    handle.ptr    = handle.data;

    res = FreeImage_SaveToHandle (fif, dib, &io, (fi_handle) &handle, flag);
    if (res)
    {

      size = handle.size;

      handle.data   = (char *) safemalloc(size);
      handle.ptr    = handle.data;
      handle.size   = 0;
      handle.mode   = IOHANDLE_WRITE;

      res = FreeImage_SaveToHandle (fif, dib, &io, (fi_handle) &handle, flag);
      if (res)
        RETVAL = newSVpv(handle.data, size);

      safefree (handle.data);
      if (!res)
        XSRETURN_UNDEF;
    }
    else
      XSRETURN_UNDEF;
  }
OUTPUT:
    RETVAL

  #
  # _saveToRawData (internal)
  #

  # DLL_API void DLL_CALLCONV FreeImage_ConvertToRawBits(BYTE *bits, FIBITMAP *dib, int pitch, unsigned bpp, unsigned red_mask, unsigned green_mask, unsigned blue_mask, BOOL topdown FI_DEFAULT(FALSE));

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Win32::GUI::DIBitmap Information routines
  #

  #
  # GetColorsUsed
  #

UINT
GetColorsUsed(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetColorsUsed(dib);
OUTPUT:
    RETVAL

  #
  # GetColorsType
  #

UINT
GetColorType(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetColorType(dib);
OUTPUT:
    RETVAL

  #
  # GetBPP
  #

UINT
GetBPP(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetBPP(dib);
OUTPUT:
    RETVAL

  #
  # GetWidth
  #

UINT
GetWidth(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetWidth(dib);
OUTPUT:
    RETVAL

  #
  # GetHeight
  #

UINT
GetHeight(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetHeight(dib);
OUTPUT:
    RETVAL

  #
  # GetLine
  #

UINT
GetLine(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetLine(dib);
OUTPUT:
    RETVAL

  #
  # GetPitch
  #

UINT
GetPitch(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetPitch(dib);
OUTPUT:
    RETVAL

  #
  # GetSize
  #

UINT
GetSize(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetDIBSize(dib);
OUTPUT:
    RETVAL

  #
  # GetDotsPerMeterX
  #

UINT
GetDotsPerMeterX(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetDotsPerMeterX(dib);
OUTPUT:
    RETVAL

  #
  # GetDotsPerMeterY
  #

UINT
GetDotsPerMeterY(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetDotsPerMeterX(dib);
OUTPUT:
    RETVAL

  #
  # GetInfoHeader
  #

SV*
GetInfoHeader(dib)
    Win32::GUI::DIBitmap   dib
CODE:
  {
    BITMAPINFOHEADER * bh;

    bh = FreeImage_GetInfoHeader(dib);
    RETVAL = newSVpv((char *)bh, sizeof(BITMAPINFOHEADER));
  }
OUTPUT:
    RETVAL

  #
  # GetInfo
  #

SV*
GetInfo(dib)
    Win32::GUI::DIBitmap   dib
CODE:
  {
    BITMAPINFO * bi;
    bi = FreeImage_GetInfo(dib);
    RETVAL = newSVpv((char *)bi, FreeImage_GetDIBSize(dib));
  }
OUTPUT:
    RETVAL

  #
  # GetBits
  #

SV*
GetBits(dib)
    Win32::GUI::DIBitmap   dib
CODE:
  {
    BYTE * data;

    data = FreeImage_GetBits(dib);
    RETVAL = newSVpv((char *)data, FreeImage_GetPitch(dib) * FreeImage_GetHeight(dib));
  }
OUTPUT:
    RETVAL

  #
  # IsTransparent
  #

UINT
IsTransparent(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_IsTransparent(dib);
OUTPUT:
    RETVAL

  #
  # GetRedMask
  #

UINT
GetRedMask(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetRedMask(dib);
OUTPUT:
    RETVAL

  #
  # GetGreenMask
  #

UINT
GetGreenMask(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetGreenMask(dib);
OUTPUT:
    RETVAL

  #
  # GetBlueMask
  #

UINT
GetBlueMask(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetBlueMask(dib);
OUTPUT:
    RETVAL

  #
  # GetImageType
  #

FREE_IMAGE_TYPE
GetImageType(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_GetImageType(dib);
OUTPUT:
    RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Pixel function
  #

  #
  # GetPixel
  #

void
GetPixel(dib, x, y)
    Win32::GUI::DIBitmap   dib
    UINT x
    UINT y
CODE:
  {
    if (FreeImage_GetBPP(dib) <= 8)
    {
      BYTE value;
      if (FreeImage_GetPixelIndex(dib, x, y, &value))
      {
        EXTEND(SP, 1);
        XST_mIV( 0, value);
        XSRETURN(1);
      }
      else
        XSRETURN_UNDEF;
    }
    else
    {
      RGBQUAD value;
      if (FreeImage_GetPixelColor(dib, x, y, &value))
      {
        if(GIMME == G_ARRAY)
        {
          EXTEND(SP, 4);
          XST_mIV( 0, value.rgbBlue);
          XST_mIV( 1, value.rgbGreen);
          XST_mIV( 2, value.rgbRed);
          XST_mIV( 3, value.rgbReserved);
          XSRETURN(4);
        }
        else
        {
          EXTEND(SP, 1);
          XST_mIV( 0, *((UINT*)&value));
          XSRETURN(1);
        }
      }
      else
        XSRETURN_UNDEF;
    }
  }

  #
  # SetPixel
  #

BOOL
SetPixel(dib, x, y, ...)
    Win32::GUI::DIBitmap   dib
    UINT x
    UINT y
CODE:
  {
    // BREAK_POINT;
    if (items != 4 && items != 6 && items != 7)
    {
      if(PL_dowarn) warn("SetPixel (x,y, Index/Color | Blue, Green, Red, [Alpha]");
      RETVAL = FALSE;
    }
    else if (FreeImage_GetBPP(dib) <= 8)
    {
      BYTE value = (BYTE) SvIV(ST(3));
      RETVAL = FreeImage_SetPixelIndex(dib, x, y, &value);
    }
    else
    {
      RGBQUAD value;
      if (items == 4)
      {
        if(SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVAV)
        {
          SV** sv ;
          AV* av = (AV*) SvRV(ST(3));
          value.rgbBlue     = (BYTE) ((sv = av_fetch(av, 0, 0)) ? SvIV(*sv) : 0);
          value.rgbGreen    = (BYTE) ((sv = av_fetch(av, 1, 0)) ? SvIV(*sv) : 0);
          value.rgbRed      = (BYTE) ((sv = av_fetch(av, 2, 0)) ? SvIV(*sv) : 0);
          value.rgbReserved = (BYTE) ((sv = av_fetch(av, 3, 0)) ? SvIV(*sv) : 0xff);
        }
        else
            /* XXX this looks wrong - the cast should be to UINT, not BYTE??? */
          *((UINT*)&value) = (BYTE) SvIV(ST(3));
      }
      else
      {
        value.rgbBlue  = (BYTE) SvIV(ST(3));
        value.rgbGreen = (BYTE) SvIV(ST(4));
        value.rgbRed   = (BYTE) SvIV(ST(5));
        value.rgbReserved = (BYTE) (items == 7 ? SvIV(ST(6)) : 0xff);
      }

      RETVAL = FreeImage_SetPixelColor(dib, x, y, &value);
    }
  }
OUTPUT:
    RETVAL

  #
  # HasBackgroundColor
  #

BOOL
HasBackgroundColor(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_HasBackgroundColor(dib);
OUTPUT:
    RETVAL

  #
  # GetBackgroundColor
  #

void
GetBackgroundColor(dib)
    Win32::GUI::DIBitmap   dib
CODE:
  {
    RGBQUAD value;
    if (FreeImage_GetBackgroundColor(dib, &value))
    {
      if(GIMME == G_ARRAY)
      {
        EXTEND(SP, 4);
        XST_mIV( 0, value.rgbBlue);
        XST_mIV( 1, value.rgbGreen);
        XST_mIV( 2, value.rgbRed);
        XST_mIV( 3, value.rgbReserved);
        XSRETURN(4);
      }
      else
      {
        EXTEND(SP, 1);
        XST_mIV( 0, *((UINT*)&value));
        XSRETURN(1);
      }
    }
    else
      XSRETURN_UNDEF;
  }

  #
  # SetBackgroundColor
  #

BOOL
SetBackgroundColor(dib, ...)
    Win32::GUI::DIBitmap   dib
CODE:
  {
    RGBQUAD value;
    if (items == 2)
    {
      if(SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV)
      {
        SV** sv ;
        AV* av = (AV*) SvRV(ST(1));
        value.rgbBlue     = (BYTE) ((sv = av_fetch(av, 0, 0)) ? SvIV(*sv) : 0);
        value.rgbGreen    = (BYTE) ((sv = av_fetch(av, 1, 0)) ? SvIV(*sv) : 0);
        value.rgbRed      = (BYTE) ((sv = av_fetch(av, 2, 0)) ? SvIV(*sv) : 0);
        value.rgbReserved = (BYTE) ((sv = av_fetch(av, 3, 0)) ? SvIV(*sv) : 0xff);
      }
      else
        *((UINT*)&value) = (BYTE) SvIV(ST(1));
    }
    else
    {
      value.rgbBlue  = (BYTE) SvIV(ST(1));
      value.rgbGreen = (BYTE) SvIV(ST(2));
      value.rgbRed   = (BYTE) SvIV(ST(3));
      value.rgbReserved = (BYTE) (items == 5 ? SvIV(ST(4)) : 0xff);
    }

    RETVAL = FreeImage_SetBackgroundColor(dib, &value);
  }
OUTPUT:
    RETVAL


  #
  # LookupX11Color
  #

void
LookupX11Color(szColor)
    LPCTSTR szColor
CODE:
  {
    RGBQUAD value;
    if (FreeImage_LookupX11Color(szColor, &value.rgbRed, &value.rgbGreen, &value.rgbBlue))
    {
      value.rgbReserved = 0xff;
      if(GIMME == G_ARRAY)
      {
        EXTEND(SP, 4);
        XST_mIV( 0, value.rgbBlue);
        XST_mIV( 1, value.rgbGreen);
        XST_mIV( 2, value.rgbRed);
        XST_mIV( 3, value.rgbReserved);
        XSRETURN(4);
      }
      else
      {
        EXTEND(SP, 1);
        XST_mIV( 0, *((UINT*)&value));
        XSRETURN(1);
      }
    }
    else
      XSRETURN_UNDEF;
  }

  #
  # LookupSVGColor
  #

void
LookupSVGColor(szColor)
    LPCTSTR szColor
CODE:
  {
    RGBQUAD value;
    if (FreeImage_LookupSVGColor(szColor, &value.rgbRed, &value.rgbGreen, &value.rgbBlue))
    {
      value.rgbReserved = 0xff;
      if(GIMME == G_ARRAY)
      {
        EXTEND(SP, 4);
        XST_mIV( 0, value.rgbBlue);
        XST_mIV( 1, value.rgbGreen);
        XST_mIV( 2, value.rgbRed);
        XST_mIV( 3, value.rgbReserved);
        XSRETURN(4);
      }
      else
      {
        EXTEND(SP, 1);
        XST_mIV( 0, *((UINT*)&value));
        XSRETURN(1);
      }
    }
    else
      XSRETURN_UNDEF;
  }

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Device context function
  #

  #
  # CopyToDC
  #

int
CopyToDC(dib, hdc, xd=0, yd=0, w=0, h=0, xs=0, ys=0)
    Win32::GUI::DIBitmap   dib
    HDC                    hdc
    int                    xd
    int                    yd
    UINT                   w
    UINT                   h
    int                    xs
    int                    ys
CODE:
    if (w == 0 || w > FreeImage_GetWidth(dib))  w = FreeImage_GetWidth(dib);
    if (h == 0 || h > FreeImage_GetHeight(dib)) h = FreeImage_GetHeight(dib);

    RETVAL = SetDIBitsToDevice(hdc, xd, yd, w, h, xs, ys,
                               0, FreeImage_GetHeight(dib),
                               FreeImage_GetBits(dib),
                               FreeImage_GetInfo(dib), DIB_RGB_COLORS);
OUTPUT:
    RETVAL


  #
  # AlphaCopyToDC
  #

int
AlphaCopyToDC(dib, hdc, xd=0, yd=0, w=0, h=0, xs=0, ys=0)
    Win32::GUI::DIBitmap   dib
    HDC                    hdc
    int                    xd
    int                    yd
    UINT                   w
    UINT                   h
    int                    xs
    int                    ys
CODE:
  {
    if (w == 0 || w > FreeImage_GetWidth(dib))  w = FreeImage_GetWidth(dib);
    if (h == 0 || h > FreeImage_GetHeight(dib)) h = FreeImage_GetHeight(dib);

    if (FreeImage_IsTransparent(dib) == 0 &&
        FreeImage_GetBPP(dib) != 32)
    {

      RETVAL = SetDIBitsToDevice(hdc, xd, yd, w, h, xs, ys,
                                 0, FreeImage_GetHeight(dib),
                                 FreeImage_GetBits(dib),
                                 FreeImage_GetInfo(dib), DIB_RGB_COLORS);
    }
    else
    {

	  UINT i, j;
      BITMAPINFOHEADER BMI;
      BYTE *           pBits;
      HBITMAP          hbm;
      HDC              dc;
      HBITMAP          dcOld;
      FIBITMAP * ldib = (FIBITMAP *) dib;

      // Convert Transparent value to Alpha chanel
      if (FreeImage_GetBPP(dib) != 32)
      {
         ldib = FreeImage_ConvertTo32Bits(dib);
      }

      // Fill in the header info.
      BMI.biSize = sizeof(BITMAPINFOHEADER);
      BMI.biWidth = w;
      BMI.biHeight = h;
      BMI.biPlanes = 1;
      BMI.biBitCount = 32;
      BMI.biCompression = BI_RGB;   // No compression
      BMI.biSizeImage = 0;
      BMI.biXPelsPerMeter = 0;
      BMI.biYPelsPerMeter = 0;
      BMI.biClrUsed = 0;           // Always use the whole palette.
      BMI.biClrImportant = 0;

      // Create DIB section in shared memory
      hbm  = CreateDIBSection (hdc, (BITMAPINFO *)&BMI,
                               DIB_RGB_COLORS, (void **)&pBits, 0, 0l);

      // Copy background image
      dc    = CreateCompatibleDC(NULL);
      dcOld = (HBITMAP) SelectObject(dc, hbm);

      BitBlt(dc, 0, 0, w, h, hdc, xd, yd, SRCCOPY);

      SelectObject(dc, dcOld);
      DeleteDC(dc);

      // Modify background image

      for (j = 0; j < h; j++)
      {

        BYTE * pSrc  = FreeImage_GetScanLine(ldib, j + ys) + (xs * 4);
        BYTE * pDest = &pBits [j * w * 4];

        for (i = 0; i < w; i++)
        {

           pDest[0] = (pDest[0] * (255-pSrc[3]) + pSrc[0] * pSrc[3])>>8;
           pDest[1] = (pDest[1] * (255-pSrc[3]) + pSrc[1] * pSrc[3])>>8;
           pDest[2] = (pDest[2] * (255-pSrc[3]) + pSrc[2] * pSrc[3])>>8;

           pSrc  += 4;
           pDest += 4;
        }
      }

      // Copy calculate image in DC
      dc    = CreateCompatibleDC(NULL);
      dcOld = (HBITMAP) SelectObject(dc, hbm);

      RETVAL   = BitBlt(hdc, xd, yd, w, h, dc, 0, 0, SRCCOPY);

      SelectObject(dc, dcOld);
      DeleteDC(dc);

      // Free tempory image
      if (ldib != dib) FreeImage_Unload(ldib);
      // Free memory allocated by CreateDIBSection
      DeleteObject(hbm);
    }
  }
OUTPUT:
    RETVAL

  #
  # StretchToDC
  #

int
StretchToDC(dib, hdc, xd=0, yd=0, wd=0, hd=0, xs=0, ys=0, ws=0, hs=0, flag=SRCCOPY)
    Win32::GUI::DIBitmap   dib
    HDC                    hdc
    int                    xd
    int                    yd
    UINT                   wd
    UINT                   hd
    int                    xs
    int                    ys
    UINT                   ws
    UINT                   hs
    int                    flag
CODE:
    if (wd == 0 ) wd = FreeImage_GetWidth(dib);
    if (hd == 0 ) hd = FreeImage_GetHeight(dib);

    if (ws == 0 || ws > FreeImage_GetWidth(dib))  ws = FreeImage_GetWidth(dib);
    if (hs == 0 || hs > FreeImage_GetHeight(dib)) hs = FreeImage_GetHeight(dib);

    RETVAL = StretchDIBits (hdc,
                            xd, yd, wd, hd,
                            xs, ys, ws, hs,
                            FreeImage_GetBits(dib),
                            FreeImage_GetInfo(dib), DIB_RGB_COLORS, flag);
OUTPUT:
    RETVAL


  #
  # AlphaStretchToDC
  #

int
AlphaStretchToDC(dib, hdc, xd=0, yd=0, wd=0, hd=0, xs=0, ys=0, ws=0, hs=0)
    Win32::GUI::DIBitmap   dib
    HDC                    hdc
    int                    xd
    int                    yd
    UINT                   wd
    UINT                   hd
    int                    xs
    int                    ys
    UINT                   ws
    UINT                   hs
CODE:
  {
    if (wd == 0 ) wd = FreeImage_GetWidth(dib);
    if (hd == 0 ) hd = FreeImage_GetHeight(dib);

    if (ws == 0 || ws > FreeImage_GetWidth(dib))  ws = FreeImage_GetWidth(dib);
    if (hs == 0 || hs > FreeImage_GetHeight(dib)) hs = FreeImage_GetHeight(dib);

    if (FreeImage_IsTransparent(dib) == 0 &&
       FreeImage_GetBPP(dib) != 32)
    {

     RETVAL = StretchDIBits (hdc,
                             xd, yd, wd, hd,
                             xs, ys, ws, hs,
                             FreeImage_GetBits(dib),
                             FreeImage_GetInfo(dib), DIB_RGB_COLORS, SRCCOPY);
    }
    else
    {

      BITMAPINFOHEADER BMI;
      BYTE *           pSrcBits;
      HBITMAP          hbmSrc;
      BYTE *           pDestBits;
      HBITMAP          hbmDest;
      HDC              dc;
      HBITMAP          dcOld;
      int              ret;

      FIBITMAP * ldib = (FIBITMAP *) dib;

      // Convert Transparent value to Alpha chanel
      if (FreeImage_GetBPP(dib) != 32)
      {
         ldib = FreeImage_ConvertTo32Bits(dib);
      }

      // Fill in the header info.
      BMI.biSize = sizeof(BITMAPINFOHEADER);
      BMI.biWidth = wd;
      BMI.biHeight = hd;
      BMI.biPlanes = 1;
      BMI.biBitCount = 32;
      BMI.biCompression = BI_RGB;   // No compression
      BMI.biSizeImage = 0;
      BMI.biXPelsPerMeter = 0;
      BMI.biYPelsPerMeter = 0;
      BMI.biClrUsed = 0;           // Always use the whole palette.
      BMI.biClrImportant = 0;

      // Create DIB section in shared memory
      hbmSrc  = CreateDIBSection (hdc, (BITMAPINFO *)&BMI,
                                  DIB_RGB_COLORS, (void **)&pSrcBits, 0, 0l);

      // Create DIB section in shared memory
      hbmDest = CreateDIBSection (hdc, (BITMAPINFO *)&BMI,
                                  DIB_RGB_COLORS, (void **)&pDestBits, 0, 0l);

      // Copy our source and destination bitmaps onto our DIBSections,
      // so we can get access to their bits using the BYTE *'s we
      // passed into CreateDIBSection

      dc = CreateCompatibleDC(NULL);
      dcOld = (HBITMAP) SelectObject(dc, hbmSrc);

      ret = StretchDIBits (dc,
                           0, 0, wd, hd,
                           xs, ys, ws, hs,
                           FreeImage_GetBits(ldib),
                           FreeImage_GetInfo(ldib), DIB_RGB_COLORS, SRCCOPY);

      if (ret != GDI_ERROR)
      {
        SelectObject(dc, hbmDest);
        ret = StretchBlt(dc, 0, 0, wd, hd, hdc, xd, yd, wd, hd, SRCCOPY);

        if (ret != GDI_ERROR)
        {
			UINT j;
          for (j = 0; j < hd; ++j)
          {
			  UINT i;
            LPBYTE pbDestRGB = (LPBYTE)&((DWORD*)pDestBits)[j * wd];
            LPBYTE pbSrcRGB  = (LPBYTE)&((DWORD*)pSrcBits) [j * wd];

            for (i = 0; i < wd; ++i)
            {
              pbDestRGB[0] = (pbDestRGB[0] * (255-pbSrcRGB[3]) + pbSrcRGB[0] * pbSrcRGB[3])>>8;
              pbDestRGB[1] = (pbDestRGB[1] * (255-pbSrcRGB[3]) + pbSrcRGB[1] * pbSrcRGB[3])>>8;
              pbDestRGB[2] = (pbDestRGB[2] * (255-pbSrcRGB[3]) + pbSrcRGB[2] * pbSrcRGB[3])>>8;

              pbSrcRGB  += 4;
              pbDestRGB += 4;
            }
          }

          ret   = BitBlt(hdc, xd, yd, wd, hd, dc, 0, 0, SRCCOPY);
        }
      }

      SelectObject(dc, dcOld);
      DeleteDC(dc);

      DeleteObject(hbmSrc);
      DeleteObject(hbmDest);

      // Free tempory image
      if (ldib != dib) FreeImage_Unload(ldib);

      RETVAL = (ret == GDI_ERROR);
    }
  }
OUTPUT:
    RETVAL


  #
  #
  #
  ##################################################################

  ##################################################################
  #
  #  Conversion function
  #

  #
  # ConvertTo4Bits
  #

Win32::GUI::DIBitmap
ConvertTo4Bits(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_ConvertTo4Bits(dib);
OUTPUT:
    RETVAL

  #
  # ConvertTo8Bits
  #

Win32::GUI::DIBitmap
ConvertTo8Bits(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_ConvertTo8Bits(dib);
OUTPUT:
    RETVAL

  #
  # ConvertTo16Bits555
  #

Win32::GUI::DIBitmap
ConvertTo16Bits555(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_ConvertTo16Bits555(dib);
OUTPUT:
    RETVAL

  #
  # ConvertTo16Bits565
  #

Win32::GUI::DIBitmap
ConvertTo16Bits565(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_ConvertTo16Bits565(dib);
OUTPUT:
    RETVAL

  #
  # ConvertTo24Bits
  #

Win32::GUI::DIBitmap
ConvertTo24Bits(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_ConvertTo24Bits(dib);
OUTPUT:
    RETVAL

  #
  # ConvertTo32Bits
  #

Win32::GUI::DIBitmap
ConvertTo32Bits(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_ConvertTo32Bits(dib);
OUTPUT:
    RETVAL

  #
  # _colorQuantize (internal)
  #

Win32::GUI::DIBitmap
_colorQuantize(dib,flag=FIQ_WUQUANT)
    Win32::GUI::DIBitmap      dib
    FREE_IMAGE_QUANTIZE flag
CODE:
    RETVAL = FreeImage_ColorQuantize(dib, flag);
OUTPUT:
    RETVAL

  #
  #  Threshold
  #

Win32::GUI::DIBitmap
Threshold(dib,T)
    Win32::GUI::DIBitmap dib
    char                 T
CODE:
    RETVAL = FreeImage_Threshold(dib, T);
OUTPUT:
    RETVAL

  #
  #  Dither
  #

Win32::GUI::DIBitmap
Dither(dib,flag=FID_FS)
    Win32::GUI::DIBitmap dib
    FREE_IMAGE_DITHER flag
CODE:
    RETVAL = FreeImage_Dither(dib, flag);
OUTPUT:
    RETVAL

  #
  #  Bitmap convertion (internal)
  #

HBITMAP
_convertToBitmap(dib)
    Win32::GUI::DIBitmap   dib
CODE:
  {
    HDC hdc;

    hdc = GetDC(NULL);

    RETVAL = CreateDIBitmap(hdc, FreeImage_GetInfoHeader(dib),
                            CBM_INIT,
                            FreeImage_GetBits(dib), FreeImage_GetInfo(dib),
                            DIB_RGB_COLORS);

    ReleaseDC(NULL,hdc);
   }
OUTPUT:
    RETVAL

  #
  #  ConvertToStandardType convertion
  #

Win32::GUI::DIBitmap
ConvertToStandardType(dib,scale_linear=TRUE)
    Win32::GUI::DIBitmap dib
    BOOL scale_linear
CODE:
    RETVAL = FreeImage_ConvertToStandardType(dib, scale_linear);
OUTPUT:
    RETVAL

  #
  #  ConvertToType convertion
  #

Win32::GUI::DIBitmap
ConvertToType(dib,dst_type,scale_linear=TRUE)
    Win32::GUI::DIBitmap dib
    FREE_IMAGE_TYPE dst_type
    BOOL scale_linear
CODE:
    RETVAL = FreeImage_ConvertToType(dib, dst_type, scale_linear);
OUTPUT:
    RETVAL

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  # Color manipulation routines
  #

  #
  # AdjustCurve
  #

  #
  # AdjustGamma
  #

BOOL
AdjustGamma(dib,gamma)
    Win32::GUI::DIBitmap   dib
    double                 gamma
CODE:
    RETVAL = FreeImage_AdjustGamma(dib, gamma);
OUTPUT:
    RETVAL

  #
  # AdjustBrightness
  #

BOOL
AdjustBrightness(dib,percentage)
    Win32::GUI::DIBitmap   dib
    double                 percentage
CODE:
    RETVAL = FreeImage_AdjustBrightness(dib, percentage);
OUTPUT:
    RETVAL

  #
  # AdjustContrast
  #

BOOL
AdjustContrast(dib,percentage)
    Win32::GUI::DIBitmap   dib
    double                 percentage
CODE:
    RETVAL = FreeImage_AdjustContrast(dib, percentage);
OUTPUT:
    RETVAL

  #
  # Invert
  #

void
Invert(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    FreeImage_Invert(dib);

  #
  # GetHistogram
  #

void
GetHistogram(dib, channel)
    Win32::GUI::DIBitmap dib
    FREE_IMAGE_COLOR_CHANNEL channel
PREINIT:
  DWORD histo [256];
  int i;
CODE:
  {
    if (FreeImage_GetHistogram (dib, histo, channel) == TRUE)
    {
      EXTEND(SP, 256);
      for (i = 0; i < 256; i++)
        XST_mIV( i, histo[i] );
      XSRETURN(256);
    }
    else
      XSRETURN_UNDEF;
  }

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  # Rotation and flipping function
  #

  #
  # Rotate (>= 8bits)
  #

Win32::GUI::DIBitmap
Rotate(dib, angle)
    Win32::GUI::DIBitmap dib
    double angle
CODE:
    RETVAL = FreeImage_RotateClassic(dib, angle);
OUTPUT:
    RETVAL

  #
  # RotateEx
  #

Win32::GUI::DIBitmap
RotateEx(dib, angle, x_shift, y_shift, x_origin, y_origin, use_mask)
    Win32::GUI::DIBitmap dib
    double angle
    double x_shift
    double y_shift
    double x_origin
    double y_origin
    BOOL   use_mask
CODE:
    RETVAL = FreeImage_RotateEx(dib, angle, x_shift, y_shift, x_origin, y_origin, use_mask);
OUTPUT:
    RETVAL


  #
  # FlipHorizontal
  #

void
FlipHorizontal(dib)
    Win32::GUI::DIBitmap   dib
CODE:
  FreeImage_FlipHorizontal(dib);

  #
  # FlipVertical
  #

void
FlipVertical(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    FreeImage_FlipVertical(dib);

  #
  #
  #
  ##################################################################

  ##################################################################
  #
  # Upsampling / downsampling
  #

  #
  # Rescale
  #

Win32::GUI::DIBitmap
Rescale(dib, width, height, filter=FILTER_BOX)
    Win32::GUI::DIBitmap dib
    int width
    int height
    FREE_IMAGE_FILTER filter
CODE:
    RETVAL = FreeImage_Rescale(dib, width, height, filter);
OUTPUT:
    RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Channel routine
  #

  #
  # GetChannel
  #

Win32::GUI::DIBitmap
GetChannel (dib, channel)
    Win32::GUI::DIBitmap dib
    FREE_IMAGE_COLOR_CHANNEL channel
CODE:
    RETVAL = FreeImage_GetChannel (dib, channel);
OUTPUT:
    RETVAL

  #
  # SetChannel
  #

BOOL
SetChannel (dib, channel, dib8)
    Win32::GUI::DIBitmap dib
    FREE_IMAGE_COLOR_CHANNEL channel
    Win32::GUI::DIBitmap dib8
CODE:
    RETVAL = FreeImage_SetChannel (dib, dib8, channel);
OUTPUT:
    RETVAL

  #
  # GetComplexChannel
  #

Win32::GUI::DIBitmap
GetComplexChannel (dib, channel)
    Win32::GUI::DIBitmap dib
    FREE_IMAGE_COLOR_CHANNEL channel
CODE:
    RETVAL = FreeImage_GetComplexChannel (dib, channel);
OUTPUT:
    RETVAL

  #
  # SetComplexChannel
  #

BOOL
SetComplexChannel (dib, channel, dibcomplex)
    Win32::GUI::DIBitmap dib
    FREE_IMAGE_COLOR_CHANNEL channel
    Win32::GUI::DIBitmap dibcomplex
CODE:
    RETVAL = FreeImage_SetComplexChannel (dib, dibcomplex, channel);
OUTPUT:
    RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Copy/Paste routine
  #

  #
  # Copy
  #

Win32::GUI::DIBitmap
Copy(dib, left, top, right, bottom)
    Win32::GUI::DIBitmap   dib
    int left
    int top
    int right
    int bottom
CODE:
    RETVAL = FreeImage_Copy(dib, left, top, right, bottom);
OUTPUT:
    RETVAL

  #
  # Paste
  #

BOOL
Paste(dest, src, left, top, alpha)
    Win32::GUI::DIBitmap   dest
    Win32::GUI::DIBitmap   src
    int left
    int top
    int alpha
CODE:
    RETVAL = FreeImage_Paste(dest, src, left, top, alpha);
OUTPUT:
    RETVAL

  #
  # Composite
  #

Win32::GUI::DIBitmap
Composite(dib, useFileBkg=FALSE, dibBkg=NULL, ...)
    Win32::GUI::DIBitmap   dib
    BOOL  useFileBkg
    Win32::GUI::DIBitmap   dibBkg
CODE:
  {
    RGBQUAD *pColor = NULL;
    RGBQUAD Color;
    if (items == 4)
    {
      if(SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVAV)
      {
        SV** sv ;
        AV* av = (AV*) SvRV(ST(3));
        Color.rgbBlue     = (BYTE) ((sv = av_fetch(av, 0, 0)) ? SvIV(*sv) : 0);
        Color.rgbGreen    = (BYTE) ((sv = av_fetch(av, 1, 0)) ? SvIV(*sv) : 0);
        Color.rgbRed      = (BYTE) ((sv = av_fetch(av, 2, 0)) ? SvIV(*sv) : 0);
        Color.rgbReserved = (BYTE) ((sv = av_fetch(av, 3, 0)) ? SvIV(*sv) : 0xff);
      }
      else
        *((UINT*)&Color) = (BYTE) SvIV(ST(3));
      pColor = &Color;
    }
    else if (items == 6 || items == 7)
    {
      Color.rgbBlue  = (BYTE) SvIV(ST(3));
      Color.rgbGreen = (BYTE) SvIV(ST(4));
      Color.rgbRed   = (BYTE) SvIV(ST(5));
      Color.rgbReserved = (BYTE) (items == 7 ? SvIV(ST(6)) : 0xff);
      pColor = &Color;
    }

    RETVAL = FreeImage_Composite(dib, useFileBkg, pColor, dibBkg);
  }
OUTPUT:
    RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Clone routine
  #

  #
  # Clone
  #

Win32::GUI::DIBitmap
Clone(dib)
    Win32::GUI::DIBitmap   dib
CODE:
    RETVAL = FreeImage_Clone(dib);
OUTPUT:
    RETVAL

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Free routine
  #

  #
  # DESTROY
  #

void
DESTROY(dib)
   Win32::GUI::DIBitmap   dib
CODE:
  FreeImage_Unload(dib);

  #
  #
  ##################################################################


#**********************************************************************
#**********************************************************************
#**********************************************************************

MODULE = Win32::GUI::DIBitmap     PACKAGE = Win32::GUI::DIBitmap::Ext

  ##################################################################
  #
  #  Special DIBbitmap for MDIBitmap.
  #  Free routine do nothing because it's managed by the multi-paging
  #  engine
  #

  #
  # DESTROY
  #

void
DESTROY(dib)
   Win32::GUI::DIBitmap::Ext   dib
CODE:
   {
    // printf ("Win32::GUI::DIBitmap::Ext destroy\n");
   }

  #
  #
  ##################################################################


#**********************************************************************
#**********************************************************************
#**********************************************************************

MODULE = Win32::GUI::DIBitmap     PACKAGE = Win32::GUI::MDIBitmap

  ##################################################################
  #                                                                #
  #              Win32::GUI::MDIBitmap  package                    #
  #                                                                #
  ##################################################################

  ##################################################################
  #
  #  Win32::GUI::MDIBitmap new routine
  #

  #
  # _newFromFile (internal)
  #

Win32::GUI::MDIBitmap
_newFromFile (packname="Win32::GUI::MDIBitmap",fif,filename,create_new=0,read_only=1,keep_cache_in_memory=0)
    char * packname
    FREE_IMAGE_FORMAT      fif
    LPCTSTR  filename
    int      create_new
    int      read_only
    int      keep_cache_in_memory
CODE:
    RETVAL = FreeImage_OpenMultiBitmap (fif,filename,
                                        create_new,
                                        read_only,
                                        keep_cache_in_memory);
OUTPUT:
    RETVAL

  #
  # _newFromData (internal)
  #


  #
  #
  ##################################################################

  ##################################################################
  #
  #  Win32::GUI::MDIBitmap Get routine
  #

  #
  # GetPageCount
  #

UINT
GetPageCount(mdib)
    Win32::GUI::MDIBitmap   mdib
CODE:
    RETVAL = FreeImage_GetPageCount(mdib);
OUTPUT:
    RETVAL

  #
  # GetLockedPageNumbers
  #

void
GetLockedPageNumbers(mdib)
    Win32::GUI::MDIBitmap   mdib
CODE:
  {
    int i, count = 0;
    int *pages;

    FreeImage_GetLockedPageNumbers(mdib, NULL, &count);

    if (count != 0)
    {
      pages = (int *) safemalloc (sizeof(int) * count);

      FreeImage_GetLockedPageNumbers(mdib, pages, &count);

      EXTEND(SP, count);
      for (i = 0; i < count; i++)
        XST_mIV( i, pages[i] );
      XSRETURN(count);

      safefree (pages);
    }
    else
      XSRETURN_UNDEF;
  }

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Win32::GUI::MDIBitmap Edit routine
  #

  #
  # AppendPage
  #

void
AppendPage(mdib,dib)
    Win32::GUI::MDIBitmap   mdib
    Win32::GUI::DIBitmap    dib
CODE:
    FreeImage_AppendPage (mdib,dib);

  #
  # InsertPage
  #

void
InsertPage(mdib,dib,page=0)
    Win32::GUI::MDIBitmap   mdib
    Win32::GUI::DIBitmap    dib
    int page
CODE:
    FreeImage_InsertPage (mdib,page,dib);

  #
  # DeletePage
  #

void
DeletePage(mdib,page=0)
    Win32::GUI::MDIBitmap   mdib
    int page
CODE:
    FreeImage_DeletePage (mdib,page);

  #
  # MovePage
  #

BOOL
MovePage(mdib,topage,frompage=0)
    Win32::GUI::MDIBitmap   mdib
    int topage
    int frompage
CODE:
    RETVAL = FreeImage_MovePage (mdib,topage,frompage);
OUTPUT:
    RETVAL


  #
  #
  ##################################################################

  ##################################################################
  #
  #  Win32::GUI::MDIBitmap Access Routine
  #

  #
  # LockPage
  #

Win32::GUI::DIBitmap::Ext
LockPage(mdib,page=0)
    Win32::GUI::MDIBitmap   mdib
    int page
CODE:
    RETVAL = FreeImage_LockPage (mdib,page);
OUTPUT:
    RETVAL

  #
  # UnlockPage
  #

void
UnlockPage(mdib,dib,changed=0)
    Win32::GUI::MDIBitmap     mdib
    Win32::GUI::DIBitmap::Ext dib
    int changed
CODE:
    FreeImage_UnlockPage (mdib,dib,changed);

  #
  #
  ##################################################################

  ##################################################################
  #
  #  Free routine
  #

  #
  # DESTROY
  #

void
DESTROY(mdib)
   Win32::GUI::MDIBitmap   mdib
CODE:
   FreeImage_CloseMultiBitmap(mdib, 0);

  #
  #
  ##################################################################

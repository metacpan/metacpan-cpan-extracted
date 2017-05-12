/*
 * imgTIFF.c --
 *
 * A photo image file handler for TIFF files.
 *
 * Uses the libtiff.so library, which is dynamically
 * loaded only when used.
 *
 */

/* Author : Jan Nijtmans */
/* Date   : 7/16/97      */
/* Changed for perl/Tk by Slaven Rezic (based on the img1.2b2 code) */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#if defined(__STDC__) || defined(HAS_STDARG)
#include <stdarg.h>
#else
#include <varargs.h>
#endif

#include "pTk/tk.h"
#include "pTk/imgInt.h"
#include "pTk/tkVMacro.h"
#include <float.h>

extern int unlink _ANSI_ARGS_((CONST char *));

#ifdef __WIN32__
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#define WIN32_LEAN_AND_MEAN
#endif

#ifdef MAC_TCL
#include "libtiff:tiffio.h"
#else
#ifdef HAVE_TIFF_H
#   include <tiffio.h>
#else
#   include "libtiff/tiffio.h"
#endif
#endif

#ifdef __WIN32__
#define TIFF_LIB_NAME "tiff.dll"
#endif

#ifndef TIFF_LIB_NAME
#define TIFF_LIB_NAME "libtiff.so"
#endif

/*
 * Prototypes for local procedures defined in this file:
 */

/*
 * Flag for Float TIFF files.  Do we simply scale to byte,
 *   or do we also equalize its histogram?
 */
int contrast_enhance = 0;


/*
  The extra Tcl_Interp * arg was added in different
  place when tcl/tk adopted this code so we need two
  signatures of a couple of functions - one for Tk800 and
  one for modern Tk
*/
#if TK_MAJOR_VERSION == 8 && TK_MINOR_VERSION == 0
static int ChnMatchTIFF _ANSI_ARGS_((Tcl_Interp *interp, Tcl_Channel chan, char *fileName,
	Tcl_Obj *format, int *widthPtr, int *heightPtr));
static int ObjMatchTIFF _ANSI_ARGS_((Tcl_Interp *interp, Tcl_Obj *dataObj,
	Tcl_Obj *format, int *widthPtr, int *heightPtr));
#else
static int ChnMatchTIFF _ANSI_ARGS_((Tcl_Channel chan, char *fileName,
	Tcl_Obj *format, int *widthPtr, int *heightPtr, Tcl_Interp *interp));
static int ObjMatchTIFF _ANSI_ARGS_((Tcl_Obj *dataObj,
	Tcl_Obj *format, int *widthPtr, int *heightPtr, Tcl_Interp *interp));
#endif

static int ChnReadTIFF _ANSI_ARGS_((Tcl_Interp *interp, Tcl_Channel chan,
	char *fileName, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
	int destX, int destY, int width, int height, int srcX, int srcY));
static int ObjReadTIFF _ANSI_ARGS_((Tcl_Interp *interp,
	Tcl_Obj *dataObj, Tcl_Obj *format,
	Tk_PhotoHandle imageHandle, int destX, int destY,
	int width, int height, int srcX, int srcY));
static int ChnWriteTIFF _ANSI_ARGS_((Tcl_Interp *interp, char *filename,
	Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr));
static int StringWriteTIFF _ANSI_ARGS_((Tcl_Interp *interp,
	Tcl_DString *dataPtr, Tcl_Obj *format,
	Tk_PhotoImageBlock *blockPtr));

Tk_PhotoImageFormat imgFmtTIFF = {
    "TIFF",					/* name */
    (Tk_ImageFileMatchProc *) ChnMatchTIFF,	/* fileMatchProc */
    (Tk_ImageStringMatchProc *) ObjMatchTIFF,	/* stringMatchProc */
    (Tk_ImageFileReadProc *) ChnReadTIFF,	/* fileReadProc */
    (Tk_ImageStringReadProc *) ObjReadTIFF,	/* stringReadProc */
    (Tk_ImageFileWriteProc *) ChnWriteTIFF,	/* fileWriteProc */
    (Tk_ImageStringWriteProc *) StringWriteTIFF,/* stringWriteProc */
};

#if defined(__STDC__) || defined(HAS_STDARG)
#   define TCL_VARARGS2(type, name) type name, ...
#else
#   ifdef __cplusplus
#	define TCL_VARARGS2(type, name) type name, ...
#   else
#	define TCL_VARARGS(type, name) 
#   endif
#endif

static struct TiffFunctions {
    VOID *handle;
    void (* Close) _ANSI_ARGS_((TIFF *));
    int (* GetField) _ANSI_ARGS_((TIFF *, TCL_VARARGS2(ttag_t, tag)));
    int (* GetFieldDefaulted) _ANSI_ARGS_((TIFF *, TCL_VARARGS2(ttag_t, tag)));
    TIFF* (* Open) _ANSI_ARGS_((CONST char*, CONST char*));
    tsize_t (* ReadEncodedStrip) _ANSI_ARGS_((TIFF*, tstrip_t, tdata_t, tsize_t));
    int (* ReadRGBAImage) _ANSI_ARGS_((TIFF *, uint32, uint32, uint32*, int));
    tsize_t (* ReadTile) _ANSI_ARGS_((TIFF *, tdata_t, uint32, uint32, uint32, tsample_t));
    int (* SetField) _ANSI_ARGS_((TIFF *, TCL_VARARGS2(ttag_t, tag)));
    tsize_t (* TileSize) _ANSI_ARGS_((TIFF*));
    tsize_t (* WriteEncodedStrip) _ANSI_ARGS_((TIFF*, tstrip_t, tdata_t, tsize_t));
    void (* free) _ANSI_ARGS_((tdata_t));
    tdata_t (* malloc) _ANSI_ARGS_((tsize_t));
    void (* memcpy) _ANSI_ARGS_((tdata_t, CONST tdata_t, tsize_t));
    tdata_t (* realloc) _ANSI_ARGS_((tdata_t, tsize_t));
    TIFFErrorHandler (* SetErrorHandler) _ANSI_ARGS_((TIFFErrorHandler));
    TIFFErrorHandler (* SetWarningHandler) _ANSI_ARGS_((TIFFErrorHandler));
    TIFF* (* ClientOpen) _ANSI_ARGS_((CONST char*, CONST char*, VOID *,
	    TIFFReadWriteProc, TIFFReadWriteProc, TIFFSeekProc,
	    TIFFCloseProc, TIFFSizeProc, TIFFMapFileProc, TIFFUnmapFileProc));
    TIFFCodec* (*RegisterCODEC) _ANSI_ARGS_((uint16, CONST char*, TIFFInitMethod));
    void (* Error) _ANSI_ARGS_((CONST char *, TCL_VARARGS2(CONST char *, arg1)));
    int (* PredictorInit) _ANSI_ARGS_((TIFF *));
    void (* MergeFieldInfo) _ANSI_ARGS_((TIFF *, CONST VOID *, int));
    int (* FlushData1) _ANSI_ARGS_((TIFF *));
    void (* NoPostDecode) _ANSI_ARGS_((TIFF *, VOID*, tsize_t));
    tsize_t (* TileRowSize) _ANSI_ARGS_((TIFF *));
    tsize_t (* ScanlineSize) _ANSI_ARGS_((TIFF *));
    int (* ReadScanline) _ANSI_ARGS_ ((TIFF *, tdata_t, uint32, tsample_t));
    void (* setByteArray) _ANSI_ARGS_((VOID **, VOID*, long));
    int (* VSetField) _ANSI_ARGS_((TIFF *, ttag_t, va_list));
    void (* SwabArrayOfShort) _ANSI_ARGS_((uint16*, unsigned long));
} tiff = {
  0,
  TIFFClose,
  TIFFGetField,
  TIFFGetFieldDefaulted,
  TIFFOpen,
  TIFFReadEncodedStrip,
  TIFFReadRGBAImage,
  TIFFReadTile,
  TIFFSetField,
  TIFFTileSize,
  TIFFWriteEncodedStrip,
  /* The following symbols are not crucial. If they cannot be
     found, just don't use them. The ClientOpen function is
     more difficult to emulate, but even that is possible. */
  _TIFFfree,
  _TIFFmalloc,
  _TIFFmemcpy,
  _TIFFrealloc,
  TIFFSetErrorHandler,
  TIFFSetWarningHandler,
  TIFFClientOpen,
  TIFFRegisterCODEC,
  TIFFError,
  /* TIFFPredictorInit, */ 0,
  /* _TIFFMergeFieldInfo, */ 0,
  /* TIFFFlushData1, */ 0,
  /* _TIFFNoPostDecode, */ 0,
  TIFFTileRowSize,
  TIFFScanlineSize,
  TIFFReadScanline,
  /* _TIFFsetByteArray, */ 0,
  TIFFVSetField,
  TIFFSwabArrayOfShort
  /* (char *) NULL */
};

/*
 * Prototypes for local procedures defined in this file:
 */

static int getint _ANSI_ARGS_((unsigned char *buf, TIFFDataType format,
	int order));
static int CommonMatchTIFF _ANSI_ARGS_((MFile *handle, int *widhtPtr,
	int *heightPtr));
static int CommonReadTIFF _ANSI_ARGS_((Tcl_Interp *interp, TIFF *tif,
	Tcl_Obj *format, Tk_PhotoHandle imageHandle, int destX, int destY,
	int width, int height, int srcX, int srcY));
static int CommonWriteTIFF _ANSI_ARGS_((Tcl_Interp *interp, TIFF *tif,
	int comp, Tk_PhotoImageBlock *blockPtr));
static int ParseWriteFormat _ANSI_ARGS_((Tcl_Interp *interp, Tcl_Obj *format,
	int *comp, char **mode));
static int load_tiff_library _ANSI_ARGS_((Tcl_Interp *interp));
static void  _TIFFerr    _ANSI_ARGS_((CONST char *, CONST char *, va_list));
static void  _TIFFwarn   _ANSI_ARGS_((CONST char *, CONST char *, va_list));
void ImgTIFFfree _ANSI_ARGS_((tdata_t data));
tdata_t ImgTIFFmalloc _ANSI_ARGS_((tsize_t size));
tdata_t ImgTIFFrealloc _ANSI_ARGS_((tdata_t data, tsize_t size));
void ImgTIFFmemcpy _ANSI_ARGS_((tdata_t, CONST tdata_t, tsize_t));
void ImgTIFFError _ANSI_ARGS_(TCL_VARARGS(CONST char *, module));
int ImgTIFFPredictorInit _ANSI_ARGS_((TIFF *tif));
void ImgTIFFMergeFieldInfo _ANSI_ARGS_((TIFF* tif, CONST VOID *voidp, int i));
int ImgTIFFFlushData1 _ANSI_ARGS_((TIFF *tif));
void ImgTIFFNoPostDecode _ANSI_ARGS_((TIFF *, VOID *, tsize_t));
tsize_t ImgTIFFTileRowSize _ANSI_ARGS_((TIFF *));
tsize_t ImgTIFFScanlineSize _ANSI_ARGS_((TIFF *));
int ImgTIFFReadScanline _ANSI_ARGS_ ((TIFF *, tdata_t, uint32, uint32));
void ImgTIFFsetByteArray _ANSI_ARGS_((VOID **, VOID*, long));
int ImgTIFFSetField _ANSI_ARGS_(TCL_VARARGS(TIFF *, tif));
tsize_t ImgTIFFTileSize _ANSI_ARGS_((TIFF*));
void ImgTIFFSwabArrayOfShort _ANSI_ARGS_((uint16*, unsigned long));

/*
 * External hooks to functions, so they can be called from
 * imgTIFFzip.c and imgTIFFjpeg.c as well.
 */

void ImgTIFFfree (data)
    tdata_t data;
{
    if (tiff.free) {
	tiff.free(data);
    } else {
	ckfree((char *) data);
    }
}

tdata_t ImgTIFFmalloc(size)
    tsize_t size;
{
    if (tiff.malloc) {
	return tiff.malloc(size);
    } else {
	return ckalloc(size);
    }
}

tdata_t ImgTIFFrealloc(data, size)
    tdata_t data;
    tsize_t size;
{
    if (tiff.realloc) {
	return tiff.realloc(data, size);
    } else {
	return ckrealloc(data, size);
    }
}

void
ImgTIFFmemcpy(a,b,c)
     tdata_t a;
     CONST tdata_t b;
     tsize_t c;
{
    (tiff.memcpy)(a, b, c);
}

void
ImgTIFFError TCL_VARARGS_DEF(CONST char *, arg1)
{
    va_list ap;
    CONST char* module;
    CONST char* fmt;

    module = (CONST char*) TCL_VARARGS_START(CONST char *, arg1, ap);
    fmt =  va_arg(ap, CONST char *);
    _TIFFerr(module, fmt, ap);
    va_end(ap);
}

int
ImgTIFFPredictorInit(tif)
    TIFF *tif;
{
    return tiff.PredictorInit(tif);
}

void
ImgTIFFMergeFieldInfo(tif, voidp, i)
    TIFF* tif;
    CONST VOID *voidp;
    int i;
{
    tiff.MergeFieldInfo(tif, voidp, i);
}

int
ImgTIFFFlushData1(tif)
    TIFF *tif;
{
    return tiff.FlushData1(tif);
}

void
ImgTIFFNoPostDecode(tif,a,b)
    TIFF * tif;
    VOID *a;
    tsize_t b;
{
    tiff.NoPostDecode(tif, a, b);
}

tsize_t
ImgTIFFTileRowSize(tif)
    TIFF * tif;
{
    return tiff.TileRowSize(tif);
}

tsize_t
ImgTIFFScanlineSize(tif)
    TIFF *tif;
{
    return tiff.ScanlineSize(tif);
}

int 
ImgTIFFReadScanline (tif, scanline, row, sample)
    TIFF *tif;
    tdata_t scanline;
    uint32 row;
    uint32 sample;
{
    return tiff.ReadScanline(tif, scanline, row, sample);
}

void
ImgTIFFsetByteArray(a,b,c)
    VOID **a;
    VOID *b;
    long c;
{
    tiff.setByteArray(a,b,c);
}

int
ImgTIFFSetField TCL_VARARGS_DEF(TIFF*, arg1)
{
    va_list ap;
    TIFF* tif;
    ttag_t tag;
    int result;

    tif = (TIFF*) TCL_VARARGS_START(TIFF*, arg1, ap);
    tag =  va_arg(ap, ttag_t);
    result = tiff.VSetField(tif, tag, ap);
    va_end(ap);
    return result;
}

tsize_t
ImgTIFFTileSize(tif)
    TIFF* tif;
{
    return tiff.TileSize(tif);
}

void
ImgTIFFSwabArrayOfShort(p, l)
    uint16* p;
    unsigned long l;
{
    tiff.SwabArrayOfShort(p,l);
    return;
}

/*
 * The functions for the TIFF input handler
 */

static int mapDummy _ANSI_ARGS_((thandle_t, tdata_t *, toff_t *));
static void unMapDummy _ANSI_ARGS_((thandle_t, tdata_t, toff_t));
static int closeDummy _ANSI_ARGS_((thandle_t));
static tsize_t writeDummy _ANSI_ARGS_((thandle_t, tdata_t, tsize_t));

static tsize_t readMFile _ANSI_ARGS_((thandle_t, tdata_t, tsize_t));
static toff_t seekMFile _ANSI_ARGS_((thandle_t, toff_t, int));
static toff_t  sizeMFile _ANSI_ARGS_((thandle_t));

static tsize_t readString _ANSI_ARGS_((thandle_t, tdata_t, tsize_t));
static tsize_t writeString _ANSI_ARGS_((thandle_t, tdata_t, tsize_t));
static toff_t seekString _ANSI_ARGS_((thandle_t, toff_t, int));
static toff_t  sizeString _ANSI_ARGS_((thandle_t));

static char *errorMessage = NULL;

static int getint(buf, format, order)
    unsigned char *buf;
    TIFFDataType format;
    int order;
{
    int result;

    switch (format) {
	case TIFF_BYTE:
	    result = buf[0]; break;
	case TIFF_SHORT:
	    result = (buf[order]<<8) + buf[1-order]; break;
	case TIFF_LONG:
	    if (order) {
		result = (buf[3]<<24) + (buf[2]<<16) + (buf[1]<<8) + buf[0];
	    } else {
		result = (buf[0]<<24) + (buf[1]<<16) + (buf[2]<<8) + buf[3];
	    }; break;
	default:
	    result = -1;
    }
    return result;
}

static int
load_tiff_library(interp)
    Tcl_Interp *interp;
{
    static int initialized = 0;
    if (errorMessage) {
	ckfree(errorMessage);
	errorMessage = NULL;
    }
#ifndef _LANG
    if (ImgLoadLib(interp, TIFF_LIB_NAME, &tiff.handle, symbols, 10)
	    != TCL_OK) {
	return TCL_ERROR;
    }
#endif
    if (tiff.SetErrorHandler != NULL) {
	tiff.SetErrorHandler(_TIFFerr);
    }
    if (tiff.SetWarningHandler != NULL) {
	tiff.SetWarningHandler(_TIFFwarn);
    }
    if (!initialized) {
	initialized = 1;
	if (tiff.RegisterCODEC && tiff.Error && tiff.PredictorInit &&
		tiff.MergeFieldInfo && tiff.FlushData1 && tiff.NoPostDecode &&
		tiff.TileRowSize && tiff.ScanlineSize && tiff.setByteArray &&
		tiff.VSetField && tiff.SwabArrayOfShort) {
#ifndef _LANG
	    tiff.RegisterCODEC(COMPRESSION_DEFLATE, "Deflate", ImgInitTIFFzip);
	    tiff.RegisterCODEC(COMPRESSION_JPEG, "JPEG", ImgInitTIFFjpeg);
	    tiff.RegisterCODEC(COMPRESSION_PIXARLOG, "PixarLog", ImgInitTIFFpixar);
#endif
	}
    }
    return TCL_OK;
}

static void _TIFFerr(module, fmt, ap)
     CONST char *module;
     CONST char *fmt;
     va_list     ap;
{
  char buf[2048];
  char *cp = buf;

  if (module != NULL) {
    sprintf(cp, "%s: ", module);
    cp += strlen(module) + 2;
  }

  vsprintf(cp, fmt, ap);
  if (errorMessage) {
    ckfree(errorMessage);
  }
  errorMessage = (char *) ckalloc(strlen(buf)+1);
  strcpy(errorMessage, buf);
}

/* warnings are not processed in Tcl */
static void _TIFFwarn(module, fmt, ap)
     CONST char *module;
     CONST char *fmt;
     va_list     ap;
{
}

static int
mapDummy(fd, base, size)
    thandle_t fd;
    tdata_t *base;
    toff_t *size;
{
    return (toff_t) 0;
}

static void
unMapDummy(fd, base, size)
    thandle_t fd;
    tdata_t base;
    toff_t size;
{
}

static int
closeDummy(fd)
    thandle_t fd;
{
    return 0;
}

static tsize_t
writeDummy(fd, data, size)
    thandle_t fd;
    tdata_t data;
    tsize_t size;
{
   return size;
}

static tsize_t
readMFile(fd, data, size)
    thandle_t fd;
    tdata_t data;
    tsize_t size;
{
    return (tsize_t) ImgRead((MFile *) fd, (char *) data, (int) size) ;
}

static toff_t
seekMFile(fd, off, whence)
    thandle_t fd;
    toff_t off;
    int whence;
{
#ifdef USE_IMGSEEK
    return (tsize_t) ImgSeek((MFile *) fd, (int) off, whence);
#else
    return Tcl_Seek((Tcl_Channel) ((MFile *) fd)->data, (int) off, whence);
#endif
}

static toff_t
sizeMFile(fd)
    thandle_t fd;
{
    int fsize;
#ifdef USE_IMGSEEK
    return (fsize = ImgSeek((MFile *) fd, 0, SEEK_END)) < 0 ? 0 : (toff_t) fsize;
#else
    return (fsize = Tcl_Seek((Tcl_Channel) ((MFile *) fd)->data,
            (int) 0, SEEK_END)) < 0 ? 0 : (toff_t) fsize;
#endif
}

/*
 * In the following functions "handle" is used differently for speed reasons:
 *
 *	handle.buffer   (writing only) dstring used for writing.
 *	handle.data	pointer to first character
 *	handle.lenght	size of data
 *	handle.state	"file" position pointer.
 *
 * After a read, only the position pointer is adapted, not the other fields.
 */

static tsize_t
readString(fd, data, size)
    thandle_t fd;
    tdata_t data;
    tsize_t size;
{
    register MFile *handle = (MFile *) fd;

    if ((size + handle->state) > handle->length) {
	size = handle->length - handle->state;
    }
    if (size) {
	memcpy((char *) data, handle->data + handle->state, (size_t) size);
	handle->state += size;
    }
    return size;
}

static tsize_t
writeString(fd, data, size)
    thandle_t fd;
    tdata_t data;
    tsize_t size;
{
    register MFile *handle = (MFile *) fd;

    if (handle->state + size > handle->length) {
	handle->length = handle->state + size;
	Tcl_DStringSetLength(handle->buffer, handle->length);
	handle->data = Tcl_DStringValue(handle->buffer);
    }
    memcpy(handle->data + handle->state, (char *) data, (size_t) size);
    handle->state += size;
    return size;
}

static toff_t
seekString(fd, off, whence)
    thandle_t fd;
    toff_t off;
    int whence;
{
    register MFile *handle = (MFile *) fd;

    switch (whence) {
	case SEEK_SET:
	    handle->state = (int) off;
	    break;
	case SEEK_CUR:
	    handle->state += (int) off;
	    break;
	case SEEK_END:
	    handle->state = handle->length + (int) off;
	    break;
    }
    if (handle->state < 0) {
	handle->state = 0;
	return -1;
    }
    return (toff_t) handle->state;
}

static toff_t
sizeString(fd)
    thandle_t fd;
{
    return ((MFile *) fd)->length;
}


/*
 *----------------------------------------------------------------------
 *
 * ObjMatchTIFF --
 *
 *  This procedure is invoked by the photo image type to see if
 *  a string contains image data in TIFF format.
 *
 * Results:
 *  The return value is 1 if the first characters in the string
 *  is like TIFF data, and 0 otherwise.
 *
 * Side effects:
 *  the size of the image is placed in widthPre and heightPtr.
 *
 *----------------------------------------------------------------------
 */

#if TK_MAJOR_VERSION == 8 && TK_MINOR_VERSION == 0
static int ObjMatchTIFF(interp, data, format, widthPtr, heightPtr)
#else
static int ObjMatchTIFF(data, format, widthPtr, heightPtr, interp)
#endif
    Tcl_Interp *interp;
    Tcl_Obj *data;		/* the object containing the image data */
    Tcl_Obj *format;		/* the image format string */
    int *widthPtr;		/* where to put the string width */
    int *heightPtr;		/* where to put the string height */
{
    MFile handle;

    if (!ImgReadInit(data, '\111', &handle) &&
	    !ImgReadInit(data, '\115', &handle)) {
	return 0;
    }
    return CommonMatchTIFF(&handle, widthPtr, heightPtr);
}

#if TK_MAJOR_VERSION == 8 && TK_MINOR_VERSION == 0
static int ChnMatchTIFF(interp, chan, fileName, format, widthPtr, heightPtr)
#else
static int ChnMatchTIFF(chan, fileName, format, widthPtr, heightPtr, interp)
#endif
    Tcl_Interp *interp;
    Tcl_Channel chan;
    char *fileName;
    Tcl_Obj *format;
    int *widthPtr, *heightPtr;
{
    MFile handle;

    handle.data = (char *) chan;
    handle.state = IMG_CHAN;

    return CommonMatchTIFF(&handle, widthPtr, heightPtr);
}

static int CommonMatchTIFF(handle, widthPtr, heightPtr)
    MFile *handle;
    int *widthPtr, *heightPtr;
{
    unsigned char buf[4096];
    int i, j, order, w = 0, h = 0;

    i = ImgRead(handle, (char *) buf, 8);
    order = (buf[0] == '\111');
    if ((i != 8) || (buf[0] != buf[1])
	    || ((buf[0] != '\111') && (buf[0] != '\115'))
	    || (getint(buf+2,TIFF_SHORT,order) != 42)) {
	return 0;
    }
    i = getint(buf+4,TIFF_LONG,order);

    while (i > 4104) {
	i -= 4096;
	ImgRead(handle, (char *) buf, 4096);
    }
    if (i>8) {
        ImgRead(handle, (char *) buf, i-8);
    }
    ImgRead(handle, (char *) buf, 2);
    i = getint(buf,TIFF_SHORT,order);
    while (i--) {
	ImgRead(handle, (char *) buf, 12);
	if (buf[order]!=1) continue;
	j = getint(buf+2,TIFF_SHORT,order);
	j = getint(buf+8, (TIFFDataType) j, order);
	if (buf[1-order]==0) {
	    w = j;
	    if (h>0) break;
	} else if (buf[1-order]==1) {
	    h = j;
	    if (w>0) break;
	}
    }

    if ((w <= 0) || (h <= 0)) {
	return 0;
    }
    *widthPtr = w;
    *heightPtr = h;
    return 1;
}

static int ObjReadTIFF(interp, data, format, imageHandle,
	destX, destY, width, height, srcX, srcY)
    Tcl_Interp *interp;
    Tcl_Obj *data;			/* object containing the image */
    Tcl_Obj *format;
    Tk_PhotoHandle imageHandle;
    int destX, destY;
    int width, height;
    int srcX, srcY;
{
    TIFF *tif;
    char tempFileName[256];
    int count, result;
    MFile handle;
    char buffer[1024];
    char *dataPtr = NULL;

    if (load_tiff_library(interp) != TCL_OK) {
	return TCL_ERROR;
    }

    if (!ImgReadInit(data, '\115', &handle)) {
	    ImgReadInit(data, '\111', &handle);
    }

    if (tiff.ClientOpen) {
	tempFileName[0] = 0;
	if (handle.state != IMG_STRING) {
	    dataPtr = ckalloc((handle.length*3)/4 + 2);
	    handle.length = ImgRead(&handle, dataPtr, handle.length);
	    handle.data = dataPtr;
	}
	handle.state = 0;
	tif = tiff.ClientOpen("inline data", "r", (thandle_t) &handle,
		readString, writeString, seekString, closeDummy,
		sizeString, mapDummy, unMapDummy);
    } else {
	Tcl_Channel outchan;
	tmpnam(tempFileName);
	outchan = Tcl_OpenFileChannel(interp, tempFileName, "w", 0644);
	if (!outchan) {
	    return TCL_ERROR;
	}
	if (Tcl_SetChannelOption(interp, outchan, "-translation", "binary") != TCL_OK) {
	    return TCL_ERROR;
	}

	count = ImgRead(&handle, buffer, 1024);
	while (count == 1024) {
	    Tcl_Write(outchan, buffer, count);
	    count = ImgRead(&handle, buffer, 1024);
	}
	if (count>0){
	    Tcl_Write(outchan, buffer, count);
	}
	if (Tcl_Close(interp, outchan) == TCL_ERROR) {
	    return TCL_ERROR;
	}
	tif = tiff.Open(tempFileName, "r");
    }

    if (tif != NULL) {
	result = CommonReadTIFF(interp, tif, format, imageHandle,
		destX, destY, width, height, srcX, srcY);
    } else {
	result = TCL_ERROR;
    }
    if (tempFileName[0]) {
	unlink(tempFileName);
    }
    if (result == TCL_ERROR) {
	Tcl_AppendResult(interp, errorMessage, (char *) NULL);
	ckfree(errorMessage);
	errorMessage = NULL;
    }
    if (dataPtr) {
	ckfree(dataPtr);
    }
    return result;
}

static int ChnReadTIFF(interp, chan, fileName, format, imageHandle,
	destX, destY, width, height, srcX, srcY)
    Tcl_Interp *interp;
    Tcl_Channel chan;
    char *fileName;
    Tcl_Obj *format;
    Tk_PhotoHandle imageHandle;
    int destX, destY;
    int width, height;
    int srcX, srcY;
{
    TIFF *tif;
    char tempFileName[256];
    int count, result;
    char buffer[1024];

    if (load_tiff_library(interp) != TCL_OK) {
	return TCL_ERROR;
    }

    if (tiff.ClientOpen) {
	MFile handle;
	tempFileName[0] = 0;
	handle.data = (char *) chan;
	handle.state = IMG_CHAN;
	tif = tiff.ClientOpen(fileName, "r", (thandle_t) &handle,
		readMFile, writeDummy, seekMFile, closeDummy,
		sizeMFile, mapDummy, unMapDummy);
    } else {
	Tcl_Channel outchan;
	tmpnam(tempFileName);
	outchan = Tcl_OpenFileChannel(interp, tempFileName, "w", 0644);
	if (!outchan) {
	    return TCL_ERROR;
	}
	if (Tcl_SetChannelOption(interp, outchan, "-translation", "binary") != TCL_OK) {
	    return TCL_ERROR;
	}

	count = Tcl_Read(chan, buffer, 1024);
	while (count == 1024) {
	    Tcl_Write(outchan, buffer, count);
	    count = Tcl_Read(chan, buffer, 1024);
	}
	if (count>0){
	    Tcl_Write(outchan, buffer, count);
	}
	if (Tcl_Close(interp, outchan) == TCL_ERROR) {
	    return TCL_ERROR;
	}

	tif = tiff.Open(tempFileName, "r");
    }
    if (tif) {
	result = CommonReadTIFF(interp, tif, format, imageHandle,
		destX, destY, width, height, srcX, srcY);
    } else {
	result = TCL_ERROR;
    }
    if (tempFileName[0]) {
	unlink(tempFileName);
    }
    if (result == TCL_ERROR) {
	Tcl_AppendResult(interp, errorMessage, (char *) NULL);
	ckfree(errorMessage);
	errorMessage = 0;
    }
    return result;
}


typedef struct myblock {
    Tk_PhotoImageBlock ck;
    int dummy; /* extra space for offset[3], if not included already
		  in Tk_PhotoImageBlock */
} myblock;

#define block bl.ck
#define HISTSIZE 1024
static int CommonReadTIFF(interp, tif, format, imageHandle,
	destX, destY, width, height, srcX, srcY)
    Tcl_Interp *interp;
    TIFF *tif;
    Tcl_Obj *format;
    Tk_PhotoHandle imageHandle;
    int destX, destY;
    int width, height;
    int srcX, srcY;
{
    myblock bl;
    unsigned char *pixelPtr = block.pixelPtr;
    int result;

    double imgmin = DBL_MAX;
    double imgmax = DBL_MIN;
    double newmin = DBL_MAX;
    double newmax = DBL_MIN;
    double factor = 0.0;
    
    uint32 npixels;
    uint32 w, h;
    uint32 row, col;
    uint32 i;
    uint32 imgrow;    /* The image's row number (mostly for upside down images) */
    uint32 histmin = -1;
    uint32 histmax = -1;
    uint32 histtot;   /* The cumulative total of the histogram */

    uint16 bps;       /* Bits Per Sample */
    uint16 datatype;
    uint16 orientation;
    uint16 val;

    uint8 histpos;

    float *fscanline;
    float *fraster;
    uint32 *hist;     /* HISTSIZE slot histogram */
    uint32 *raster;   /* Raster image */
    uint32 *praster;  /* Extra pointer to specific points in raster */
    
    uint8 *r;         /* r, g, b, and a represent byte pointers inside */
    uint8 *g;         /* 32bit ints in raster */
    uint8 *b;
    uint8 *a;

    tiff.GetField (tif, TIFFTAG_IMAGEWIDTH, &w);
    tiff.GetField (tif, TIFFTAG_IMAGELENGTH, &h);
    tiff.GetField (tif, TIFFTAG_BITSPERSAMPLE, &bps);
    tiff.GetField (tif, TIFFTAG_SAMPLEFORMAT, &datatype);
    tiff.GetField (tif, TIFFTAG_ORIENTATION, &orientation);

#ifdef WORDS_BIGENDIAN
    block.offset[0] = 3;
    block.offset[1] = 2;
    block.offset[2] = 1;
    block.offset[3] = 0;
#else
    block.offset[0] = 0;
    block.offset[1] = 1;
    block.offset[2] = 2;
    block.offset[3] = 3;
#endif
    block.pixelSize = sizeof (uint32);
    npixels = w * h;

    if (tiff.malloc == NULL) {
        raster = (uint32 *) ckalloc(npixels * sizeof (uint32));
    } else {
        raster = (uint32 *) tiff.malloc(npixels * sizeof (uint32));
    }
    block.width = w;
    block.height = h;
    block.pitch = - (block.pixelSize * (int) w);
    block.pixelPtr = ((unsigned char *) raster) + ((1-h) * block.pitch);
    if (raster == NULL) {
        return TCL_ERROR;
    }

    result = 0;
    if (datatype == SAMPLEFORMAT_IEEEFP) {
        if (bps != 32) {
            if (tiff.free == NULL) {
                ckfree ((char *) raster);
            } else {
                tiff.free ((char *) raster);
            }
            Tcl_AppendResult (interp, "Only 32-bit Float-TIFFs supported", (char *) NULL);
            return TCL_ERROR;
        }
        
        if (tiff.malloc == NULL) {
            hist = (uint32 *)ckalloc(HISTSIZE * sizeof(uint32));
        } else {
            hist = (uint32 *)tiff.malloc(HISTSIZE * sizeof(uint32));        
        }
        memset(hist, 0, HISTSIZE * sizeof(uint32));

        if (tiff.malloc == NULL) {
            fscanline = (float *) ckalloc (w * sizeof(float));
            fraster   = (float *) ckalloc (npixels * sizeof (float));
        } else {
            fscanline = (float *) tiff.malloc (w * sizeof(float));
            fraster   = (float *) tiff.malloc (npixels * sizeof (float));
        }

        for (row = 0; row < h; row++) {
            imgrow = row;
            if (orientation == ORIENTATION_TOPLEFT) {
                imgrow = h - row - 1;
            }
            tiff.ReadScanline (tif, fscanline, row, 0);
            for (col = 0; col < w; col++) {
                fraster[imgrow * w + col] = fscanline[col];
                if (fscanline[col] > imgmax)
                    imgmax = fscanline[col];
                if (fscanline[col] < imgmin)
                    imgmin = fscanline[col];
            }
        }
        if (contrast_enhance) {
            /*  val = (((fraster[i]-imgmin)/(imgmax-imgmin))*(HISTSIZE-1)); */
            factor = (HISTSIZE-1) / (imgmax - imgmin);
            for (i = 0; i < npixels; i++) {
                val = (fraster[i] - imgmin) * factor;
                hist[val]++;
            }

            /* Cumulative histogram */
            histtot = 0;
            for (i = 0; i < HISTSIZE; i++) {
                histtot += hist[i];
                if ((histmin == -1) && (histtot > (npixels*0.005))) {
                    histmin = i;
                }
                if (histtot > (npixels*0.995)) {
                    histmax = i;
                    break;
                }
            }
            
            /* Always floor the newmin, and ceil the newmax */
            newmin = ((imgmax*histmin)     - (HISTSIZE*imgmin))/HISTSIZE;
            newmax = ((imgmax*(histmax+1)) - (HISTSIZE*imgmin))/HISTSIZE;
            if (newmin < 0) newmin = 0;

            imgmin = newmin;
            imgmax = newmax;
        }

        praster = raster;

        /* Apply equalized histogram and stuff into RGBA format */
        /*   val = (((fraster[i]-imgmin)/(imgmax-imgmin))*255); */
        factor = 255 / (imgmax - imgmin);
        for (i = 0; i < npixels; i++, praster++) {
            if (contrast_enhance) {
                if      (fraster[i] < imgmin) fraster[i] = imgmin;
                else if (fraster[i] > imgmax) fraster[i] = imgmax;
            }
            val = (fraster[i] - imgmin) * factor;

            #ifdef WORDS_BIGENDIAN
                a = (uint8 *) praster;
                b = (uint8 *) praster + 1;
                g = (uint8 *) praster + 2;
                r = (uint8 *) praster + 3;
            #else
                r = (uint8 *) praster;
                g = (uint8 *) praster + 1;
                b = (uint8 *) praster + 2;
                a = (uint8 *) praster + 3;
            #endif
            *r = *g = *b = val;
            *a = 0;
        }

        if (tiff.free == NULL) {
            ckfree ((void *) fscanline);
            ckfree ((void *) fraster);
            ckfree ((void *) hist);
        } else {
            tiff.free (fraster);
            tiff.free (fscanline);
            tiff.free (hist);
        }
        result = 1;

    } else {
        result = tiff.ReadRGBAImage (tif, w, h, raster, 0);
    }

    if (!result || errorMessage) {
        if (tiff.free == NULL) {
            ckfree((char *)raster);
        } else {
            tiff.free((char *)raster);
        }
        if (errorMessage) {
            Tcl_AppendResult(interp, errorMessage, (char *) NULL);
            ckfree(errorMessage);
            errorMessage = NULL;
        }
        return TCL_ERROR;
    }

    pixelPtr = block.pixelPtr += srcY * block.pitch + srcX * block.pixelSize;
    block.offset[3] = block.offset[0]; /* don't use transparency */
    ImgPhotoPutBlock(imageHandle, &block, destX,
    		destY, width, height);

    if (tiff.free == NULL) {
        ckfree((char *)raster);
    } else {
        tiff.free((char *)raster);
    }
    tiff.Close(tif);
    return TCL_OK;
}

static int StringWriteTIFF(interp, dataPtr, format, blockPtr)
    Tcl_Interp *interp;
    Tcl_DString *dataPtr;
    Tcl_Obj *format;
    Tk_PhotoImageBlock *blockPtr;
{
    TIFF *tif;
    int result, comp;
    MFile handle;
    char tempFileName[256];
    Tcl_DString dstring;
    char *mode;

    if (load_tiff_library(interp) != TCL_OK) {
	return TCL_ERROR;
    }

    if (ParseWriteFormat(interp, format, &comp, &mode) != TCL_OK) {
    	return TCL_ERROR;
    }

    if (tiff.ClientOpen) {
	tempFileName[0] = 0;
	Tcl_DStringInit(&dstring);
	ImgWriteInit(&dstring, &handle);
	tif = tiff.ClientOpen("inline data", mode, (thandle_t) &handle,
		readString, writeString, seekString, closeDummy,
		sizeString, mapDummy, unMapDummy);
    } else {
	tmpnam(tempFileName);
	tif = tiff.Open(tempFileName,mode);
    }

    result = CommonWriteTIFF(interp, tif, comp, blockPtr);
    tiff.Close(tif);

    if (result != TCL_OK) {
	if (tempFileName[0]) {
	    unlink(tempFileName);
	}
	Tcl_AppendResult(interp, errorMessage, (char *) NULL);
	ckfree(errorMessage);
	errorMessage = NULL;
	return TCL_ERROR;
    }

    if (tempFileName[0]) {
	Tcl_Channel inchan;
	char buffer[1024];
	inchan = Tcl_OpenFileChannel(interp, tempFileName, "w", 0644);
	if (!inchan) {
	    return TCL_ERROR;
	}
	if (Tcl_SetChannelOption(interp, inchan, "-translation", "binary") != TCL_OK) {
	    return TCL_ERROR;
	}
	ImgWriteInit(dataPtr, &handle);

	result = Tcl_Read(inchan, buffer, 1024);
	while ((result == TCL_OK) && !Tcl_Eof(inchan)) {
	    ImgWrite(&handle, buffer, result);
	    result = Tcl_Read(inchan, buffer, 1024);
	}
	if (result == TCL_OK) {
	    ImgWrite(&handle, buffer, result);
	    result = Tcl_Close(interp, inchan);
	}
	unlink(tempFileName);
    } else {
	int length = handle.length;
	ImgWriteInit(dataPtr, &handle);
	ImgWrite(&handle, Tcl_DStringValue(&dstring), length);
	Tcl_DStringFree(&dstring);
    }
    ImgPutc(IMG_DONE, &handle);
    return result;
}

static int ChnWriteTIFF(interp, filename, format, blockPtr)
    Tcl_Interp *interp;
    char *filename;
    Tcl_Obj *format;
    Tk_PhotoImageBlock *blockPtr;
{
    TIFF *tif;
    int result, comp;
    Tcl_DString nameBuffer; 
    char *fullname, *mode;

    if ((fullname=Tcl_TranslateFileName(interp,filename,&nameBuffer))==NULL) {
	return TCL_ERROR;
    }

    if (load_tiff_library(interp) != TCL_OK) {
	Tcl_DStringFree(&nameBuffer);
	return TCL_ERROR;
    }

    if (ParseWriteFormat(interp, format, &comp, &mode) != TCL_OK) {
    	return TCL_ERROR;
    }

    if (!(tif = tiff.Open(fullname,mode))) {
	Tcl_AppendResult(interp, filename, ": ", Tcl_PosixError(interp),
		(char *)NULL);
	Tcl_DStringFree(&nameBuffer);
	return TCL_ERROR;
    }

    Tcl_DStringFree(&nameBuffer);

    result = CommonWriteTIFF(interp, tif, comp, blockPtr);
    tiff.Close(tif);
    return result;
}

static int ParseWriteFormat(interp, format, comp, mode)
    Tcl_Interp *interp;
    Tcl_Obj *format;
    int *comp;
    char **mode;
{
    static
#if !(TK_MAJOR_VERSION == 8 && TK_MINOR_VERSION == 0)
           CONST
#endif
                 char *tiffWriteOptions[] = {"-compression", "-byteorder"};
    int objc, length, c, i, index;
    Tcl_Obj **objv;
    char *compression, *byteorder;

    *comp = COMPRESSION_NONE;
    *mode = "w";
    if (ImgListObjGetElements(interp, format, &objc, &objv) != TCL_OK)
	return TCL_ERROR;
    if (objc) {
	compression = "none";
	byteorder = "";
	for (i=1; i<objc; i++) {
	    if (Tcl_GetIndexFromObj(interp, objv[i], tiffWriteOptions,
		    "format option", 0, &index)!=TCL_OK) {
		return TCL_ERROR;
	    }
	    if (++i >= objc) {
		Tcl_AppendResult(interp, "No value for option \"",
			Tcl_GetStringFromObj(objv[--i], (int *) NULL),
			"\"", (char *) NULL);
		return TCL_ERROR;
	    }
	    switch(index) {
		case 0:
		    compression = Tcl_GetStringFromObj(objv[i], (int *) NULL); break;
		case 1:
		    byteorder = Tcl_GetStringFromObj(objv[i], (int *) NULL); break;
	    }
	}
	c = compression[0]; length = strlen(compression);
	if ((c == 'n') && (!strncmp(compression,"none",length))) {
	    *comp = COMPRESSION_NONE;
	} else if ((c == 'd') && (!strncmp(compression,"deflate",length))) {
	    *comp = COMPRESSION_DEFLATE;
	} else if ((c == 'j') && (!strncmp(compression,"jpeg",length))) {
	    *comp = COMPRESSION_JPEG;
#ifdef COMPRESSION_SGILOG
	} else if ((c == 'l') && (length>1) && (!strncmp(compression,"logluv",length))) {
	    *comp = COMPRESSION_SGILOG;
#endif
	} else if ((c == 'l') && (length>1) && (!strncmp(compression,"lzw",length))) {
	    *comp = COMPRESSION_LZW;
	} else if ((c == 'p') && (length>1) && (!strncmp(compression,"packbits",length))) {
	    *comp = COMPRESSION_PACKBITS;
	} else if ((c == 'p') && (length>1) && (!strncmp(compression,"pixarlog",length))) {
	    *comp = COMPRESSION_PIXARLOG;
	} else {
	    Tcl_AppendResult(interp, "invalid compression mode \"",
		     compression,"\": should be deflate, jpeg, logluv, lzw, ",
		    "packbits, pixarlog, or none", (char *) NULL);
	    return TCL_ERROR;
	}
	c = byteorder[0]; length = strlen(byteorder);
	if (c == 0) {
	    *mode = "w";
	} else if ((c == 's') && (!strncmp(byteorder,"smallendian", length))) {
	    *mode = "wl";
	} else if ((c == 'l') && (!strncmp(byteorder,"littleendian", length))) {
	    *mode = "wl";
	} else if ((c == 'b') && (!strncmp(byteorder,"bigendian", length))) {
	    *mode = "wb";
	} else if ((c == 'n') && (!strncmp(byteorder,"network", length))) {
	    *mode = "wb";
	} else {
	    Tcl_AppendResult(interp, "invalid byteorder \"",
		     byteorder,"\": should be bigendian, littleendian",
		    "network, smallendian, or {}", (char *) NULL);
	    return TCL_ERROR;
	}
    }
    return TCL_OK;
}

static int CommonWriteTIFF(interp, tif, comp, blockPtr)
    Tcl_Interp *interp;
    TIFF *tif;
    int comp;
    Tk_PhotoImageBlock *blockPtr;
{
    int numsamples;
    unsigned char *data = NULL;

    tiff.SetField(tif, TIFFTAG_IMAGEWIDTH, blockPtr->width);
    tiff.SetField(tif, TIFFTAG_IMAGELENGTH, blockPtr->height);
    tiff.SetField(tif, TIFFTAG_COMPRESSION, comp);

    tiff.SetField(tif, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
    tiff.SetField(tif, TIFFTAG_SAMPLESPERPIXEL, 1);
    tiff.SetField(tif, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
    tiff.SetField(tif, TIFFTAG_ROWSPERSTRIP, blockPtr->height);

    tiff.SetField(tif, TIFFTAG_RESOLUTIONUNIT, (int)2);
    tiff.SetField(tif, TIFFTAG_XRESOLUTION, (float)1200.0);
    tiff.SetField(tif, TIFFTAG_YRESOLUTION, (float)1200.0);

    tiff.SetField(tif, TIFFTAG_BITSPERSAMPLE,   8);
    if ((blockPtr->offset[0] == blockPtr->offset[1])
	    && (blockPtr->offset[0] == blockPtr->offset[2])) {
	numsamples = 1;
	tiff.SetField(tif, TIFFTAG_SAMPLESPERPIXEL, 1);
	tiff.SetField(tif, TIFFTAG_PHOTOMETRIC,    PHOTOMETRIC_MINISBLACK);
    } else {
	numsamples = 3;
	tiff.SetField(tif, TIFFTAG_SAMPLESPERPIXEL, 3);
	tiff.SetField(tif, TIFFTAG_PHOTOMETRIC,     PHOTOMETRIC_RGB);
    }

    if ((blockPtr->pitch == numsamples * blockPtr->width)
	    && (blockPtr->pixelSize == numsamples)) {
	data = blockPtr->pixelPtr;
    } else {
	unsigned char *srcPtr, *dstPtr, *rowPtr;
	int greenOffset, blueOffset, alphaOffset, x, y;
	dstPtr = data = (unsigned char *) ckalloc(numsamples *
		blockPtr->width * blockPtr->height);
	rowPtr = blockPtr->pixelPtr + blockPtr->offset[0];
	greenOffset = blockPtr->offset[1] - blockPtr->offset[0];
	blueOffset = blockPtr->offset[2] - blockPtr->offset[0];
	alphaOffset =  blockPtr->offset[0];
	if (alphaOffset < blockPtr->offset[2]) {
	    alphaOffset = blockPtr->offset[2];
	}
	if (++alphaOffset < blockPtr->pixelSize) {
	    alphaOffset -= blockPtr->offset[0];
	} else {
	    alphaOffset = 0;
	}
	if (blueOffset || greenOffset) {
	    for (y = blockPtr->height; y > 0; y--) {
		srcPtr = rowPtr;
		for (x = blockPtr->width; x>0; x--) {
		    if (alphaOffset && !srcPtr[alphaOffset]) {
			*dstPtr++ = 0xd9;
			*dstPtr++ = 0xd9;
			*dstPtr++ = 0xd9;
		    } else {
			*dstPtr++ = srcPtr[0];
			*dstPtr++ = srcPtr[greenOffset];
			*dstPtr++ = srcPtr[blueOffset];
		    }
		    srcPtr += blockPtr->pixelSize;
		}
		rowPtr += blockPtr->pitch;
	    }
	} else {
	    for (y = blockPtr->height; y > 0; y--) {
		srcPtr = rowPtr;
		for (x = blockPtr->width; x>0; x--) {
		    *dstPtr++ = srcPtr[0];
		    srcPtr += blockPtr->pixelSize;
		}
		rowPtr += blockPtr->pitch;
	    }
	}
    }

    tiff.WriteEncodedStrip(tif, 0, data,
	    numsamples * blockPtr->width * blockPtr->height);
    if (data != blockPtr->pixelPtr) {
	ckfree((char *) data);
    }

    return TCL_OK;
}

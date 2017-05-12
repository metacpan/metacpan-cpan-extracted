#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <unistd.h>
#include <sys/mman.h>

#include "../gppport.h"

#include "codec/RTjpeg.h"

static int fwidth, fheight;

MODULE = Video::RTjpeg		PACKAGE = Video::RTjpeg		PREFIX = RTjpeg_

PROTOTYPES: ENABLE

SV *
RTjpeg_init_compress(width,height,Q)
	int	width
        int	height
        U8	Q
        CODE:
        fwidth = width;
        fheight = height;
        RETVAL = newSVpv ("", 0);
        SvGROW (RETVAL, sizeof (RTjpeg_tables));
        SvCUR_set (RETVAL, sizeof (RTjpeg_tables));
        RTjpeg_init_compress ((u32 *)SvPV_nolen (RETVAL), width, height, Q);
	OUTPUT:
        RETVAL

void
RTjpeg_init_decompress(tables,width,height)
	SV *	tables
	int	width
        int	height
        CODE:
        fwidth = width;
        fheight = height;
        RTjpeg_init_decompress ((u32 *)SvPV_nolen (tables), width, height);

SV *
RTjpeg_compress(YCrCb422_data)
	SV *	YCrCb422_data
        CODE:
        RETVAL = newSVpv ("", 0);
        SvGROW (RETVAL, (fwidth * fheight * 3 + 2) / 2);
        SvCUR_set (RETVAL, RTjpeg_compress (SvPV_nolen (RETVAL), SvPV_nolen (YCrCb422_data)));
	OUTPUT:
        RETVAL
        
SV *
RTjpeg_decompress(RTjpeg_data)
	SV *	RTjpeg_data
        CODE:
        RETVAL = newSVpv ("", 0);
        SvGROW (RETVAL, fwidth * fheight * 2);
        SvCUR_set (RETVAL, fwidth * fheight * 2);
        RTjpeg_decompress (SvPV_nolen (RTjpeg_data), SvPV_nolen (RETVAL));
	OUTPUT:
        RETVAL

void
RTjpeg_init_mcompress()
        
SV *
RTjpeg_mcompress(YCrCb422_data,lmask,cmask=(lmask)>>1,x=0,y=0,w=fwidth,h=fheight)
	SV *	YCrCb422_data
        U16	lmask
        U16	cmask
        int	x
        int	y
        int	w
        int	h
        CODE:
        RETVAL = newSVpv ("", 0);
        SvGROW (RETVAL, (fwidth * fheight * 3 + 2) / 2);
        SvCUR_set (RETVAL, RTjpeg_mcompress (SvPV_nolen (RETVAL), SvPV_nolen (YCrCb422_data), lmask, cmask,
                                             x, y, w, h));
	OUTPUT:
        RETVAL
        
SV *
RTjpeg_yuvrgb(yuv_data)
	SV *	yuv_data
        CODE:
        RETVAL = newSVpv ("", 0);
        SvGROW (RETVAL, fwidth * fheight * 3);
        SvCUR_set (RETVAL, fwidth * fheight * 3);
        RTjpeg_yuvrgb (SvPV_nolen (yuv_data), SvPV_nolen (RETVAL));
	OUTPUT:
        RETVAL

void
_exit(retcode=0)
  	int retcode
	CODE:
        _exit (retcode);
        
void
fdatasync(fd)
  	int	fd
	CODE:
#ifdef _POSIX_SYNCHRONIZED_IO
        fdatasync (fd);
#endif
        
BOOT:
{
	HV *stash = gv_stashpvn("Video::RTjpeg", 13, TRUE);

	//newCONSTSUB(stash,"VBI_VT",	newSViv(VBI_VT));
}
        

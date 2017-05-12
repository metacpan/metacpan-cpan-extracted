#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <vga.h>

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ACCELFLAG_DRAWHLINELIST"))
#ifdef ACCELFLAG_DRAWHLINELIST
	    return ACCELFLAG_DRAWHLINELIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_DRAWLINE"))
#ifdef ACCELFLAG_DRAWLINE
	    return ACCELFLAG_DRAWLINE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_FILLBOX"))
#ifdef ACCELFLAG_FILLBOX
	    return ACCELFLAG_FILLBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_PUTBITMAP"))
#ifdef ACCELFLAG_PUTBITMAP
	    return ACCELFLAG_PUTBITMAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_PUTIMAGE"))
#ifdef ACCELFLAG_PUTIMAGE
	    return ACCELFLAG_PUTIMAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SCREENCOPY"))
#ifdef ACCELFLAG_SCREENCOPY
	    return ACCELFLAG_SCREENCOPY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SCREENCOPYBITMAP"))
#ifdef ACCELFLAG_SCREENCOPYBITMAP
	    return ACCELFLAG_SCREENCOPYBITMAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SETBGCOLOR"))
#ifdef ACCELFLAG_SETBGCOLOR
	    return ACCELFLAG_SETBGCOLOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SETFGCOLOR"))
#ifdef ACCELFLAG_SETFGCOLOR
	    return ACCELFLAG_SETFGCOLOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SETMODE"))
#ifdef ACCELFLAG_SETMODE
	    return ACCELFLAG_SETMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SETRASTEROP"))
#ifdef ACCELFLAG_SETRASTEROP
	    return ACCELFLAG_SETRASTEROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SETTRANSPARENCY"))
#ifdef ACCELFLAG_SETTRANSPARENCY
	    return ACCELFLAG_SETTRANSPARENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCELFLAG_SYNC"))
#ifdef ACCELFLAG_SYNC
	    return ACCELFLAG_SYNC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_DRAWHLINELIST"))
#ifdef ACCEL_DRAWHLINELIST
	    return ACCEL_DRAWHLINELIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_DRAWLINE"))
#ifdef ACCEL_DRAWLINE
	    return ACCEL_DRAWLINE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_FILLBOX"))
#ifdef ACCEL_FILLBOX
	    return ACCEL_FILLBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_PUTBITMAP"))
#ifdef ACCEL_PUTBITMAP
	    return ACCEL_PUTBITMAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_PUTIMAGE"))
#ifdef ACCEL_PUTIMAGE
	    return ACCEL_PUTIMAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SCREENCOPY"))
#ifdef ACCEL_SCREENCOPY
	    return ACCEL_SCREENCOPY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SCREENCOPYBITMAP"))
#ifdef ACCEL_SCREENCOPYBITMAP
	    return ACCEL_SCREENCOPYBITMAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SETBGCOLOR"))
#ifdef ACCEL_SETBGCOLOR
	    return ACCEL_SETBGCOLOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SETFGCOLOR"))
#ifdef ACCEL_SETFGCOLOR
	    return ACCEL_SETFGCOLOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SETMODE"))
#ifdef ACCEL_SETMODE
	    return ACCEL_SETMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SETRASTEROP"))
#ifdef ACCEL_SETRASTEROP
	    return ACCEL_SETRASTEROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SETTRANSPARENCY"))
#ifdef ACCEL_SETTRANSPARENCY
	    return ACCEL_SETTRANSPARENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ACCEL_SYNC"))
#ifdef ACCEL_SYNC
	    return ACCEL_SYNC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ALI"))
#ifdef ALI
	    return ALI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ARK"))
#ifdef ARK
	    return ARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ATI"))
#ifdef ATI
	    return ATI;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BLITS_IN_BACKGROUND"))
#ifdef BLITS_IN_BACKGROUND
	    return BLITS_IN_BACKGROUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BLITS_SYNC"))
#ifdef BLITS_SYNC
	    return BLITS_SYNC;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	if (strEQ(name, "CAPABLE_LINEAR"))
#ifdef CAPABLE_LINEAR
	    return CAPABLE_LINEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CIRRUS"))
#ifdef CIRRUS
	    return CIRRUS;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DISABLE_BITMAP_TRANSPARENCY"))
#ifdef DISABLE_BITMAP_TRANSPARENCY
	    return DISABLE_BITMAP_TRANSPARENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISABLE_TRANSPARENCY_COLOR"))
#ifdef DISABLE_TRANSPARENCY_COLOR
	    return DISABLE_TRANSPARENCY_COLOR;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "EGA"))
#ifdef EGA
	    return EGA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENABLE_BITMAP_TRANSPARENCY"))
#ifdef ENABLE_BITMAP_TRANSPARENCY
	    return ENABLE_BITMAP_TRANSPARENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENABLE_TRANSPARENCY_COLOR"))
#ifdef ENABLE_TRANSPARENCY_COLOR
	    return ENABLE_TRANSPARENCY_COLOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ET3000"))
#ifdef ET3000
	    return ET3000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ET4000"))
#ifdef ET4000
	    return ET4000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXT_INFO_AVAILABLE"))
#ifdef EXT_INFO_AVAILABLE
	    return EXT_INFO_AVAILABLE;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	break;
    case 'G':
	if (strEQ(name, "G1024x768x16"))
#ifdef G1024x768x16
	    return G1024x768x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1024x768x16M"))
#ifdef G1024x768x16M
	    return G1024x768x16M;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1024x768x16M32"))
#ifdef G1024x768x16M32
	    return G1024x768x16M32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1024x768x256"))
#ifdef G1024x768x256
	    return G1024x768x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1024x768x32K"))
#ifdef G1024x768x32K
	    return G1024x768x32K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1024x768x64K"))
#ifdef G1024x768x64K
	    return G1024x768x64K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1152x864x16"))
#ifdef G1152x864x16
	    return G1152x864x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1152x864x16M"))
#ifdef G1152x864x16M
	    return G1152x864x16M;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1152x864x16M32"))
#ifdef G1152x864x16M32
	    return G1152x864x16M32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1152x864x256"))
#ifdef G1152x864x256
	    return G1152x864x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1152x864x32K"))
#ifdef G1152x864x32K
	    return G1152x864x32K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1152x864x64K"))
#ifdef G1152x864x64K
	    return G1152x864x64K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1280x1024x16"))
#ifdef G1280x1024x16
	    return G1280x1024x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1280x1024x16M"))
#ifdef G1280x1024x16M
	    return G1280x1024x16M;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1280x1024x16M32"))
#ifdef G1280x1024x16M32
	    return G1280x1024x16M32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1280x1024x256"))
#ifdef G1280x1024x256
	    return G1280x1024x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1280x1024x32K"))
#ifdef G1280x1024x32K
	    return G1280x1024x32K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1280x1024x64K"))
#ifdef G1280x1024x64K
	    return G1280x1024x64K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1600x1200x16"))
#ifdef G1600x1200x16
	    return G1600x1200x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1600x1200x16M"))
#ifdef G1600x1200x16M
	    return G1600x1200x16M;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1600x1200x16M32"))
#ifdef G1600x1200x16M32
	    return G1600x1200x16M32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1600x1200x256"))
#ifdef G1600x1200x256
	    return G1600x1200x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1600x1200x32K"))
#ifdef G1600x1200x32K
	    return G1600x1200x32K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G1600x1200x64K"))
#ifdef G1600x1200x64K
	    return G1600x1200x64K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x200x16"))
#ifdef G320x200x16
	    return G320x200x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x200x16M"))
#ifdef G320x200x16M
	    return G320x200x16M;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x200x16M32"))
#ifdef G320x200x16M32
	    return G320x200x16M32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x200x256"))
#ifdef G320x200x256
	    return G320x200x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x200x32K"))
#ifdef G320x200x32K
	    return G320x200x32K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x200x64K"))
#ifdef G320x200x64K
	    return G320x200x64K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x240x256"))
#ifdef G320x240x256
	    return G320x240x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G320x400x256"))
#ifdef G320x400x256
	    return G320x400x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G360x480x256"))
#ifdef G360x480x256
	    return G360x480x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x200x16"))
#ifdef G640x200x16
	    return G640x200x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x350x16"))
#ifdef G640x350x16
	    return G640x350x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x480x16"))
#ifdef G640x480x16
	    return G640x480x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x480x16M"))
#ifdef G640x480x16M
	    return G640x480x16M;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x480x16M32"))
#ifdef G640x480x16M32
	    return G640x480x16M32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x480x2"))
#ifdef G640x480x2
	    return G640x480x2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x480x256"))
#ifdef G640x480x256
	    return G640x480x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x480x32K"))
#ifdef G640x480x32K
	    return G640x480x32K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G640x480x64K"))
#ifdef G640x480x64K
	    return G640x480x64K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G720x348x2"))
#ifdef G720x348x2
	    return G720x348x2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G800x600x16"))
#ifdef G800x600x16
	    return G800x600x16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G800x600x16M"))
#ifdef G800x600x16M
	    return G800x600x16M;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G800x600x16M32"))
#ifdef G800x600x16M32
	    return G800x600x16M32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G800x600x256"))
#ifdef G800x600x256
	    return G800x600x256;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G800x600x32K"))
#ifdef G800x600x32K
	    return G800x600x32K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "G800x600x64K"))
#ifdef G800x600x64K
	    return G800x600x64K;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GLASTMODE"))
#ifdef GLASTMODE
	    return GLASTMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GVGA6400"))
#ifdef GVGA6400
	    return GVGA6400;
#else
	    goto not_there;
#endif
	break;
    case 'H':
	if (strEQ(name, "HAVE_BITBLIT"))
#ifdef HAVE_BITBLIT
	    return HAVE_BITBLIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HAVE_BLITWAIT"))
#ifdef HAVE_BLITWAIT
	    return HAVE_BLITWAIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HAVE_EXT_SET"))
#ifdef HAVE_EXT_SET
	    return HAVE_EXT_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HAVE_FILLBLIT"))
#ifdef HAVE_FILLBLIT
	    return HAVE_FILLBLIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HAVE_HLINELISTBLIT"))
#ifdef HAVE_HLINELISTBLIT
	    return HAVE_HLINELISTBLIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HAVE_IMAGEBLIT"))
#ifdef HAVE_IMAGEBLIT
	    return HAVE_IMAGEBLIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HAVE_RWPAGE"))
#ifdef HAVE_RWPAGE
	    return HAVE_RWPAGE;
#else
	    goto not_there;
#endif
	break;
    case 'I':
	if (strEQ(name, "IS_DYNAMICMODE"))
#ifdef IS_DYNAMICMODE
	    return IS_DYNAMICMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IS_INTERLACED"))
#ifdef IS_INTERLACED
	    return IS_INTERLACED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IS_LINEAR"))
#ifdef IS_LINEAR
	    return IS_LINEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IS_MODEX"))
#ifdef IS_MODEX
	    return IS_MODEX;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	if (strEQ(name, "MACH32"))
#ifdef MACH32
	    return MACH32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MACH64"))
#ifdef MACH64
	    return MACH64;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MON1024_43I"))
#ifdef MON1024_43I
	    return MON1024_43I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MON1024_60"))
#ifdef MON1024_60
	    return MON1024_60;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MON1024_70"))
#ifdef MON1024_70
	    return MON1024_70;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MON1024_72"))
#ifdef MON1024_72
	    return MON1024_72;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MON640_60"))
#ifdef MON640_60
	    return MON640_60;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MON800_56"))
#ifdef MON800_56
	    return MON800_56;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MON800_60"))
#ifdef MON800_60
	    return MON800_60;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	break;
    case 'O':
	if (strEQ(name, "OAK"))
#ifdef OAK
	    return OAK;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "RGB_MISORDERED"))
#ifdef RGB_MISORDERED
	    return RGB_MISORDERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ROP_AND"))
#ifdef ROP_AND
	    return ROP_AND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ROP_COPY"))
#ifdef ROP_COPY
	    return ROP_COPY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ROP_INVERT"))
#ifdef ROP_INVERT
	    return ROP_INVERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ROP_OR"))
#ifdef ROP_OR
	    return ROP_OR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ROP_XOR"))
#ifdef ROP_XOR
	    return ROP_XOR;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "S3"))
#ifdef S3
	    return S3;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TEXT"))
#ifdef TEXT
	    return TEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TVGA8900"))
#ifdef TVGA8900
	    return TVGA8900;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	if (strEQ(name, "UNDEFINED"))
#ifdef UNDEFINED
	    return UNDEFINED;
#else
	    goto not_there;
#endif
	break;
    case 'V':
	if (strEQ(name, "VGA"))
#ifdef VGA
	    return VGA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_AVAIL_ACCEL"))
#ifdef VGA_AVAIL_ACCEL
	    return VGA_AVAIL_ACCEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_AVAIL_FLAGS"))
#ifdef VGA_AVAIL_FLAGS
	    return VGA_AVAIL_FLAGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_AVAIL_SET"))
#ifdef VGA_AVAIL_SET
	    return VGA_AVAIL_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_CLUT8"))
#ifdef VGA_CLUT8
	    return VGA_CLUT8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_EXT_AVAILABLE"))
#ifdef VGA_EXT_AVAILABLE
	    return VGA_EXT_AVAILABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_EXT_CLEAR"))
#ifdef VGA_EXT_CLEAR
	    return VGA_EXT_CLEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_EXT_PAGE_OFFSET"))
#ifdef VGA_EXT_PAGE_OFFSET
	    return VGA_EXT_PAGE_OFFSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_EXT_RESET"))
#ifdef VGA_EXT_RESET
	    return VGA_EXT_RESET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_EXT_SET"))
#ifdef VGA_EXT_SET
	    return VGA_EXT_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_H"))
#ifdef VGA_H
	    return VGA_H;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_KEYEVENT"))
#ifdef VGA_KEYEVENT
	    return VGA_KEYEVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VGA_MOUSEEVENT"))
#ifdef VGA_MOUSEEVENT
	    return VGA_MOUSEEVENT;
#else
	    goto not_there;
#endif
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case '_':
	if (strEQ(name, "__GLASTMODE"))
#ifdef __GLASTMODE
	    return __GLASTMODE;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = vga		PACKAGE = vga		PREFIX = vga_

# test

double
constant(name,arg)
	char *		name
	int		arg

int
vga_setmode(mode)
	int mode

int
vga_hasmode(mode)
	int mode

int
vga_setflipchar(c)
	int c

int
vga_clear()

int
vga_flip()

int
vga_getxdim()

int
vga_getydim()

int
vga_getcolors()

int
vga_setpalette(index,red,green,blue)
	int index
	int red
	int green
	int blue

int
vga_getpalette(index,red,green,blue)
	int index
	char *	red
	char *	green
	char *	blue

int 
vga_setpalvec(start,num,pal)
	int start
	int num
	char * pal

int 
vga_getpalvec(start,num,pal)
	int start
	int num
	char * pal

int 
vga_screenoff()

int 
vga_screenon()

int
vga_setcolor(color)
	int color

int
vga_drawpixel(x,y)
	int x
	int y

int
vga_drawline(x1,y1,x2,y2)
	int x1
	int y1
	int x2
	int y2

int
vga_drawscanline(line,colors)
	int line
	unsigned char *	colors

int
vga_drawscansegment(colors,x,y,length)
	unsigned char *	colors
	int x
	int y
	int length

int
vga_getpixel(x,y)
	int x
	int y

int
vga_getscansegment(colors,x,y,length)
	unsigned char * colors
	int x
	int y
	int length

int
vga_getch()

int
vga_dumpregs()

# Extensions to VGAlib v1.2:

int
vga_getdefaultmode()

int
vga_getcurrentmode()

int
vga_getcurrentchipset()

int
vga_getmodenumber(name)
	char *	name

int
vga_lastmodenumber()

void
vga_setpage(p)
	int p

void
vga_setreadpage(p)
	int p

void
vga_setwritepage(p)
	int p

void
vga_setlogicalwidth(w)
	int w

void
vga_setdisplaystart(a)
	int a

void
vga_waitretrace()

int
vga_claimvideomemory(n)
	int n

void
vga_disabledriverreport()

int
vga_setmodeX()

int
vga_init()

int
vga_getmousetype()

int 
vga_getmonitortype()

void 
vga_setmousesupport(s)
	int s

void 
vga_lockvc()

void
vga_unlockvc()

int 
vga_getkey()


void
vga_runinbackground(s)
	int s

int 
vga_oktowrite()

void 
vga_copytoplanar256(virtualp,pitch,voffset,vpitch,w,h)
	unsigned char *	virtualp
	int pitch
	int voffset
	int vpitch
	int w
	int h

void 
vga_copytoplanar16(virtualp,pitch,voffset,vpitch,w,h)
	unsigned char *	virtualp
	int pitch
	int voffset
	int vpitch
	int w
	int h

void 
vga_copytoplane(virtualp,pitch,voffset,vpitch,w,h,plane)
	unsigned char *	virtualp
	int pitch
	int voffset
	int vpitch
	int w
	int h
	int plane

int 
vga_setlinearaddressing()

void 
vga_setchipset(c)
	int c

void 
vga_setchipsetandfeatures(c,par1,par2)
	int c
	int par1
	int par2

void 
vga_gettextfont(font)
	void *	font

void 
vga_puttextfont(font)
	void *	font

void 
vga_settextmoderegs(regs)
	void *	regs

void 
vga_gettextmoderegs(regs)
	void *	regs

int
vga_white()

int 
vga_setegacolor(c)
	int c

int 
vga_setrgbcolor(r,g,b)
	int r
	int g
	int b

void 
vga_bitblt(srcaddr,destaddr,w,h,pitch)
	int srcaddr
	int destaddr
	int w
	int h
	int pitch

void 
vga_imageblt(srcaddr,destaddr,w,h,pitch)
	void *srcaddr
	int destaddr
	int w
	int h
	int pitch

void 
vga_fillblt(destaddr,w,h,pitch,c)
	int destaddr
	int w
	int h
	int pitch
	int c

void 
vga_hlinelistblt(ymin,n,xmin,xmax,pitch,c)
	int ymin
	int n
	char *	xmin
	char *	xmax
	int pitch
	int c

void 
vga_blitwait()

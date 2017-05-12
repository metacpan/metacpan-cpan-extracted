package vga;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	ACCELFLAG_DRAWHLINELIST
	ACCELFLAG_DRAWLINE
	ACCELFLAG_FILLBOX
	ACCELFLAG_PUTBITMAP
	ACCELFLAG_PUTIMAGE
	ACCELFLAG_SCREENCOPY
	ACCELFLAG_SCREENCOPYBITMAP
	ACCELFLAG_SETBGCOLOR
	ACCELFLAG_SETFGCOLOR
	ACCELFLAG_SETMODE
	ACCELFLAG_SETRASTEROP
	ACCELFLAG_SETTRANSPARENCY
	ACCELFLAG_SYNC
	ACCEL_DRAWHLINELIST
	ACCEL_DRAWLINE
	ACCEL_FILLBOX
	ACCEL_PUTBITMAP
	ACCEL_PUTIMAGE
	ACCEL_SCREENCOPY
	ACCEL_SCREENCOPYBITMAP
	ACCEL_SETBGCOLOR
	ACCEL_SETFGCOLOR
	ACCEL_SETMODE
	ACCEL_SETRASTEROP
	ACCEL_SETTRANSPARENCY
	ACCEL_SYNC
	ALI
	ARK
	ATI
	BLITS_IN_BACKGROUND
	BLITS_SYNC
	CAPABLE_LINEAR
	CIRRUS
	DISABLE_BITMAP_TRANSPARENCY
	DISABLE_TRANSPARENCY_COLOR
	EGA
	ENABLE_BITMAP_TRANSPARENCY
	ENABLE_TRANSPARENCY_COLOR
	ET3000
	ET4000
	EXT_INFO_AVAILABLE
	G1024x768x16
	G1024x768x16M
	G1024x768x16M32
	G1024x768x256
	G1024x768x32K
	G1024x768x64K
	G1152x864x16
	G1152x864x16M
	G1152x864x16M32
	G1152x864x256
	G1152x864x32K
	G1152x864x64K
	G1280x1024x16
	G1280x1024x16M
	G1280x1024x16M32
	G1280x1024x256
	G1280x1024x32K
	G1280x1024x64K
	G1600x1200x16
	G1600x1200x16M
	G1600x1200x16M32
	G1600x1200x256
	G1600x1200x32K
	G1600x1200x64K
	G320x200x16
	G320x200x16M
	G320x200x16M32
	G320x200x256
	G320x200x32K
	G320x200x64K
	G320x240x256
	G320x400x256
	G360x480x256
	G640x200x16
	G640x350x16
	G640x480x16
	G640x480x16M
	G640x480x16M32
	G640x480x2
	G640x480x256
	G640x480x32K
	G640x480x64K
	G720x348x2
	G800x600x16
	G800x600x16M
	G800x600x16M32
	G800x600x256
	G800x600x32K
	G800x600x64K
	GLASTMODE
	GVGA6400
	HAVE_BITBLIT
	HAVE_BLITWAIT
	HAVE_EXT_SET
	HAVE_FILLBLIT
	HAVE_HLINELISTBLIT
	HAVE_IMAGEBLIT
	HAVE_RWPAGE
	IS_DYNAMICMODE
	IS_INTERLACED
	IS_LINEAR
	IS_MODEX
	MACH32
	MACH64
	MON1024_43I
	MON1024_60
	MON1024_70
	MON1024_72
	MON640_60
	MON800_56
	MON800_60
	OAK
	RGB_MISORDERED
	ROP_AND
	ROP_COPY
	ROP_INVERT
	ROP_OR
	ROP_XOR
	S3
	TEXT
	TVGA8900
	UNDEFINED
	VGA
	VGA_AVAIL_ACCEL
	VGA_AVAIL_FLAGS
	VGA_AVAIL_SET
	VGA_CLUT8
	VGA_EXT_AVAILABLE
	VGA_EXT_CLEAR
	VGA_EXT_PAGE_OFFSET
	VGA_EXT_RESET
	VGA_EXT_SET
	VGA_H
	VGA_KEYEVENT
	VGA_MOUSEEVENT
	__GLASTMODE
);
$VERSION = '0.4';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined vga macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap vga $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

vga - Perl extension for svgalib-1.2.11

=head1 SYNOPSIS

  use vga;

  [script ...]

=head1 DESCRIPTION

Perl interface to svgalib 1.2.11, which is an enhancement of VGAlib v.1.2.
The main difference in usage is all the vgalib functions that took the
form of vga_functionname are now accessed as vga::functionname (without
the 'vga_') 

Things notably missing from the library:
vga_modeinfo structure	
vga_getmodeinfo()				(vga::getmodeinfo)
vga_getmodename()				(vga::getmodename)		
the pointer to video ram, graph_mem	(\$vga::graphmem)
and the function vga_getgraphmem()	(vga::getgraphmem)

Also, I realize the docs are kinda hacked. If there is any interest in
this package, I will revamp it and reupload it to the CPAN.

Here is a description of the basic library functions (from the original
VGAlib v1.2 README):

    - Support for all standard VGA 16 and 256 color modes
    - Support for non-standard 256 color modes (including mode X)
    - Tseng ET4000 SVGA 256 color modes
    - Monochrome 640x480 mode
    - Text mode restoration
    - Handling of console I/O
    - Flipping between graphics mode and text mode
    - Restores text mode after CTRL-C interrupt
    - The ET4000 modes should now be more robust
    - Tools for creating your own video modes

VGAlib requires the 0.96b kernel (or newer) and must be compiled
with GCC 2.2.2 (or newer). To compile and install VGAlib just
type make. This will also build the following programs:
    vgatest: a simple demonstration of the library and the various
             video modes
    dumpreg: dumps the current VGA registers to stdout, mainly used
             for debugging and creating new video modes
    runx   : if you have problems with text mode restoration after
             running X386, then try to use runx instead of startx
Remember that all programs using VGAlib must be run with setuid
root (login as root and do a 'chmod +s prog-name'), otherwise you
will get a "can't get I/O permissions" error.

VGAlib does it's best to restore the text mode, but it may fail
with some SVGA cards if you use a text mode with more than 80
columns. If you are having problems please try to use an 80
column text mode.

Below is a short description of the functions in the library.
Look at vgatest.c for examples on how to use these functions:
    - vga_setmode() is used to select the graphics mode or to
      restore the text mode.
    - vga_hasmode() tests if a given video mode is supported
      by the graphics card (use this function before using
      any of the ET4000 SVGA modes)
    - vga_clear() clears the graphics screen. This is also done
      by vga_setmode().
    - vga_getxdim(), vga_getydim() and vga_getcolors() return
      the resolution and number of colors for the current mode.
    - vga_getpalette() and vga_getpalvec() returns the contents
      of one or more palette registers, respectively.
    - vga_setpalette() and vga_setpalvec() allows you to modify
      one or more palette registers, respectively.
    - vga_setcolor() determines the color for future calls of
      the drawing functions.
    - vga_drawpixel() and vga_drawline() draws a pixel or a line
      in the current color, respectively.
    - vga_drawscanline() draws one single horisontal line of
      pixels and has been optimized for the fastest possible
      output.
    - vga_screenoff() and vga_screenon() turns the screen refresh
      off and on. On some VGA's the graphics operations will be
      faster, if the screen is turned off during graphics output.
    - vga_flip() switches between graphics and text mode without
      destroying the screen contents. This makes it possible for
      your application to use both text and graphics output.
    - vga_gecth() waits for a character to be typed an returns
      the ASCII value. If you press ESC (the exact key can be
      changed with vga_setflipchar()), the text mode will be
      temporarily restored until you press another key. This allows
      you to switch to another virtual console and later return to
      your graphics application.
    - vga_setflipchar() changes the character that vga_getch()
      uses for flipping between graphics and text mode.
    - vga_dumpregs() dumps the current VGA register contents to
      stdout
My main motivation for implementing the graphics/text flipping was
to make debugging easier. If your program reaches a breakpoint while
in graphics mode, you can switch to text mode with the gdb command

    print vga_flip()

and later restore the graphics screen contents with the same command.
It is usefull to define the following alias in gdb:
in graphics mode, you can switch to text mode with the gdb command

    print vga_flip()

and later restore the graphics screen contents with the same command.
It is usefull to define the following alias in gdb:

    define flip <RETURN> print vga_flip() <RETURN> end <RETURN>              

=head1 Exported constants

  ACCELFLAG_DRAWHLINELIST
  ACCELFLAG_DRAWLINE
  ACCELFLAG_FILLBOX
  ACCELFLAG_PUTBITMAP
  ACCELFLAG_PUTIMAGE
  ACCELFLAG_SCREENCOPY
  ACCELFLAG_SCREENCOPYBITMAP
  ACCELFLAG_SETBGCOLOR
  ACCELFLAG_SETFGCOLOR
  ACCELFLAG_SETMODE
  ACCELFLAG_SETRASTEROP
  ACCELFLAG_SETTRANSPARENCY
  ACCELFLAG_SYNC
  ACCEL_DRAWHLINELIST
  ACCEL_DRAWLINE
  ACCEL_FILLBOX
  ACCEL_PUTBITMAP
  ACCEL_PUTIMAGE
  ACCEL_SCREENCOPY
  ACCEL_SCREENCOPYBITMAP
  ACCEL_SETBGCOLOR
  ACCEL_SETFGCOLOR
  ACCEL_SETMODE
  ACCEL_SETRASTEROP
  ACCEL_SETTRANSPARENCY
  ACCEL_SYNC
  ALI
  ARK
  ATI
  BLITS_IN_BACKGROUND
  BLITS_SYNC
  CAPABLE_LINEAR
  CIRRUS
  DISABLE_BITMAP_TRANSPARENCY
  DISABLE_TRANSPARENCY_COLOR
  EGA
  ENABLE_BITMAP_TRANSPARENCY
  ENABLE_TRANSPARENCY_COLOR
  ET3000
  ET4000
  EXT_INFO_AVAILABLE
  G1024x768x16
  G1024x768x16M
  G1024x768x16M32
  G1024x768x256
  G1024x768x32K
  G1024x768x64K
  G1152x864x16
  G1152x864x16M
  G1152x864x16M32
  G1152x864x256
  G1152x864x32K
  G1152x864x64K
  G1280x1024x16
  G1280x1024x16M
  G1280x1024x16M32
  G1280x1024x256
  G1280x1024x32K
  G1280x1024x64K
  G1600x1200x16
  G1600x1200x16M
  G1600x1200x16M32
  G1600x1200x256
  G1600x1200x32K
  G1600x1200x64K
  G320x200x16
  G320x200x16M
  G320x200x16M32
  G320x200x256
  G320x200x32K
  G320x200x64K
  G320x240x256
  G320x400x256
  G360x480x256
  G640x200x16
  G640x350x16
  G640x480x16
  G640x480x16M
  G640x480x16M32
  G640x480x2
  G640x480x256
  G640x480x32K
  G640x480x64K
  G720x348x2
  G800x600x16
  G800x600x16M
  G800x600x16M32
  G800x600x256
  G800x600x32K
  G800x600x64K
  GLASTMODE
  GVGA6400
  HAVE_BITBLIT
  HAVE_BLITWAIT
  HAVE_EXT_SET
  HAVE_FILLBLIT
  HAVE_HLINELISTBLIT
  HAVE_IMAGEBLIT
  HAVE_RWPAGE
  IS_DYNAMICMODE
  IS_INTERLACED
  IS_LINEAR
  IS_MODEX
  MACH32
  MACH64
  MON1024_43I
  MON1024_60
  MON1024_70
  MON1024_72
  MON640_60
  MON800_56
  MON800_60
  OAK
  RGB_MISORDERED
  ROP_AND
  ROP_COPY
  ROP_INVERT
  ROP_OR
  ROP_XOR
  S3
  TEXT
  TVGA8900
  UNDEFINED
  VGA
  VGA_AVAIL_ACCEL
  VGA_AVAIL_FLAGS
  VGA_AVAIL_SET
  VGA_CLUT8
  VGA_EXT_AVAILABLE
  VGA_EXT_CLEAR
  VGA_EXT_PAGE_OFFSET
  VGA_EXT_RESET
  VGA_EXT_SET
  VGA_H
  VGA_KEYEVENT
  VGA_MOUSEEVENT
  __GLASTMODE


=head1 AUTHOR

Scott VanRavenswaay	(scottvr@netcomi.com)
VGAlib:	Tommy Frandsen (frandsen@diku.dk)
svgalib: (you know who you are)
 
=head1 SEE ALSO

perl(1).
vgalib docs.

=cut

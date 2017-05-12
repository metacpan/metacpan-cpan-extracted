Building the Static FreeImage libraries (correct as at FreeImage 3.8.0)

Download FreeImage source code at http://freeimage.sourceforge.net/

For VC6:
- Build the FreeImage static lib with MSVC project.
- Copy the FreeImage.lib and FreeImage.h in the extlib directory.

For Mingw:
- I've not managed to build FreeImage under mingw yet (although it is supposed
  to be possible)

For Cygwin:
- Download Makefile.cygwin from http://freeimage.cvs.sourceforge.net/freeimage/FreeImage/
- Build the static lib (make -fMakefile.cygwin)
- Copy the libFreeImage.a and FreeImage.h in the extlib directory, renaming
  libfreeimage.a to libfreeimage-cygwin.a





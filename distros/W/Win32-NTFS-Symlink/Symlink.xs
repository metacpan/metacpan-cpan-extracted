#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "ntfs_symlink.h"
#include "ntfs_readlink.h"


MODULE = Win32::NTFS::Symlink		PACKAGE = Win32::NTFS::Symlink		

PROTOTYPES: DISABLE

int ntfs_junction(oldpath, newpath)
   const char * oldpath
   const char * newpath
   CODE:
      int ret = _ntfs_junction(oldpath, newpath);
      if (!ret) errno = GetLastError();
      RETVAL = ret;
   OUTPUT:
      RETVAL

int ntfs_symlink(oldpath, newpath)
   const char * oldpath
   const char * newpath
   CODE:
      int ret = _ntfs_symlink(oldpath, newpath);
      if (!ret) errno = GetLastError();
      RETVAL = ret;
   OUTPUT:
      RETVAL

char * ntfs_readlink(path)
   SV * path
   CODE:
      RETVAL = _ntfs_readlink(SvPV_nolen(path));
   OUTPUT:
      RETVAL

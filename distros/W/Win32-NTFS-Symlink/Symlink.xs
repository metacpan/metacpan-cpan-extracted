#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "ntfs_symlink.h"
#include "ntfs_readlink.h"


MODULE = Win32::NTFS::Symlink		PACKAGE = Win32::NTFS::Symlink		

PROTOTYPES: DISABLE

char * ntfs_readlink(path)
   SV * path
   PROTOTYPE: _
   CODE:
      RETVAL = _ntfs_readlink(SvPV_nolen(path));
   OUTPUT:
      RETVAL

int ntfs_symlink(oldpath, newpath)
   const char * oldpath
   const char * newpath
   PROTOTYPE: $$
   CODE:
      int ret = _ntfs_symlink(oldpath, newpath);
      if (!ret) errno = GetLastError();
      RETVAL = ret;
   OUTPUT:
      RETVAL

int ntfs_junction(oldpath, newpath)
   const char * oldpath
   const char * newpath
   PROTOTYPE: $$
   CODE:
      int ret = _ntfs_junction(oldpath, newpath);
      if (!ret) errno = GetLastError();
      RETVAL = ret;
   OUTPUT:
      RETVAL

BOOL is_ntfs_symlink(path)
   SV * path
   PROTOTYPE: _
   CODE:
      RETVAL = _is_ntfs_symlink(SvPV_nolen(path));
   OUTPUT:
      RETVAL

BOOL is_ntfs_junction(path)
   SV * path
   PROTOTYPE: _
   CODE:
      RETVAL = _is_ntfs_junction(SvPV_nolen(path));
   OUTPUT:
      RETVAL

DWORD ntfs_reparse_tag(path)
   SV * path
   PROTOTYPE: _
   CODE:
      RETVAL = _ntfs_reparse_tag(SvPV_nolen(path));
   OUTPUT:
      RETVAL

DWORD IO_REPARSE_TAG_MOUNT_POINT()
   CODE:
      RETVAL = IO_REPARSE_TAG_MOUNT_POINT;
   OUTPUT:
      RETVAL

DWORD IO_REPARSE_TAG_SYMLINK()
   CODE:
      RETVAL = IO_REPARSE_TAG_SYMLINK;
   OUTPUT:
      RETVAL

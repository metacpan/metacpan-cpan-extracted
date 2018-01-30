#include <windows.h>
#include <winioctl.h>
#include <stdio.h>
#include "ioctlcmd.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


BOOL get_ntfs_reparse_data(LinkPath, u)
   CONST TCHAR * LinkPath;
   union REPARSE_DATA_BUFFER_UNION * u;
{
   HANDLE hFile;
   DWORD returnedLength;
   
   int attr = GetFileAttributes(LinkPath);
   
   if (!(attr & FILE_ATTRIBUTE_REPARSE_POINT)) {
      return FALSE;
   }
   
   hFile = CreateFile(LinkPath, 0, 0, NULL, OPEN_EXISTING,
      FILE_FLAG_OPEN_REPARSE_POINT|FILE_FLAG_BACKUP_SEMANTICS, NULL);
   
   if (hFile == INVALID_HANDLE_VALUE) {
      return FALSE;
   }
   
   /* Get the link */
   if (!DeviceIoControl(hFile, FSCTL_GET_REPARSE_POINT, NULL,
      0, &u->iobuf, 1024, &returnedLength, NULL)) {
      
      CloseHandle(hFile);
      return FALSE;
   }
   
   CloseHandle(hFile);
   
   if (
      u->iobuf.ReparseTag != IO_REPARSE_TAG_MOUNT_POINT &&
      u->iobuf.ReparseTag != IO_REPARSE_TAG_SYMLINK
   ) {
      return FALSE;
   }
   
   return TRUE;
}

char * _ntfs_readlink(LinkPath)
   CONST TCHAR * LinkPath;
{
   union REPARSE_DATA_BUFFER_UNION u;
   
   if (!get_ntfs_reparse_data(LinkPath, &u)) {
      return NULL;
   }
   
   switch (u.iobuf.ReparseTag) {
      case IO_REPARSE_TAG_MOUNT_POINT: { // Junction
         char *retval;
         unsigned int len = u.iobuf.MountPointReparseBuffer.SubstituteNameLength;
         
         Newx(retval, len + sizeof(WCHAR), char);
         
         sprintf(retval, "%.*S",
            u.iobuf.MountPointReparseBuffer.SubstituteNameLength / sizeof(WCHAR),
            u.iobuf.MountPointReparseBuffer.PathBuffer + u.iobuf.MountPointReparseBuffer.SubstituteNameOffset / sizeof(WCHAR)
         );
         
         retval += 4;
         return retval;
      }
      case IO_REPARSE_TAG_SYMLINK: { // Symlink
         char *retval;
         unsigned int len = u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameLength;
         
         Newx(retval, len + sizeof(WCHAR), char);
         
         sprintf(retval, "%.*S",
            u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameLength / sizeof(WCHAR),
            u.iobuf.SymbolicLinkReparseBuffer.PathBuffer + u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameOffset / sizeof(WCHAR)
         );
         
         return retval;
      }
   }
   
   return NULL;
}

DWORD _ntfs_reparse_tag(LinkPath)
   CONST TCHAR * LinkPath;
{
   union REPARSE_DATA_BUFFER_UNION u;
   
   if (!get_ntfs_reparse_data(LinkPath, &u)) {
      return 0;
   }
   
   return u.iobuf.ReparseTag;
}

BOOL _is_ntfs_symlink(LinkPath)
   CONST TCHAR * LinkPath;
{
   return _ntfs_reparse_tag(LinkPath) == IO_REPARSE_TAG_SYMLINK;
}

BOOL _is_ntfs_junction(LinkPath)
   CONST TCHAR * LinkPath;
{
   return _ntfs_reparse_tag(LinkPath) == IO_REPARSE_TAG_MOUNT_POINT;
}

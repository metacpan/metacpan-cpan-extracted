#include <windows.h>
#include <winioctl.h>
#include <stdio.h>
#include "ioctlcmd.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


static int NativeReadReparse(LinkPath, u)
   CONST TCHAR * LinkPath;
   union REPARSE_DATA_BUFFER_UNION * u;
{
   HANDLE hFile;
   DWORD returnedLength;
   
   hFile = CreateFile(LinkPath, 0, 0, NULL, OPEN_EXISTING,
      FILE_FLAG_OPEN_REPARSE_POINT|FILE_FLAG_BACKUP_SEMANTICS, NULL);
   
   if (hFile == INVALID_HANDLE_VALUE) {
      return -1;
   }
   
   /* Get the link */
   if (!DeviceIoControl(hFile, FSCTL_GET_REPARSE_POINT, NULL,
      0, &u->iobuf, 1024, &returnedLength, NULL)) {
      
      CloseHandle(hFile);
      return -1;
   }
   
   CloseHandle(hFile);
   
   if (
      u->iobuf.ReparseTag != IO_REPARSE_TAG_MOUNT_POINT &&
      u->iobuf.ReparseTag != IO_REPARSE_TAG_SYMLINK
   ) {
      return -1;
   }
   
   return 0;
}


char * _ntfs_readlink(LinkPath)
   CONST TCHAR * LinkPath;
{
   union REPARSE_DATA_BUFFER_UNION u;
   int attr;
   
   attr = GetFileAttributes(LinkPath);
   
   if (!(attr & FILE_ATTRIBUTE_REPARSE_POINT)) {
      return NULL;
   }
   
   if (NativeReadReparse(LinkPath, &u)) {
      return NULL;
   }
   
   switch (u.iobuf.ReparseTag) {
      case IO_REPARSE_TAG_MOUNT_POINT: {
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
      case IO_REPARSE_TAG_SYMLINK: {
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


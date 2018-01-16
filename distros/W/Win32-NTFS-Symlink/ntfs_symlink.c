#include <windows.h>
#include <winioctl.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <io.h>
#include <fcntl.h>
#include <tchar.h>
#include "ioctlcmd.h"


#define SE_CREATE_SYMBOLIC_LINK_NAME      TEXT("SeCreateSymbolicLinkPrivilege")


BOOL AcquireSymlinkPriv(LPCTSTR lpLinkName)
{
   HANDLE hToken;
   TOKEN_PRIVILEGES TokenPriv;
   BOOL result;

   if (!LookupPrivilegeValue(NULL, SE_CREATE_SYMBOLIC_LINK_NAME, &TokenPriv.Privileges[0].Luid)) {
      //
      // Windows XP
      //
      return TRUE;
   }
   TokenPriv.PrivilegeCount = 1;
   TokenPriv.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

   if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, &hToken)) {
      return FALSE;
   }

   result = AdjustTokenPrivileges(hToken, FALSE, &TokenPriv, 0, NULL, NULL)
      && GetLastError() == ERROR_SUCCESS;
   CloseHandle(hToken);

   return result;
}

BOOL CreateSymlink(LPCTSTR lpLinkName, LPCTSTR lpTargetName, LPSECURITY_ATTRIBUTES lpsa)
{
   union REPARSE_DATA_BUFFER_UNION u;
   HANDLE hFile;
   TCHAR namebuf[MAX_PATH + 6];
   DWORD cb;
   DWORD attr;
   BOOL isDirectory;
   BOOL (WINAPI *deletefunc)();
   BOOL isRelative = FALSE;
   
   attr = GetFileAttributes(lpTargetName);
   if (attr == INVALID_FILE_ATTRIBUTES)
      return FALSE;
   isDirectory = attr & FILE_ATTRIBUTE_DIRECTORY;
   deletefunc = isDirectory ? RemoveDirectory : DeleteFile;
   
   if (!AcquireSymlinkPriv(lpLinkName))
      return FALSE;
   
   if (*lpTargetName == '\\' || isalpha(*lpTargetName) && lpTargetName[1] == ':') {
      BOOL rv;
      _tcscpy(namebuf, _T("\\?\?\\"));
      if (lpTargetName[0] == '\\' && lpTargetName[1] == '\\') {
         rv = GetFullPathName(lpTargetName, sizeof(namebuf) / sizeof(namebuf[0]) - 6, namebuf + 6, NULL);
         if (!rv) {
            return FALSE;
         }
         _tcsncpy(namebuf + 4, _T("UNC\\"), 4);
      } else {
         rv = GetFullPathName(lpTargetName, sizeof(namebuf) / sizeof(namebuf[0]) - 4, namebuf + 4, NULL);
         if (!rv) {
            return FALSE;
         }
      }
   } else {
      LPCWSTR p = (LPCWSTR)lpTargetName;
      LPWSTR q = (LPWSTR)namebuf, root = (LPWSTR)namebuf;
      while (*p) {
         for (;;) {
            if (p[0] == L'.' && p[1] == L'.' && p[2] == L'\\') {
               if (q > root) {
                  p += 3;
                  q--;
                  while (q > root && q[-1] != '\\')
                     q--;
               } else {
                  memcpy(q, p, 3 * sizeof(WCHAR));
                  q += 3;
                  root += 3;
                  p += 3;
               }
            } else if (p[0] == L'.' && p[1] == L'\\') {
               p += 2;
            } else {
               break;
            }
         }
         
         while (*p && (*q++ = *p++) != '\\')
            ;
      }
      *q = 0;
      isRelative = TRUE;
   }
   
   if (isDirectory) {
      if (!CreateDirectory(lpLinkName, lpsa))
         return FALSE;
      hFile = CreateFile(lpLinkName, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
         OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
   } else {
      hFile = CreateFile(lpLinkName, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, lpsa,
         CREATE_NEW, 0, NULL);
   }
   if (hFile == INVALID_HANDLE_VALUE) {
      return FALSE;
   }
   
   WCHAR lpTargetName_w[MAXIMUM_REPARSE_DATA_BUFFER_SIZE];
   WCHAR namebuf_w[MAXIMUM_REPARSE_DATA_BUFFER_SIZE];
#ifdef UNICODE
   lstrcpyn(lpTargetName_w, lpTargetName, MAXIMUM_REPARSE_DATA_BUFFER_SIZE);
   lstrcpyn(namebuf_w, namebuf, MAXIMUM_REPARSE_DATA_BUFFER_SIZE);
#else
   MultiByteToWideChar(CP_ACP, 0, lpTargetName, -1, lpTargetName_w, MAXIMUM_REPARSE_DATA_BUFFER_SIZE);
   MultiByteToWideChar(CP_ACP, 0, namebuf, -1, namebuf_w, MAXIMUM_REPARSE_DATA_BUFFER_SIZE);
#endif
   
   u.iobuf.ReparseTag = IO_REPARSE_TAG_SYMLINK;
   u.iobuf.Reserved = 0;
   
   
   u.iobuf.SymbolicLinkReparseBuffer.PrintNameOffset = 0;
   u.iobuf.SymbolicLinkReparseBuffer.PrintNameLength = wcslen(lpTargetName_w) * sizeof(WCHAR);
   
   memcpy((char *)u.iobuf.SymbolicLinkReparseBuffer.PathBuffer + u.iobuf.SymbolicLinkReparseBuffer.PrintNameOffset,
      lpTargetName_w, u.iobuf.SymbolicLinkReparseBuffer.PrintNameLength);;
   
   
   u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameOffset = u.iobuf.SymbolicLinkReparseBuffer.PrintNameOffset
      + u.iobuf.SymbolicLinkReparseBuffer.PrintNameLength;
   u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameLength = wcslen(namebuf_w) * sizeof(WCHAR);
   
   memcpy((char *)u.iobuf.SymbolicLinkReparseBuffer.PathBuffer + u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameOffset,
      namebuf_w, u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameLength);
   
   
   u.iobuf.SymbolicLinkReparseBuffer.Flags = isRelative ? 1 : 0;
   u.iobuf.ReparseDataLength =
      12 +
      u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameOffset +
      u.iobuf.SymbolicLinkReparseBuffer.SubstituteNameLength;
   cb = 8 + u.iobuf.ReparseDataLength;
   
   if (!DeviceIoControl(hFile, FSCTL_SET_REPARSE_POINT,
      &u.iobuf, cb, NULL, 0, &cb, NULL)) {
      
      CloseHandle(hFile);
      deletefunc(lpLinkName);
      return FALSE;
   }
   
   CloseHandle(hFile);
   return TRUE;
}

BOOL CreateJunction(LPCTSTR lpLinkName, LPCTSTR lpTargetName, LPSECURITY_ATTRIBUTES lpsa)
{
   union REPARSE_DATA_BUFFER_UNION u;
   HANDLE hFile;
   TCHAR namebuf[MAX_PATH + 4];
   DWORD cb;
   DWORD attr;
   BOOL isDirectory;
   BOOL (WINAPI *deletefunc)();

   attr = GetFileAttributes(lpTargetName);
   if (attr == INVALID_FILE_ATTRIBUTES)
      return FALSE;
   isDirectory = attr & FILE_ATTRIBUTE_DIRECTORY;
   deletefunc = isDirectory ? RemoveDirectory : DeleteFile;

   _tcscpy(namebuf, _T("\\?\?\\"));
   if (!GetFullPathName(lpTargetName, sizeof(namebuf) / sizeof(namebuf[0]) - 4, namebuf + 4, NULL)) {
      return FALSE;
   }
   
#ifdef UNICODE
   if (!lstrcpyn(u.iobuf.MountPointReparseBuffer.PathBuffer, namebuf, MAXIMUM_REPARSE_DATA_BUFFER_SIZE))
#else
   if (!MultiByteToWideChar(CP_ACP, 0, namebuf, -1,
         u.iobuf.MountPointReparseBuffer.PathBuffer, MAXIMUM_REPARSE_DATA_BUFFER_SIZE))
#endif
   {
      return FALSE;
   }
   
   if (isDirectory) {
      if (!CreateDirectory(lpLinkName, lpsa))
         return FALSE;
      hFile = CreateFile(lpLinkName, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
         OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
   } else {
      hFile = CreateFile(lpLinkName, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, lpsa,
         CREATE_NEW, 0, NULL);
   }
   if (hFile == INVALID_HANDLE_VALUE) {
      return FALSE;
   }

   u.iobuf.ReparseTag = IO_REPARSE_TAG_MOUNT_POINT;
   u.iobuf.Reserved = 0;
   u.iobuf.MountPointReparseBuffer.SubstituteNameOffset = 0;
   u.iobuf.MountPointReparseBuffer.SubstituteNameLength = wcslen(u.iobuf.MountPointReparseBuffer.PathBuffer) * 2;
   u.iobuf.MountPointReparseBuffer.PrintNameOffset = u.iobuf.MountPointReparseBuffer.SubstituteNameLength + 2;
   u.iobuf.MountPointReparseBuffer.PrintNameLength = 0;
   memset((char *)u.iobuf.MountPointReparseBuffer.PathBuffer + 
      u.iobuf.MountPointReparseBuffer.SubstituteNameLength, 0, 4);
   u.iobuf.ReparseDataLength =
      8 +
      u.iobuf.MountPointReparseBuffer.PrintNameOffset +
      u.iobuf.MountPointReparseBuffer.PrintNameLength + 2;
   cb = 8 + u.iobuf.ReparseDataLength;
   if (!DeviceIoControl(hFile, FSCTL_SET_REPARSE_POINT,
               &u.iobuf, cb, NULL, 0, &cb, NULL)) {
      
      CloseHandle(hFile);
      deletefunc(lpLinkName);
      return FALSE;
   }

   CloseHandle(hFile);
   return TRUE;
}


int _ntfs_junction(const char * oldpath, const char * newpath) {
   return CreateJunction(newpath, oldpath, NULL);
}

int _ntfs_symlink(const char * oldpath, const char * newpath) {
   return CreateSymlink(newpath, oldpath, NULL);
}

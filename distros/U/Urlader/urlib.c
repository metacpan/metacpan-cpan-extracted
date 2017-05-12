/*
 * Copyright (c) 2012 Marc Alexander Lehmann <schmorp@schmorp.de>
 * 
 * Redistribution and use in source and binary forms, with or without modifica-
 * tion, are permitted provided that the following conditions are met:
 * 
 *   1.  Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 * 
 *   2.  Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MER-
 * CHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPE-
 * CIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTH-
 * ERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU General Public License ("GPL") version 2 or any later version,
 * in which case the provisions of the GPL are applicable instead of
 * the above. If you wish to allow the use of your version of this file
 * only under the terms of the GPL and not to allow others to use your
 * version of this file under the BSD license, indicate your decision
 * by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL. If you do not delete the
 * provisions above, a recipient may use your version of this file under
 * either the BSD or the GPL.
 */

#include "urlib.h"

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef _WIN32

  #include <windows.h>
  //#include <winbase.h>
  #include <shlobj.h>
  #include <shlwapi.h>
  #include <wininet.h>

  static DWORD dword;

  #define u_handle HANDLE
  #define u_invalid_handle 0
  #define u_valid(handle) (!!handle)

  #define u_setenv(name,value) SetEnvironmentVariable (name, value)
  #define u_mkdir(path) !CreateDirectory (path, NULL)
  #define u_chdir(path) !SetCurrentDirectory (path)
  #define u_rename(fr,to) !MoveFile (fr, to)
  #define u_open(path) CreateFile (path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL)
  #define u_creat(path,exec) CreateFile (path, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL)
  #define u_creat(path,exec) CreateFile (path, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL)
  #define u_close(handle) CloseHandle (handle)
  #define u_append(path,add) PathAppend (path, add)
  #define u_write(handle,data,len) (WriteFile (handle, data, len, &dword, 0) ? dword : -1)

  #define u_fsync(handle) FlushFileBuffers (handle)
  #define u_sync()

  #define u_lockfile(path) CreateFile (path, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
  #define u_cloexec(handle)

#else

  #define _GNU_SOURCE 1
  #define _BSD_SOURCE 1
  // the above increases our chances of getting MAP_ANONYMOUS

  #include <sys/mman.h>
  #include <sys/types.h>
  #include <sys/stat.h>
  #include <unistd.h>
  #include <pwd.h>

  #if defined (MAP_ANON) && !defined (MAP_ANONYMOUS)
    #define MAP_ANONYMOUS MAP_ANON
  #endif

  #ifdef PATH_MAX
    #define MAX_PATH (PATH_MAX < 4096 ? 4096 : PATH_MAX)
  #else
    #define MAX_PATH 4096
  #endif

  #define u_handle int
  #define u_invalid_handle -1
  #define u_valid(fd) ((fd) >= 0)

  #define u_setenv(name,value) setenv (name, value, 1)
  #define u_mkdir(path) mkdir (path, 0777)
  #define u_chdir(path) chdir (path)
  #define u_rename(fr,to) rename (fr, to)
  #define u_open(path) open (path, O_RDONLY)
  #define u_creat(path,exec) open (path, O_WRONLY | O_CREAT | O_TRUNC, (exec) ? 0777 : 0666)
  #define u_close(handle) close (handle)
  #define u_append(path,add) strcat (strcat (path, "/"), add)
  #define u_write(handle,data,len) write (handle, data, len)

  // on a mostly idle system, a sync at the end is certainly faster, hope for the best
  #define u_fsync(handle)
  #define u_sync() sync ()

  #define u_lockfile(path) open (path, O_RDWR | O_CREAT, 0666)
  #define u_cloexec(handle) fcntl (handle, F_SETFD, FD_CLOEXEC)

#endif

#define u_16(ptr) (((ptr)[0] << 8) | (ptr)[1])
#define u_32(ptr) (((ptr)[0] << 24) | ((ptr)[1] << 16) | ((ptr)[2] << 8) | (ptr)[3])

static char currdir[MAX_PATH];
static char datadir[MAX_PATH];  // %AppData%/urlader
static char exe_dir[MAX_PATH];  // %AppData%/urlader/EXE_ID
static char execdir[MAX_PATH];  // %AppData%/urlader/EXE_ID/EXE_VER
static char exe_id[MAX_PATH];
static char exe_ver[MAX_PATH];

/////////////////////////////////////////////////////////////////////////////

static void
u_fatal (const char *msg)
{
#ifdef _WIN32
  MessageBox (0, msg, URLADER, 0);
#else
  write (2, URLADER ": ", sizeof (URLADER ": ") - 1);
  write (2, msg, strlen (msg));
  write (2, "\n", 1);
#endif

  _exit (1);
}

static void *
u_malloc (unsigned int size)
{
  void *addr;

  if (!size)
    return 0;

#ifdef _WIN32
  {
    HANDLE handle = CreateFileMapping (0, 0, PAGE_READWRITE, 0, size, NULL);

    addr = 0;
    if (handle)
      {
        addr = MapViewOfFile (handle, FILE_MAP_WRITE, 0, 0, size);
        CloseHandle (handle);
      }
  }
#elif defined (MAP_ANONYMOUS)
  addr = mmap (0, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);

  if (addr == (void *)-1)
    addr = 0;
#else
  addr = malloc (size);
#endif

  if (!addr)
    u_fatal ("memory allocation failure, aborting.");

  return addr;
}

static void
u_free (void *addr, unsigned int size)
{
  if (!addr)
    return;

#ifdef _WIN32
  UnmapViewOfFile (addr);
#elif defined (MAP_ANONYMOUS)
  munmap (addr, size);
#else
  free (addr);
#endif
}

static void *
u_realloc (void *addr, unsigned int old_size, unsigned int new_size)
{
  void *addr2 = u_malloc (new_size);
  memcpy (addr2, addr, (new_size < old_size ? new_size : old_size));
  u_free (addr, old_size);

  return addr2;
}

static void *
u_mmap (u_handle h, unsigned int size)
{
  void *addr;

#ifdef _WIN32
  HANDLE handle = CreateFileMapping (h, 0, PAGE_READONLY, 0, size, NULL);

  if (!handle)
    return 0;

  addr = MapViewOfFile (handle, FILE_MAP_READ, 0, 0, size);

  CloseHandle (handle);
#else
  addr = mmap (0, size, PROT_READ, MAP_SHARED, h, 0);

  if (addr == (void *)-1)
    addr = 0;
#endif

  return addr;
}

static void
u_munmap (void *addr, unsigned int len)
{
#ifdef _WIN32
  UnmapViewOfFile (addr);
#else
  munmap (addr, len);
#endif
}

/////////////////////////////////////////////////////////////////////////////

typedef struct
{
  char *addr;
  unsigned int used;
  unsigned int size;
} u_dynbuf;

static void *
u_dynbuf_append (u_dynbuf *dynbuf, void *data, unsigned int len)
{
  char *dest;

  if ((dynbuf->used += len) > dynbuf->size)
    {
      unsigned int new_size = dynbuf->size ? dynbuf->size * 2 : 4096;
      dynbuf->addr = u_realloc (dynbuf->addr, dynbuf->size, new_size);
      dynbuf->size = new_size;
    }

  dest = dynbuf->addr + dynbuf->used - len;

  if (data)
    memcpy (dest, data, len);

  return dest;
}

/////////////////////////////////////////////////////////////////////////////

static void
u_set_datadir (void)
{
#ifdef _WIN32
  if (SHGetFolderPath (0, CSIDL_APPDATA | CSIDL_FLAG_CREATE, NULL, SHGFP_TYPE_CURRENT, datadir) != S_OK)
    u_fatal ("unable to find application data directory");

  u_mkdir (datadir);
  u_append (datadir, URLADER);

#else
  char *home = getenv ("HOME");

  if (!home)
    {
      struct passwd *pw;

      if ((pw = getpwuid (getuid ())))
        home = pw->pw_dir;
      else
        home = "/tmp";
    }

  u_mkdir (home);
  //strcat (strcat (strcpy (datadir, home), "/."), URLADER);
  sprintf (datadir, "%s/.%s", home, URLADER);
#endif

  u_setenv ("URLADER_DATADIR", datadir);
}

static void
u_set_exe_info (void)
{
  strcpy (exe_dir, datadir);
  u_append (exe_dir, exe_id);
  u_mkdir (exe_dir);

  strcpy (execdir, exe_dir);
  u_append (execdir, "i-");
  strcat (execdir, exe_ver);

  u_setenv ("URLADER_EXECDIR", execdir);
  u_setenv ("URLADER_EXE_ID" , exe_id);
  u_setenv ("URLADER_EXE_DIR", exe_dir);
  u_setenv ("URLADER_EXE_VER", exe_ver);
}

/////////////////////////////////////////////////////////////////////////////

static u_handle
u_lock (const char *path, int excl, int dowait)
{
  u_handle h;

  h = u_lockfile (path);
  if (!u_valid (h))
    return h;

  u_cloexec (h);

  for (;;)
    {
      int success;

      // acquire the lock
#ifdef _WIN32
      OVERLAPPED ov = { 0 };

      success = LockFileEx (h,
                            (excl ? LOCKFILE_EXCLUSIVE_LOCK : 0)
                            | (dowait ? 0 : LOCKFILE_FAIL_IMMEDIATELY),
                            0,
                            1, 0,
                            &ov);
#else
      struct flock lck = { 0 };

      lck.l_type   = excl ? F_WRLCK : F_RDLCK;
      lck.l_whence = SEEK_SET;
      lck.l_len    = 1;

      success = !fcntl (h, dowait ? F_SETLKW : F_SETLK, &lck);
#endif

      if (!success)
        break;

      // we have the lock, now verify that the lockfile still exists

#ifdef _WIN32
      // apparently, we have to open the file to get its info :(
      {
        BY_HANDLE_FILE_INFORMATION s1, s2;
        u_handle h2 = u_lockfile (path);
        if (!u_valid (h))
          break;

        success = GetFileInformationByHandle (h, &s1)
                  && GetFileInformationByHandle (h2, &s2);

        u_close (h2);

        if (!success)
          break;

        success = s1.dwVolumeSerialNumber == s2.dwVolumeSerialNumber
               && s1.nFileIndexHigh       == s2.nFileIndexHigh
               && s1.nFileIndexLow        == s2.nFileIndexLow;
      }
#else
      struct stat s1, s2;

      if (fstat (h, &s1) || stat (path, &s2))
        break;

      success = s1.st_dev == s2.st_dev
             && s1.st_ino == s2.st_ino;
#endif

      if (success)
        return h; // lock successfully acquired

      // files differ, close and retry - should be very rare
      u_close (h);
    }

  // failure
  u_close (h);
  return u_invalid_handle;
}


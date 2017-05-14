/* zxutil.c  -  Utility functions
 * Copyright (c) 2012-2013 Synergetics (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distrtion prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxutil.c,v 1.53 2009-11-29 12:23:06 sampo Exp $
 *
 * 15.4.2006, created over Easter holiday --Sampo
 * 7.10.2008, added documentation --Sampo
 * 21.5.2010, added file copy --Sampo
 * 20.6.2011, improved error reporting to show cwd in vopen_fd_from_path() --Sampo
 * 17.8.2012, added socket specific utilities --Sampo
 * 21.6.2013, added wild card matcher --Sampo
 * 30.11.2013, fixed read 1 past end in base64_fancy_raw() found by valgrind --Sampo
 */

#include "platform.h"
#include "errmac.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <openssl/sha.h>
#include <zlib.h>

#ifdef MINGW
#include <windows.h>
#define fdtype HANDLE
#else
#define fdtype int
#include <sys/stat.h>
#include <sys/socket.h>
#endif

#include "zx.h"
#include "zxidconf.h"

#if !defined(USE_STDIO) && !defined(MINGW)
/* *** Static initialization of struct flock is suspect since man fcntl() documentation
 * does not guarantee ordering of the fields, or that they would be the first fields.
 * On Linux-2.4 and 2.6 as well as Solaris-8 the ordering is as follows, but this needs
 * to be checked on other platforms.
 *                       l_type,  l_whence, l_start, l_len */
struct flock errmac_rdlk = { F_RDLCK, SEEK_SET, 0, 1 };
struct flock errmac_wrlk = { F_WRLCK, SEEK_SET, 0, 1 };
struct flock errmac_unlk = { F_UNLCK, SEEK_SET, 0, 1 };
#endif

int close_file(fdtype fd, const char* logkey);

/*(-) Report brokenness of snprintf() */

/* Called by:  vname_from_path, write_all_fd_fmt, write_all_path_fmt, zx_alloc_vasprintf, zxbus_log_receipt, zxid_epr_path */
void platform_broken_snprintf(int n, const char* where, int maxlen, const char* fmt)
{
  perror("snprintf");
  D("Broken snprintf? Impossible to compute length of string. Be sure to `export LANG=C' if you get errors about multibyte characters. Length returned: %d. Caller: %s, maxlen=%d, format(%s)", n, where, maxlen, fmt);
}

/*() Generate formatted file name path. Returns length of path or 0 on failure. */

/* Called by: */
int vname_from_path(char* buf, int buf_len, const char* name_fmt, va_list ap)
{
  int len = vsnprintf(buf, buf_len, name_fmt, ap);
  buf[buf_len-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
  if (len < 0) {
    platform_broken_snprintf(len, __FUNCTION__, buf_len, name_fmt);
    return 0;
  }
  return len;
}

/*() Generate formatted file name path. Returns length of path or 0 on failure. */

/* Called by: */
int name_from_path(char* buf, int buf_len, const char* name_fmt, ...)
{
  int ret;
  va_list ap;
  va_start(ap, name_fmt);
  ret = vname_from_path(buf, buf_len, name_fmt, ap);
  va_end(ap);
  return ret;
}

/*() Open a file with formatted file name path. */

/* Called by: */
fdtype vopen_fd_from_path(int flags, int mode, const char* logkey, int reperr, const char* name_fmt, va_list ap)
{
  fdtype fd;
  char buf[ZXID_MAX_BUF];
  DD("vopen_fd_from_path(%d, %d, %s, %d, %s)", flags, mode, logkey, reperr, name_fmt);
  if (!vname_from_path(buf, sizeof(buf), name_fmt, ap))
    return BADFD;
#ifdef MINGW
  if (flags == O_RDONLY) {
    fd = openfile_ro(buf);
  } else {
    fd = zx_CreateFile(buf, MINGW_RW_PERM, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  }
#else
  fd = open(buf, flags, mode);
#endif
  if (fd == BADFD) {
#ifndef PATH_MAX
#define PATH_MAX ZXID_MAX_BUF
#endif
    char err_buf[PATH_MAX];
    if (reperr && logkey[0] != '-') {
      perror("open (vopen_fd_from_path)");
      ERR("%s: File(%s) not found errno=%d err(%s). flags=0x%x %o, euid=%d egid=%d cwd(%s)", logkey, buf, errno, STRERROR(errno), flags, flags, geteuid(), getegid(), getcwd(err_buf, sizeof(err_buf)));
    } else {
      D("%s: File(%s) not found errno=%d err(%s). flags=0x%x, euid=%d egid=%d cwd(%s)", logkey, buf, errno, STRERROR(errno), flags, geteuid(), getegid(), getcwd(err_buf, sizeof(err_buf)));
    }
    return BADFD;
  } else {
    D("%s: Opened(%s) flags=0x%x", logkey, buf, flags);
  }
  return fd;
}

/*() Open a file with formatted file name path. */

/* Called by: */
fdtype open_fd_from_path(int flags, int mode, const char* logkey, int reperr, const char* name_fmt, ...)
{
  va_list ap;
  fdtype fd;
  va_start(ap, name_fmt);
  fd = vopen_fd_from_path(flags, mode, logkey, reperr, name_fmt, ap);
  va_end(ap);
  return fd;
}

/*() Low level function that keeps on sucking from a file descriptor until
 * want is satisfied or error happens. May block (though usually will not if
 * the file is in cache or local disk) in process. Buffer p must have been allocated.
 * Return value reflects last got, i.e. what last read(2) system call returned.
 * got_all reflects the total number of bytes received. Does not nul terninate. */

/* Called by: */
int read_all_fd(fdtype fd, char* p, int want, int* got_all)
{
#ifdef USE_STDIO
  int got;
  got = fread(p, 1, want, (FILE*)fd);
  if (got_all) *got_all = got;
#elif defined(MINGW)
  DWORD got;
  HANDLE fdh = fd;
  if( fdh == 0 ) // stdin
      fdh = GetStdHandle(STD_INPUT_HANDLE);
  if (!ReadFile(fdh, p, want, &got, 0)) {
    return -1;
  }
  if (got_all) *got_all = got;
#else  /* The Unix way */
  int got = 0;
  if (got_all) *got_all = 0;
  while (want) {
    got = read(fd, p, want);
    if (got <= 0) break;  /* EOF, possibly premature */
    if (got_all)
      *got_all += got;
    p += got;
    want -= got;
  }
#endif
  return got;   /* N.B. This is the last got, not the total. Use got_all for total. */
}

/*() Read all data from a file at formatted file name path.
 *
 * maxlen:: Length of buffer
 * buf:: Result parameter. This buffer will be filled with data from the file. Caller allocates.
 * logkey:: Logging key to help debugging
 * reperr:: Whether to report an error (flag: 0=do not report)
 * name_fmt:: Format string for building the file name
 * return:: actual total length. The buffer will always be nul terminated. Zero on failure. */

/* Called by: */
int read_all(int maxlen, char* buf, const char* logkey, int reperr, const char* name_fmt, ...)
{
  va_list ap;
  int gotall;
  fdtype fd;
  va_start(ap, name_fmt);
  fd = vopen_fd_from_path(O_RDONLY, 0, logkey, reperr, name_fmt, ap);
  va_end(ap);
  if (fd == BADFD) { if (buf) buf[0] = 0; return 0; }
  if (read_all_fd(fd, buf, maxlen, &gotall) == -1) {
    perror("Trouble reading.");
    D("read error lk(%s)", logkey);
    close_file(fd, logkey);
    buf[maxlen-1] = 0;
    return 0;
  }
  close_file(fd, logkey);
  buf[MIN(gotall, maxlen-1)] = 0;  /* nul terminate */
  return gotall;
}

/* Called by: */
int get_file_size(fdtype fd)
{
#ifdef MINGW
  return GetFileSize(fd,0);
#else
  struct stat st;
  fstat(fd, &st);
  return st.st_size;
#endif
}

/*() Read all data from a file at formatted file name path, allocating
 * the buffer as needed using ZX allocator.
 *
 * c:: ZX allocation context
 * logkey:: Logging key to help debugging
 * reperr:: Whether to report an error (flag)
 * lenp:: Optional result parameter returning the length of the data read. Null ok.
 * name_fmt:: Format string for building file name
 * return:: The data or null on fail. The buffer will always be nul terminated. */

/* Called by: */
char* read_all_alloc(struct zx_ctx* c, const char* logkey, int reperr, int* lenp, const char* name_fmt, ...)
{
  va_list ap;
  char* buf;
  int len, gotall;
  fdtype fd;
  va_start(ap, name_fmt);
  fd = vopen_fd_from_path(O_RDONLY, 0, logkey, reperr, name_fmt, ap);
  va_end(ap);
  if (fd == BADFD) {
    if (lenp)
      *lenp = 0;
    c->zx_errno = errno;
    return 0;
  }

  len = get_file_size(fd);
  buf = ZX_ALLOC(c, len+1);
  
  if (read_all_fd(fd, buf, len, &gotall) == -1) {
    perror("Trouble reading.");
    c->zx_errno = errno;
    D("read error lk(%s)", logkey);
    close_file(fd, logkey);
    buf[len] = 0;
    if (lenp)
      *lenp = 0;
    return 0;
  }
  close_file(fd, logkey);
  buf[MIN(gotall, len)] = 0;  /* nul terminate */
  if (lenp)
    *lenp = gotall;
  c->zx_errno = 0;
  return buf;
}

/*() Read all data from a file at formatted file name path, allocating
 * the buffer as needed using malloc(3).
 *
 * logkey:: Logging key to help debugging
 * reperr:: Whether to report an error (flag)
 * lenp:: Optional result parameter returning the length of the data read. Null ok.
 * name_fmt:: Format string for building file name
 * return:: The data or null on fail. The buffer will always be nul terminated. */

/* Called by:  zxbus_load_ch_subs */
char* read_all_malloc(const char* logkey, int reperr, int* lenp, const char* name_fmt, ...)
{
  va_list ap;
  char* buf;
  int len, gotall;
  fdtype fd;
  va_start(ap, name_fmt);
  fd = vopen_fd_from_path(O_RDONLY, 0, logkey, reperr, name_fmt, ap);
  va_end(ap);
  if (fd == BADFD) {
    if (lenp)
      *lenp = 0;
    return 0;
  }

  len = get_file_size(fd);
  ZMALLOCN(buf, len+1);
  
  if (read_all_fd(fd, buf, len, &gotall) == -1) {
    perror("Trouble reading.");
    D("read error lk(%s)", logkey);
    close_file(fd, logkey);
    buf[len] = 0;
    if (lenp)
      *lenp = 0;
    return 0;
  }
  close_file(fd, logkey);
  buf[MIN(gotall, len)] = 0;  /* nul terminate */
  if (lenp)
    *lenp = gotall;
  return buf;
}

/*() Low level function that keeps writing data to a file descriptor until
 * everything is written. It may block in the process - infact it WILL block
 * until the job is done or error has happened.
 * return:: 0 on error, 1 on success (amount written will always be equal to pending). */

/* Called by: */
int write_all_fd(fdtype fd, const char* p, int pending)
{
#ifdef MINGW
  DWORD wrote;
  if ((fd == BADFD) || !pending || !p) {
    ERR("Bad fd(%x) or no data p=%p pending=%d", fd, p, pending);
    return 0;
  }
  if (!WriteFile(fd, p, pending, &wrote, 0))
    return 0;
  FlushFileBuffers(fd);
  DD("write_all_fd(%x, `%.*s', %d) wrote=%d\n", fd, pending, p, pending, wrote);
#else
  int wrote;
  if ((fd == BADFD) || !pending || !p) {
    ERR("Bad fd(%x) or no data p=%p pending=%d", fd, p, pending);
    return 0;
  }
  while (pending) {
    wrote = write(fd, (char*)p, pending);
    if (wrote <= 0) return 0;
    pending -= wrote;
    p += wrote;
  }
#endif
  return 1;
}

/*() Low level function that keeps writing data to a socket until
 * everything is written. It may block in the process. (On Unix
 * it would be possible to use write_all_fd(), but using send(2)
 * works on all platforms that support sockets.) */

/* Called by:  zxbus_close, zxbus_send_cmdf x6 */
int send_all_socket(fdtype fd, const char* p, int pending)
{
  int wrote;
  if ((fd == BADFD) || !pending || !p) return 0;
  while (pending) {
    wrote = send((SOCKET)fd, (char*)p, pending, 0);
    if (wrote <= 0) return 0;
    pending -= wrote;
    p += wrote;
  }
  return 1;
}

/*() Write all formatted data to a file descriptor. The buf is used
 * for formatting data. The path_fmt can have up to two %s specifiers,
 * which will be satisfied by prepath and postpath.
 *
 * fd::       File descriptor, already open for writing
 * logkey::   Used for debug prints and error messages
 * maxlen::   Size of the buffer
 * buf::      Buffer for rendering the formatted data
 * data_fmt:: Format string for the data to be written. Following arguments satisfy the format string. Overall the data length is constrained to maxlen. Caller needs to allocate/provide buffer sufficient to satisfy the data_fmt.
 * Returns:: 1 on success, 0 on fail. */

/* Called by: */
int write_all_fd_fmt(fdtype fd, const char* logkey, int maxlen, char* buf, const char* data_fmt, ...)
{
  int len;
  va_list ap;
  va_start(ap, data_fmt);
  len = vsnprintf(buf, maxlen-1, data_fmt, ap); /* Format data into buf */
  buf[maxlen-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
  va_end(ap);
  if (len < 0) {
    platform_broken_snprintf(len, __FUNCTION__, maxlen-1, data_fmt);
    len = 0;
  }
  if (write_all_fd(fd, buf, len) == -1) {
    perror("Trouble writing");
    close_file(fd, logkey);
    return 0;
  }
  return 1;
}

/*() Write all data to a file at the formatted path. The buf is used
 * for formatting data. The path_fmt can have up to two %s specifiers,
 * which will be satisfied by prepath and postpath.
 *
 * logkey::   Used for debug prints and error messages
 * maxlen::   Size of the buffer
 * buf::      Buffer for rendering the formatted data
 * path_fmt:: Format string for filesystem path to the file
 * prepath::  Argument to satisfy first %s in path_fmt
 * postpath:: Argument to satisfy second %s in path_fmt
 * data_fmt:: Format string for the data to be written. Following arguments satisfy the format string. Overall the data length is constrained to maxlen. Caller needs to allocate/provide buffer sufficient to satisfy the data_fmt.
 * Returns:: 1 on success, 0 on fail. */

/* Called by: */
int write_all_path_fmt(const char* logkey, int maxlen, char* buf, const char* path_fmt, const char* prepath, const char* postpath, const char* data_fmt, ...)
{
  int len;
  va_list ap;
  fdtype fd;
  fd = open_fd_from_path(O_CREAT | O_RDWR | O_TRUNC, 0666, logkey, 1, path_fmt, prepath, postpath);
  DD("write_all_path_fmt(%s, %x)", logkey, fd);
  if (fd == BADFD) return 0;
  
  va_start(ap, data_fmt);
  len = vsnprintf(buf, maxlen-1, data_fmt, ap); /* Format data into buf */
  buf[maxlen-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
  va_end(ap);
  if (len < 0) {
    platform_broken_snprintf(len, __FUNCTION__, maxlen-1, data_fmt);
    len = 0;
  }
  if (write_all_fd(fd, buf, len) == -1) {
    perror("Trouble writing");
    close_file(fd, logkey);
    return 0;
  }
  close_file(fd, logkey);
  return 1;
}

/*() Write all data to a file at the formatted path. The buf is used
 * for formatting data. The path_fmt can have up to two %s specifiers,
 * which will be satisfied by prepath and postpath.
 *
 * logkey::   Used for debug prints and error messages
 * path_fmt:: Format string for filesystem path to the file
 * prepath::  Argument to satisfy first %s in path_fmt
 * postpath:: Argument to satisfy second %s in path_fmt
 * len::      Length of the data, pass -1 to use strlen(data).
 * data::     Data to be written. No formatting on data is performed.
 * Returns:: 1 on success, 0 on fail. */

/* Called by: */
int write_all_path(const char* logkey, const char* path_fmt, const char* prepath, const char* postpath, int len, const char* data)
{
  fdtype fd;
  fd = open_fd_from_path(O_CREAT | O_RDWR | O_TRUNC, 0666, logkey, 1, path_fmt, prepath, postpath);
  DD("write_all_path(%s, %x)", logkey, fd);
  if (fd == BADFD) return 0;
  if (len == -1)
    len = strlen(data);
  if (write_all_fd(fd, data, len) == -1) {
    perror("Trouble writing");
    close_file(fd, logkey);
    return 0;
  }
  close_file(fd, logkey);
  return 1;
}

#define WRITE_FAIL_MSG "Check that all directories exist, permissions allow writing, and disk is not full or that ulimit(1) is not too low."

/*() Write or append all data to a file at the already formatted path.
 * The file is opened for appending, data written, and file closed
 * (flushing the data).  Will perform file locking to ensure
 * consistent results. Will create the file if needed, but will not
 * create parent directories. Up to two items of data can
 * be written or appended. If you have only one item, supply null
 * for the second. For overwrite behaviour supply seeky=SEEK_SET and
 * flag=O_TRUNC (the seek offset is always 0). For append behaviour
 * supply seeky=SEEK_END and flag=O_APPEND.
 * Returns 1 on success, 0 on err */

/* Called by: */
int write2_or_append_lock_c_path(const char* c_path,
				 int len1, const char* data1,
				 int len2, const char* data2,
				 const char* which,  /* log key */
				 int seeky, /* SEEK_END,0 O_APPEND == append */
				 int flag)  /* SEEK_SET,0 O_TRUNC  == overwr */
{
  fdtype fd;
  if (!c_path)
    return 0;
#ifdef MINGW
  fd = zx_CreateFile(c_path, MINGW_RW_PERM, /*0*/FILE_SHARE_READ | FILE_SHARE_WRITE /* 0  means no sharing allowed */, 0 /* security */,
		  (flag & O_APPEND) ? OPEN_ALWAYS : CREATE_ALWAYS /* truncates, too? */,
		  FILE_ATTRIBUTE_NORMAL, 0);
  if (fd == BADFD) goto badopen;
  if (flag & O_APPEND) {
    MS_LONG zero = 0;
    SetFilePointer(fd, 0, &zero, FILE_END);  /* seek to end */
  }

  if (len1 && data1) {
    if (!write_all_fd(fd, data1, len1)) {
      ERR("%s: Writing to file `%s' %d bytes failed: %d %s; euid=%d egid=%d. %s", which, c_path, len1, errno, STRERROR(errno), geteuid(), getegid(), WRITE_FAIL_MSG);
      close_file(fd, which);
      return 0;
    }
  }
  if (len2 && data2) {
    if (!write_all_fd(fd, data2, len2)) {
      ERR("%s: Writing to file `%s' %d bytes failed: %d %s; euid=%d egid=%d. %s", which, c_path, len2, errno, STRERROR(errno), geteuid(), getegid(), WRITE_FAIL_MSG);
      close_file(fd, which);
      return 0;
    }
  }
#else
  fd = open(c_path, O_RDWR | O_CREAT | flag, 0666);
  if (fd == BADFD) goto badopen;
  if (FLOCKEX(fd)  == -1) {
    ERR("%s: Locking exclusively file `%s' failed: %d %s; euid=%d egid=%d. Check that the file system supports locking. %s", which, c_path, errno, STRERROR(errno), geteuid(), getegid(), WRITE_FAIL_MSG);
    close_file(fd, which);
    return 0;
  }
  
  lseek(fd,0,seeky);
  if (len1 && data1) {
    if (!write_all_fd(fd, data1, len1)) {
      ERR("%s: Writing to file(%s) fd=%d %d bytes starting(%.*s) failed: %d %s; euid=%d egid=%d. %s", which, c_path, fd, len1, MIN(len1, 4), data1, errno, STRERROR(errno), geteuid(), getegid(), WRITE_FAIL_MSG);
      FUNLOCK(fd);
      close_file(fd, which);
      return 0;
    }
  }

  if (len2 && data2) {
    if (!write_all_fd(fd, data2, len2)) {
      ERR("%s: Writing to file(%s) %d bytes starting(%.*s) failed: %d %s; euid=%d egid=%d. %s", which, c_path, len2, MIN(len2, 4), data2, errno, STRERROR(errno), geteuid(), getegid(), WRITE_FAIL_MSG);
      FUNLOCK(fd);
      close_file(fd, which);
      return 0;
    }
  }
  
  FUNLOCK(fd);
#endif
  if (close_file(fd, which) < 0) {
    ERR("%s: closing file(%s) after write failed: %d %s; euid=%d egid=%d. %s Could be NFS problem.", which, c_path, errno, STRERROR(errno), geteuid(), getegid(), WRITE_FAIL_MSG);
    return 0;
  }
  return 1;
badopen:
  ERR("%s: Opening file(%s) for writing failed: %d %s; euid=%d egid=%d. %s", which, c_path, errno, STRERROR(errno), geteuid(), getegid(), WRITE_FAIL_MSG);
  return 0;
}

/*() Close a file rather than just any file descriptor and check error
 * return. It is important that it is a file since on MS Windows closing
 * files is different from closing descriptors. Checking error return
 * from close is important because in NFS environments you may not know
 * that your write has failed until you actually attempt to close the file. */

/* Called by: */
int close_file(fdtype fd, const char* logkey)
{
  int res = closefile(fd);
  if (res) {
    perror("close file");
    ERR("%s: Errors on closing file, after write, could indicate write back cache problems, especially under NFS. Ignoring the error.  euid=%d egid=%d", logkey, geteuid(), getegid());
  }
  return res;
}

/*() Copy contents of a file, i.e. first read a file, then write a file.
 * Many places use copy_file() as opposed to hardlinking file because
 * actually copying file is more portable. Even in Unix, hardlinking
 * can be troublesome if the from and to are on different file systems. */

/* Called by:  covimp_test x5, zxid_cp_usr_eprs2ses */
int copy_file(const char* from, const char* to, const char* logkey, int may_link)
{
  fdtype fd_from;
  fdtype fd_to;
  int ret, pending, wrote;
  char buf[4096];
  char* p;

#ifndef MINGW
  switch (may_link) {
  case 2:
    ret = symlink(from, to);
    goto linkrest;
  case 1:
    ret = link(from, to);
linkrest:
    if (ret) {
      perror("{hard|sym}link");
      ERR("%s: Error linking(%d) from(%s) to(%s) euid=%d egid=%d", logkey, may_link, from, to, geteuid(), getegid());
      return -1;
    }
    return 0;
  }
#endif
  fd_from = openfile_ro(from);
  if (fd_from == BADFD) {
      perror("openfile_ro");
      ERR("%s: Error opening from(%s) euid=%d egid=%d", logkey, from, geteuid(), getegid());
      return -1;
  }
#ifdef MINGW
  fd_to = zx_CreateFile(to, MINGW_RW_PERM, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
#else
  fd_to = open(to, O_RDWR | O_CREAT, 0666);
#endif
  if (fd_to == BADFD) {
      perror("openfile_rw");
      ERR("%s: Error opening to(%s) euid=%d egid=%d", logkey, to, geteuid(), getegid());
      return -1;
  }

#ifdef USE_STDIO
  while (1) {
    pending = fread(buf, 1, sizeof(buf), (FILE*)fd_from);
    if (pending <= 0) break; /* EOF */
    p = buf;
    while (pending) {
      wrote = fwrite(p, 1, pending, fd_to);
      if (wrote <= 0) return 0;
      pending -= wrote;
      p += wrote;
    }
  }
#elif defined(MINGW)
  while (1) {
    DWORD wrot;
    DWORD pend;
    if (!ReadFile(fd_from, buf, sizeof(buf), &pend, 0))
      return -1;
    if (!pend)
      break;
    p = buf;
    while (pend) {
      if (!WriteFile(fd_to, p, pend, &wrot, 0))
	return -1;
      pend -= wrot;
      p += wrot;
    }
  }
  FlushFileBuffers(fd_to);
#else
  while (1) {
    pending = read(fd_from, buf, sizeof(buf));
    if (!pending) break; /* EOF */
    p = buf;
    while (pending) {
      wrote = write(fd_to, p, pending);
      if (wrote <= 0) return 0;
      pending -= wrote;
      p += wrote;
    }
  }
#endif

  close_file(fd_to, logkey);
  closefile(fd_from);
  return 0;
}

/*() Output a hexdump to stderr. Used for debugging purposes. */

/* Called by: */
int hexdump(const char* msg, const void* data, const void* lim, int max)
{
  int i;
  const char* p = (const char*)data;
  const char* lim16;
  char buf[3*16+1+1+16+1];
  if (!msg)
    msg = "";
  if ((const char*)lim-p > max)
    lim = p + max;
  
  buf[sizeof(buf)-1] = '\0';
  
  while (p<(const char*)lim) {
    memset(buf, ' ', sizeof(buf)-1);
    lim16 = MIN(p+16, (const char*)lim);
    for (i = 0; p<lim16; ++p, ++i) {
      buf[3*i+(i>7?1:0)]   = HEX_DIGIT((*p >> 4) & 0x0f);
      buf[3*i+1+(i>7?1:0)] = HEX_DIGIT(*p & 0x0f);
      switch (*p) {
      case '\0': buf[3*16+1+1+i] = '~'; break;
      case '\r': buf[3*16+1+1+i] = '^'; break;
      case '\n': buf[3*16+1+1+i] = '\\'; break;
      case '~':  buf[3*16+1+1+i] = '^'; break;
      case '\\': buf[3*16+1+1+i] = '^'; break;
      case 0x7f: buf[3*16+1+1+i] = '^'; break;
	//case ']':  buf[3*16+1+1+i] = '^'; break;
      default:
	buf[3*16+1+1+i] = *p < ' ' ? '^' : *p;
      }
    }
    fprintf(stderr, "%s %s\n", msg, buf);
    /*fprintf(stderr, "%s %s  ;;%*s\n", msg, buf, lim-data, data);*/
  }
  return 0;
}

/* Called by:  covimp_test x2, zxsig_validate x6 */
int hexdmp(const char* msg, const void* p, int len, int max) {
  return hexdump(msg, p, p+len, max);
}

/*
 *  Base 64 encoding and decoding in its canonical and URL safe forms.
 */

/* Base64 std, RFC3548, defines also safe base64, the form that does not need URL encoding
 * and is also otherwise more filesystem safe (i.e. / is not used). The pw_basis
 * is used by md5_crypt() and other password hashing schemes. */

#define MAX_LINE  76 /* size of encoded lines */
const char std_basis_64[64]  = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; /*=*/
const char safe_basis_64[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"; /*=*/
const char pw_basis_64[64]   = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

/*() Raw version. Can use any encoding table and arbitrary line length.
 * Known bug: line_len is not fully respected on last line - it can
 * be up to 3 characters longer than specified due to padding.
 * Every three bytes (from alphabet of 256) of input map to
 * four chars (from alphabet of 64) of output. See also SIMPLE_BASE64_LEN().
 *
 * > +Base64url Encoding+ URL- and filename-safe Base64 encoding
 * > described in RFC 4648 [RFC4648], Section 5, with the (non URL-
 * > safe) '=' padding characters may be omitted, as permitted by Section 3.2.
 *
 * p::        input
 * len::      length of input
 * r::        Output buffer. Will not be NUL terminated.
 * basis_64:: The 64 character alphabet to be used, such as ~std_basis_64~ or ~safe_basis_64~
 * line_len:: Length of each line. 76 is customary. Or use very large value to
 *     avoid any line breaks
 * eol_len::  Length of End-of-Line string.
 * eol::      End-of-Line string, inserted every line_len.
 * eq_pad::   Padding character, usually equals (=). If nul (0), no padding is added.
 * return::   Pointer one past last byte written in r. This function never fails. */

/* Called by:  sha_safe_base64 */
char* base64_fancy_raw(const char* p, int len, /* input and its length */
		       char* r,                /* Output buffer. Will not be NUL terminated. */
		       const char* basis_64,   /* 64 character alphabet to be used, see above */
		       int line_len,           /* Length of each line. 76 is customary. */
		       int eol_len,            /* Length of End-of-Line string. */
		       const char* eol,        /* End-of-Line string, inserted every line_len. */
		       char eq_pad)            /* Padding character, usually equals (=) */
{
  unsigned char c1,c2,c3;
  int chunk;
  line_len /= 4;
  
  for (chunk=0; len > 2; len -= 3, ++chunk) {
    if ((chunk == line_len) && eol_len) {  /* 19 chunks (3x19=57chars) per line */
      memcpy(r, eol, eol_len);
      r += eol_len;
      chunk = 0;
    }
    c1 = *p++;
    c2 = *p++;  // *** len==1 causes bug if no null term
    *r++ = basis_64[c1>>2];
    *r++ = basis_64[((c1 & 0x0003)<< 4) | ((c2 & 0x00f0) >> 4)];
    
    c3 = *p++;
    *r++ = basis_64[((c2 & 0x000f) << 2) | ((c3 & 0x00c0) >> 6)];
    *r++ = basis_64[c3 & 0x003f];
  }
  
  /* Post processing to handle the last line, which is often incomplete. */
  
  switch (len) {
  case 2:
    c1 = *p++;
    c2 = *p;
    *r++ = basis_64[c1>>2];
    *r++ = basis_64[((c1 & 0x0003)<< 4) | ((c2 & 0x00f0) >> 4)];
    *r++ = basis_64[(c2 & 0x000f) << 2];
    if (eq_pad)
      *r++ = eq_pad;
    break;
  case 1:
    c1 = *p;
    *r++ = basis_64[c1>>2];
    *r++ = basis_64[(c1 & 0x0003)<< 4];
    if (eq_pad) {
      *r++ = eq_pad;
      *r++ = eq_pad;
    }
    break;
  case 0:
    break;  /* no padding needed */
  default:
    NEVERNEVER("Corrupt len=%d", len);
  }
  if (eol_len) {
    memcpy(r, eol, eol_len);
    r += eol_len;
  }
  return r;
}

#define XX      255     /* illegal base64 char */
#define Eq      254     /* padding */
#define INVALID XX

unsigned char zx_std_index_64[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,62, Eq,62,XX,63,  /* `+' ',' '-' `/' */
    52,53,54,55, 56,57,58,59, 60,61,XX,XX, XX,Eq,XX,XX,  /* `=' */
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,63,  /* `_' */
    XX,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,XX, XX,XX,XX,XX,

    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX
};

/*() Raw version. Can use any decoding table (such as zx_std_index_64).
 * Assumes reciving buffer r has been allocated
 * to correct length. Is able to perform the operation in place, i.e. p and r
 * can point to the same buffer. Both canonical and safe base64 are handled.
 * If string contains URL encoding (as it might for + or =) it is automatically
 * unraveled as well. This is useful for SAMLRequest field in Redirect signing.
 * Returns pointer one past last output char written. Does not nul terminate.
 * Never fails. See also SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(). */

/* Called by: */
char* unbase64_raw(const char* p, const char* lim, char* r, const unsigned char* index_64)
{
  int i;
  unsigned char c[4];
  unsigned char uc;
  
  while (p < lim) {
    i = 0;
    do {
      if (*p == '%' && p+2 < lim && IS_HEX(p[1]) && IS_HEX(p[2])) {
	/* Percent sign from URL encoding: decode */
	uc = index_64[(HEX(p[1]) << 4) | HEX(p[2])];
	p += 3;
      } else
	uc = index_64[(int)*p++];
      if (uc != INVALID)
	c[i++] = uc;
      
      if (p == lim) {
	if (i < 4) {
	  /*if (i) ERR("Premature end of base64 data. (incomplete base64 input) i=%d", i);*/
	  if (i < 2) return r;
	  if (i == 2) c[2] = Eq;
	  c[3] = Eq;
	}
	break;
      }
    } while (i < 4);
    
    if (c[0] == Eq || c[1] == Eq) {
      ERR("Premature end of base64 data. (incomplete base64 input) c0(%x)", c[0]);
      break;
    }
    /* D("c0=%d,c1=%d,c2=%d,c3=%d\n", c[0],c[1],c[2],c[3]); */
    
    *r++ = (c[0] << 2) | ((c[1] & 0x30) >> 4);
    if (c[2] == Eq) break;
    *r++ = ((c[1] & 0x0f) << 4) | ((c[2] & 0x3c) >> 2);
    if (c[3] == Eq) break;
    *r++ = ((c[2] & 0x03) << 6) | c[3];
  }
  return r;
}

/*() The out_buf should be 28 chars in length. The buffer is not automatically nul termianated.
 * There will be 27 characters of payload, plus one padding character "." (which
 * caller can overwrite with nul, if you like).
 *
 * out_buf:: Buffer where result will be written. It must be 28 characters long and already allocated. The buffer will not be null terminated.
 * len:: Length of data. -2=use strlen(data)
 * data:: Data to be digested
 * return:: Pointer one past last character written (not nul terminated) */

/* Called by: */
char* sha1_safe_base64(char* out_buf, int len, const char* data)
{
  char sha1[20];
  if (len == -2)
    len = strlen(data);
  SHA1((unsigned char*)data, len, (unsigned char*)sha1);
  return base64_fancy_raw(sha1, 20, out_buf, safe_basis_64, 1<<31, 0, 0, '.');
}

/*(-) zlib integration internal */
/* Called by: */
voidpf zx_zlib_zalloc(void* opaque, uInt items, uInt size)
{
  DD("HERE5 len= %d x %d = %d", items, size, items*size);
  return ZX_ALLOC(opaque, items*size);
}

/*(-) zlib integration internal */
/* Called by: */
void zx_zlib_zfree(void* opaque, voidpf addr)
{
  ZX_FREE(opaque, addr);
}

/*() Compress data using zlib-deflate (RFC1951). The deflated data will be in new
 * buffer, which is returned. out_len will indicate the length
 * of the comressed data. Since the compressed data will be
 * binary, there is no provision for nul termination. Caveat: RFC1951 is not same a gzip. */

/* Called by:  zxid_deflate_safe_b64_raw, zxid_map_val_ss, zxid_saml2_redir_enc, zxlog_write_line */
char* zx_zlib_raw_deflate(struct zx_ctx* c, int in_len, const char* in, int* out_len)
{
  int ret, dlen;
  char* out;
  z_stream z;
  *out_len = 0;
  ZERO(&z, sizeof(z_stream));
  z.zalloc = zx_zlib_zalloc;
  z.zfree = zx_zlib_zfree;
  z.opaque = c;
  z.next_in = (unsigned char*)in;
  z.avail_in = in_len;
  ret = deflateInit2(&z, 9, Z_DEFLATED, -15, 9, Z_DEFAULT_STRATEGY);
  if (ret != Z_OK) {
    ERR("zlib deflateInit2 error: %d", ret);
    return 0;
  }
  
  dlen = in_len + (in_len >> 8) + 12;  /* worst case: orig_size * 1.001 + 12, see also compressBound() */
  out = ZX_ALLOC(c, dlen);
  z.next_out = (unsigned char*)out;
  z.avail_out = dlen;
  
  ret = deflate(&z, Z_FINISH);
  if (ret != Z_STREAM_END) {
    deflateEnd(&z);
    ERR("zlib deflate error: %d", ret);
    return 0;
  }
  *out_len = z.total_out;
  deflateEnd(&z);
  return out;
}

/*() Helper to compress and ascii armour the original request.
 * c:: zx context for allocation
 * len:: Length of string to process, or -2 to use strlen()
 * s:: String to compress and ascii armour
 * return:: string that has been allocated from zx_ctx. Caller frees. */

/* Called by:  zxid_deflate_safe_b64, zxid_mk_oauth_az_req, zxid_parse_cgi, zxid_simple_show_idp_sel */
char* zxid_deflate_safe_b64_raw(struct zx_ctx* c, int len, const char* s)
{
  int zlen;
  char* zbuf;
  char* p;
  char* b64 = 0;
  if (len == -2)
    len = strlen(s);
  D("z input(%.*s) len=%d", len, s, len);
  zbuf = zx_zlib_raw_deflate(c, len, s, &zlen);
  if (!zbuf)
    return 0;
  
  len = SIMPLE_BASE64_LEN(zlen);
  DD("zbuf(%.*s) zlen=%d len=%d", zlen, zbuf, zlen, len);
  b64 = ZX_ALLOC(c, len+1);
  p = base64_fancy_raw(zbuf, zlen, b64, safe_basis_64, 1<<31, 0, 0, '=');
  *p = 0;
  ZX_FREE(c, zbuf);
  return b64;  /* so it can be encoded as hidden form field "ar". */
}

/*() Helper to compress and ascii armour the original request. */

/* Called by:  zxid_simple_idp_show_an x2 */
char* zxid_deflate_safe_b64(struct zx_ctx* c, struct zx_str* ss)
{
  char* b64 = zxid_deflate_safe_b64_raw(c, ss->len, ss->s);
  zx_str_free(c, ss);
  return b64;  /* so it can be encoded as hidden form field "ar". */
}

/*() Decompress zlib-deflate (RFC1951) compressed data. The decompressed data will
 * be in a newly allocated buffer which is returned. The length
 * of the decompressed data is returned via out_len. The buffer
 * will always be at least byte one longer than indicated by out_len - this
 * should allow safe nul termination (but the decompressed data itself
 * may contain any number of nuls). Caveat: RFC1951 is not same a gzip. */

/* Called by:  decode, zxid_decode_redir_or_post, zxid_unbase64_inflate, zxlog_zsig_verify_print */
char* zx_zlib_raw_inflate(struct zx_ctx* c, int in_len, const char* in, int* out_len)
{
  int ret, dlen, iter = 30;
  char* out;
  char* old_out;
  z_stream z;
  *out_len = 0;
  ZERO(&z, sizeof(z_stream));
  z.zalloc = zx_zlib_zalloc;
  z.zfree = zx_zlib_zfree;
  z.opaque = c;
  z.next_in = (unsigned char*)in;
  z.avail_in = in_len;
  
  dlen = in_len << 3;  /* guess inflated size: orig_size * 8 */
  out = ZX_ALLOC(c, dlen+1);
  z.next_out = (unsigned char*)out;
  z.avail_out = dlen;
  
  ret = inflateInit2(&z, -15);
  if (ret != Z_OK) {
    ERR("zlib inflateInit failed with error code %d", ret);
    return 0;
  }
  
#if 0
  ret = inflate(&z, Z_FINISH);
  if (ret != Z_STREAM_END) {
    inflateEnd(&z);
    ERR("zlib inflate failed with error code %d. Most probably the input data is empty, corrupt, or not in zlib format.", ret);
    return 0;
  }
#else
  while (--iter) {  /* Make sure we can never be caught in infinite loop */
    ret = inflate(&z, Z_SYNC_FLUSH);
    switch (ret) {
    case Z_STREAM_END: goto done;
    case Z_OK:  /* avail_out should be 0 now. Time to grow the buffer. */
      ret = z.next_out - (Bytef*)out;
      dlen += dlen;
      old_out = out;
      out = ZX_ALLOC(c, dlen+1);
      memcpy(out, old_out, ret);
      z.next_out = (unsigned char*)out + ret;
      z.avail_out = dlen - ret;
      break;
    default:
      inflateEnd(&z);
      ERR("zlib inflate failed with error code %d. Most probably the input data is empty, corrupt, or not in RFC1951 (zlib deflate) format. A common error is incomplete data (due to read(2) not returing all data on first iteration) resulting a failed detection of uncompressed data (the detection looks for '<' in beginning and '>' in end of base64 decoded data - often the latter is missing in incomplete data). iter=%d in_len=%d dlen=%d", ret, iter, in_len, dlen);
      D("out80(%.*s)", 80, out);  /* just in case something was successfully deflated */
      return 0;
    }
  }
#endif
 done:
  *out_len = z.total_out;
  inflateEnd(&z);
  return out;
}

/*() Decode safe base64 and then decompress the content. The decompressed
 * result may be binary, but will be nul terminated anyway. out_len
 * will not reflect such termination. Supply in_len==-2 to use strlen(3).
 * The return value is newly allocated string (caller frees). Inplace inflate
 * does not make sense as the result is nearly always bigger than the input. */

/* Called by:  pool2apache, zxid_decode_ssoreq, zxid_map_bangbang, zxid_map_val_ss, zxid_show_protected_content_setcookie */
char* zxid_unbase64_inflate(struct zx_ctx* c, int in_len, const char* in, int* out_len)
{
  int len;
  char* buf;
  char* p;
  if (!in) {
    D("NULL input %d", in_len);
    return 0;
  }
  if (in_len == -2)
    in_len = strlen(in);
  if (!out_len)
    out_len = &len;
  D("in(%s) len=%d pessimistic_len=%d", in, in_len, SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(in_len));
  buf = ZX_ALLOC(c, SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(in_len));
  p = unbase64_raw(in, in + in_len, buf, zx_std_index_64);
  p = zx_zlib_raw_inflate(c, p-buf, buf, out_len);
  ZX_FREE(c, buf);
  if (!p)
    return 0;
  p[*out_len] = 0;
  return p;
}

/*() Eliminate characters in zap from the string s, in place, i.e. shifting the
 * tail of the string left. The string is modified in place. */

char* zx_zap_inplace_raw(char* s, const char* zap)
{
  char* ret = s;
  char* p;
  // *** scanning in reverse would be (marginally) more efficient
  int n;
  while (*s) {
    n = strcspn(s, zap);
    s += n;
    if (!*s)
      break;
    n = strspn(s, zap);
    for (p = s; *(p+n); ++p)
      *p = *(p+n);
    *p = 0;
    //memmove(s, s+n);  // whish strmove existed
  }
  return ret;
}

#if 1
/* N.B. Many other Liberty implementations expect nearly everything to be URL encoded. */
#define URL_BAD(x) (!AZaz_09_(x))
#else
#define URL_BAD(x) (((x)<=' ')||((x)>=0x7f)||ONE_OF_4((x),'+','%','=','&')||ONE_OF_2((x),'#','?'))
#endif

/*() Compute length of the URL encoded string. The encoding is done
 * to characters listed in URL_BAD() macro in zxutil.c.
 * return: Required buffer size, including nul term. Subtract 1 for string length. */

/* Called by: */
int zx_url_encode_len(int in_len, const char* in)
{
  int n;
  const char* lim;
  /* scan through to see how many escape expansions are needed */
  lim = in + in_len;
  for (n = 0; in < lim; ++in)
    if (URL_BAD(*in)) ++n;
  return n+n+in_len+1;   /* nul-terminated length */
}

/*() URL encode input into output. The encoding is done to
 * characters listed in URL_BAD() macro in zxutil.c. The output must already
 * have been allocated to correct length, which can be obtained from
 * zx_url_encode_len() function. zx_url_encode() is higher
 * level function that does just that. Raw version does not nul terminate.
 * Returns pointer one past last byte written. */

/* Called by: */
char* zx_url_encode_raw(int in_len, const char* in, char* out)
{
  const char* lim;
  for (lim = in+in_len; in < lim; ++in)
    if (URL_BAD(*in)) {
      *out++ = '%';
      *out++ = HEX_DIGIT((*in >> 4) & 0x0f);
      *out++ = HEX_DIGIT(*in & 0x0f);
    } else
      *out++ = *in;
  return out;
}

/*() Perform URL encoding on buffer. New output buffer is allocated.
 * The low level work is performed by zx_url_encode_raw().
 * Returns the length of the output string (not including nul termination,
 * but nul termination is actually allocated and made).
 *
 * N.B. For zx_url_decode() operation see URL_DECODE() macro in errmac.h */

/* Called by: */
char* zx_url_encode(struct zx_ctx* c, int in_len, const char* in, int* out_len)
{
  int olen;
  char* out;
  char* p;
  if (in_len == -2)
    in_len = strlen(in);
  olen = zx_url_encode_len(in_len, in) + 1;
  out = ZX_ALLOC(c, olen);
  p = zx_url_encode_raw(in_len, in, out);
  *p = '\0';
  if (out_len)
    *out_len = p - out;
  return out;
}

/*() Base64 encode and URL encode concatenation "uid:password" as in HTTP basic authentication */

char* zx_mk_basic_auth_b64(struct zx_ctx* c, const char* uid, const char* pw)
{
  char* p;
  char* q;
  char* b64;
  int len;

  p = zx_alloc_sprintf(c, &len, "%s:%s", uid, pw);
  b64 = ZX_ALLOC(c, SIMPLE_BASE64_LEN(len));
  q = base64_fancy_raw(p, len, b64, std_basis_64, 10000000, 0, 0, '=');
  ZX_FREE(c, p);
  p = zx_url_encode(c, q-b64, b64, 0);
  ZX_FREE(c, b64);
  return p;
}

/*() Parse one fragment of a query string (QUERY_STRING querystring).
 *
 * qs:: The query string to parse, modified in place to insert nul terms and URL decode.
 * name:: result parameter pointing to the name analyzed from qs, nul terminated
 * val:: result parameter pointing to the value analyzed from qs, nul terminated
 * url_decode_val_flag:: 0 = do not decode, 1 = always decode, 2 = decode except SAMLResponse
 * return:: pointer to beginning of the next name (one past the ampersand ending the
 *     previous val, i.e. the nul, unless URL decode made the val shorter)
 *     or to the end of string nul (if nul, outer parsing
 *     loop should terminate). Any error causes null pointer to be returned.
 *
 * Typical invocation pattern:
 *
 *   while (qs && *qs) {
 *     qs = zxid_qs_nv_scan(qs, &name, &val);
 *     ... switch on name ...
 *   }
 *
 * Query string separation character can be traditional ampersand or conf file
 * oriented newline. Comment lines starting with # are also handled.
 */

/* Called by:  hrxml_parse_cgi, zxid_add_qs2ses, zxid_load_obl_list, zxid_parse_cgi, zxid_parse_conf_raw */
char* zxid_qs_nv_scan(char* qs, char** name, char** val, int url_decode_val_flag)
{
  char* p;
  char* q;
  *name = *val = 0;
  if (!qs)
    return 0;

again:  
  qs += strspn(qs, "& \n\t\r");                  /* Skip over & or &&, or line end */
  if (!*qs)
    return 0;
    
  if (*qs == '#') {                              /* Comment line */
scan_end:
    qs += strcspn(qs, "&\n\r"); /* Scan until '&' or end of line */
    goto again;
  }

  if (*qs == '[')                                /* Section header line, treat like comment */
    goto scan_end;

  for (; *qs == '&'; ++qs) ;                     /* Skip over & or && */
  if (!*qs)
    return 0;
  
  *name = qs;
  qs = strchr(qs, '=');                          /* Scan name (until '=') */
  if (!qs)
    return 0;
  if (qs == *name)                               /* Key was an empty string: skip it */
    goto scan_end;
  for (; *name < qs && **name <= ' '; ++*name) ; /* Skip over initial whitespace before name */
  p = q = *name;
  URL_DECODE(p, q, qs);                          /* In place mod of name */
  *p = 0;                                        /* Nul-term *name */

  *val = ++qs;                /* Skip over =    */
  qs += strcspn(qs, "&\n\r"); /*   and scan val */

  switch (url_decode_val_flag) {
  case 0: p = qs; break;      /* 0 = do not decode */
  case 2:                     /* 1 = decode except SAMLResponse etc. */
    /* SAMLRequest and Response MUST NOT be URL decoded as the URL encoding
     * is needed for redirect binding signature validation. See also unbase64_raw()
     * for how these fields are URL decoded at later stage. */
    if (!((*name)[0] != 'S' && (*name)[0] != 'R'
	  || strcmp(*name, "SAMLRequest") && strcmp(*name, "SAMLResponse")
	  && strcmp(*name, "SigAlg") && strcmp(*name, "Signature")
	  && strcmp(*name, "RelayState"))) {
      p = qs;
      break;
    }
    /* fall thru */
  case 1:                     /* 1 = always decode */
    p = q = *val;
    URL_DECODE(p, q, qs);
    break;
  default: NEVERNEVER("unsupported case(%d)", url_decode_val_flag);
  }
  if (*qs)
    ++qs;
  *p = 0;
  return qs;
}

const unsigned char const * hex_trans      = (unsigned char*)"0123456789abcdef";
const unsigned char const * ykmodhex_trans = (unsigned char*)"cbdefghijklnrtuv";  /* as of libyubikey-1.5 */

/*() Especially useful as yubikey_modhex_decode() replacement.
 * Supports inplace conversion. Does not nul terminate. */

/* Called by:  authn_user x2, covimp_test, zx_yubikey_authn x2 */
char* zx_hexdec(char* dst, char* src, int src_len, const unsigned char* trans)
{
  const unsigned char* hi;
  const unsigned char* lo;
  for (; src_len>1; src_len-=2, ++dst, src+=2) {
    hi = (const unsigned char*)strchr((char*)trans, src[0]);
    if (!hi) {
      ERR("Bad hi character(%x) in hex string using trans(%s) len left=%d src(%.*s)", src[0], trans, src_len, src_len, src);
      hi = trans;
    }
    lo = (const unsigned char*)strchr((char*)trans, src[1]);
    if (!lo) {
      ERR("Bad lo character(%x) in hex string using trans(%s) len left=%d src(%.*s)", src[1], trans, src_len, src_len, src);
      lo = trans;
    }
    *dst = ((hi-trans) << 4) | (lo-trans);
  }
  return dst;
}

static short zx_mmdd[] = { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 };

/*() Map from tm struct back to seconds since Unix epoch. The tm struct
 * is assumed to be on GMT. This function is needed because mktime(3) is
 * tainted by local time zone brain damage. This function aims to be
 * equivalent to GNU extension timegm(3) (see Linux man pages). */

/* Called by:  zx_date_time_to_secs */
static int zx_timegm(const struct tm* t)
{
  int x;
  int aa = t->tm_year - 70, mon = t->tm_mon, dd = t->tm_mday;
  int hh = t->tm_hour, mm = t->tm_min, ss = t->tm_sec;

  if (ss > 60) {
    mm += ss/60;
    ss %= 60;
  }
  if (mm > 60) {
    hh += mm/60;
    mm %= 60;
  }
  if (hh > 60) {
    dd += hh/60;
    hh %= 60;
  }
  if (mon > 12) {
    aa += mon/12;
    mon %= 12;
  }
  while (dd > zx_mmdd[mon+1]) {
    if (mon == 1 && LEAP(aa+1970))
      --dd;
    dd -= zx_mmdd[mon];
    ++mon;
    if (mon > 11) {
      mon = 0;
      ++aa;
    }
  }
  if (aa < 0)
    return -1;

  x  = aa * 365 + (aa + 1) / 4; /* Account for leap year every 4 years */

  if ((aa -= 131) >= 0) {
    aa /= 100;
    x -= (aa >> 2) * 3 + 1;
    if ((aa &= 3) == 3)
      --aa;
    x -= aa;
  }
  
  x += zx_mmdd[mon] + dd-1 + (LEAP(t->tm_year+1900) && mon>1?1:0);
  x *= 24; /* Days to hours */
  return ((x + hh) * 60 + mm) * 60 + ss;
}

/*() Convert a date-time format timestamp into seconds since Unix epoch.
 * Format is as follows
 *   01234567890123456789
 *   yyyy-MM-ddThh:mm:ssZ
 *
 * See also zxid_date_time() for inverse. */

/* Called by:  timegm_tester, zxid_parse_invite x2, zxid_sp_sso_finalize, zxid_sso_issue_a7n, zxid_sso_issue_jwt, zxid_timestamp_chk, zxid_validate_cond x2 */
int zx_date_time_to_secs(const char* dt)
{
  struct tm t;
  ZERO(&t, sizeof(t));
  sscanf(dt, "%d-%d-%dT%d:%d:%dZ",
	 &t.tm_year, &t.tm_mon, &t.tm_mday,
	 &t.tm_hour, &t.tm_min, &t.tm_sec);
  t.tm_year -= 1900;
  --t.tm_mon;
  return zx_timegm(&t);
}

/*() Extract simple scalar string value of a json key using string
 * matching, rather than actually parsing JSON.
 * return: pointer to the value, but this is in the original hay buffer and is
 *     not nul terminated. You need to look at len for the length of the string.
 * N.B. The key specification MUST include the quotes, e.g. "\"yourkey\""
 */

const char* zx_json_extract_raw(const char* hay, const char* key, int* len)
{
  const char* s;
  const char* p = strstr(hay, key);
  if (!p) {
    D("key(%s) not found in json(%s)", key, hay);
    return 0;
  }
  p += strlen(key);
  p += strspn(p, " \t\r\n");
  if (*p != ':') {
    D("key(%s) found in json(%s) but subsequent colon (:) not found. Did you forget the double quotes around the key? p(%s)", key, hay, p);
    return 0;
  }
  ++p;
  p += strspn(p, " \t\r\n");
  if (*p != '"')
    return 0;
  s = ++p;
  p = strchr(p, '"');  /* *** Escaped double quotes not correctly considered. */
  if (len)
    *len = p-s;
  return s;
}

/*() Extract simple scalar string from JSON document. Return newly allocated memory.
 * N.B. The key specification MUST include the quotes, e.g. "\"yourkey\""
 */

char* zx_json_extract_dup(struct zx_ctx* c, const char* hay, const char* key)
{
  int len;
  const char* p = zx_json_extract_raw(hay, key, &len);
  if (!p)
    return 0;
  return zx_dup_len_cstr(c, len, p);
}

/*() Extract simple scalar integer from JSON document.
 * N.B. The key specification MUST include the quotes, e.g. "\"yourkey\""
 */

int zx_json_extract_int(const char* hay, const char* key)
{
  int i;
  const char* p = strstr(hay, key);
  if (!p) {
    D("key(%s) not found in json(%s)", key, hay);
    return 0;
  }
  p += strlen(key);
  p += strspn(p, " \t\r\n");
  if (*p != ':') {
    D("key(%s) found in json(%s) but subsequent colon (:) not found. Did you forget the double quotes around the key? p(%s)", key, hay, p);
    return 0;
  }
  ++p;
  p += strspn(p, " \t\r\n");
  sscanf(p, "%i", &i);
  return i;
}

/*() Extract query string parameter without really parsing the query string.
 * return: pointer to the value, but this is in the original hay buffer and is
 *     not nul terminated. You need to look at len for the length of the string.
 * N.B. The key specification MUST include the equals sign, e.g. "yourkey="
 */

const char* zx_qs_extract_raw(const char* hay, const char* key, int* len)
{
  const char* s;
  const char* p = strstr(hay, key);
  if (!p) {
    D("key(%s) not found in qs(%s)", key, hay);
    return 0;
  }
  p += strlen(key);
  if (len) {
    s = strchr(p, '&');
    if (!s)
      *len = strlen(p);
    else
      *len = s-p;
  }
  return p;
}

/*() Extract simple scalar string from query string. Return newly allocated memory.
 * N.B. The key specification MUST include the quotes, e.g. "\"yourkey\""
 */

char* zx_qs_extract_dup(struct zx_ctx* c, const char* hay, const char* key)
{
  int len;
  const char* p = zx_qs_extract_raw(hay, key, &len);
  if (!p)
    return 0;
  return zx_dup_len_cstr(c, len, p);
}

/* EOF  --  zxutil.c */

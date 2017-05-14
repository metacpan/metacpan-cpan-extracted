/* aklog.c  -  Application Black (K) Box Logging Library
 *
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is unpublished proprietary source code. All dissemination
 * prohibited. Contains trade secrets. NO WARRANTY. See file COPYING.
 * Special grant: aktab.h may be used with zxid open source project under
 * same licensing terms as zxid itself.
 *
 * Application Black (K) Box provides a lock-less logging facility
 * using a circular memory buffer per thread. These buffers will
 * hold recent history of application and will be part of any core
 * dump that may happen, facilitating interpretation of such core. */

#include "errmac.h"
#include "akbox.h"

#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifndef MINGW
#include <sys/utsname.h>
#endif
#include <fcntl.h>
#include <unistd.h>

#ifdef LINUX
#include <sys/sysinfo.h>
#endif
#ifdef SUNOS
#include <sys/systeminfo.h>
#endif
#ifdef AIXOS
#include <sys/systemcfg.h>
#include <nlist.h>
#endif

AKEXPORT pthread_key_t akmem_pool_key;

/* AFR master block is statically intialized so its always available. */
struct ak_master_rec ak_master =
  { AK_MASTER_STAMP, 0, AK_LOGKEY_MARK, AK_ENDIAN_MARK, __DATE__, __TIME__, PTHREAD_MUTEX_INITIALIZER, 0, 0, 0, 0 };

/* pthread specific data key for locating the logging buffer */
pthread_key_t ak_buf_key;

/* Called by:  main, zxbusd_main */
void ak_init(char* argv0) {
  char buf[8192];
  int x,n=0;
  fdtype f;
#ifdef MINGW
  pthread_mutex_init(&ak_master.ak_mutex, 0);
#endif
#ifdef LINUX
  mallopt(M_MMAP_MAX, 0); /* Disable use of mmap(2) in malloc(3) as mmaps do not appear in core. */
#endif

  ak_master.first_sec = time(0); /** Not used in linux, maybe in a future ...*/
  /** Adding Machine INFO **/
#ifndef INTERIXOS 
#ifndef MINGW  
  struct utsname os_info;
  int res;
#ifdef LINUX
  struct sysinfo system_info;
  char mem[100];
  int copied_before = 0;
  FILE * file;
  /** Getting proc info from /proc/cpuinfo **/
  if ((file = fopen("/proc/cpuinfo","rt")) != NULL ) { /** /proc/cpuinfo found **/
    while (!feof(file)){
      fgets(mem,100,file);
      if (!strncmp(mem,"processor",9))
         ak_master.ProcNum++;
      if (!copied_before && !strncmp(mem,"model name",10)){
         int j = 10;
         copied_before = 1; /** Only one copy needed **/
         while ((mem[j] != ':') && (j<100)) j++;
         j+=2; /** jump over ':' and next space **/
         strncpy(ak_master.ModelName, &mem[j], MIN(strlen(&mem[j])+1, INFO_BUF));
         ak_master.ModelName[INFO_BUF]='\0'; 
      }
    }
    fclose(file);
  }

  res = sysinfo(&system_info); 
  ak_master.MaxMem = system_info.totalram;
  ak_master.MaxSwap = system_info.totalswap;
  ak_master.MemUnit = system_info.mem_unit;
#endif
#ifdef SUNOS /** SOLARIS **/
  long resp;
  resp = sysinfo (SI_ARCHITECTURE, ak_master.ModelName, INFO_BUF);
  ak_master.ProcNum = sysconf(_SC_NPROCESSORS_ONLN);
  ak_master.first_tick = gethrtime();
#endif
#ifdef AIXOS
  struct nlist info;
  int fd;
  info.n_name = "_system_configuration";
  fd = open("/dev/kmem",O_RDONLY);
  knlist(&info,1,sizeof(struct nlist));
  lseek(fd,info.n_value,0);
  read(fd,&_system_configuration,sizeof(_system_configuration));
  ak_master.ProcNum  = _system_configuration.ncpus;
  ak_master.MaxMem   = _system_configuration.physmem;
  ak_master.ProcImp  = _system_configuration.implementation;
  ak_master.ProcArch = _system_configuration.architecture;
  ak_master.ProcVer  = _system_configuration.version;
  ak_master.Width    = _system_configuration.width;
  close(fd);
#endif /* AIXOS */
  ak_master.HostId = gethostid();
  res = uname(&os_info);
  if (!res){ /** Success **/
    strncpy(ak_master.nodename, os_info.nodename, MIN(strlen(os_info.nodename)+1 ,INFO_BUF));
    strncpy(ak_master.sysname, os_info.sysname, MIN(strlen(os_info.sysname)+1 ,INFO_BUF));
    strncpy(ak_master.os_release, os_info.release, MIN(strlen(os_info.release)+1 ,INFO_BUF));
    strncpy(ak_master.os_version, os_info.version, MIN(strlen(os_info.version)+1 ,INFO_BUF));
    strncpy(ak_master.machine, os_info.machine, MIN(strlen(os_info.machine)+1 ,INFO_BUF));
  }
#endif /* MINGW */
#endif /* INTERIXOS */

/** Machine info for windows **/
#ifdef MINGW
  SYSTEM_INFO system_info;
  DWORD dwVersion = 0;
  DWORD dwMajorVersion = 0;
  DWORD dwMinorVersion = 0;
  DWORD dwBuild = 0;
  LPDWORD siz = INFO_BUF;

  QueryPerformanceFrequency(&ak_master.ticksPerSecond);
  QueryPerformanceCounter(&ak_master.first_tick);

  GetSystemInfo(&system_info);
  ak_master.ProcNum      = system_info.dwNumberOfProcessors;
  ak_master.ProcArch     = system_info.wProcessorArchitecture;
  ak_master.ProcType     = system_info.dwProcessorType;
  ak_master.ProcLevel    = system_info.wProcessorLevel;
  ak_master.ProcRev      = system_info.wProcessorRevision;
  
  dwVersion = GetVersion();
  /** Get os version **/
  dwMajorVersion = (DWORD)(LOBYTE(LOWORD(dwVersion)));
  dwMinorVersion = (DWORD)(HIBYTE(LOWORD(dwVersion)));
  if (dwVersion < 0x80000000)              
     dwBuild = (DWORD)(HIWORD(dwVersion));
  sprintf(ak_master.os_version, "%d.%d (%d)", dwMajorVersion, dwMinorVersion, dwBuild);
  GetComputerName( &ak_master.sysname, &siz);
 
#endif

  /** End of machine info **/

  pthread_key_create(&ak_buf_key, 0 /* no destructor */ );
  ak_master.self = &ak_master;   /* helps to compute (or double check) offset */
  /*fprintf(stderr, "logkey(%s)\n", STRNULLCHK(ak_master.lkmark));*/

#ifndef  INTERIXOS 
#ifndef MINGW  
  /* Copy the executable file into heap memory so it will be included in an eventual
   * core that may be generated. */
  realpath(argv0, ak_master.realpath);
  ak_master.realpath[sizeof(ak_master.realpath)-1] = 0;
  f = open(argv0, O_RDONLY);
  if (f < 0) goto bad;
  x = fstat(f, &ak_master.binary_st);
  if (x < 0) goto bad;
  ak_master.binary = malloc(ak_master.binary_st.st_size);
  if (!ak_master.binary) goto bad;
  while (n < ak_master.binary_st.st_size) {
    x = read(f, ak_master.binary + n, sizeof(buf));
    if (x <= 0) goto badio;
    n += x;
  }
  closefile(f);
#endif
#endif
#ifdef MINGW
  DWORD pathlength;
  char argv0exe[strlen(argv0) + 4 + 1];
  if (strstr(argv0, ".exe") == 0) {
    /* the extension was not passed; not 100% certain... */
    strcpy(argv0exe, argv0);
    strcpy(argv0exe + strlen(argv0), ".exe");
    argv0exe[strlen(argv0) + 5] = '\0';
  } else {
    strcpy(argv0exe, argv0);
  }
  if ((pathlength = GetFullPathName(argv0exe, sizeof(ak_master.realpath), ak_master.realpath, 0)) == 0) {
    errno = GetLastError();
    goto bad;
  }
  ak_master.realpath[pathlength] = 0;
  f = openfile_ro(argv0exe);
  if (f == BADFD) goto bad;
  // need to change this to GetFileSizeEx()
  DWORD filesize;
  if ((filesize = GetFileSize(f, 0)) == INVALID_FILE_SIZE) {
    errno = GetLastError();
    goto bad;
  }
  ak_master.binary_st.st_size = filesize;
  ak_master.binary = malloc(ak_master.binary_st.st_size);
  if (!ak_master.binary) goto bad;
  DWORD got;
  int howMuchToRead = 0;
  while (n < ak_master.binary_st.st_size) {
    howMuchToRead = (sizeof(buf) > ak_master.binary_st.st_size - n) ? (ak_master.binary_st.st_size - n) : sizeof(buf);
    x = ReadFile(f, ak_master.binary + n, howMuchToRead, &got, 0);
    if (x == 0) {
      errno = GetLastError();
      goto badio;
    }
    n += got;
  }
  closefile(f);
#endif /* MINGW */
#ifdef AFRDBG
  fprintf(stderr,"Recorded executable: %s (%d).\n", argv0, (int)ak_master.binary_st.st_size);
#endif
  return;
 badio:
  closefile(f);
  fprintf(stderr,"Read error on executable: %s (%x/%x/%x). This installation is not supported.\n",
	  argv0, x, n, (int)ak_master.binary_st.st_size);
  return;
 bad:
  fprintf(stderr,"Failed to read executable: %s. This installation is not supported.\n", argv0);
}

/* Creates AFR buffer explicitly. You may want to call this directly if you need
 * a special buffer other than thread buffer. */

/* Called by:  ak_add_thread */
struct ak_buf* ak_add_buf(int afr_buffer_size, int flags, char* comment)
{
  struct ak_buf* buf = 0;
  
  pthread_mutex_lock(&ak_master.ak_mutex);
  if (ak_master.n_threads >= AK_MAX_BUFS) goto out;
  
  buf = malloc(sizeof(struct ak_buf)+afr_buffer_size);
  if (!buf) goto out;
  if (flags == 2){
    ak_master.st_buf = buf;
    sprintf(buf->stamp, AK_ST_BUFFER_STAMP);
    buf->mem_pool = 0;
  }else{
    ak_master.bufs[ak_master.n_threads] = buf;
    sprintf(buf->stamp, AK_BUFFER_STAMP, ++ak_master.n_threads);
    buf->mem_pool = (unsigned int)pthread_getspecific(akmem_pool_key);
  }
  buf->p = buf->start;
  buf->lim = (struct ak_ts*)(((char*)(buf->start)) + afr_buffer_size);
  buf->flags = flags;
  buf->wrap_around = 0;
  if (comment)
    strncpy(buf->comment, comment, AK_COMMENT_SIZE);
  else
    buf->comment[0] = 0;
  
 out:
  pthread_mutex_unlock(&ak_master.ak_mutex);
  return buf;
}

/* ak_add_thread() should be called from each thread that wishes to
 * use AFR facilities. It allocates and registers the buffer and records
 * a pointer to it as thread specific data. If this thread specific data is not
 * found, then AFR logging functions do nothing, but are still safe to call.
 * The prefix forms an important part of the buffer comment. The first letter
 * of buffer comment is used as thread role prefix in displays. E.g:
 *   T=regular worket thread, W=witer thread, F=fe polling thead, f=fe consumer thread,
 *   B=backend poller thread, b=backedn consumer thread, S=shuffler, s=static, etc. */

/* Called by:  main, opt, thread_loop */
void ak_add_thread(int afr_buffer_size, char* prefix, int flags)
{
  struct ak_buf* buf;
  buf = ak_add_buf(afr_buffer_size, flags, 0);
  if (!buf) return;
  buf->tid = pthread_self();
  pthread_setspecific(ak_buf_key, buf);
  sprintf(buf->comment, "%s%d", prefix, buf->tid);
}

/* Allocate a new AFR line from the circular buffer */

/* Called by:  ak_buf_err_va, ak_buf_ini, ak_buf_io, ak_buf_mem, ak_buf_pdu, ak_buf_pdu_arg, ak_buf_pdu_lite, ak_buf_report, ak_buf_run, ak_buf_trace, ak_buf_ts, ak_buf_tsa */
struct ak_ts* ak_new_line(struct ak_buf* buf, int func, int line, char* logkey)
{
  struct ak_ts* p;
  if (!buf) return 0;
  p = buf->p;
  ++buf->p;
  if (buf->p > buf->lim) {    /* did it fit? */
    p = buf->p = buf->start;  /* wrap around */
    ++buf->p;
    ++buf->wrap_around;
  }
  p->h.func = func;
  p->h.line = line;
  p->h.logkey = logkey;
#ifdef MINGW
  QueryPerformanceCounter(&p->h.tv);
#endif
#ifdef SUNOS
  p->h.tv = gethrtime();
#endif
#if (!defined(SUNOS)&&!defined(MINGW))
  gettimeofday(&p->h.tv, 0);
#endif
#ifdef AFRDBG
  fprintf(stderr, "AFR %x:%x k(%x)\t", func, line, logkey);
#endif
  return p;
}

/* -------------- R e p o r t i n g   f u n c t i o n s -------------- */

/* Report an error. If error involved PDU or ses, they will be separately reported. */

/* Called by:  ak_buf_errf, ak_err_va */
void ak_buf_err_va(struct ak_buf* buf, int func, int line, int sev, int act, int err_code, int arg, char* format, va_list pv)
{
  struct ak_err* p = (struct ak_err*)ak_new_line(buf, func, line, (char*)arg);
  if (!p) return;
  p->raz = AK_ERR_RAZ;
  p->severity = sev;
  p->action = act;
  p->error_code = err_code;
  vsnprintf(p->msg, sizeof(p->msg), format, pv);
#ifdef AFRDBG
  fprintf(stderr, "ERR(%x,%x)=%d `%s'\n", sev, act, err_code, p->msg);
#endif
}

/* Called by:  ak_errf */
void ak_err_va(int func, int line, int sev, int act, int err_code, int arg, char* format, va_list pv)
{
  ak_buf_err_va((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, sev, act, err_code, arg, format, pv);
}

/* Called by: */
void ak_buf_errf(struct ak_buf* buf, int func, int line, int sev, int act, int err_code, int arg, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_buf_err_va(buf, func, line, sev, act, err_code, arg, format, pv);
  va_end(pv);  
}

/* Called by: */
void ak_errf(int func, int line, int sev, int act, int err_code, int arg, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_err_va(func, line, sev, act, err_code, arg, format, pv);
  va_end(pv);
}

/** Included info **/

/* Called by:  ak_ini */
void ak_buf_ini(struct ak_buf* buf, uint32 size, char* md5v, int func, int line, int raz, char* logkey, char* msg)
{
  struct ak_ini* p;
  p = (struct ak_ini*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  strncpy((char *)p->md5val, md5v, sizeof(p->md5val));
  p->size = size;
  p->raz = raz;
  if (msg){
    int len = strlen(msg);
    int siz;
    len = len - sizeof(p->msg)+1;
    if (len<0) len = 0;
    siz = MIN(sizeof(p->msg)-1, strlen(&msg[len]));
    strncpy(p->msg, &msg[len], siz);
    p->msg[siz] = '\0';
  }else
    p->msg[0] = 0;
#ifdef AFRDBG
  fprintf(stderr, "INC(%x) `%s'\n", raz, msg);
#endif
}

/* Called by: */
void ak_ini(struct ak_buf* buf, uint32 size, char* md5v, int func, int line, int raz, char* logkey, char* message)
{
  ak_buf_ini(buf, size, md5v, func, line, raz, logkey, message);
}

/* Simple message with timestamp. */

/* Called by:  ak_buf_tsf, ak_ts_va */
void ak_buf_ts_va(struct ak_buf* buf, int func, int line, int raz, char* logkey, char* format, va_list pv)
{
  char b[64];
  vsnprintf(b, sizeof(b), format, pv);
  ak_buf_ts(buf, func, line, raz, logkey, b);
}

/* Called by:  ak_tsf */
void ak_ts_va(int func, int line, int raz, char* logkey, char* format, va_list pv)
{
  ak_buf_ts_va((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, format, pv);
}

/* Called by: */
void ak_buf_tsf(struct ak_buf* buf, int func, int line, int raz, char* logkey, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_buf_ts_va(buf, func, line, raz, logkey, format, pv);
  va_end(pv);
}

/* Called by: */
void ak_tsf(int func, int line, int raz, char* logkey, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_ts_va(func, line, raz, logkey, format, pv);
  va_end(pv);
}

/* Called by:  ak_buf_ts_va, ak_ts */
void ak_buf_ts(struct ak_buf* buf, int func, int line, int raz, char* logkey, char* msg)
{
  struct ak_ts* p;
  p = ak_new_line(buf, func, line, logkey);
  /*printf("buf=%p raz=%x func=%x line=%d %s [%s]\n", buf, raz, func, line, msg, STRNULLCHK(logkey));*/
  if (!p) return;
  p->raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
#ifdef AFRDBG
  fprintf(stderr, "TS(%x) `%s'\n", raz, msg); // this outputs too much...
#endif
}

/* Called by: */
void ak_ts(int func, int line, int raz, char* logkey, char* msg) {
  ak_buf_ts((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, msg);
}

/* Called by:  ak_tsa */
void ak_buf_tsa(struct ak_buf* buf, int func, int line, int raz, char* logkey, char* msg, void* arg)
{
  struct ak_tsa* p;
  p = (struct ak_tsa*)ak_new_line(buf, func, line, logkey);
  /*printf("buf=%p raz=%x func=%x line=%d %s [%s]\n", buf, raz, func, line, msg, STRNULLCHK(logkey));*/
  if (!p) return;
  p->raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
  p->arg = arg;
#ifdef AFRDBG
  fprintf(stderr, "TS(%x) `%s'\n", raz, msg); // this outputs too much...
#endif
}

/* Called by: */
void ak_tsa(int func, int line, int raz, char* logkey, char* msg, void* arg) {
  ak_buf_tsa((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, msg, arg);
}

/* Analysis of FE */

/* Called by:  ak_buf_io_full, ak_buf_io_va, ak_io */
void ak_buf_io(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct io* io, char* msg)
{
  struct ak_io* p = (struct ak_io*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  p->raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
  p->io = io;
  if (!io) return;
  p->role = io->role;
  p->proto = io->proto;
  p->fd = io->fd;
  p->flags = io->ioflags; 
  switch (io->role) {
  case IO_ROLE_FE:           /* 0 */
    p->req_head = (((struct io_fe*)io)->req_head.pdunext != ANY_PDU(&((struct io_fe*)io)->req_tail)) ? ((struct io_fe*)io)->req_head.pdunext : 0;
    p->req_tail = (((struct io_fe*)io)->req_tail.pduprev != ANY_PDU(&((struct io_fe*)io)->req_head)) ? ((struct io_fe*)io)->req_tail.pduprev : 0;
    break;
  case IO_ROLE_BE:           /* 1 */
  case IO_ROLE_LISTENER:     /* 2 */
  case IO_ROLE_UDP_LISTENER: /* 3 */
  case IO_ROLE_SUPERVISOR:   /* 4 */
  case IO_ROLE_HOPELESS:     /* 5 */
  default:
    p->req_head = 0;
    p->req_tail = 0;
  }
#ifdef AFRDBG
  fprintf(stderr, "IO(%x) io(%x.%p) `%s'\n", raz, io->fd, io, msg);
#endif
}

/* Called by: */
void ak_io(int func, int line, int raz, char* logkey, struct io* io, char* msg) {
  ak_buf_io((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, io, msg);
}

/* Called by:  ak_buf_iof, ak_io_va */
void ak_buf_io_va(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct io* io, char* format, va_list pv)
{
  char b[64];
  vsnprintf(b, sizeof(b), format, pv);
  ak_buf_io(buf, func, line, raz, logkey, io, b);
}

/* Called by:  ak_iof */
void ak_io_va(int func, int line, int raz, char* logkey, struct io* io, char* msg, va_list pv)
{
  ak_buf_io_va((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, io, msg,pv);
}

/* Called by: */
void ak_buf_iof(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct io* io, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_buf_io_va(buf, func, line, raz, logkey, io, format, pv);
  va_end(pv);
}

/* Called by: */
void ak_iof(int func, int line, int raz, char* logkey, struct io* io, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_io_va(func, line, raz, logkey, io, format, pv);
  va_end(pv);
}

/* Called by:  ak_io_full */
void ak_buf_io_full(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct io* io, char* msg)
{
  ak_buf_io(buf, func, line, raz, logkey, io, msg);
  if (!io) return;
  if (!io->role) {
    if (((struct io_fe*)io)->req_head.pdunext != ANY_PDU(&((struct io_fe*)io)->req_tail))
      ak_buf_pdu(buf, func, line, AK_REQ_HEAD_RAZ, logkey, ((struct io_fe*)io)->req_head.pdunext, "rqhd");
    if (((struct io_fe*)io)->req_tail.pduprev != ANY_PDU(&((struct io_fe*)io)->req_head))
      ak_buf_pdu(buf, func, line, AK_REQ_TAIL_RAZ, logkey, ((struct io_fe*)io)->req_tail.pduprev, "rqtl");
  }
}

/* Called by: */
void ak_io_full(int func, int line, int raz, char* logkey, struct io* io, char* msg) {
  ak_buf_io_full((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, io, msg);
}

/* Lite analysis of PDU */

/* Called by:  ak_buf_pdu_litef, ak_pdu_lite_va */
void ak_buf_pdu_lite_va(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* format, va_list pv)
{
  char b[64];
  vsnprintf(b, sizeof(b), format, pv);
  ak_buf_pdu_lite(buf, func, line, raz, logkey, pdu, b);
}

/* Called by:  ak_pdu_litef */
void ak_pdu_lite_va(int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* msg, va_list pv)
{
  ak_buf_pdu_lite_va((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, pdu, msg,pv);
}

/* Called by: */
void ak_buf_pdu_litef(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_buf_pdu_lite_va(buf, func, line, raz, logkey, pdu, format, pv);
  va_end(pv);
}

/* Called by: */
void ak_pdu_litef(int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* format, ...)
{
  va_list pv;
  va_start(pv, format);
  ak_pdu_lite_va(func, line, raz, logkey, pdu, format, pv);
  va_end(pv);
}

/* dSpRAiii
 *   d = dirty
 *   S = synth_done
 *   p = parent set (i.e. PDU is a sub)
 *   R = req set (i.e. PDU is a response)
 *   A = all seen set on request
 *   i = 3 bits of inthread - 16 info (zero means not in thread) */
#define DIGEST_PDU_FLAGS(p) \
(((p)->inthread == 0 ? 0 : \
  ((p)->inthread < PRIO_LAST_PRIO ? 1 : ((p)->inthread - 16) & 0x7 )) \
 | ((p)->noise.s<=SYNTH_PDU?0x80:0)  /* dirty flag */  \
 | ((p)->synth_done?0x40:0)          /* has synthesized a done flag */ \
 | ((p)->parent?0x20:0)              /* has parent flag */  \
 | ((p)->req || (p)->all_seen == DETACHED_RESP_MARK ? 0x10 : ((p)->all_seen ? 0x08 : 0 )))

/* Called by:  ak_buf_pdu_lite_va, ak_pdu_lite */
void ak_buf_pdu_lite(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* msg)
{
  struct ak_pdu_lite* p = (struct ak_pdu_lite*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  p->ph.raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
  p->ph.pdu = pdu;
  if (!pdu) return;
  p->ph.pdu_op = pdu->op;
  p->ph.pdu_flags = DIGEST_PDU_FLAGS(pdu);
  p->ph.pdu_mid = pdu->req ? ((struct ldap_pdu*)pdu)->new_mid : ((struct ldap_pdu*)pdu)->mid;
#ifdef AFRDBG
  fprintf(stderr, "PDU_LITE(%x) pdu(%x:%p) `%s'\n", raz, pdu->op, pdu, msg);
#endif
}

/* Called by: */
void ak_pdu_lite(int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* msg)
{
  ak_buf_pdu_lite((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, pdu, msg);
}

/* Analysis of PDU */

/* Called by:  ak_buf_io_full x2, ak_pdu */
void ak_buf_pdu(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* msg)
{
  struct ak_pdu* p = (struct ak_pdu*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  p->ph.raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
  p->ph.pdu = pdu;
  if (!pdu) return;
  memcpy(&p->pdunext, pdu, sizeof(void*)*8);
  p->ph.pdu_op = pdu->op;
  p->ph.pdu_flags = DIGEST_PDU_FLAGS(pdu);
  p->ph.pdu_mid = pdu->req ? ((struct ldap_pdu*)pdu)->new_mid : ((struct ldap_pdu*)pdu)->mid;
#ifdef AFRDBG
  fprintf(stderr, "PDU(%x) pdu(%x:%p) `%s'\n", raz, pdu->op, pdu, msg);
#endif
}

/* Called by: */
void ak_pdu(int func, int line, int raz, char* logkey, struct any_pdu* pdu, char* msg) {
  ak_buf_pdu((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, pdu, msg);
}

/* PDU with an argument instead of a message. */

/* Called by:  ak_pdu_arg */
void ak_buf_pdu_arg(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct any_pdu* pdu, int arg)
{
  struct ak_pdu_arg* p = (struct ak_pdu_arg*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  p->ph.raz = raz;
  p->arg = arg;
  p->ph.pdu = pdu;
  if (!pdu) return;
  memcpy(&p->pdunext, pdu, sizeof(void*)*8);
  p->ph.pdu_op = pdu->op;
  p->ph.pdu_flags = DIGEST_PDU_FLAGS(pdu);
  p->ph.pdu_mid = pdu->req ? ((struct ldap_pdu*)pdu)->new_mid : ((struct ldap_pdu*)pdu)->mid;
#ifdef AFRDBG
  fprintf(stderr, "PDU(%x) pdu(%x:%p) arg(%x)\n", raz, pdu->op, pdu, arg);
#endif
}

/* Called by: */
void ak_pdu_arg(int func, int line, int raz, char* logkey, struct any_pdu* pdu, int arg) {
  ak_buf_pdu_arg((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, pdu, arg);
}

/* run that may have a PDU */

/* Called by:  ak_run */
void ak_buf_run(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct zx_run* run, char* msg)
{
  struct ak_run* p = (struct ak_run*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  p->ph.raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
  p->run = run;
  if (!run) return; 
  p->ph.pdu = run->pdu;
  if (!run->pdu) return;
  p->ph.pdu_op = ANY_PDU(run->pdu)->op;
  p->ph.pdu_flags = DIGEST_PDU_FLAGS(ANY_PDU(run->pdu));
  p->ph.pdu_mid = ANY_PDU(run->pdu)->req
    ? ((struct ldap_pdu*)(run->pdu))->new_mid
    : ((struct ldap_pdu*)(run->pdu))->mid;
#ifdef AFRDBG
  fprintf(stderr, "RUN(%x) run(%p) pdu(%x:%p) `%s'\n", raz, run, ANY_PDU(run->pdu)->op, run->pdu, msg);
#endif
}

/* Called by: */
void ak_run(int func, int line, int raz, char* logkey, struct zx_run* run, char* msg)
{
  ak_buf_run((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, run, msg);
}

/* low level memory allocator reporting */

/* Called by:  ak_mem */
void
ak_buf_mem(struct ak_buf* buf, int func, int line, int raz, char* logkey, void* pool, void* mem, int len, char* msg)
{
  struct ak_mem* p = (struct ak_mem*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  p->raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
  p->pool = pool;
  p->pool_blocks = pool?((struct mem_pool*)pool)->block_counter:0;
  p->mem = mem;
  p->len = len;
#ifdef AFRDBG
  fprintf(stderr, "MEM(%x) `%s'\n", raz, msg);
#endif
}

/* Called by: */
void
ak_mem(int func, int line, int raz, char* logkey, void* pool, void* mem, int len, char* msg)
{
  ak_buf_mem((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, pool, mem, len, msg);
}

/* Reporting memory leak counters. */

/* Called by:  ak_report */
void ak_buf_report(struct ak_buf* buf, int func, int line, int raz, char* logkey, struct mem_pool* pool, char* msg)
{
  struct ak_report* p = (struct ak_report*)ak_new_line(buf, func, line, logkey);
  if (!p) return;
  p->raz = raz;
  if (msg)
    strncpy(p->msg, msg, sizeof(p->msg));
  else
    p->msg[0] = 0;
  p->block_size = pool->block_size;
  memcpy(&p->malloc_cnt, &pool->malloc_cnt, 6*sizeof(int));
#ifdef AFRDBG
  fprintf(stderr, "REPORT(%x) `%s'\n", raz, msg);
#endif
}

/* Called by: */
void ak_report(int func, int line, int raz, char* logkey, struct mem_pool* pool, char* msg)
{
  ak_buf_report((struct ak_buf*)pthread_getspecific(ak_buf_key), func, line, raz, logkey, pool, msg);
}

/* DirectoryScript Virtual Machine Tracing */

#define AK_STR_TAIL_LEN 5  /* TUNE: How much of end of string to print if whole string does not fit. */

/* Called by:  ak_buf_trace x8 */
static void ak_cpy_to_msg(char* msg, int max_len, unsigned char* s, int len)
{
  if (len > max_len) {  /* Too long. Print start and end. */
    memcpy(msg, s, max_len - AK_STR_TAIL_LEN - 1);
    msg[max_len - AK_STR_TAIL_LEN - 1] = '.';  /* Continuation indicator. */
    memcpy(msg + max_len - AK_STR_TAIL_LEN,
	   s + len - AK_STR_TAIL_LEN, AK_STR_TAIL_LEN);
  } else {
    memcpy(msg, s, len);
    if (len < max_len)
      msg[len] = 0;
  }
}

/* Called by:  ak_trace */
void ak_buf_trace(struct ak_buf* buf, int raz, struct zx_run* run,
		     struct binid* id, struct val* SP, long* PC, long sum, int tag,
		     long R0, int T0, long R1, int T1, long R2, int T2, long R3, int T3)
{
  int len = 0, len2 = 0, file = 0, line = 0;
  struct ginfo* gi;
  struct ak_disasm* p;
  U8 *s = NULL, *s2 = NULL;

  gi = run->st->prog->gi;
  if (gi && (*PC != MCOB)) {  /* figure out script file and line, if available */
    gi = gi + (PC - run->st->prog->code);
    file = gi->file;
    line = gi->line;
  }
  
  p = (struct ak_disasm*)ak_new_line(buf, file, line, (char*)PC);
  if (!p) return;
  p->raz = raz;

  p->recurse = run->currecurse;
  p->cur_func = id;
  p->SP = SP;
  p->reg_B = sum;
  p->tag_B = tag;

  switch (raz) {
  case AK_TRACE_RAZ:
    if (PC) {
      switch (*PC & AMASK) {
      case REG_0: p->tag_A = T0; p->reg_A = R0; break;
      case REG_1: p->tag_A = T1; p->reg_A = R1; break;
      case REG_2: p->tag_A = T2; p->reg_A = R2; break;
      case REG_3: p->tag_A = T3; p->reg_A = R3; break;
      }
    }
    break;
  case AK_TRACE_CALL_RAZ: p->tag_A = T0; p->reg_A = R0; break;
  }
  
  /* Try to squeeze as much useful string data as possible into the message buffer. */
  
  if (ONE_OF_2(tag, VAL_STR, VAL_LSTR) && sum) {
    switch (tag) {
    case VAL_STR:	len = S_LEN(sum);   s = S_S(sum);  break;
    case VAL_LSTR:	len = LSTR_LEN(sum);  s = LSTR_S(sum); break;
    }
    
    if (ONE_OF_2(p->tag_A, VAL_STR, VAL_LSTR) && p->reg_A) {
      /* Both */
      switch (p->tag_A) {
      case VAL_STR:     len2 = DSS_LEN(p->reg_A);   s2 = S_S(p->reg_A);  break;
      case VAL_LSTR:    len2 = LSTR_LEN(p->reg_A);  s2 = LSTR_S(p->reg_A); break;
      }
      
      if (len + len2 + 1 > (int)sizeof(p->msg)) {
	if (len < (int)sizeof(p->msg)/2) {
	  ak_cpy_to_msg(p->msg, sizeof(p->msg) - len - 1, s2, len2);
	  p->msg[sizeof(p->msg) - len - 1] = '.';
	  ak_cpy_to_msg(p->msg + sizeof(p->msg) - len, len, s, len);
	} else if (len2 < (int)sizeof(p->msg)/2) {
	  ak_cpy_to_msg(p->msg, len2, s2, len2);
	  p->msg[len2] = '.';
	  ak_cpy_to_msg(p->msg + len2 + 1, sizeof(p->msg) - len2 - 1, s, len);
	} else {
	  ak_cpy_to_msg(p->msg, sizeof(p->msg)/2, s2, len2);
	  p->msg[sizeof(p->msg)/2] = '.';
	  ak_cpy_to_msg(p->msg + sizeof(p->msg)/2 + 1, sizeof(p->msg) - sizeof(p->msg)/2 - 1,
			   s, len);
	}
      } else {  /* Both fit */
	memcpy(p->msg, s2, len2);
	p->msg[len2] = '.';
	memcpy(p->msg+len2+1, s, len);
	if (len + len2 + 1 < (int)sizeof(p->msg))
	  p->msg[len + len2 + 1] = 0;
      }
      
    } else {      /* B only */
      ak_cpy_to_msg(p->msg, sizeof(p->msg), s, len);
    }

  } else if (ONE_OF_2(p->tag_A, VAL_STR, VAL_LSTR) && p->reg_A) {    /* A only */
    switch (p->tag_A) {
    case VAL_STR:     len = S_LEN(p->reg_A);   s = S_S(p->reg_A);  break;
    case VAL_LSTR:    len = LSTR_LEN(p->reg_A);  s = LSTR_S(p->reg_A); break;
    }
    ak_cpy_to_msg(p->msg, sizeof(p->msg), s, len);
  } else {
    /* Neither was a string */
    p->msg[0] = 0;
  }
#ifdef AFRDBG
  fprintf(stderr, "TRACE(%x)\n", raz);
#endif
}

/* Called by: */
void ak_trace(int raz, struct run* run,
		 struct binid* id, struct val* SP, long* PC, long sum, int tag,
		 long R0, int T0, long R1, int T1, long R2, int T2, long R3, int T3) {
  ak_buf_trace((struct ak_buf*)pthread_getspecific(ak_buf_key),
		  raz, run, id, SP, PC, sum, tag, R0,T0, R1,T1, R2,T2, R3,T3);
}

/* ------------------------------------------------------------------ */

#include "errmac.h"

#ifdef AK_TEST
/* gcc -g -Wall -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing -DAK_TEST -D_REENTRANT -o aktest aklog.c -lpthread */

#define PRINT_SIZE(x) printf("%5d bytes sizeof(" #x ")\n", sizeof(x))

char* vals[65536];
int adhoc = 1;

/* Called by: */
int main(int argc, char** argv)
{
  struct ds_run run;
  struct dsio io;
  struct any_pdu pdu;
  int x, coll = 0, n_func = 0;
  x = ("abc"[2]);
  printf("x=%d\n", x);
  printf("main=%x (self)\n", AK_FUNCNO(__FUNCTION__));
  printf("main=%x\n", AK_FUNCNO("main"));
  printf("main=%d\n", AK_FUNCNO("main"));
  printf("moin=%d\n", AK_FUNCNO("moin"));
  printf("mainn=%d\n", AK_FUNCNO("mainn"));

#define FUNC_DEF(f,file)  x = AK_FUNCNO(f); printf("0x%04x %5d: %s\t\t\t\t%s\n", x, x, f, vals[x]?vals[x]:""); ++n_func; if (vals[x]) ++coll; vals[x] = f;

#include "../function.list"

  printf("%d/%d function number collisions\n", coll, n_func);

  PRINT_SIZE(struct ak_header);
  PRINT_SIZE(struct ak_pdu_header);
  PRINT_SIZE(struct ak_ts);
  PRINT_SIZE(struct ak_err);
  PRINT_SIZE(struct ak_pdu_lite);
  PRINT_SIZE(struct ak_pdu);
  PRINT_SIZE(struct ak_pdu_arg);
  PRINT_SIZE(struct ak_io);
  PRINT_SIZE(struct ak_buf);
  PRINT_SIZE(struct ak_master_rec);

  D("foo %d",1);
  DD("bar",2);
  D("foo again %d",3);
  NEVER("never %d",4);

  memset(&io,  0, sizeof(io));
  memset(&run, 0, sizeof(run));
  memset(&pdu, 0, sizeof(pdu));

  ak_init(*argv);
  ak_add_thread(4096,1);
  AK_TS(TS,  0,0);
  AK_TS(TS,  "logkey0",0);
  AK_TS(TS,  "logkey1","test string here");

  AK_IO(FE,  "logkey2", &io, "test2");
  AK_IOF(FE, "logkey3", &io, "test3 string %d here", 3);
  AK_IO(FE,  "logkey4", 0, "test4 string here");
  AK_IOF(FE, "logkey5", 0, "test5 string %d here", 4);

  AK_PDU_LITE(PDU_LITE,  "logkey6", &pdu, "test6 string here");
  AK_PDU_LITEF(PDU_LITE, "logkey7", &pdu, "test7 string %d here", 7);
  AK_PDU_LITE(PDU_LITE,  "logkey8", 0,    "test8 string here");

  AK_PDU(PDU,      "logkey09", &pdu, "test09 string here");
  /*AK_PDU_FULL(PDU, "logkey10", &pdu, "test10 string here");*/
  AK_PDU(PDU,      "logkey11", 0, "test11 string here");
  /*AK_PDU_FULL(PDU, "logkey12", 0, "test12 string here");*/

  AK_TSF(TS,  "logkey13", "test12 string %d here", 13);

  AK_PDU_ARG(PDU, "func14_name", &pdu, 14);
  AK_PDU_ARG(PDU, "func15_name", 0,    15);
  AK_RUN(RUN_LOCK,  "logkey16", &run, "test16 string here");

#if 0
  if (!argc) return 0;
  if (!strcmp(argv[0], "-f")) {
    --argc; ++argv;
    while (argc) {
      x = AK_FUNCNO(*argv);
      printf("%d: %s %s\n", x, *argv, vals[x]?vals[x]:"-");
      fflush(stdout);
      vals[x] = *argv;
      --argc; ++argv;
    }
  }
#endif

  if (argc>1 && !strcmp(argv[1], "-t")) {
    printf("staying alive so you can attach, e.g. ./ak -p %d\n", getpid());
    x = 1;
    while (1) {
      AK_TSF(TS, "looping", "iter %d", x);
      printf(".");
      sleep(1);
      ++x;
    }
  }
  
  printf("provoking seg fault so you can analyze the core\n");
  fflush(stdout);

  NEVERNEVER("never never %d",4);

  *((int*)0xffffffff) = 1;
  return 0;
}

#endif

/* EOF - aklog.c */

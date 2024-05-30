#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/clock.h"
#include "ulib/chacha.h"
#include "ulib/gettime.h"

#ifdef __cplusplus
}
#endif

#ifdef USE_WIN32_NATIVE
/* #define getpid()       _getpid() */
#define ftruncate(a,b) _chsize(a,b)
/* typedef U32            mode_t; */
#endif
#undef open

#define state_fd        UCXT.clock_state_fd
#define state_f         UCXT.clock_state_f
#define adjustment      UCXT.clock_adj
#define last            UCXT.clock_last
#define clock_seq       UCXT.clock_seq
#define myU2time        UCXT.myU2time
#define prev_clock_reg  UCXT.clock_prev_reg
#define defer_100ns     UCXT.clock_defer_100ns
#define pathlen         UCXT.clock_pathlen

/* called at boot */
void uu_clock_init(pUCXT) {
  state_fd       = -3;
  state_f        = NULL;
  pathlen.path   = NULL;
  pathlen.len    = 0;
  adjustment     = 0;
  last.tv_sec    = 0;
  last.tv_usec   = 0;
  prev_clock_reg = 0;
  defer_100ns    = 0;
  /* clock_seq uninit */
}

void uu_clock_getpath(pUCXT, struct_pathlen_t *sp) {
  Copy(&pathlen, sp, 1, struct_pathlen_t);
}

void uu_clock_setpath(pUCXT, struct_pathlen_t *sp) {
  if (pathlen.path)
    Safefree(pathlen.path);
  Copy(sp, &pathlen, 1, struct_pathlen_t);
  if (state_fd >= 0)
    fclose(state_f);
  state_fd  = -3;
}

/* returns 100ns intervals since unix epoch.
*  since gettimeofday() is in 1usec intervals,
*  last digit is simulated via adjustment.
*/
IV uu_clock(pUCXT, U64 *ret_clock_reg, U16 *ret_clock_seq) {
  struct timeval  tv;
  mode_t          save_umask;
  int             len;
  UV              ptod[2];
  U64             clock_reg;
#ifdef HAVE_LSTAT
  struct stat     statbuf;
#endif

  /* state_fd:
   *  -4  cannot create
   *  -3  untried
   *  -2  symlink
   *  -1  can create
   *  >=0 open
  */
  if (state_fd == -3) {
#ifdef HAVE_LSTAT
    if (lstat(pathlen.path, &statbuf) < 0) { /* this covers EINTR too.. ugh */
      if (errno == ENOENT)
        state_fd = -1;
      else
        state_fd = -4;
    }
    else if ((statbuf.st_mode & S_IFMT) == S_IFLNK) {
      state_fd = -2;
    }
    else {
#endif
      state_fd = open(pathlen.path, O_RDWR);
      if (state_fd < 0 && errno == ENOENT)
        state_fd   = -1; /* can create */
      else if (state_fd >= 0) {
#ifdef HAVE_LSTAT
        state_f = NULL;
        if ((lstat(pathlen.path, &statbuf) == 0) && ((statbuf.st_mode & S_IFMT) != S_IFLNK))
#endif
          state_f = fdopen(state_fd, "r+");
        if (!state_f) {
          close(state_fd);
          state_fd = -2;
        }
      }
#ifdef HAVE_LSTAT
    }
#endif
  }

  if (state_fd >= 0) {
    unsigned int cl;
    unsigned long tv1, tv2;
    int a;

    rewind(state_f);

    if (fscanf(state_f, "clock: %04x tv: %lu %lu adj: %d\n", &cl, &tv1, &tv2, &a) == 4) {
      clock_seq    = cl & 0x3fff;
      last.tv_sec  = tv1;
      last.tv_usec = tv2;
      adjustment   = a;
    }
  }

  /* gettimeofday(&tv, 0); */
  (*myU2time)(aTHX_ (UV*)&ptod);
  tv.tv_sec  = (long)ptod[0];
  tv.tv_usec = (long)ptod[1];

  if ((last.tv_sec == 0) && (last.tv_usec == 0)) {
    cc_rand16(aUCXT, &clock_seq);
    clock_seq &= 0x3fff;

    last.tv_sec  = tv.tv_sec - 1;
    last.tv_usec = tv.tv_usec;
  }

  if ((tv.tv_sec < last.tv_sec) || ((tv.tv_sec == last.tv_sec) && (tv.tv_usec < last.tv_usec))) {
    clock_seq = (clock_seq+1) & 0x3fff;
    adjustment = 0;
    last = tv;
  }
  else if ((tv.tv_sec == last.tv_sec) && (tv.tv_usec == last.tv_usec)) {
    if (adjustment >= MAX_ADJUSTMENT) {
      clock_seq = (clock_seq+1) & 0x3fff;
      adjustment = 0;
    }
    else {
      adjustment++;
    }
  }
  else {
    adjustment = 0;
    last = tv;
  }

  clock_reg = tv.tv_usec*10 + adjustment;
  clock_reg += ((U64)tv.tv_sec)*10000000;
  /* *clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000; */

  if ((clock_reg - prev_clock_reg) >= defer_100ns) {
    if (state_fd == -1) { /* can create */
#ifdef HAVE_LSTAT
      if ((lstat(pathlen.path, &statbuf) == 0) && ((statbuf.st_mode & S_IFMT) == S_IFLNK))
        state_fd = -2;
      else {
#endif
        save_umask = umask(0);
        state_fd = open(pathlen.path, O_RDWR|O_CREAT, 0660);
        if (state_fd < 0)
          state_fd = -4;
        (void) umask(save_umask);
        if (state_fd >= 0) {
#ifdef HAVE_LSTAT
          state_f = NULL;
          if ((lstat(pathlen.path, &statbuf) == 0) && ((statbuf.st_mode & S_IFMT) != S_IFLNK))
#endif
            state_f = fdopen(state_fd, "r+");
          if (!state_f) {
            close(state_fd);
            state_fd = -2;
          }
        }
#ifdef HAVE_LSTAT
      }
#endif
    }

    if (state_fd > 0) {
      rewind(state_f);
      len = fprintf(state_f,
              "clock: %04x tv: %016lu %08lu adj: %08d\n",
              clock_seq, (unsigned long)last.tv_sec,
              (unsigned long)last.tv_usec, adjustment);
      fflush(state_f);
      if (ftruncate(state_fd, len) < 0) {
        fprintf(state_f, "                   \n");
        fflush(state_f);
      }
      rewind(state_f);
    }
  }

  prev_clock_reg = clock_reg;

  /* *clock_high = clock_reg >> 32; */
  /* *clock_low = (U32)clock_reg; */
  *ret_clock_reg = clock_reg;
  *ret_clock_seq = clock_seq;
  return 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */

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

/*
static int        state_fd = -2;
static FILE       *state_f = NULL;
static const char *statepath = NULL;
*/

#define state_fd    UCXT.clock_state_fd
#define state_f     UCXT.clock_state_f
#define statepath   UCXT.clock_state_path
#define adjustment  UCXT.clock_adj
#define last        UCXT.clock_last
#define clock_seq   UCXT.clock_seq

/* called at boot */
void uu_clock_init(pUCXT) {
  state_fd   = -2;
  state_f    = NULL;
  statepath  = NULL;
  adjustment = 0;
  last.tv_sec = 0;
  last.tv_usec = 0;
  /* clock_seq uninit */
}

void uu_init_statepath(pUCXT, const char *path) {
  if (state_fd >= 0)
    fclose(state_f);
  state_fd  = -2;
  statepath = (char*)path;
}

/* returns 100ns intervals since unix epoch.
*  since gettimeofday() is in 1usec intervals,
*  last digit is simulated via adjustment.
*/
IV uu_clock(pUCXT, U64 *clock_reg, U16 *ret_clock_seq) {
  //static int            adjustment = 0;
  //static struct timeval last = {0, 0};
  //static U16            clock_seq;
  struct timeval        tv;
#ifdef HAVE_LSTAT
  struct stat           statbuf;
#endif
  mode_t                save_umask;
  int                   len;
  UV                    ptod[2];

  if (state_fd == -2) {
#ifdef HAVE_LSTAT
    if ((lstat(statepath, &statbuf) == 0)
      && ((statbuf.st_mode & S_IFMT) == S_IFLNK))
      state_fd = -1;
    else {
#endif
      save_umask = umask(0);
      state_fd = open(statepath, O_RDWR|O_CREAT, 0660);
      (void) umask(save_umask);
      if (state_fd >= 0) {
#ifdef HAVE_LSTAT
        state_f = NULL;
        if ((lstat(statepath, &statbuf) == 0)
          && ((statbuf.st_mode & S_IFMT) != S_IFLNK))
#endif
          state_f = fdopen(state_fd, "r+");
        if (!state_f) {
          close(state_fd);
          state_fd = -1;
        }
      }
#ifdef HAVE_LSTAT
    }
#endif
  }
  if (state_fd >= 0)
    rewind(state_f);
  if (state_fd >= 0) {
    unsigned int cl;
    unsigned long tv1, tv2;
    int a;

    if (fscanf(state_f, "clock: %04x tv: %lu %lu adj: %d\n",
         &cl, &tv1, &tv2, &a) == 4) {
      clock_seq = cl & 0x3fff;
      last.tv_sec = tv1;
      last.tv_usec = tv2;
      adjustment = a;
    }
  }

  if ((last.tv_sec == 0) && (last.tv_usec == 0)) {
    cc_rand16(aUCXT, &clock_seq);
    clock_seq &= 0x3fff;

    /* gettimeofday(&last, 0); */
    (*UCXT.myU2time)(aTHX_ (UV*)&ptod);
    last.tv_sec  = (long)ptod[0];
    last.tv_usec = (long)ptod[1];

    last.tv_sec--;
  }

  /* gettimeofday(&tv, 0); */
  (*UCXT.myU2time)(aTHX_ (UV*)&ptod);
  tv.tv_sec  = (long)ptod[0];
  tv.tv_usec = (long)ptod[1];

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

  *clock_reg = tv.tv_usec*10 + adjustment;
  *clock_reg += ((U64)tv.tv_sec)*10000000;
  /* *clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000; */

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

  /* *clock_high = clock_reg >> 32; */
  /* *clock_low = (U32)clock_reg; */
  *ret_clock_seq = clock_seq;
  return 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */

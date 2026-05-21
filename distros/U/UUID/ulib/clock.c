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
#define ftruncate(a,b) _chsize(a,b)
#endif
#undef open

#define state_fd        UCXT.clock_state_fd
#define state_f         UCXT.clock_state_f
#define thread_persist  UCXT.clock_persist
#define adjustment      SMEM->clock_adj
#define last            SMEM->clock_last
#define clock_seq       SMEM->clock_seq
#define prev_reg        SMEM->clock_prev_reg
#define defer_100ns     SMEM->clock_defer_100ns
#define global_persist  SMEM->clock_persist

/* state_fd:
 *  -4  cannot create
 *  -3  untried
 *  -2  symlink
 *  -1  can create
 *  >=0 open fd
*/
#define STATEFD_NOCREATE -4
#define STATEFD_UNTRIED  -3
#define STATEFD_SYMLINK  -2
#define STATEFD_CREATEOK -1


/* compare paths, return 0 if same or longer length if not */
static IV persistNE(persist_t *a, persist_t *b) {
  STRLEN longer = a->len >= b->len ? a->len : b->len;
  UV i;
  if (a->len != b->len)
    return longer;
  for (i=0 ; i<longer ; ++i)
    if(a->path[i] != b->path[i])
      return longer;
  return 0;
}

/* called at boot */
void uu_clock_init(pUCXT) {
  UV ptod[2];

  /* gettimeofday(&tv, 0); */
  (*uu_gettime_U2time)(aTHX_ ptod);
  last.tv_sec  = (long)ptod[0];
  last.tv_usec = (long)ptod[1];

  uu_chacha_rand16(aUCXT, &clock_seq);
  clock_seq &= 0x3fff;

  state_fd     = STATEFD_UNTRIED;
  state_f      = NULL;
  adjustment   = 0;
  prev_reg     = 0;
  defer_100ns  = 0;
  Zero(&global_persist, 1, persist_t);
  Zero(&thread_persist, 1, persist_t);
}

void uu_clock_getpath(pUCXT, persist_t *persist) {
  Copy(&global_persist, &thread_persist, 1, persist_t);
  Copy(&thread_persist, persist,         1, persist_t);
}

void uu_clock_setpath(pUCXT, persist_t *persist) {
  Copy(persist, &thread_persist, 1, persist_t);
  Copy(persist, &global_persist, 1, persist_t);
  if (state_fd >= 0)
    fclose(state_f);
  state_fd = STATEFD_UNTRIED;
  /* doing this would break inter-process deferrals */
  /* prev_reg = 0; */
}

/* returns 100ns intervals since unix epoch.
*  since gettimeofday() is in 1usec intervals,
*  last digit is simulated via adjustment.
*/
IV uu_clock(pUCXT, U64 *ret_clock_reg, U16 *ret_clock_seq) {
  struct timeval  tv;
  mode_t          save_umask;
  U64             clock_reg;
  STRLEN          longer;
  UV              ptod[2];
#ifdef HAVE_LSTAT
  struct stat     statbuf;
#endif

  if ((longer = persistNE(&global_persist, &thread_persist))) {
    Copy(&global_persist, &thread_persist, longer, UCHAR);
    if (state_fd >= 0)
      fclose(state_f);
    state_fd = STATEFD_UNTRIED;
  }

  if (state_fd == STATEFD_UNTRIED) {
#ifdef HAVE_LSTAT
    if (lstat((char*)thread_persist.path, &statbuf) < 0) { /* this covers EINTR too.. ugh */
      if (errno == ENOENT)
        state_fd = STATEFD_CREATEOK;
      else
        state_fd = STATEFD_NOCREATE;
    }
    else if ((statbuf.st_mode & S_IFMT) == S_IFLNK)
      state_fd = STATEFD_SYMLINK;
    else {
#endif
      state_fd = open((char*)thread_persist.path, O_RDWR);
      if (state_fd < 0 && errno == ENOENT)
        state_fd = STATEFD_CREATEOK;
      else if (state_fd >= 0) {
#ifdef HAVE_LSTAT
        state_f = NULL;
        if ((lstat((char*)thread_persist.path, &statbuf) == 0) && ((statbuf.st_mode & S_IFMT) != S_IFLNK))
#endif
          state_f = fdopen(state_fd, "r+");
        if (!state_f) {
          close(state_fd);
          state_fd = STATEFD_SYMLINK;
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
  (*uu_gettime_U2time)(aTHX_ ptod);
  tv.tv_sec  = (long)ptod[0];
  tv.tv_usec = (long)ptod[1];

  if ((tv.tv_sec == last.tv_sec) && (tv.tv_usec == last.tv_usec)) {
    /* same time as last */
    if (++adjustment >= MAX_ADJUSTMENT) {
      clock_seq = (clock_seq+1) & 0x3fff;
      adjustment = 0;
    }
  }
  else {
    /* time changed */
    if (((tv.tv_sec == last.tv_sec) && (tv.tv_usec < last.tv_usec)) || (tv.tv_sec < last.tv_sec))
        clock_seq = (clock_seq+1) & 0x3fff; /* time moved backward */
    adjustment = 0;
    last = tv;
  }

  clock_reg = tv.tv_usec*10 + adjustment;
  clock_reg += ((U64)tv.tv_sec)*10000000;
  /* *clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000; */

  if ((clock_reg - prev_reg) >= defer_100ns) {
    if (state_fd == STATEFD_CREATEOK) {
#ifdef HAVE_LSTAT
      if ((lstat((char*)thread_persist.path, &statbuf) == 0) && ((statbuf.st_mode & S_IFMT) == S_IFLNK))
        state_fd = STATEFD_SYMLINK;
      else {
#endif
        save_umask = umask(0);
        state_fd = open((char*)thread_persist.path, O_RDWR|O_CREAT, 0660);
        if (state_fd < 0)
          state_fd = STATEFD_NOCREATE;
        (void) umask(save_umask);
        if (state_fd >= 0) {
#ifdef HAVE_LSTAT
          state_f = NULL;
          if ((lstat((char*)thread_persist.path, &statbuf) == 0) && ((statbuf.st_mode & S_IFMT) != S_IFLNK))
#endif
            state_f = fdopen(state_fd, "r+");
          if (!state_f) {
            close(state_fd);
            state_fd = STATEFD_SYMLINK;
          }
        }
#ifdef HAVE_LSTAT
      }
#endif
    }

    if (state_fd > 0) {
      rewind(state_f);
      long len = fprintf(state_f,
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

  prev_reg = clock_reg;

  /* *clock_high = clock_reg >> 32; */
  /* *clock_low = (U32)clock_reg; */
  *ret_clock_reg = clock_reg;
  *ret_clock_seq = clock_seq;
  return 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */

#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/sysrand.h"

#ifdef __cplusplus
}
#endif


#ifndef WIN32
#ifndef USE_WIN32_NATIVE
static int get_random_fd(void)
{
  int	i, fd = -2;

  if (fd == -2) {
    fd = open("/dev/urandom", O_RDONLY);
    if (fd == -1)
      fd = open("/dev/random", O_RDONLY | O_NONBLOCK);
    if (fd >= 0) {
      i = fcntl(fd, F_GETFD);
      if (i >= 0)
        fcntl(fd, F_SETFD, i | FD_CLOEXEC);
    }
  }
  return fd;
}
#endif
#endif


/*
 * Generate a series of random bytes.  Use /dev/urandom if possible,
 * and if not, use srandom/random.
 */
void uu_sysrand_bytes(void *buf, int nbytes)
{
  int i, n = nbytes, fd;
  int lose_counter = 0;
  unsigned char *cp = buf;
  (void)n;
  (void)fd;
  (void)lose_counter;

#ifdef HAVE_ARC4RANDOM
  arc4random_buf(buf, nbytes);
  return;
#endif
#ifdef HAVE_BCRYPTGENRANDOM
  if (BCryptGenRandom(NULL, buf, nbytes, BCRYPT_USE_SYSTEM_PREFERRED_RNG) == 0)
    return;
#endif
#ifdef HAVE_CRYPTGENRANDOM
  {
    int ok = 0;
    HCRYPTPROV  hCryptProv;
    if (CryptAcquireContext(&hCryptProv, NULL, NULL, PROV_RSA_FULL, 0)) {
      ok = CryptGenRandom(hCryptProv, nbytes, buf);
      CryptReleaseContext(hCryptProv, 0);
      if (ok) return;
    }
  }
#endif
#ifdef HAVE_GETENTROPY
  if (getentropy(buf, nbytes) == 0)
    return;
#endif
#ifdef HAVE_GETRANDOM
  if (getrandom(buf, nbytes, 0) == nbytes)
    return;
#endif

#ifndef WIN32
#ifndef USE_WIN32_NATIVE
  fd = get_random_fd();
  if (fd >= 0) {
    while (n > 0) {
      i = read(fd, cp, n);
      if (i <= 0) {
        if (lose_counter++ > 16)
          break;
        continue;
      }
      n -= i;
      cp += i;
      lose_counter = 0;
    }
  }
#endif
#endif

  /*
   * We do this anyway, but this is the only source of
   * randomness if /dev/random/urandom is out to lunch.
   */
  for (cp = buf, i = 0; i < nbytes; i++)
    *cp++ ^= (rand() >> 7) & 0xFF;

  return;
}

/* ex:set ts=2 sw=2 itab=spaces: */

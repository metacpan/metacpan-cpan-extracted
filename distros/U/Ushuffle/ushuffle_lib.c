/*
 * Compiles the uShuffle library into the extension.
 *
 * ushufflelib/ holds ushuffle.c and ushuffle.h unmodified from the master
 * branch of https://github.com/s-will/ushuffle at commit 2c4b8f3 (release
 * 1.2.2 plus the hcode overflow fix merged there as pull request #1). The
 * source is included from here rather than placed next
 * to Ushuffle.xs because a file named ushuffle.c would collide with the
 * generated Ushuffle.c on case-insensitive file systems.
 */

#include "ushufflelib/ushuffle.c"

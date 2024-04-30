#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/clear.h"

#ifdef __cplusplus
}
#endif

void uu_clear(struct_uu_t *io) {
  io->v1.time_low              = 0;
  io->v1.time_mid              = 0;
  io->v1.time_high_and_version = 0;
  io->v1.clock_seq_and_variant = 0;
  io->v1.node[0]               = 0;
  io->v1.node[1]               = 0;
  io->v1.node[2]               = 0;
  io->v1.node[3]               = 0;
  io->v1.node[4]               = 0;
  io->v1.node[5]               = 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */

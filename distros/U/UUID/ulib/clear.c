#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/clear.h"

#ifdef __cplusplus
}
#endif

void uu_clear(struct_uu1_t *io) {
  io->members.time_low              = 0;
  io->members.time_mid              = 0;
  io->members.time_high_and_version = 0;
  io->members.clock_seq_and_variant = 0;
  io->members.node[0]               = 0;
  io->members.node[1]               = 0;
  io->members.node[2]               = 0;
  io->members.node[3]               = 0;
  io->members.node[4]               = 0;
  io->members.node[5]               = 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */

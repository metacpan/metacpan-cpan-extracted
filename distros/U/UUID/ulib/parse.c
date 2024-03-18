#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/parse.h"

#ifdef __cplusplus
}
#endif

IV uu_parse(const char *in, struct_uu1_t *out) {
  int         i;
  const char  *cp;
  char        buf[3];

  if (strlen(in) != 36)
    return -1;
  for (i=0, cp = in; i <= 36; i++,cp++) {
    if ((i == 8) || (i == 13) || (i == 18) || (i == 23)) {
      if (*cp == '-')
        continue;
      return -1;
    }
    if (i == 36 && *cp == 0)
      continue;
    if (!isxdigit(*cp))
      return -1;
  }
  out->members.time_low              = strtoul(in, NULL, 16);
  out->members.time_mid              = (U16)strtoul(in+9, NULL, 16);
  out->members.time_high_and_version = (U16)strtoul(in+14, NULL, 16);
  out->members.clock_seq_and_variant = (U16)strtoul(in+19, NULL, 16);
  cp = in+24;
  buf[2] = 0;
  for (i=0; i < 6; i++) {
    buf[0] = *cp++;
    buf[1] = *cp++;
    out->members.node[i] = (U8)strtoul(buf, NULL, 16);
  }

  return 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */

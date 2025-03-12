
#include "unijp.h"
#include <stdio.h>
#include <string.h>

static enum uj_charcode_e codes[] = {
  /* ujc_auto, */
  ujc_utf8,
  ujc_sjis,
  ujc_eucjp,
  ujc_jis,

  ujc_ucs2,
  ujc_ucs4,
  ujc_utf16,
  /* ujc_ascii */

  /* ujc_binary, */
  /* ujc_undefined */
};

int main(int argc, const char* argv[])
{
  const int nr_codes = sizeof(codes)/sizeof(codes[0]);
  int i;

  printf("1..%d\n", 2*nr_codes);

  /* from any to utf8. */
  for( i=0; i<nr_codes; ++i )
  {
    unijp_t* uj;
    uj = uj_new((uj_uint8*)"", 0, codes[i]);
    uj_delete(uj);
    printf("ok %d - from empty %s\n", i+1, uj_charcode_str(codes[i]));
  }

  /* from utf8 to any. */
  for( i=0; i<nr_codes; ++i )
  {
    unijp_t* uj;
    uj_uint8* ret;
    uj_size_t ret_len;
    int ok = 0;
    uj = uj_new((uj_uint8*)"", 0, ujc_utf8);
    ret = uj_conv(uj, codes[i], &ret_len);
    if( ret!=NULL )
    {
      uj_delete_buffer(uj, ret);
      uj_delete(uj);
      ok = ret_len ==  0;
    }else
    {
      uj_delete(uj);
    }
    printf("%s %d - to empty %s\n", ok?"ok":"not ok", nr_codes+i+1, uj_charcode_str(codes[i]));
  }

  return 0;
}

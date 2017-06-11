#ifndef _MYPNY_H_
#define _MYPNY_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../spreps.h"
#include "../pcodes.h"

int length(void *ptr);

char *puny_enc(char *dnam);
char *puny_dec(char *dnam);

  #define PNY_APPNAME "twpuny"
  #define PNY_APPVERS "1.05"

  #define PNY_APPLOGO  "   _                                    \n" \
                       "  | |                                   \n" \
                       "  | |___      ___ __  _   _ _ __  _   _ \n" \
                       "  | __\\ \\ /\\ / / '_ \\| | | | '_ \\| | | |\n" \
                       "  | |_ \\ V  V /| |_) | |_| | | | | |_| |\n" \
                       "   \\__| \\_/\\_/ | .__/ \\__,_|_| |_|\\__, |\n" \
                       "               | |                 __/ |\n" \
                       "               |_|                |___/ \n\n"

  #define PNY_OPTIONS \
    PNY_APPNAME " [OPTION(FEATURE)S] string\n\n" \
    "  [OPTIONS]\n" \
    "    -e    encode punycode(defaults).\n" \
    "    -d    decode punycode.\n\n\0"

  #define PNY_CRIGHTS \
    "Copyright (C)2013 Twinkle Computing All rights reserved.\n" \
    "\n" \
    "Report bugs to <twinkle@cpan.org>\n\0"

  #define PNY_VERSION \
    PNY_APPNAME " (twinkle-utils) " PNY_APPVERS "\n" \
    "\n" PNY_CRIGHTS

#endif

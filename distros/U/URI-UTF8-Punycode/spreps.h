/* stringprep.h --- Header file for stringprep functions.
   Copyright (C) 2002-2012 Simon Josefsson

   This file is part of GNU Libidn.

   GNU Libidn is free software: you can redistribute it and/or
   modify it under the terms of either:

     * the GNU Lesser General Public License as published by the Free
       Software Foundation; either version 3 of the License, or (at
       your option) any later version.

   or

     * the GNU General Public License as published by the Free
       Software Foundation; either version 2 of the License, or (at
       your option) any later version.

   or both in parallel, as here.

   GNU Libidn is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received copies of the GNU General Public License and
   the GNU Lesser General Public License along with this program.  If
   not, see <http://www.gnu.org/licenses/>. */

#ifndef STRINGPREP_H
# define STRINGPREP_H

#include <stddef.h>		/* size_t */

#ifdef _MSC_VER
  #include <windows.h>
  typedef int ssize_t;
  typedef unsigned int uint32_t;
#else
  #include <stdint.h>		/* uint32_t */
  #include <unistd.h>		/* ssize_t */
#endif

# ifdef __cplusplus
extern "C"
{
# endif

# define STRINGPREP_VERSION "1.26"

uint32_t *stringprep_utf8_to_ucs4 (const char *str,
						   ssize_t len,
						   size_t * items_written);
char *stringprep_ucs4_to_utf8 (const uint32_t * str,
					       ssize_t len,
					       size_t * items_read,
					       size_t * items_written);

# ifdef __cplusplus
}
# endif

#endif				/* STRINGPREP_H */

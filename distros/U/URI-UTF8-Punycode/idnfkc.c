/* nfkc.c --- Unicode normalization utilities.
 * Copyright (C) 2002, 2003, 2004, 2006, 2007, 2008, 2009, 2010 Simon
 * Josefsson
 *
 * This file is part of GNU Libidn.
 *
 * GNU Libidn is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GNU Libidn is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with GNU Libidn; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
 *
 */
#include <stdlib.h>
#include <string.h>

#include "spreps.h"

/* This file contains functions from GLIB, including gutf8.c and
 * gunidecomp.c, all licensed under LGPL and copyright hold by:
 *
 *  Copyright (C) 1999, 2000 Tom Tromey
 *  Copyright 2000 Red Hat, Inc.
 */

/* Hacks to make syncing with GLIB code easier. */
#define gboolean int
#define gchar char
#define guchar unsigned char
#define glong long
#define gint int
#define guint unsigned int
#define gushort unsigned short
#define gint16 int16_t
#define guint16 uint16_t
#define gunichar uint32_t
#define gsize size_t
#define gssize ssize_t
#define g_malloc malloc
#define g_free free
#define g_return_val_if_fail(expr,val)	{		\
    if (!(expr))					\
      return (val);					\
  }

/* Code from GLIB gmacros.h starts here. */

/* GLIB - Library of useful routines for C programming
 * Copyright (C) 1995-1997  Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#define G_UNLIKELY(expr) (expr)

/* Code from GLIB gunicode.h starts here. */

/* gunicode.h - Unicode manipulation functions
 *
 *  Copyright (C) 1999, 2000 Tom Tromey
 *  Copyright 2000, 2005 Red Hat, Inc.
 *
 * The Gnome Library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * The Gnome Library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with the Gnome Library; see the file COPYING.LIB.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 *   Boston, MA 02111-1307, USA.
 */

#define UTF8_LENGTH(Char)			\
  ((Char) < 0x80 ? 1 :				\
   ((Char) < 0x800 ? 2 :			\
    ((Char) < 0x10000 ? 3 :			\
     ((Char) < 0x200000 ? 4 :			\
      ((Char) < 0x4000000 ? 5 : 6)))))

static const gchar utf8_skip_data[256] = {
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5,
  5, 5, 5, 6, 6, 1, 1
};

const gchar *const g_utf8_skip = utf8_skip_data;

#define g_utf8_next_char(p) ((p) + g_utf8_skip[*(const guchar *)(p)])

/*
 * g_unichar_to_utf8:
 * @c: a Unicode character code
 * @outbuf: output buffer, must have at least 6 bytes of space.
 *       If %NULL, the length will be computed and returned
 *       and nothing will be written to @outbuf.
 *
 * Converts a single character to UTF-8.
 *
 * Return value: number of bytes written
 **/
static int
g_unichar_to_utf8 (gunichar c, gchar * outbuf)
{
  /* If this gets modified, also update the copy in g_string_insert_unichar() */
  guint len = 0;
  int first;
  int i;

  if (c < 0x80)
    {
      first = 0;
      len = 1;
    }
  else if (c < 0x800)
    {
      first = 0xc0;
      len = 2;
    }
  else if (c < 0x10000)
    {
      first = 0xe0;
      len = 3;
    }
  else if (c < 0x200000)
    {
      first = 0xf0;
      len = 4;
    }
  else if (c < 0x4000000)
    {
      first = 0xf8;
      len = 5;
    }
  else
    {
      first = 0xfc;
      len = 6;
    }

  if (outbuf)
    {
      for (i = len - 1; i > 0; --i)
	{
	  outbuf[i] = (c & 0x3f) | 0x80;
	  c >>= 6;
	}
      outbuf[0] = c | first;
    }

  return len;
}

/*
 * g_utf8_to_ucs4_fast:
 * @str: a UTF-8 encoded string
 * @len: the maximum length of @str to use, in bytes. If @len < 0,
 *       then the string is nul-terminated.
 * @items_written: location to store the number of characters in the
 *                 result, or %NULL.
 *
 * Convert a string from UTF-8 to a 32-bit fixed width
 * representation as UCS-4, assuming valid UTF-8 input.
 * This function is roughly twice as fast as g_utf8_to_ucs4()
 * but does no error checking on the input. A trailing 0 character
 * will be added to the string after the converted text.
 *
 * Return value: a pointer to a newly allocated UCS-4 string.
 *               This value must be freed with g_free().
 **/
static gunichar *
g_utf8_to_ucs4_fast (const gchar * str, glong len, glong * items_written)
{
  gunichar *result;
  gsize n_chars, i;
  const gchar *p;

  g_return_val_if_fail (str != NULL, NULL);

  p = str;
  n_chars = 0;
  if (len < 0)
    {
      while (*p)
	{
	  p = g_utf8_next_char (p);
	  ++n_chars;
	}
    }
  else
    {
      while (p < str + len && *p)
	{
	  p = g_utf8_next_char (p);
	  ++n_chars;
	}
    }

  result = g_malloc (sizeof (gunichar) * (n_chars + 1));
  if (!result)
    return NULL;

  p = str;
  for (i = 0; i < n_chars; i++)
    {
      gunichar wc = (guchar) * p++;

      if (wc < 0x80)
	{
	  result[i] = wc;
	}
      else
	{
	  gunichar mask = 0x40;

	  if (G_UNLIKELY ((wc & mask) == 0))
	    {
	      /* It's an out-of-sequence 10xxxxxxx byte.
	       * Rather than making an ugly hash of this and the next byte
	       * and overrunning the buffer, it's more useful to treat it
	       * with a replacement character */
	      result[i] = 0xfffd;
	      continue;
	    }

	  do
	    {
	      wc <<= 6;
	      wc |= (guchar) (*p++) & 0x3f;
	      mask <<= 5;
	    }
	  while ((wc & mask) != 0);

	  wc &= mask - 1;

	  result[i] = wc;
	}
    }
  result[i] = 0;

  if (items_written)
    *items_written = i;

  return result;
}

/*
 * g_ucs4_to_utf8:
 * @str: a UCS-4 encoded string
 * @len: the maximum length (number of characters) of @str to use.
 *       If @len < 0, then the string is nul-terminated.
 * @items_read: location to store number of characters read, or %NULL.
 * @items_written: location to store number of bytes written or %NULL.
 *                 The value here stored does not include the trailing 0
 *                 byte.
 * @error: location to store the error occurring, or %NULL to ignore
 *         errors. Any of the errors in #GConvertError other than
 *         %G_CONVERT_ERROR_NO_CONVERSION may occur.
 *
 * Convert a string from a 32-bit fixed width representation as UCS-4.
 * to UTF-8. The result will be terminated with a 0 byte.
 *
 * Return value: a pointer to a newly allocated UTF-8 string.
 *               This value must be freed with g_free(). If an
 *               error occurs, %NULL will be returned and
 *               @error set. In that case, @items_read will be
 *               set to the position of the first invalid input
 *               character.
 **/
static gchar *
g_ucs4_to_utf8 (const gunichar * str,
		glong len,
		glong * items_read, glong * items_written)
{
  gint result_length;
  gchar *result = NULL;
  gchar *p;
  gint i;

  result_length = 0;
  for (i = 0; len < 0 || i < len; i++)
    {
      if (!str[i])
	break;

      if (str[i] >= 0x80000000)
	goto err_out;

      result_length += UTF8_LENGTH (str[i]);
    }

  result = g_malloc (result_length + 1);
  if (!result)
    return NULL;
  p = result;

  i = 0;
  while (p < result + result_length)
    p += g_unichar_to_utf8 (str[i++], p);

  *p = '\0';

  if (items_written)
    *items_written = p - result;

err_out:
  if (items_read)
    *items_read = i;

  return result;
}

/**
 * stringprep_utf8_to_ucs4:
 * @str: a UTF-8 encoded string
 * @len: the maximum length of @str to use. If @len < 0, then
 *       the string is nul-terminated.
 * @items_written: location to store the number of characters in the
 *                 result, or %NULL.
 *
 * Convert a string from UTF-8 to a 32-bit fixed width
 * representation as UCS-4, assuming valid UTF-8 input.
 * This function does no error checking on the input.
 *
 * Return value: a pointer to a newly allocated UCS-4 string.
 *               This value must be deallocated by the caller.
 **/
uint32_t *
stringprep_utf8_to_ucs4 (const char *str, ssize_t len, size_t * items_written)
{
  return g_utf8_to_ucs4_fast (str, (glong) len, (glong *) items_written);
}

/**
 * stringprep_ucs4_to_utf8:
 * @str: a UCS-4 encoded string
 * @len: the maximum length of @str to use. If @len < 0, then
 *       the string is terminated with a 0 character.
 * @items_read: location to store number of characters read read, or %NULL.
 * @items_written: location to store number of bytes written or %NULL.
 *                 The value here stored does not include the trailing 0
 *                 byte.
 *
 * Convert a string from a 32-bit fixed width representation as UCS-4.
 * to UTF-8. The result will be terminated with a 0 byte.
 *
 * Return value: a pointer to a newly allocated UTF-8 string.
 *               This value must be deallocated by the caller.
 *               If an error occurs, %NULL will be returned.
 **/
char *
stringprep_ucs4_to_utf8 (const uint32_t * str, ssize_t len,
			 size_t * items_read, size_t * items_written)
{
  return g_ucs4_to_utf8 (str, len, (glong *) items_read,
			 (glong *) items_written);
}

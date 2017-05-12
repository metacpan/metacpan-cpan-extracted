/* -*- c -*- 
   $Id: cdxa2mpeg.c,v 1.1 2002/10/18 03:21:30 allenday Exp $

   Copyright (C) 2001 Herbert Valerio Riedel <hvr@gnu.org>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
    
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* quick'n'dirty RIFF CDXA 2 MPEG converter */

/* assert(LITTLE_ENDIAN); */

#define _GNU_SOURCE

#include <stdint.h> /* ISO C99 */
#include <stdbool.h> /* ISO C99 */

#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

typedef struct 
{
  FILE *fd;
  FILE *fd_out;
  uint32_t size;
  uint32_t lsize;
} riff_context;

static int next_id (riff_context *ctxt);

static int 
handler_RIFF (riff_context *ctxt)
{
  uint32_t size;
  fread (&size, 1, 4, ctxt->fd);

  printf ("RIFF data[%d]\n", size);
  
  ctxt->lsize = ctxt->size = size;

  return next_id (ctxt);
}

static int 
handler_CDXA (riff_context *ctxt)
{
  printf ("CDXA RIFF detected\n");

  next_id (ctxt); /* fmt */
  next_id (ctxt); /* data */

  return 0;
}

static int 
handler_data (riff_context *ctxt)
{
  uint32_t size;
  uint32_t sectors;
  fread (&size, 1, 4, ctxt->fd);

  if (size % 2352)
    printf ("warning size not a multiple of 2352 bytes!!");
  sectors = size / 2352;

  printf ("CDXA data[%d] (%d sectors)\n", size, sectors);

  if (ctxt->fd_out)
    {
      long first_nzero = -1, last_nzero = -1, s;
      struct {
	uint8_t sync[12];
	uint8_t header[4];
	uint8_t subheader[8];
	uint8_t data[2324];
	uint8_t edc[4];
      } sbuf;
      
      assert (sizeof (sbuf) == 2352);

      printf ("...converting...\n");

      for (s = 0; s < sectors; s++)
	{
	  int r = fread (&sbuf, 2352, 1, ctxt->fd);
	  bool empty = true;

	  {
	    int i;
	    for (i = 0; (i < 2324) && !sbuf.data[i]; i++);
	    empty = i == 2324;
	  }

	  if (!r)
	    {
	      if (ferror (ctxt->fd))
		printf ("fread (): %s\n", strerror (errno));

	      if (feof (ctxt->fd))
		printf ("premature end of file encountered after %ld sectors\n", s);
	      
	      fclose (ctxt->fd);
	      fclose (ctxt->fd_out);
	      exit (EXIT_FAILURE);
	    }

	  if (empty)
	    {
	      if (first_nzero == -1)
		continue;
	    }
	  else
	    {
	      last_nzero = s;

	      if (first_nzero == -1)
		first_nzero = s;
	    }

	  fwrite (&sbuf.data, 2324, 1, ctxt->fd_out);
	}

      fflush (ctxt->fd_out);
      
      {
	const long allsecs = (last_nzero - first_nzero + 1);
	ftruncate (fileno (ctxt->fd_out), allsecs * 2324);
	
	printf ("...stripped %ld leading and %ld trailing empty sectors...\n",
		first_nzero, (sectors - last_nzero - 1));
	printf ("...extraction done (%ld sectors extracted to file)!\n", allsecs);
      }
    }
  else
    printf ("no extraction done, since no output file was given\n");

  return 0;
}

static int 
handler_fmt (riff_context *ctxt)
{
  uint8_t buf[1024] = { 0, };
  uint32_t size;
  int i;

  fread (&size, 1, 4, ctxt->fd);

  assert (size < sizeof (buf));
  fread (buf, 1, (size % 2) ? size + 1 : size, ctxt->fd);

  printf ("CDXA fmt[%d] =", size);
  for (i = 0; i < size; i++)
    printf (" 0x%.2x", buf[i]);
  printf ("\n");

  return 0;
}

static int
handle (riff_context *ctxt, char id[4])
{
  struct {
    char id[4];
    int (*handler) (riff_context *);
  } handlers[] = {
    { "RIFF", handler_RIFF},
    { "CDXA", handler_CDXA},
    { "fmt ", handler_fmt},
    { "data", handler_data},
    { "", 0}
  }, *p = handlers;

  for (; p->id[0]; p++)
    if (!strncmp (p->id, id, 4))
      return p->handler (ctxt);

  printf ("unknown chunk id [%.4s] encountered\n", id);

  return -1;
}

static int
next_id (riff_context *ctxt)
{
  char id[4] = { 0, };

  fread (id, 1, 4, ctxt->fd);

  return handle (ctxt, id);
}

static void
usage (void)
{
  printf ("usage: cdxa2mpg infile [outfile]\n\n"
	  "description: \n"
	  "  Converts a Video CD RIFF CDXA file to plain mpeg streams\n\n"
	  "copyright: \n"
	  "  Copyright (C) 2001 Herbert Valerio Riedel <hvr@gnu.org>\n"
	  "  This is free software; see the source for copying conditions.  There is NO\n"
	  "  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n");

  exit (EXIT_FAILURE);
}

int 
main (int argc, char *argv[])
{
  FILE *in = NULL, *out = NULL;
  riff_context ctxt = { 0, };

  if (argc == 2 || argc == 3)
    {
      in = fopen (argv[1], "rb");
      if (!in) 
	{
	  printf ("fopen (): %s\n", strerror (errno));
	  exit (EXIT_FAILURE);
	}
    }
  else
    usage ();

  if (argc == 3)
    {
      out = fopen (argv[2], "wb");
      if (!out) 
	{
	  printf ("fopen (): %s\n", strerror (errno));
	  exit (EXIT_FAILURE);
	}
    }
  
  ctxt.fd = in;
  ctxt.fd_out = out;
  
  next_id (&ctxt);

  if (in)
    fclose (in);

  if (out)
    fclose (out);
 
  return 0;
}

/*
  Local Variables:
  c-file-style: "gnu"
  tab-width: 8
  indent-tabs-mode: nil
  compile-command: "gcc -Wall -O2 -ansi -o cdxa2mpeg cdxa2mpeg.c"
  End:
*/ 

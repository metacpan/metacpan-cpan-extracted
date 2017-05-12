/* PerlHBM
 * Copyright (C) 1999  Author <someone@somewhere>
 *
 * PerlHBM is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * PerlHBM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with PerlHBM; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <hb.h>

#include <EXTERN.h>
#include <perl.h>

#include <pthread.h>

/*
 * The hbm_info pointer is used by HB to keep information about us. We should
 * never access it directly and we should initialize it to NULL.
 *
 */

HBModule *hbm_info = NULL;

static int               perl_code ( HBArgs *d );
static int               hbm_perl_exec ( HBArgs *d, char *code );

static pthread_mutex_t   perl_mutex = PTHREAD_MUTEX_INITIALIZER;
static PerlInterpreter  *perl_int;

#include <perlxsi.c>

int
hbm_init ( HBArgs *d )
{
  return d->sym->function(d, "perl.code", &perl_code, NULL);
}

static int
perl_code ( HBArgs *d )
{
  char *em[] = { "", "-e", "0" };

  char *code;
  int   code_f;

  int   retval;

  if (!d->sym->arg(d, NULL, &code, NULL, &code_f))
    return 0;

  if (!code)
    return 1;

  pthread_mutex_lock(&perl_mutex);

  perl_int = perl_alloc();
  perl_construct(perl_int);
  perl_parse(perl_int, xs_init, 3, em, NULL);
  perl_run(perl_int);

  perl_eval_pv("use HB;", TRUE);

  retval = hbm_perl_exec(d, code);

  perl_destruct(perl_int);
  perl_free(perl_int);

  pthread_mutex_unlock(&perl_mutex);

  if (code_f)
    free(code);

  return retval;
}

static int
hbm_perl_exec (HBArgs *d, char *code)
{
  dSP;

  SV  *args;
  SV  *retval;

  args = perl_get_sv("args", TRUE);
  if (!args)
    printf("PANIC: No args\n");

  sv_setref_pv(args, "hbargsPtr", (void*) d);

  retval = perl_eval_pv(code, TRUE);

  return SvIV(retval);
}

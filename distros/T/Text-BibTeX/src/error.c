/* ------------------------------------------------------------------------
@NAME       : error.c
@DESCRIPTION: Collecting errors and warnings.  The library never prints
              anything and never exits: every problem is appended to a
              caller-supplied bt_errors list, and the caller (the Perl XS
              layer) decides how to report it.
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <string.h>
#include "bt_internal.h"

static const char * errclass_names[BT_NUM_ERRCLASSES] =
{
   NULL,                        /* BTERR_NOTIFY */
   "warning",                   /* BTERR_CONTENT */
   "warning",                   /* BTERR_LEXWARN */
   "warning",                   /* BTERR_USAGEWARN */
   "error",                     /* BTERR_LEXERR */
   "syntax error",              /* BTERR_SYNTAX */
   "fatal error",               /* BTERR_USAGEERR */
   "internal error"             /* BTERR_INTERNAL */
};

const char *
bt_errclass_name (bt_errclass errclass)
{
   if ((int) errclass < 0 || (int) errclass >= BT_NUM_ERRCLASSES)
      return NULL;
   return errclass_names[errclass];
}

void
bt_errors_init (bt_errors *errs)
{
   memset (errs, 0, sizeof (*errs));
}

void
bt_errors_clear (bt_errors *errs)
{
   bt_error * e = errs->head;

   while (e)
   {
      bt_error * next = e->next;
      free (e->filename);
      free (e->item_desc);
      free (e->message);
      free (e);
      e = next;
   }
   bt_errors_init (errs);
}

void
bt_vreport (bt_errors *errs, bt_errclass errclass,
            const char *filename, int line,
            const char *item_desc, int item,
            const char *fmt, va_list ap)
{
   bt_error * e;
   bt_sbuf    msg;

   if (errs == NULL)
      return;

   bt_sbuf_init (&msg);
   bt_sbuf_vprintf (&msg, fmt, ap);

   e = bt_xmalloc (sizeof (bt_error));
   e->errclass = errclass;
   e->filename = bt_xstrdup (filename);
   e->line = line;
   e->item_desc = bt_xstrdup (item_desc);
   e->item = item;
   e->message = bt_sbuf_steal (&msg);
   e->next = NULL;

   if (errs->tail)
      errs->tail->next = e;
   else
      errs->head = e;
   errs->tail = e;
   errs->counts[errclass]++;
}

void
bt_report (bt_errors *errs, bt_errclass errclass,
           const char *filename, int line,
           const char *item_desc, int item,
           const char *fmt, ...)
{
   va_list ap;

   va_start (ap, fmt);
   bt_vreport (errs, errclass, filename, line, item_desc, item, fmt, ap);
   va_end (ap);
}

int
bt_errors_count (const bt_errors *errs, bt_errclass errclass)
{
   return errs->counts[errclass];
}

/* A "serious" error is anything other than a notification, a content
 * warning or a lexical warning -- the same rule btparse always used to
 * decide whether an entry parsed OK. */
boolean
bt_errors_ok (const bt_errors *errs)
{
   int i;

   for (i = 0; i < BT_NUM_ERRCLASSES; i++)
   {
      if (i == BTERR_NOTIFY || i == BTERR_CONTENT || i == BTERR_LEXWARN)
         continue;
      if (errs->counts[i])
         return FALSE;
   }
   return TRUE;
}

boolean
bt_errors_fatal (const bt_errors *errs)
{
   return errs->counts[BTERR_USAGEERR] || errs->counts[BTERR_INTERNAL];
}

/* $Id: $ */
/* XSUB for Perl module Text::Scws                      */
/* Copyright (c) 2008 Xueron Nee                        */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <scws.h>

/*****************************************************************************/
/* This struct represents a Text::Scws object */

struct tsobj
{
   scws_t handle;      /* scws handle (returned by scws_new()) */
};

/*****************************************************************************/

static int not_here(char *s)
{
   croak("%s not implemented on this architecture", s);
   return -1;
}

typedef struct tsobj Text__Scws;

/*****************************************************************************/
/* Perl interface                                                            */

MODULE = Text::Scws  PACKAGE = Text::Scws

PROTOTYPES: ENABLE

Text::Scws *
new(self)
   CODE:
      scws_t handle;
      Text__Scws *obj;

      handle = scws_new();
      if (handle == NULL) {
         croak("call scws_new() fail");
      }

      Newz(0, obj, 1, Text__Scws);
      if (obj == NULL) {
         croak("Newz: %s", strerror(errno));
      }

      obj->handle = handle;
      RETVAL = obj;
   OUTPUT:
      RETVAL

MODULE = Text::Scws  PACKAGE = Text::ScwsPtr  PREFIX = ts_

int
ts_set_charset(self, cs)
   Text::Scws *self
   char *cs
   CODE:
      scws_set_charset(self->handle, cs);
      RETVAL = 1;
   OUTPUT:
      RETVAL

int
ts_set_dict(self, fpath)
   Text::Scws *self
   char *fpath
   CODE:
      scws_set_dict(self->handle, fpath, SCWS_XDICT_XDB);
      RETVAL = (self->handle->d == NULL) ? 0 : 1;
   OUTPUT:
      RETVAL

int
ts_set_rule(self, fpath)
   Text::Scws *self
   char *fpath
   CODE:
      scws_set_rule(self->handle, fpath);
      RETVAL = (self->handle->r == NULL) ? 0 : 1;
   OUTPUT:
      RETVAL

int
ts_set_ignore(self, yes)
   Text::Scws *self
   int yes
   CODE:
      scws_set_ignore(self->handle, yes);
      RETVAL = 1;
   OUTPUT:
      RETVAL

int
ts_set_multi(self, yes)
   Text::Scws *self
   int yes
   CODE:
      scws_set_multi(self->handle, yes);
      RETVAL = 1;
   OUTPUT:
      RETVAL

int
ts_set_debug(self, yes)
   Text::Scws *self
   int yes
   CODE:
      not_here("(feature disables: scws_set_debug())");
      RETVAL = -1;
   OUTPUT:
      RETVAL

int
ts_send_text(self, text)
   Text::Scws *self
   char *text
   PREINIT:
      int len;
   CODE:
      len = strlen(text);
      scws_send_text(self->handle, text, len);
      RETVAL = 1;
   OUTPUT:
      RETVAL

SV *
ts_get_result(self)
   Text::Scws *self
   PREINIT:
   AV *av;
   scws_res_t res, cur;
   CODE:
      res = cur = scws_get_result(self->handle);
      if (res == NULL) {
         RETVAL = &PL_sv_undef;
      } else {
         av = newAV();
         while (cur != NULL) {  
            HV *hv;
            hv = newHV();
            hv_store(hv, "word", 4, newSVpv(self->handle->txt + cur->off, cur->len), 0);
            hv_store(hv, "attr", 4, newSVpv(cur->attr, 0), 0);
            hv_store(hv, "off",  3, newSViv(cur->off), 0);
            hv_store(hv, "len",  3, newSViv(cur->len), 0);
            hv_store(hv, "idf",  3, newSVnv(cur->idf), 0);

            av_push(av, newRV((SV*)hv));
            SvREFCNT_dec(hv);

            //printf("Word: %.*s/%s (IDF = %4.2f)\n", cur->len, self->handle->txt + cur->off, cur->attr, cur->idf);
            cur = cur->next;
         }
         scws_free_result(res);
         RETVAL = newRV((SV*)av);
         SvREFCNT_dec(av);
      }
   OUTPUT:
      RETVAL

void
ts_DESTROY(self)
   Text::Scws *self
   CODE:
      //printf("Now in Text::Scws::DESTROY\n");
      (void) scws_free(self->handle);
      Safefree(self);

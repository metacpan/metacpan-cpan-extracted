#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>

#include "hb.h"

typedef HBReq   hbreq;
typedef HBArgs  hbargs;

static int
req_function_inner (HBArgs *d)
{
  dSP;

  SV    *args;
  int    retval;

  ENTER;
  SAVETMPS;

  args = sv_newmortal();
  sv_setref_pv(args, "hbargsPtr", (void*) d);

  PUSHMARK(SP);
  XPUSHs(args);
  PUTBACK;

  perl_call_sv(d->sym->data(d), G_SCALAR);
  retval = POPi;

  FREETMPS;
  LEAVE;

  return retval;
}

MODULE = HB PACKAGE = HB

PROTOTYPES: DISABLE

void
hb_init()
    ALIAS:
        HB::init = 1
    CODE:
        hb_init(NULL, NULL);

void
hb_shutdown()
    ALIAS:
        HB::shutdown = 1

void
hb_clean()
    ALIAS:
        HB::clean = 1

hbreq *
hb_req_create()
    ALIAS:
        HB::req = 1
    CODE:
        RETVAL = malloc(sizeof(HBReq));
        if (RETVAL)
          hb_req_init(RETVAL);
    OUTPUT:
        RETVAL

MODULE = HB PACKAGE = hbreq PREFIX = req

PROTOTYPES: DISABLE

void
req_DESTROY (req)
    hbreq *req;
    CODE:
    	hb_req_free(req);
	free(req);

int
hb_req_file(req, file)
    hbreq *req;
    char *file;
    ALIAS:
    	hbreqPtr::file = 1

int
hb_req_name (req, name)
    hbreq *req;
    char *name;
    ALIAS:
    	hbreqPtr::name = 1

int
hb_req_input (req, input)
    hbreq *req;
    char *input;
    ALIAS:
    	hbreqPtr::input = 1

int
hb_req_exec (req)
    hbreq *req;
    ALIAS:
    	hbreqPtr::exec = 1

char *
hb_req_content (req)
    hbreq *req;
    ALIAS:
    	hbreqPtr::content = 1

int
hb_req_status (req)
    hbreq *req;
    ALIAS:
    	hbreqPtr::status = 1

int
hb_req_string_wrapper (req, name, value)
    hbreq *req;
    char *name;
    char *value
    ALIAS:
        hbreqPtr::string = 1
    CODE:
        RETVAL = hb_req_string(req, name, value, strlen(value), 0);
    OUTPUT:
        RETVAL

int
req_function_wrapper (req, name, callback)
    hbreq *req;
    char *name;
    SV *callback;
    ALIAS:
        hbreqPtr::function = 1
    CODE:
        RETVAL = hb_req_function(req, name, req_function_inner, callback);
    OUTPUT:
        RETVAL

MODULE = HB PACKAGE = hbargs PREFIX = args

PROTOTYPES: DISABLE

SV *
args_arg (args, name)
    hbargs *args;
    char   *name;
    ALIAS:
        hbargsPtr::arg = 1
    CODE:
	{
	  char *val;
	  int   val_l;
	  int   val_f;

          if (!args->sym->arg(args, name, &val, &val_l, &val_f))
            RETVAL = &PL_sv_undef;
	  else
            {
	      /* If val is NULL, we should really use undef. However, that
	       * would make it impossible to detect an error condition.
	       */
              RETVAL = newSVpv(val ? val : "", val ? val_l : 0);
              if (val_f)
                free(val);
            }
	}
    OUTPUT:
        RETVAL

SV *
args_remote_addr (args)
    hbargs *args;
    ALIAS:
        hbargsPtr::remote_addr = 1
    CODE:
        RETVAL = newSVpv(args->sym->remote_addr(args), 0);
    OUTPUT:
        RETVAL

int
args_adds (args, st)
    hbargs *args;
    SV     *st;
    ALIAS:
        hbargsPtr::adds = 1
    CODE:
        RETVAL = args->sym->adds(args, SvPV(st, SvCUR(st)), SvCUR(st));
    OUTPUT:
        RETVAL

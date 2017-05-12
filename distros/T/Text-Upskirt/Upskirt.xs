#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "markdown.h"
#include "html.h"
#include "buffer.h"

#include "const-c.inc"

MODULE = Text::Upskirt		PACKAGE = Text::Upskirt

INCLUDE: const-xs.inc

SV *markdown(input, extens = 0, html = 0)
    char *input
    unsigned int extens
    unsigned int html
    CODE:
       struct mkd_renderer renderer;
       struct buf *ib, *ob;
       SV *out;

       ib = bufnew(1024);
       ob = bufnew(64);
       bufputs(ib, input);
       upshtml_renderer(&renderer, html);
       ups_markdown(ob, ib, &renderer, extens);
       upshtml_free_renderer(&renderer);
       out = newSVpv(ob->data, ob->size);
       bufrelease(ib);
       bufrelease(ob);
       RETVAL = out;

    OUTPUT:
      RETVAL

SV *smartypants(input)
    char *input
    CODE:
       struct buf *ib, *ob;
       SV *out;

       ib = bufnew(1024);
       ob = bufnew(64);
       bufputs(ib, input);
       upshtml_smartypants(ob, ib);
       out = newSVpv(ob->data, ob->size);
       bufrelease(ib);
       bufrelease(ob);
       RETVAL = out;

    OUTPUT:
      RETVAL

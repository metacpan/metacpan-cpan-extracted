#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "markdown.h"
#include "renderers.h"
#include <errno.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

MODULE = libsoldout		PACKAGE = libsoldout		

#define OUTPUT_UNIT 64


SV *
markdown2html(in_buffer)
        char * in_buffer;
INIT:
        SV * res;
CODE:
        struct buf *ib, *ob;
        const struct mkd_renderer *hrndr, *xrndr;
        const struct mkd_renderer **prndr;

        /* default options: strict markdown input, HTML output */
        hrndr = &mkd_html;
        xrndr = &mkd_xhtml;
        prndr = &hrndr;

        /* create the input buffer, grow it an push the data on it */
        ib = bufnew(strlen(in_buffer)+1);
        bufgrow(ib, strlen(in_buffer)+1);
        ib->size = strlen(in_buffer);
        strcpy(ib->data,in_buffer);

        /* create the output buffer */
        ob = bufnew(OUTPUT_UNIT);

        /* perform the markdown conversion */
        markdown(ob, ib, *prndr);

        res = newSVpv(ob->data,ob->size);
        /* fwrite(ob->data, 1, ob->size, stdout); */
        RETVAL = res;

        /* cleanup */
        bufrelease(ib);
        bufrelease(ob);
OUTPUT:
        RETVAL


SV *
markdown2discount_html(in_buffer)
        char * in_buffer;
INIT:
        SV * res;
CODE:
        struct buf *ib, *ob;
        const struct mkd_renderer *hrndr, *xrndr;
        const struct mkd_renderer **prndr;

        /* default options: strict markdown input, HTML output */
        hrndr = &discount_html;
        xrndr = &discount_xhtml;
        prndr = &hrndr;

        /* create the input buffer, grow it an push the data on it */
        ib = bufnew(strlen(in_buffer)+1);
        bufgrow(ib, strlen(in_buffer)+1);
        ib->size = strlen(in_buffer);
        strcpy(ib->data,in_buffer);

        /* create the output buffer */
        ob = bufnew(OUTPUT_UNIT);

        /* perform the markdown conversion */
        markdown(ob, ib, *prndr);

        res = newSVpv(ob->data,ob->size);
        /* fwrite(ob->data, 1, ob->size, stdout); */
        RETVAL = res;

        /* cleanup */
        bufrelease(ib);
        bufrelease(ob);
OUTPUT:
        RETVAL


SV *
markdown2nath_tml(in_buffer)
        char * in_buffer;
INIT:
        SV * res;
CODE:
        struct buf *ib, *ob;
        const struct mkd_renderer *hrndr, *xrndr;
        const struct mkd_renderer **prndr;

        /* default options: strict markdown input, HTML output */
        hrndr = &nat_html;
        xrndr = &nat_xhtml;
        prndr = &hrndr;

        /* create the input buffer, grow it an push the data on it */
        ib = bufnew(strlen(in_buffer)+1);
        bufgrow(ib, strlen(in_buffer)+1);
        ib->size = strlen(in_buffer);
        strcpy(ib->data,in_buffer);

        /* create the output buffer */
        ob = bufnew(OUTPUT_UNIT);

        /* perform the markdown conversion */
        markdown(ob, ib, *prndr);

        res = newSVpv(ob->data,ob->size);
        /* fwrite(ob->data, 1, ob->size, stdout); */
        RETVAL = res;

        /* cleanup */
        bufrelease(ib);
        bufrelease(ob);
OUTPUT:
        RETVAL

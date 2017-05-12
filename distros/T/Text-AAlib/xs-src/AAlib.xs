#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <aalib.h>

static void boot_setup_const(void)
{
    HV *stash = gv_stashpv("Text::AAlib", 1);

    /* enum aa_dithering_mode */
    newCONSTSUB(stash, "AA_NONE"         , newSViv(AA_NONE));
    newCONSTSUB(stash, "AA_ERRORDISTRIB" , newSViv(AA_ERRORDISTRIB));
    newCONSTSUB(stash, "AA_FLOYD_S"      , newSViv(AA_FLOYD_S));
    newCONSTSUB(stash, "AA_DITHERTYPES"  , newSViv(AA_DITHERTYPES));

    /* enum aa_attribute */
    newCONSTSUB(stash, "AA_NORMAL"   , newSViv(AA_NORMAL));
    newCONSTSUB(stash, "AA_BOLD"     , newSViv(AA_BOLD));
    newCONSTSUB(stash, "AA_DIM"      , newSViv(AA_DIM));
    newCONSTSUB(stash, "AA_BOLDFONT" , newSViv(AA_BOLDFONT));
    newCONSTSUB(stash, "AA_REVERSE"  , newSViv(AA_REVERSE));

    /* masks for attibute */
    newCONSTSUB(stash, "AA_NORMAL_MASK"   , newSViv(AA_NORMAL_MASK));
    newCONSTSUB(stash, "AA_DIM_MASK"      , newSViv(AA_DIM_MASK));
    newCONSTSUB(stash, "AA_BOLD_MASK"     , newSViv(AA_BOLD_MASK));
    newCONSTSUB(stash, "AA_BOLDFONT_MASK" , newSViv(AA_BOLDFONT_MASK));
    newCONSTSUB(stash, "AA_REVERSE_MASK"  , newSViv(AA_REVERSE_MASK));
}

MODULE = Text::AAlib    PACKAGE = Text::AAlib

PROTOTYPES: disable

BOOT:
    boot_setup_const();

void
xs_init(SV *width, SV *height, SV *mask)
CODE:
{
    aa_context *context;
    struct aa_hardware_params param;

    param = aa_defparams;
    if (SvOK(width)) {
        param.width  = SvIV(width);
    }
    if (SvOK(height)) {
        param.height  = SvIV(height);
    }
    if (SvOK(mask)) {
        param.supported = SvIV(mask);
    }

    context = aa_init(&mem_d, &param, NULL);
    if (context == NULL) {
        croak("Error aa_init");
    }

    ST(0) = sv_2mortal( newSViv(PTR2IV(context)) );
    XSRETURN(1);
}

void
xs_copy_default_parameter()
CODE:
{
    HV * h;
    h = (HV*)sv_2mortal((SV*)newHV());

    (void)hv_store(h, "bright",    6, newSViv(aa_defrenderparams.bright), 0);
    (void)hv_store(h, "contrast",  8, newSViv(aa_defrenderparams.contrast), 0);
    (void)hv_store(h, "gamma",     5, newSVnv(aa_defrenderparams.gamma), 0);
    (void)hv_store(h, "dither",    6, newSViv(aa_defrenderparams.dither), 0);
    (void)hv_store(h, "inversion", 9, newSViv(aa_defrenderparams.inversion), 0);
    (void)hv_store(h, "randomval", 9, newSViv(aa_defrenderparams.randomval), 0);

    ST(0) = newRV((SV*)h);
    XSRETURN(1);
}

void
xs_putpixel(struct aa_context *context, SV *x, SV *y, SV *color)
CODE:
{
    aa_putpixel(context, SvIV(x), SvIV(y), SvIV(color));
}

void
xs_puts(struct aa_context *context, SV *x, SV *y, SV *attr, SV *str)
CODE:
{
    aa_puts(context, SvIV(x), SvIV(y), SvIV(attr), SvPV_nolen(str));
}

void
xs_render(struct aa_context *context, struct aa_renderparams ar, \
          SV *x1, SV *y1, SV *x2, SV *y2)
CODE:
{
    aa_render(context, &ar, SvIV(x1), SvIV(y1), SvIV(x2), SvIV(y2));
}

void
xs_text(struct aa_context *context)
CODE:
{
    AV *text_array;
    int width, height;
    int i, j;
    unsigned char *text;

    text_array = (AV*)sv_2mortal((SV*)newAV());

    width  = aa_scrwidth(context);
    height = aa_scrheight(context);

    text = aa_text(context);
    for (i = 0; i < height; i++) {
        AV *row = newAV();
        for (j = 0; j < width; j++) {
            av_push(row, newSViv(text[i * width + j]));
        }
        av_push(text_array, newRV((SV*)row));
    }

    ST(0) = (SV*)newRV((SV*)text_array);
    XSRETURN(1);
}

void
xs_attrs(struct aa_context *context)
CODE:
{
    AV *attr_array;
    int width, height;
    int i, j;
    unsigned char *attr;

    attr_array = (AV*)sv_2mortal((SV*)newAV());

    width  = aa_scrwidth(context);
    height = aa_scrheight(context);

    attr = aa_attrs(context);
    for (i = 0; i < height; i++) {
        AV *row = newAV();
        for (j = 0; j < width; j++) {
            av_push(row, newSViv(attr[i * width + j]));
        }
        av_push(attr_array, newRV((SV*)row));
    }

    ST(0) = (SV*)newRV((SV*)attr_array);
    XSRETURN(1);
}

void
xs_image(struct aa_context *context)
CODE:
{
    unsigned char *p;

    p = aa_image(context);
    if (p == NULL) {
        croak("No image buffer");
    }
}

void
xs_resize(struct aa_context *context)
CODE:
{
    if (aa_resize(context) == 0) {
        warn("no resize");
    }
}

void
xs_flush(struct aa_context *context)
CODE:
{
    aa_flush(context);
}

void
xs_close(struct aa_context *context)
CODE:
{
    aa_close(context);
}

void
xs_render_width(struct aa_context *context)
CODE:
{
    ST(0) = sv_2mortal( newSViv( aa_scrwidth(context)) );
    XSRETURN(1);
}

void
xs_render_height(struct aa_context *context)
CODE:
{
    ST(0) = sv_2mortal( newSViv( aa_scrheight(context)) );
    XSRETURN(1);
}

void
xs_imgwidth(struct aa_context *context)
CODE:
{
    ST(0) = sv_2mortal( newSViv( aa_imgwidth(context)) );
    XSRETURN(1);
}

void
xs_imgheight(struct aa_context *context)
CODE:
{
    ST(0) = sv_2mortal( newSViv( aa_imgheight(context)) );
    XSRETURN(1);
}

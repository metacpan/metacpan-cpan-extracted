/*
 * $Id: Aosd.xs,v 1.3 2008/03/29 16:28:30 joern Exp $
 *
 * This binds libaosd functions of
 *
 *    aosd.h version 0.2.4.
 * 
 * Written by Jörn Reder with support from Thorsten Schönfeld.
 *
 * Copyright (C) 2008 Jörn Reder, All Rights Reserved
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.8.8 or,
 * at your option, any later version of Perl 5 you may have available.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libaosd/aosd.h>
#include <gperl.h>
#include <cairo-perl.h>

#include "const-c.inc"

/* Render callback glue - thanks to Thorsten ;) */

static void
perl_aosd_renderer (cairo_t *cr, void *user_data)
{
    GPerlCallback *callback = user_data;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK (SP);
    EXTEND (SP, 2);
    PUSHs (sv_2mortal (newSVCairo (cr)));
    PUSHs (sv_2mortal (newSVsv (callback->data)));
    PUTBACK;

    call_sv (callback->func, G_DISCARD);

    FREETMPS;
    LEAVE;
}

static void
perl_aosd_mouse_event_cb (AosdMouseEvent* event, void* user_data)
{
    GPerlCallback *callback = user_data;
    HV *event_hash;
    dSP;

    ENTER;
    SAVETMPS;

    event_hash = newHV();
    hv_store(event_hash, "x",           1, newSViv((IV)event->x),           0);
    hv_store(event_hash, "y",           1, newSViv((IV)event->y),           0);
    hv_store(event_hash, "x_root",      6, newSViv((IV)event->x_root),      0);
    hv_store(event_hash, "y_root",      6, newSViv((IV)event->y_root),      0);
    hv_store(event_hash, "send_event",  9, newSViv((IV)event->send_event),  0);
    hv_store(event_hash, "button",      6, newSViv((IV)event->button),      0);
    hv_store(event_hash, "time",        4, newSViv((IV)event->time),        0);
    
    PUSHMARK (SP);
    EXTEND (SP, 2);
    PUSHs (sv_2mortal (newRV((SV*)event_hash)));
    PUSHs (sv_2mortal (newSVsv (callback->data)));
    PUTBACK;

    call_sv (callback->func, G_DISCARD);

    FREETMPS;
    LEAVE;
}

MODULE = X11::Aosd	PACKAGE = X11::Aosd     PREFIX = aosd_

INCLUDE: const-xs.inc

#-- object (de)allocators

Aosd *
aosd_new(class)
    C_ARGS:
	/* void */

void
DESTROY (Aosd *aosd)
    CODE:
	aosd_destroy (aosd);

#-- object inspectors

void
aosd_get_name(Aosd* aosd);
    INIT:
    XClassHint result;
    
    PPCODE:
    aosd_get_name(aosd, &result);

    XPUSHs(sv_2mortal(newSVpv((char*)result.res_name, 0)));
    XPUSHs(sv_2mortal(newSVpv((char*)result.res_class, 0)));

#-- void aosd_get_names(Aosd* aosd, char** res_name, char** res_class);

AosdTransparency
aosd_get_transparency(Aosd *aosd)

void
aosd_get_geometry(Aosd* aosd)
    INIT:
    int x,y,width,height;
    
    PPCODE:
    aosd_get_geometry(aosd, &x, &y, &width, &height);
    
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));

void
aosd_get_screen_size(Aosd* aosd)
    INIT:
    int width,height;

    PPCODE:
    aosd_get_screen_size(aosd, &width, &height);
    
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));

Bool
aosd_get_is_shown(Aosd* aosd)

#-- object configurators

void
aosd_set_name(Aosd* aosd, char* res_name, char* res_class)
    INIT:
    XClassHint name;
    
    CODE:
    name.res_name  = res_name;
    name.res_class = res_class;
    
    aosd_set_name(aosd, &name);


#-- void aosd_set_names(Aosd* aosd, char* res_name, char* res_class);

void
aosd_set_transparency(Aosd* aosd, AosdTransparency mode)

void
aosd_set_geometry(Aosd* aosd, int x, int y, int width, int height);

void
aosd_set_position(Aosd* aosd, unsigned pos, int width, int height);

void
aosd_set_position_offset(Aosd* aosd, int x_offset, int y_offset)

void
aosd_set_position_with_offset(Aosd* aosd, AosdCoordinate abscissa, AosdCoordinate ordinate, int width, int height, int x_offset, int y_offset);

void
aosd_set_renderer (Aosd *aosd, SV *func, SV *data=NULL)
    PREINIT:
        GPerlCallback *callback;
    CODE:
        callback = gperl_callback_new (func, data, 0, NULL, 0);
        aosd_set_renderer (aosd, perl_aosd_renderer, callback);

void
aosd_set_mouse_event_cb(Aosd* aosd, SV *func, SV *data=NULL)
    PREINIT:
        GPerlCallback *callback;
    CODE:
        callback = gperl_callback_new (func, data, 0, NULL, 0);
        aosd_set_mouse_event_cb (aosd, perl_aosd_mouse_event_cb, callback);

void
aosd_set_hide_upon_mouse_event(Aosd* aosd, Bool enable);

#-- object manipulators
void
aosd_render(Aosd* aosd)

void
aosd_show(Aosd* aosd);

void
aosd_hide(Aosd* aosd);


#-- X main loop processing
void
aosd_loop_once(Aosd* aosd)

void
aosd_loop_for(Aosd* aosd, unsigned loop_ms)


#-- automatic object manipulator
void
aosd_flash(Aosd* aosd, unsigned fade_in_ms, unsigned full_ms, unsigned fade_out_ms);

/* NOTE: THIS FILE WAS POSSIBLY AUTO-GENERATED! */

/*
 * Copyright (c) 2005 Brian Tarricone <bjt23@cornell.edu>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "xfce4perl.h"

MODULE = Xfce4::Clock    PACKAGE = Xfce4::Clock    PREFIX = xfce_clock_

GtkWidget *
xfce_clock_new(class)
    C_ARGS:
        /* void */

void
xfce_clock_show_ampm(clock, show)
        XfceClock * clock
        gboolean show

void
xfce_clock_ampm_toggle(clock)
        XfceClock * clock

gboolean
xfce_clock_ampm_shown(clock)
        XfceClock * clock

void
xfce_clock_show_secs(clock, show)
        XfceClock * clock
        gboolean show

void
xfce_clock_secs_toggle(clock)
        XfceClock * clock

gboolean
xfce_clock_secs_shown(clock)
        XfceClock * clock

void
xfce_clock_show_military(clock, show)
        XfceClock * clock
        gboolean show

void
xfce_clock_military_toggle(clock)
        XfceClock * clock

gboolean
xfce_clock_military_shown(clock)
        XfceClock * clock

void
xfce_clock_set_interval(clock, interval)
        XfceClock * clock
        guint interval

guint
xfce_clock_get_interval(clock)
        XfceClock * clock

void
xfce_clock_set_led_size(clock, size)
        XfceClock * clock
        XfceClockLedSize size

XfceClockLedSize
xfce_clock_get_led_size(clock)
        XfceClock * clock

void
xfce_clock_suspend(clock)
        XfceClock * clock

void
xfce_clock_resume(clock)
        XfceClock * clock

void
xfce_clock_set_mode(clock, mode)
        XfceClock * clock
        XfceClockMode mode

void
xfce_clock_toggle_mode(clock)
        XfceClock * clock

XfceClockMode
xfce_clock_get_mode(clock)
        XfceClock * clock


// Copyright © 2015 David Caldwell <david@porkrind.org>.
//
// This library is free software; you can redistribute it and/or modify
// it under the same terms as Perl itself, either Perl version 5.12.4 or,
// at your option, any later version of Perl 5 you may have available.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "monotonic_clock.h"

MODULE = Time::Monotonic             PACKAGE = Time::Monotonic

char *
monotonic_clock_name()
    CODE:
        RETVAL = (char*)monotonic_clock_name;
    OUTPUT:
        RETVAL

int
monotonic_clock_is_monotonic()

double
clock_get_dbl_fallback()

double
clock_get_dbl()

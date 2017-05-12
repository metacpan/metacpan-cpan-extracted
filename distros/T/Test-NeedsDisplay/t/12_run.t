#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	# ENV{DISPLAY} = undef if $ENV{DISPLAY};
}

use t::lib::Display;
t::lib::Display::xeyes();


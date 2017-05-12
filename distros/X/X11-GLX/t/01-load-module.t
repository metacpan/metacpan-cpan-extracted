#! /usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok('X11::GLX')
 && use_ok('X11::GLX::DWIM')
 or BAIL_OUT;

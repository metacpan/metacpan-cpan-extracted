#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;
no utf8;

use Test::More tests => 1;
use Unicode::Precis::Utils qw(mapSpace);

my $string = pack 'U*',
    0x0020,
    0x00A0,
    0x1680,
    0x2000,
    0x2001,
    0x2002,
    0x2003,
    0x2004,
    0x2005,
    0x2006,
    0x2007,
    0x2008,
    0x2009,
    0x200A,
    0x202F,
    0x205F,
    0x3000;
my $mapped = "\x20" x length($string);

is(mapSpace($string), $mapped, sprintf '%d spaces', length $mapped);

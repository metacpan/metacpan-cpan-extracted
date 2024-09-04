#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use autobox::universal 'type';

# SVt_IV, SVt_NV and SVt_PV can all hold undef now (though they all have the
# same SvTYPE (SVt_NULL), so it makes no difference to the code (or this test))

# $ perl -MDevel::Peek -e 'Dump(undef)'
#
#   SV = NULL(0x0) at 0x4321
#     REFCNT = 1234567890
#     FLAGS = (READONLY,PROTECT)
#
# $ perl -MDevel::Peek -e 'my $val = 42; undef $val; Dump($val)'
#
#   SV = IV(0x1234) at 0x4321
#     REFCNT = 1
#     FLAGS = ()
#     IV = 42
#
# $ perl -MDevel::Peek -e 'my $val = 3.1415927; undef $val; Dump($val)'
#
#   SV = NV(0x1234) at 0x4321
#     REFCNT = 1
#     FLAGS = ()
#     NV = 3.1415926999999999
#
# $ perl -MDevel::Peek -e 'my $val = "foo"; undef $val; Dump($val)'
#
#   SV = PV(0x1234) at 0x4321
#     REFCNT = 1
#     FLAGS = ()
#     PV = 0

my $undef = undef;
is type($undef), 'UNDEF', 'undef is UNDEF';

my $int = 42;
undef $int;
is type($int), 'UNDEF', 'undefined INTEGER is UNDEF';

my $float = 3.1415927;
undef $float;
is type($float), 'UNDEF', 'undefined FLOAT is UNDEF';

my $string = 'foo';
undef $string;
is type($string), 'UNDEF', 'undefined STRING is UNDEF';

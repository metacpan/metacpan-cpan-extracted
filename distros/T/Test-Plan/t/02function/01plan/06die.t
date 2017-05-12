# $Id $

use strict;
use warnings FATAL => qw(all);

use Test::More;
use Test::Plan;

plan tests => 1;

eval { plan tests => 1, {} };

like ($@,
      qr/don't know how to handle a condition of type HASH/,
      'hash reference is an unknown precondition for plan()');

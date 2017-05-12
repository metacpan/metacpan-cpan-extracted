# $Id $

use strict;
use warnings FATAL => qw(all);

use Test::More;

local $^O = 'MSWin32';

if ( $^O ne 'MSWin32' ) {
  plan tests => 3;
}
else {
  plan 'skip_all';
}

fail('this test should not run');

# $Id $

use strict;
use warnings FATAL => qw(all);

use Test::More;
use Test::Plan;

local $^O = 'MSWin32';

plan tests => 1, sub { $^O ne 'MSWin32' };

fail('this test should not run');

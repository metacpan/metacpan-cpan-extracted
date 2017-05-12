# $Id $

use strict;
use warnings FATAL => qw(all);

use Test::Plan;

plan tests => 1, need_module('Foo::Zwazzle');

die('the test should not get here');

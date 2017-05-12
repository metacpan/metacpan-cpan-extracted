# $Id $

use strict;
use warnings FATAL => qw(all);

use Test::Plan qw(plan need_module);
use Test::More import => [qw(!plan)];

plan tests => 1, need_module('CGI');

pass('this test should run');

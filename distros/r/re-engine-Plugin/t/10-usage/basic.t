use strict;
use lib 't/10-usage';
use Test::More tests => 1;

use basic;

"str" =~ /pattern/;

is($1, "str_1");


use strict;
use Test;

plan tests => 1;

ok( eval 'use XML::CuteQueries; 1' ) or warn $@;

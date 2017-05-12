#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render('<TMPL_VAR NAME=foo>', params => { foo => 'this is foo'}, expected => 'this is foo');
compare_render('<TMPL_VAR EXPR=foo>', params => { foo => 'this is foo'}, expected => 'this is foo');

done_testing;



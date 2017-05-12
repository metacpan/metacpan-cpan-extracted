#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_ast('[% 1 %]', '<TMPL_VAR EXPR=1>');
compare_ast('[% "abc" %]', q{<TMPL_VAR EXPR='"abc"'>});
compare_ast('[% 1+2*3 %]', '<TMPL_VAR EXPR=1+2*3>', params => {});
compare_ast('[% $foo * 2%]', '<TMPL_VAR EXPR="foo * 2">', params => { foo => 5});

done_testing;



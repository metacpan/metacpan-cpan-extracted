#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_ast('[% $foo %]', '<TMPL_VAR NAME=foo>', args => { foo => 'this is foo'});
compare_ast('[% $foo %]', '<TMPL_VAR EXPR=foo>', args => { foo => 'this is foo'});

done_testing;



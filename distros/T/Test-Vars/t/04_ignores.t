#!perl -w

use strict;
use Test::More;

use Test::Vars;

vars_ok 't/lib/Warned1.pm', ignore_vars => { '$an_unused_var' => 1 };
vars_ok 't/lib/Warned1.pm', ignore_vars => [ '$an_unused_var' ];
vars_ok 't/lib/Warned1.pm', ignore_if   => sub{ /unused/ };


done_testing;

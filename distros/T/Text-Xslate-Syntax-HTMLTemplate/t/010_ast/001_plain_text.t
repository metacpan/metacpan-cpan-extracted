#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_ast(qq{plain text}, qq{plain text});
compare_ast(qq{123}, qq{123});

done_testing;

#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(qq{plain text}, expected => 'plain text');
compare_render(qq{plain text\nline 2}, expected => "plain text\nline 2");
compare_render(qq{123},  expected => 123);
compare_render(qq{a\tb\n\tc}, expected => qq{a\tb\n\tc});

done_testing;

use strict;
use warnings;
use Test::Script;
use Test::More;

script_compiles('t/bin/taint.pl');
script_runs('t/bin/taint.pl');

done_testing;

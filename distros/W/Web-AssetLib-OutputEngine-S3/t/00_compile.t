use strict;
use Test::More 0.98;
use Test::Compile;

my $test = Test::Compile->new();
$test->all_files_ok();
$test->done_testing();
 

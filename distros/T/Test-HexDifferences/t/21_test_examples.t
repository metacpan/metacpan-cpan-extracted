#!perl

use strict;
use warnings;

use Test::More;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING} or plan(
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.'
);

plan(tests => 2);

for my $test ( qw(01_eq_or_dump_diff.t 02_dumped_eq_dump_or_diff.t) ) {
    my $dir = getcwd();
    chdir "$dir/example";
    my $result = qx{prove -I../lib -T $test 2>&1};
    $CHILD_ERROR && $CHILD_ERROR != 256
        and die "Couldn't run $test (status $CHILD_ERROR)";
    chdir $dir;
    like(
        $result,
        qr{\QFailed 2/3 subtests\E | \Qfailed 2 tests of 3\E }xms,
        "prove example $test",
    );
}

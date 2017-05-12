#!perl

use Test::More tests => 2;
use Test::Harness;

BEGIN {
    $ENV{HARNESS_ACCEPT_FILES} = '^(\w+|\d+)\.t';
    use_ok( 'Test::Harness::FileFilter' );
}

diag( 'Testing HARNESS_ACCEPT_FILES' );

my @files = glob("t/suite/*.t");

{
    my ($ok, $failed) = Test::Harness::_run_all_tests(@files);
    ok($ok->{files} == 2 && $ok->{ok} == 2);
}

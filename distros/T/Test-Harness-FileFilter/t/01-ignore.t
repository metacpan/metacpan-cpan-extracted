#!perl

use Test::More tests => 2;

BEGIN {
    $ENV{HARNESS_IGNORE_FILES} = '0[12]-\w+\.t';
    use_ok( 'Test::Harness::FileFilter' );
}

diag( 'Testing HARNESS_IGNORE_FILES' );

my @files = glob("t/suite/*.t");

{
    my ($ok, $failed) = Test::Harness::_run_all_tests(@files);
    ok($ok->{files} == 3 && $ok->{ok} == 3);
}

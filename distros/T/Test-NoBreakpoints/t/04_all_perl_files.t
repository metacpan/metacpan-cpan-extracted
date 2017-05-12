BEGIN {
    use Test::More;
    our $tests = 1;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib';
}

use Test::NoBreakpoints 'all_perl_files';
use Test::Exception;

# test that all files in the test directory are found properly
my @tests = qw|
   ./00-load.t
   ./01_use.t
   ./02_pod.t
   ./04_all_perl_files.t
   ./05_no_breakpoints_ok.t
   ./06_all_files_no_breakpoints_ok.t
   ./baz/foo.t
   ./baz/gzonk/foo.pl
   ./baz/quux/Foo.pm
   ./release-no-tabs.t
   ./release-kwalitee.t
   ./release-pod-coverage.t
   ./release-pod-syntax.t
|;

my @expected = sort @tests;

my @gotback = sort( all_perl_files('.') );

is_deeply(\@gotback, \@expected, 'all perl files found');


BEGIN {
    use Test::More;
    unless ($ENV{RELEASE_TESTING}) {
        plan skip_all => 'Release test. Set $ENV{RELEASE_TESTING} to a true value to run.';
    }
}

use strict;
use warnings;

eval "use Test::NoTabs";
plan skip_all => "Test::NoTabs required for testing tabs" if $@;

my @files = (
    'lib/Test/NoBreakpoints.pm',
    't/00-load.t',
    't/01_use.t',
    't/02_pod.t',
    't/04_all_perl_files.t',
    't/05_no_breakpoints_ok.t',
    't/06_all_files_no_breakpoints_ok.t',
    't/bar1',
    't/bar2',
    't/bar3',
    't/bar4',
    't/bar5',
    't/bar6',
    't/baz/foo.t',
    't/baz/gzonk/foo.pl',
    't/baz/quux/Foo.pm',
    't/foo',
    't/release-kwalitee.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
);

notabs_ok($_) foreach @files;
done_testing;

use strict;
use warnings;

use Test::Tester 0.108;
use Test::More 0.88;
use Test::Deep;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

plan( skip_all => "running in a bare repository (some files missing): skipping" ) if -d '.git';

require Test::Kwalitee;

my ($premature, @results) = run_tests(
    sub {
        # prevent Test::Kwalitee from making a plan
        no warnings 'redefine';
        local *Test::Builder::plan = sub { };
        local *Test::Builder::done_testing = sub { };

        # we are testing ourselves, so we don't want this warning
        local $ENV{_KWALITEE_NO_WARN} = 1;

        Test::Kwalitee->import;
    },
);

# this list reflects Module::CPANTS::Analyse 0.88 (also works on 0.87)
my @expected = qw(
    has_buildtool
    has_changelog
    has_manifest
    has_meta_yml
    has_readme
    has_tests
    no_symlinks
    use_strict
);

# this somewhat redundant test allows an easier way of seeing which tests failed
cmp_deeply(
    [ map { $_->{name} } @results ],
    superbagof(@expected),
    'expected tests ran',
);

cmp_deeply(
    \@results,
    superbagof(
        map {
            superhashof({
                name => $_,
                depth => 1,
                ok => 1,
                actual_ok => 1,
                type => '',
                diag => '',
            })
        } @expected
    ),
    'our expected tests ran correctly',
) or diag 'got results: ', diag \@results;

done_testing;

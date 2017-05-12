use strict;
use warnings;

use Test::Tester 0.108;
use Test::More;
use Test::Warnings qw(:all :no_end_test);
use Test::Deep;
use File::pushd 'pushd';
use Test::NewVersion;

use lib 't/lib';
use NoNetworkHits;

{
    my $wd = pushd('t/corpus/basic');

    my ($premature, @results) = run_tests(sub {
        # prevent done_testing from performing a warnings check
        {
            package Test::Tester::Delegate;
            sub in_subtest { 1 }
        }

        # Test::Tester cannot handle calls to done_testing?!
        no warnings 'redefine';
        local *Test::Builder::done_testing = sub { };

        all_new_version_ok();
    });

    # this somewhat redundant test allows an easier way of seeing which tests failed
    cmp_deeply(
        [ map { $_->{name} } @results ],
        [
            'Bar::Baz (lib/Bar/Baz.pm) VERSION is ok (not indexed)',
            re(qr{^ExtUtils::MakeMaker \(lib/ExtUtils\/MakeMaker\.pm\) VERSION is ok \(indexed at \d.\d+; local version is 100\.0\)$}),
            'Foo (lib/Foo.pm) VERSION is ok (not indexed)',
            re(qr{^Moose \(lib/Moose\.pm\) VERSION is ok \(VERSION is not set; indexed version is \d.\d+\)$}),
            re(qr{^Moose::Cookbook \(lib/Moose\/Cookbook\.pod\) VERSION is ok \(indexed at \d.\d+; local version is 20\.0\)$}),
            'Plack::Test (lib/Plack/Test.pm) VERSION is ok (VERSION is not set in index)',
        ],
        'expected tests ran',
    )
    or diag('ran tests: ', do { require Data::Dumper; Data::Dumper::Dumper([map { $_->{name} } @results ]) });

    # on older Test::More, depth appears to be 2, but it really ought to be 1
    # (it gets confused by the do $file) - see https://github.com/Test-More/test-more/issues/533
    my $depth = eval 'require Test::Stream; 1' ? 1 : ignore;

    cmp_deeply(
        \@results,
        [
            superhashof({
                name => 'Bar::Baz (lib/Bar/Baz.pm) VERSION is ok (not indexed)',
                ok => 1, actual_ok => 1,
                depth => $depth, type => '', diag => '',
            }),
            superhashof({
                name => re(qr{^ExtUtils::MakeMaker \(lib/ExtUtils\/MakeMaker\.pm\) VERSION is ok \(indexed at \d.\d+; local version is 100\.0\)$}),
                ok => 1, actual_ok => 1,
                depth => $depth, type => '', diag => '',
            }),
            superhashof({
                name => 'Foo (lib/Foo.pm) VERSION is ok (not indexed)',
                ok => 1, actual_ok => 1,
                depth => $depth, type => '', diag => '',
            }),
            superhashof({
                name => re(qr{^Moose \(lib/Moose\.pm\) VERSION is ok \(VERSION is not set; indexed version is \d.\d+\)$}),
                ok => 0, actual_ok => 0,
                depth => $depth, type => '', diag => '',
            }),
            superhashof({
                name => re(qr{^Moose::Cookbook \(lib/Moose\/Cookbook\.pod\) VERSION is ok \(indexed at \d.\d+; local version is 20\.0\)$}),
                ok => 1, actual_ok => 1,
                depth => $depth, type => '', diag => '',
            }),
            superhashof({
                name => 'Plack::Test (lib/Plack/Test.pm) VERSION is ok (VERSION is not set in index)',
                ok => 1, actual_ok => 1,
                depth => $depth, type => '', diag => '',
            }),
        ],
        'our expected tests ran correctly',
    );
}

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;

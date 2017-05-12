#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 0.96; # subtests don't work properly on earlier versions

BEGIN { require_ok( 'Warnings::Version' ); }

my @versions = qw/ 5.6 5.8 5.10 5.12 5.14 5.16 5.18 5.20 /;
my @all = qw/ closure exiting glob io closed exec newline pipe unopened misc
    numeric once overflow pack portable recursion redefine regexp debugging
    inplace internal malloc signal substr syntax ambiguous bareword deprecated
    digit parenthesis precedence printf prototype qw reserved semicolon taint
    uninitialized unpack untie utf8 void /;

subtest 'Checking that warnings don\'t get removed when filtered on version' =>
   sub {
    is_deeply(
        [ Warnings::Version::get_warnings('all', 'all') ],
        [ @all ],
        'Warnings for all versions of perl are correct'
    );
    foreach my $version (@versions) {
        is_deeply(
            [ Warnings::Version::get_warnings('all', $version) ],
            [ @all ],
            "No warnings removed by filtering with $version"
        );
    }
};

my %warnings = (
    '5.6'  => {
        '5.6'  => [ qw/ chmod umask y2k / ],
        '5.8'  => [ qw/ y2k / ],
        '5.10' => [ ],
        '5.12' => [ ],
        '5.14' => [ ],
        '5.16' => [ ],
        '5.18' => [ ],
        '5.20' => [ ],
    },
    '5.8'  => {
        '5.6'  => [ qw/ y2k / ],
        '5.8'  => [ qw/ layer threads y2k / ],
        '5.10' => [ qw/ layer threads / ],
        '5.12' => [ qw/ layer threads / ],
        '5.14' => [ qw/ layer threads / ],
        '5.16' => [ qw/ layer threads / ],
        '5.18' => [ qw/ layer threads / ],
        '5.20' => [ qw/ layer threads / ],
    },
    '5.10' => {
        '5.6'  => [ ],
        '5.8'  => [ qw/ layer threads / ],
        '5.10' => [ qw/ layer threads / ],
        '5.12' => [ qw/ layer threads / ],
        '5.14' => [ qw/ layer threads / ],
        '5.16' => [ qw/ layer threads / ],
        '5.18' => [ qw/ layer threads / ],
        '5.20' => [ qw/ layer threads / ],
    },
    '5.12' => {
        '5.6'  => [ ],
        '5.8'  => [ qw/ layer threads / ],
        '5.10' => [ qw/ layer threads / ],
        '5.12' => [ qw/ layer imprecision illegalproto threads / ],
        '5.14' => [ qw/ layer imprecision illegalproto threads / ],
        '5.16' => [ qw/ layer imprecision illegalproto threads / ],
        '5.18' => [ qw/ imprecision layer illegalproto threads / ],
        '5.20' => [ qw/ imprecision layer illegalproto threads / ],
    },
    '5.14' => {
        '5.6'  => [ ],
        '5.8'  => [ qw/ layer threads / ],
        '5.10' => [ qw/ layer threads / ],
        '5.12' => [ qw/ layer imprecision illegalproto threads / ],
        '5.14' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.16' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.18' => [ qw/ imprecision layer illegalproto threads non_unicode
            nonchar surrogate / ],
        '5.20' => [ qw/ imprecision layer illegalproto threads non_unicode
            nonchar surrogate / ],
    },
    '5.16' => {
        '5.6'  => [ ],
        '5.8'  => [ qw/ layer threads / ],
        '5.10' => [ qw/ layer threads / ],
        '5.12' => [ qw/ layer imprecision illegalproto threads / ],
        '5.14' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.16' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.18' => [ qw/ imprecision layer illegalproto threads non_unicode
            nonchar surrogate / ],
        '5.20' => [ qw/ imprecision layer illegalproto threads non_unicode
            nonchar surrogate / ],
    },
    '5.18' => {
        '5.6'  => [ ],
        '5.8'  => [ qw/ layer threads / ],
        '5.10' => [ qw/ layer threads / ],
        '5.12' => [ qw/ layer imprecision illegalproto threads / ],
        '5.14' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.16' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.18' => [ qw/ experimental::lexical_subs imprecision layer
            illegalproto threads non_unicode nonchar surrogate / ],
        '5.20' => [ qw/ experimental::lexical_subs imprecision layer
            illegalproto threads non_unicode nonchar surrogate / ],
    },
    '5.20' => {
        '5.6'  => [ ],
        '5.8'  => [ qw/ layer threads / ],
        '5.10' => [ qw/ layer threads / ],
        '5.12' => [ qw/ layer imprecision illegalproto threads / ],
        '5.14' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.16' => [ qw/ layer imprecision illegalproto threads surrogate
            non_unicode nonchar / ],
        '5.18' => [ qw/ experimental::lexical_subs imprecision layer
            illegalproto threads non_unicode nonchar surrogate / ],
        '5.20' => [ qw/ experimental::autoderef experimental::lexical_subs
            experimental::lexical_topic experimental::postderef
            experimental::regex_sets experimental::signatures
            experimental::smartmatch imprecision layer syscalls illegalproto
            threads non_unicode nonchar surrogate / ],
    },
);

foreach my $test_version (@versions) {
    subtest "Checking for perl $test_version warnings" => sub {
        foreach my $version (@versions) {
            is_deeply(
                [ Warnings::Version::get_warnings($test_version, $version) ],
                [ @all, @{ $warnings{$test_version}{$version} } ],
                "Warnings for perl $test_version on $version are right"
            );
        }
    };
}

done_testing;

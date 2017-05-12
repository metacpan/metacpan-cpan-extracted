#!perl
############ STANDARD Pod::Coverage TEST - DO NOT EDIT ##################
use Test::More;
use strict;
unless ($ENV{POD_TESTS} || $ENV{PERL_AUTHOR} || $ENV{THIS_IS_MARKF_YOU_BETCHA}) {
    Test::More::plan(
        skip_all => "Test::Pod::Coverage tests not enabled (set POD_TESTS or PERL_AUTHOR env var)"
    );
}
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::CountParents' });

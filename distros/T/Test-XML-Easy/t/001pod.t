#!perl
############## STANDARD Test::Pod TEST - DO NOT EDIT ####################
use strict;
use Test::More;
unless ($ENV{POD_TESTS} || $ENV{PERL_AUTHOR} || $ENV{THIS_IS_MARKF_YOU_BETCHA}) {
    Test::More::plan(
        skip_all => "Test::Pod tests not enabled (set POD_TESTS or PERL_AUTHOR env var)"
    );
}
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();

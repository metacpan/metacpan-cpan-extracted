#!perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'Author tests not required for installation'
    unless $ENV{RELEASE_TESTING};

eval "use ExtUtils::Manifest qw(filecheck manicheck)";
plan skip_all => "ExtUtils::Manifest required" if $@;

is_deeply [manicheck()], [], 'all files from MANIFEST exist';
is_deeply [filecheck()], [], 'no files not mentioned in MANIFEST(.SKIP) exist';

done_testing;

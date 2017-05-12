use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

plan skip_all => 'add WWW::Ohloh::API to the environment variable TEST_AUTHOR
to run this test' unless $ENV{TEST_AUTHOR} =~ /WWW::Ohloh::API/;

eval 'use Test::Prereq::Build';
plan skip_all => "Test::Prereq::Build required to test dependencies" if $@;

plan tests => 1;

prereq_ok();

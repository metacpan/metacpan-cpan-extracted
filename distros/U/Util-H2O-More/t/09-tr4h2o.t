#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin         qw/$Bin/;
use Util::H2O::More qw/h2o tr4h2o/;
use Config::Tiny    qw//;
use File::Temp      qw/tempfile/;

my $hash = { "foo bar" => 123, "quz-ba%z" => 456 };
my $obj  = h2o tr4h2o $hash;

is $obj->foo_bar,  123, q{tr4h2o made accessor compliant as expected};
is $obj->quz_ba_z, 456, q{tr4h2o made accessor compliant as expected};

my $og_keys = $obj->__og_keys;
is ref $og_keys,         q{HASH},     q{__og_keys returns HASH ref};
is $og_keys->{foo_bar},  q{foo bar},  q{original key 'foo bar' preserved via '__og_keys'};
is $og_keys->{quz_ba_z}, q{quz-ba%z}, q{original key 'qaz-ba%z' preserved via '__og_keys'};

done_testing;

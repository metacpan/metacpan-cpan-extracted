#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::Standard -types;
use Types::SQL::Util;

my $type = Object;

throws_ok {
  my %info = column_info_from_type($type);
} qr/Unsupported type: Object/;

done_testing;

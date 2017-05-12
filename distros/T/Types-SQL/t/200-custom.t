#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Type::Library
  -base,
  -declare => qw/ CustomStr /;

use Type::Utils qw/ -all /;
use Types::SQL -types;
use Types::SQL::Util;

declare CustomStr, as Varchar [64];

my $type = CustomStr;

isa_ok $type => 'Type::Tiny';

my %info = column_info_from_type($type);

is_deeply \%info => {
    data_type  => 'varchar',
    is_numeric => 0,
    size       => 64,
  },
  'column_info'
  or note( explain \%info );

done_testing;

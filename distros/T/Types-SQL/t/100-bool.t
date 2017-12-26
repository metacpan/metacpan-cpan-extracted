#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL::Util;
use Types::Standard -types;

subtest 'bool' => sub {

    my $type = Bool;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'boolean' },
      'column_info'
      or note( explain \%info );

};

subtest 'maybe bool' => sub {

    my $type = Maybe [Bool];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'boolean',
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

done_testing;

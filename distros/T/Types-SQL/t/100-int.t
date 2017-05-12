#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL::Util;
use Types::Standard -types;

subtest 'int' => sub {

    my $type = Int;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'integer', is_numeric => 1, },
      'column_info'
      or note( explain \%info );

};

subtest 'maybe int' => sub {

    my $type = Maybe [Int];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'integer',
        is_numeric  => 1,
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

done_testing;

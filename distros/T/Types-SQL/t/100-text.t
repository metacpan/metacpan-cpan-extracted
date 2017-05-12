#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL -types;
use Types::SQL::Util;

subtest 'no size' => sub {

    my $type = Text;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'text',
        is_numeric => 0,
      },
      'column_info'
      or note( explain \%info );

};

done_testing;

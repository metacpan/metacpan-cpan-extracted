#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL::Util;
use Types::Standard -types;

foreach my $type (Bool,
                  InstanceOf['Types::Serialiser::Boolean'],
                  InstanceOf['JSON::PP::Boolean'],
    ) {
    subtest $type->display_name => sub {

        my %info = column_info_from_type($type);

        is_deeply \%info => { data_type => 'boolean' },
          'column_info'
          or note( explain \%info );

    };

    my $maybe = Maybe [$type];

    subtest $maybe->display_name => sub {

        my %info = column_info_from_type($maybe);

        is_deeply \%info => { data_type => 'boolean', is_nullable => 1 },
          'column_info'
          or note( explain \%info );

    };

}

done_testing;

#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL qw/ Serial /;
use Types::SQL::Util;

subtest 'no size' => sub {

    my $type = Serial;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type         => 'serial',
        is_auto_increment => 1,
        is_numeric        => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'size' => sub {

    my $size = 12;
    my $type = Serial [$size];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type         => 'serial',
        is_auto_increment => 1,
        is_numeric        => 1,
        size              => $size,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'bad size' => sub {

    throws_ok {
        my $type = Serial ['x'];
    }
    qr/Size must be a positive integer/, 'invalid size';

};

done_testing;

#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL -types;
use Types::SQL::Util;
use Types::Standard -types;

subtest 'no size' => sub {

    no warnings 'void';

    my $type = Varchar;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'varchar',
        is_numeric => 0,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'size' => sub {

    no warnings 'void';

    my $size = 12;
    my $type = Varchar [$size];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'varchar',
        is_numeric => 0,
        size       => $size,
      },
      'column_info'
      or note( explain \%info );

    ok !$type->check(undef), 'check (undef)';
    ok $type->check( '1' x $size ), 'check';
    ok !$type->check( '1' x ( $size + 1 ) ), 'check';

};

subtest 'maybe size' => sub {

    my $size = 12;
    my $type = Maybe [ Varchar [$size] ];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'varchar',
        is_numeric  => 0,
        size        => $size,
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

    ok $type->check(undef), 'check (undef)';
    ok $type->check( '1' x $size ), 'check';
    ok !$type->check( '1' x ( $size + 1 ) ), 'check';

};

subtest 'bad size' => sub {

    throws_ok {
        my $type = Varchar ['x'];
    }
    qr/Size must be a positive integer/, 'invalid size';

};

done_testing;

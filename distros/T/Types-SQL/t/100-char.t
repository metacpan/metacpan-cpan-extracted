#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL qw/ Char /;
use Types::SQL::Util;
use Types::Standard -types;

subtest 'no size' => sub {

    no warnings 'void';

    my $type = Char;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'char',
        is_numeric => 0,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'size' => sub {

    no warnings 'void';

    my $size = 12;
    my $type = Char [$size];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'char',
        is_numeric => 0,
        size       => $size,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'maybe size' => sub {

    my $size = 12;
    my $type = Maybe [ Char [$size] ];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'char',
        is_numeric  => 0,
        size        => $size,
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'bad size' => sub {

    throws_ok {
        my $type = Char ['x'];
    }
    qr/Size must be a positive integer/, 'invalid size';

};

done_testing;

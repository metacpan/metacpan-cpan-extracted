#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL qw/ Numeric /;
use Types::SQL::Util;

subtest 'no size' => sub {

    my $type = Numeric;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'numeric',
        is_numeric => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'size' => sub {

    my $size = 12;
    my $type = Numeric [$size];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'numeric',
        is_numeric => 1,
        size       => [$size],
      },
      'column_info'
      or note( explain \%info );

    ok !$type->check(undef), 'check (undef)';
    ok $type->check( '1' x $size ), 'check';
    ok !$type->check( ( '1' x $size ) . '.2' ), 'check';
    ok !$type->check( 'x' x $size ), 'check';
    ok !$type->check( '1' x ( $size + 1 ) ), 'check';

};

subtest 'size range' => sub {

    my $prec  = 12;
    my $scale = 2;

    my $type = Numeric [ $prec, $scale ];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'numeric',
        is_numeric => 1,
        size       => [ $prec, $scale ],
      },
      'column_info'
      or note( explain \%info );

    my $left = $prec - $scale;

    ok !$type->check(undef), 'check (undef)';
    ok $type->check( '1' x $left ), 'check';
    ok $type->check( ( '1' x $left ) . '.2' ), 'check';
    ok $type->check( ( '1' x $left ) . '.' . ('3' x $scale) ), 'check';
    ok !$type->check( ( '1' x $left ) . '.' . ('3' x ($scale+1)) ), 'check';
    ok !$type->check( ( '1' x ($left+1) ) . '.' . ('3' x ($scale)) ), 'check';

    ok !$type->check( 'x' x $left ), 'check';
    ok !$type->check( '1' x ( $left + 1 ) ), 'check';

};

subtest 'bad size' => sub {

    throws_ok {
        my $type = Numeric ['x'];
    }
    qr/Precision must be a positive integer/, 'invalid size';

};

done_testing;

#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL::Util;
use Types::Standard -types;

subtest 'IntstanceOf[DateTime]' => sub {

    my $type = InstanceOf['DateTime'];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp' },
      'column_info'
      or note( explain \%info );

};

subtest 'IntstanceOf[DateTime::Tiny]' => sub {

    my $type = InstanceOf['DateTime::Tiny'];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp' },
      'column_info'
      or note( explain \%info );

};

subtest 'Maybe InstanceOf[DateTime]' => sub {

    my $type = Maybe [InstanceOf['DateTime']];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'timestamp',
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'IntstanceOf[Time::Moment]' => sub {

    my $type = InstanceOf['Time::Moment'];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp' },
      'column_info'
      or note( explain \%info );

};

subtest 'Maybe InstanceOf[Time::Moment]' => sub {

    my $type = Maybe [InstanceOf['Time::Moment']];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'timestamp',
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'IntstanceOf[Time::Piece]' => sub {

    my $type = InstanceOf['Time::Piece'];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp' },
      'column_info'
      or note( explain \%info );

};

subtest 'Maybe InstanceOf[Time::Piece]' => sub {

    my $type = Maybe [InstanceOf['Time::Piece']];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'timestamp',
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'IntstanceOf[Date]' => sub {

    my $type = InstanceOf['Date'];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp' },
      'column_info'
      or note( explain \%info );

};

done_testing;

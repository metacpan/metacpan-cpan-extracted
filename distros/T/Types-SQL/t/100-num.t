#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::Common::Numeric qw/ PositiveOrZeroNum /;
use Types::Standard qw/ Num /;
use Types::SQL::Util;

subtest 'Num' => sub {

    my $type = Num;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'numeric',
        is_numeric => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'PositiveOrZeroNum' => sub {

    my $type = PositiveOrZeroNum;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'numeric',
        is_numeric => 1,
        extra      => { unsigned => 1 },
      },
      'column_info'
      or note( explain \%info );

};

done_testing;

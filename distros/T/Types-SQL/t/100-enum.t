#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL::Util;
use Types::Standard -types;

subtest 'enum' => sub {

    my $type = Enum [qw/ foo bar baz /];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    cmp_deeply \%info => {
        data_type  => 'enum',
        is_numeric => 0,
        is_enum    => 1,
        extra      => { list => bag(qw/ foo bar baz /) },
      },
      'column_info'
      or note( explain \%info );

};

subtest 'maybe enum' => sub {

    my $type = Maybe [ Enum [qw/ bing bo bop /] ];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    cmp_deeply \%info => {
        data_type   => 'enum',
        is_numeric  => 0,
        is_enum     => 1,
        is_nullable => 1,
        extra       => { list => bag(qw/ bing bo bop /) },
      },
      'column_info'
      or note( explain \%info );

};

done_testing;

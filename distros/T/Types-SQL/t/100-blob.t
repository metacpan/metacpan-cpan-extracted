#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL qw/ Blob /;
use Types::SQL::Util;

subtest 'no size' => sub {

    my $type = Blob;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'blob',
        is_numeric => 0,
      },
      'column_info'
      or note( explain \%info );

};

done_testing;

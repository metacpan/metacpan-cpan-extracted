#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL::Util;
eval "use Types::DateTime -all";

plan skip_all => "Types::DateTime not installed" if $@;

subtest 'DateTime' => sub {

    my $type = Types::DateTime->DateTime;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp' },
      'column_info'
      or note( explain \%info );

};

subtest 'DateTimeWithZone' => sub {

    my $type = Types::DateTime->DateTimeWithZone;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp with time zone' },
      'column_info'
      or note( explain \%info );

};

subtest 'DateTimeUTC' => sub {

    my $type = Types::DateTime->DateTimeUTC;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp with time zone' },
      'column_info'
      or note( explain \%info );

};

subtest 'Now' => sub {

    my $type = Types::DateTime->Now;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'timestamp', default_value => \ "CURRENT_TIMESTAMP" },
      'column_info'
      or note( explain \%info );

};

done_testing;

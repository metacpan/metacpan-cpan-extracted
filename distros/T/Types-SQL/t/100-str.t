#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::SQL::Util;
use Types::Standard -types;
use Types::Common::String -types;

foreach my $type ( Str, NonEmptyStr, LowerCaseStr, UpperCaseStr ) {

    subtest $type->name => sub {

        my %info = column_info_from_type($type);

        is_deeply \%info => { data_type => 'text', is_numeric => 0 },
          'column_info'
          or note( explain \%info );

    };

    my $maybe = Maybe [$type];

    subtest $maybe->display_name => sub {

        my %info = column_info_from_type($maybe);

        is_deeply \%info =>
          { data_type => 'text', is_numeric => 0, is_nullable => 1 },
          'column_info'
          or note( explain \%info );

    };

    my $array = ArrayRef[$type];

    subtest $array->display_name => sub {

        my %info = column_info_from_type($array);

        is_deeply \%info =>
          { data_type => 'text[]', is_numeric => 0 },
          'column_info'
          or note( explain \%info );

    };

}

foreach my $type ( SimpleStr, NonEmptySimpleStr, LowerCaseSimpleStr,
    UpperCaseSimpleStr )
{

    subtest $type->name => sub {

        my %info = column_info_from_type($type);

        is_deeply \%info =>
          { data_type => 'text', is_numeric => 0, size => 255 },
          'column_info'
          or note( explain \%info );

    };

    my $maybe = Maybe [$type];

    subtest $maybe->display_name => sub {

        my %info = column_info_from_type($maybe);

        is_deeply \%info => {
            data_type   => 'text',
            is_numeric  => 0,
            size        => 255,
            is_nullable => 1
          },
          'column_info'
          or note( explain \%info );

    };

}

done_testing;

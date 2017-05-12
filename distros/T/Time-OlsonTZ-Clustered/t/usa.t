use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';
use Test::File::ShareDir -share =>
  { -dist => { 'Time-OlsonTZ-Clustered' => 'share' } };

use Time::OlsonTZ::Clustered qw/:all/;

my $us_clusters = [
    {
        'description' => 'Hawaii',
        'zones'       => [
            {
                'offset'            => -10,
                'olson_description' => 'Hawaii',
                'timezone_name'     => 'Pacific/Honolulu'
            }
        ]
    },
    {
        'description' => 'Aleutian Islands',
        'zones'       => [
            {
                'offset'            => -10,
                'olson_description' => 'Aleutian Islands',
                'timezone_name'     => 'America/Adak'
            }
        ]
    },
    {
        'description' => 'Alaska Time',
        'zones'       => [
            {
                'offset'            => '-9',
                'olson_description' => 'Alaska Time',
                'timezone_name'     => 'America/Anchorage'
            },
            {
                'offset'            => -9,
                'olson_description' => 'Alaska Time - west Alaska',
                'timezone_name'     => 'America/Nome'
            },
            {
                'offset'            => '-9',
                'olson_description' => 'Alaska Time - Alaska panhandle',
                'timezone_name'     => 'America/Juneau'
            },
            {
                'offset'            => '-9',
                'olson_description' => 'Alaska Time - Alaska panhandle neck',
                'timezone_name'     => 'America/Yakutat'
            },
            {
                'offset'            => '-9',
                'olson_description' => 'Alaska Time - southeast Alaska panhandle',
                'timezone_name'     => 'America/Sitka'
            },
        ]
    },
    {
        'description' => 'Pacific Time',
        'zones'       => [
            {
                'offset'            => -8,
                'olson_description' => 'Pacific Time',
                'timezone_name'     => 'America/Los_Angeles'
            }
        ]
    },
    {
        'description' => 'Metlakatla Time - Annette Island',
        'zones'       => [
            {
                'offset'            => -8,
                'olson_description' => 'Metlakatla Time - Annette Island',
                'timezone_name'     => 'America/Metlakatla'
            }
        ]
    },
    {
        'description' => 'Mountain Time',
        'zones'       => [
            {
                'offset'            => '-7',
                'olson_description' => 'Mountain Time',
                'timezone_name'     => 'America/Denver'
            },
            {
                'offset'            => -7,
                'olson_description' => 'Mountain Time - Navajo',
                'timezone_name'     => 'America/Shiprock'
            },
            {
                'offset'            => '-7',
                'olson_description' => 'Mountain Time - south Idaho & east Oregon',
                'timezone_name'     => 'America/Boise'
            },
        ]
    },
    {
        'description' => 'Mountain Standard Time - Arizona',
        'zones'       => [
            {
                'offset'            => -7,
                'olson_description' => 'Mountain Standard Time - Arizona',
                'timezone_name'     => 'America/Phoenix'
            }
        ]
    },
    {
        'description' => 'Central Time',
        'zones'       => [
            {
                'offset'            => '-6',
                'olson_description' => 'Central Time',
                'timezone_name'     => 'America/Chicago'
            },
            {
                'offset' => -6,
                'olson_description' =>
                  'Central Time - Michigan - Dickinson, Gogebic, Iron & Menominee Counties',
                'timezone_name' => 'America/Menominee'
            },
            {
                'offset'            => '-6',
                'olson_description' => 'Central Time - North Dakota - Mercer County',
                'timezone_name'     => 'America/North_Dakota/Beulah'
            },
            {
                'offset' => '-6',
                'olson_description' =>
                  'Central Time - North Dakota - Morton County (except Mandan area)',
                'timezone_name' => 'America/North_Dakota/New_Salem'
            },
            {
                'offset'            => '-6',
                'olson_description' => 'Central Time - Indiana - Starke County',
                'timezone_name'     => 'America/Indiana/Knox'
            },
            {
                'offset'            => '-6',
                'olson_description' => 'Central Time - Indiana - Perry County',
                'timezone_name'     => 'America/Indiana/Tell_City'
            },
            {
                'offset'            => '-6',
                'olson_description' => 'Central Time - North Dakota - Oliver County',
                'timezone_name'     => 'America/North_Dakota/Center'
            }
        ]
    },
    {
        'description' => 'Eastern Time',
        'zones'       => [
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time',
                'timezone_name'     => 'America/New_York'
            },
            {
                'offset'            => -5,
                'olson_description' => 'Eastern Time - Kentucky - Louisville area',
                'timezone_name'     => 'America/Kentucky/Louisville'
            },
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time - Indiana - Pike County',
                'timezone_name'     => 'America/Indiana/Petersburg'
            },
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time - Michigan - most locations',
                'timezone_name'     => 'America/Detroit'
            },
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time - Indiana - Crawford County',
                'timezone_name'     => 'America/Indiana/Marengo'
            },
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time - Indiana - Pulaski County',
                'timezone_name'     => 'America/Indiana/Winamac'
            },
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time - Indiana - most locations',
                'timezone_name'     => 'America/Indiana/Indianapolis'
            },
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time - Kentucky - Wayne County',
                'timezone_name'     => 'America/Kentucky/Monticello'
            },
            {
                'offset'            => '-5',
                'olson_description' => 'Eastern Time - Indiana - Switzerland County',
                'timezone_name'     => 'America/Indiana/Vevay'
            },
            {
                'offset' => '-5',
                'olson_description' =>
                  'Eastern Time - Indiana - Daviess, Dubois, Knox & Martin Counties',
                'timezone_name' => 'America/Indiana/Vincennes'
            }
        ]
    },
];

is( country_name("US"), "United States", "country_name is right" );
cmp_deeply( timezone_clusters('US'), $us_clusters, "US timezone clusters" );
cmp_deeply( timezone_clusters('uS'), $us_clusters,
    "country code is case insensitive" );

done_testing;
#
# This file is part of Time-OlsonTZ-Clustered
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

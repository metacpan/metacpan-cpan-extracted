#!/usr/bin/perl

# perl -Ilib t/lib/Yandex/Geo/Company.t

use strict;
use warnings;
use Test::More;
use File::Slurp;
use Geo::JSON;

BEGIN { use_ok('Yandex::Geo::Company'); }

my $a = Yandex::Geo::Company->new(
    id         => 12345,
    name       => 'Romashka LLC',
    phones     => [ '+1-541-754-3010', '+49-89-636-48018' ],
    postalCode => 344000,
    url        => 'example.com',
    links      => ['http://foo.bar']
);

my @all = @{ $a->properties->{all} };

# my @set = keys %$a;

for my $p (@all) {
    ok $a->can($p), "can $p";
}

ok $a->can('properties'), "can properties";
is_deeply $a->properties->{all}, \@all, 'all properties';

is_deeply $a->properties->{string},
  [qw/id name shortName url address postalCode vk instagram longitude latitude/
  ],
  'string properties';

is_deeply $a->properties->{array}, [qw/phones links/], 'array properties';

# is_deeply $a->properties->{set}, \@set, 'all set properties';

my $b = [
    12345,
    'Romashka LLC',
    undef,
    '+1-541-754-3010
+49-89-636-48018',
    344000,
    undef,
    'example.com',
    undef,
    undef,
    'http://foo.bar',
    undef,
    undef
];

is ref( $a->to_array ), 'ARRAY', 'Yandex::Geo::Company/to_array return array';

# check sequence of returned array by @all variable (taken from Object::Tiny definition of Yandex::Geo::Company)
is_deeply $a->to_array, $b, 'Yandex::Geo::Company/to_array works as documented';

# Testing from_geo_json and from_json
my $json_one = read_file('t/samples/one.json');
my $arr =
  Yandex::Geo::Company::from_geo_json( Geo::JSON->from_json($json_one) );

my $good = [
    Yandex::Geo::Company->new(
        'phones' =>
          [ '+7 (988) 515-11-03', '+7 (988) 251-82-16', '+7 (863) 221-91-14' ],
        'id'    => '1702445243',
        'links' => [
            'http://vk.com/gosmaket',
            'http://www.facebook.com/gosmaket',
            'https://www.instagram.com/gosmaket.ru'
        ],
        'name' =>
"\x{41c}\x{430}\x{43a}\x{435}\x{442}\x{43d}\x{430}\x{44f} \x{441}\x{442}\x{443}\x{434}\x{438}\x{44f} \x{413}\x{43e}\x{441}\x{43c}\x{430}\x{43a}\x{435}\x{442}",
        'url'       => 'http://gosmaket.ru/',
        'instagram' => 'https://www.instagram.com/gosmaket.ru',
        'shortName' =>
          "\x{413}\x{43e}\x{441}\x{43c}\x{430}\x{43a}\x{435}\x{442}",
        'vk' => 'http://vk.com/gosmaket',
        'address' =>
"1-\x{439} \x{41c}\x{430}\x{448}\x{438}\x{43d}\x{43e}\x{441}\x{442}\x{440}\x{43e}\x{438}\x{442}\x{435}\x{43b}\x{44c}\x{43d}\x{44b}\x{439} \x{43f}\x{435}\x{440}., 11",
        'postalCode' => '344090',
        'longitude'  => '47.254006',
        'latitude'   => '39.603088'
    )
];

is_deeply $arr, $good, 'from_geo_json works fine';

done_testing;

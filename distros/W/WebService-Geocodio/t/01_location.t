#!/usr/bin/perl

use strict;
use Test::More;
use WebService::Geocodio::Location;
use JSON;
use Data::Dumper;

plan tests => 17;

my $loc = WebService::Geocodio::Location->new(
    number => 1060,
    postdirection => 'W',
    street => 'Addison',
    suffix => 'St',
    city => 'Chicago',
    state => 'IL',
);

isa_ok($loc, 'WebService::Geocodio::Location');
is($loc->_forward_formatting, '1060 W Addison St, Chicago, IL', 'forward serializes properly');

my $loc1 = WebService::Geocodio::Location->new('1600 Pennsylvania Ave NW, Washington, DC');
isa_ok($loc1, 'WebService::Geocodio::Location');
is($loc1->_forward_formatting, '1600 Pennsylvania Ave NW, Washington, DC', 'forward serializes properly');

my $json_str = <<_EOF;
{
  "results": [
    {
      "query": "42370 Bob Hope Drive, Rancho Mirage CA",
      "response": {
        "input": {
          "address_components": {
            "number": "42370",
            "street": "Bob Hope",
            "suffix": "Dr",
            "city": "Rancho Mirage",
            "state": "CA"
          },
          "formatted_address": "42370 Bob Hope Dr, Rancho Mirage CA"
        },
        "results": [
          {
            "address_components": {
              "number": "42370",
              "street": "Bob Hope",
              "suffix": "Dr",
              "city": "Rancho Mirage",
              "state": "CA",
              "zip": "92270"
            },
            "formatted_address": "42370 Bob Hope Dr, Rancho Mirage CA, 92270",
            "location": {
              "lat": 33.738987255507,
              "lng": -116.40833849559
            },
            "accuracy": 1
          },
          {
            "address_components": {
              "number": "42370",
              "street": "Bob Hope",
              "suffix": "Dr",
              "city": "Rancho Mirage",
              "state": "CA",
              "zip": "92270"
            },
            "formatted_address": "42370 Bob Hope Dr, Rancho Mirage CA, 92270",
            "location": {
              "lat": 33.738980796909,
              "lng": -116.40833917329
            },
            "accuracy": 0.8
          }
        ]
      }
    }
  ]
}
_EOF

my $json = JSON->new();
my $obj = $json->decode($json_str);

my @l = map { WebService::Geocodio::Location->new($_) } map {; @{ $_->{response}->{results} } } @{ $obj->{results} };
isa_ok($l[0], 'WebService::Geocodio::Location');
isa_ok($l[1], 'WebService::Geocodio::Location');
is($l[0]->_forward_formatting, $l[1]->_forward_formatting, 'JSON serializes same');
is($l[0]->formatted, $l[1]->formatted, 'formatted address same');
isnt($l[0]->lng, $l[1]->lng, 'Longitude not same');
isnt($l[0]->lat, $l[1]->lat, 'Latitude not same');
isnt($l[0]->accuracy, $l[1]->accuracy, 'Accuracy not same');

my $loc2 =  WebService::Geocodio::Location->new(
    zip => 77056,
);

isa_ok($loc2, 'WebService::Geocodio::Location');
is($loc2->_forward_formatting, 77056, 'JSON serializes properly');

my $loc3 =  WebService::Geocodio::Location->new(
    city => 'Houston',
    state => 'TX',
);

isa_ok($loc3, 'WebService::Geocodio::Location');
is($loc3->_forward_formatting, 'Houston, TX', 'JSON serializes properly');

my $loc4 =  WebService::Geocodio::Location->new(
    city => 'Houston',
    state => 'TX',
    zip => '77056',
);

isa_ok($loc4, 'WebService::Geocodio::Location');
is($loc4->_forward_formatting, 77056, 'JSON serialization prefers zip');

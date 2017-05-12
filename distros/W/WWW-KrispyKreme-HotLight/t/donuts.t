use strict;
use warnings;

use Test::More;
use WWW::KrispyKreme::HotLight;
use Test::RequiresInternet ('krispykreme.com' => 80);

can_ok('WWW::KrispyKreme::HotLight',qw(new locations));

my $geo = [35.045556, -85.267222];    # chattanooga, tn
my $donuts = WWW::KrispyKreme::HotLight->new(where => $geo);
my $locations = $donuts->locations;

isa_ok($donuts,         'WWW::KrispyKreme::HotLight');
isa_ok($locations,      'ARRAY');
isa_ok($locations->[0], 'HASH');

my @keys = qw(
  Id
  LocationNumber
  Name
  Slug
  DetailUrl
  LocationType
  Address1
  Address2
  City
  Latitude
  Longitude
  Hotlight
  OffersCoffee
  OffersWifi
  LocationHours
);
ok(exists $locations->[0]{$_}, "$_ hash key exists") for @keys;

# Make sure our filter is working. This comes from the 'search' parameter now present in the API
ok($_->{Province} =~ /^(?:TN|GA|AL)$/, 'Each location is in TN/GA/AL') for @$locations;

done_testing;

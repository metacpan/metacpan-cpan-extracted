use 5.014;
use WebService::Geocodio;
use WebService::Geocodio::Location;

use Test::More;

BEGIN { 
    if (! $ENV{GEOCODIO_API_KEY} ) {
        plan skip_all => "Set GEOCODIO_API_KEY to run these tests.";
    }
    else {
        plan tests => 1;
    }
};

my $geo = WebService::Geocodio->new(
    api_key => $ENV{GEOCODIO_API_KEY}
);
    
# Wrigley Field
my $loc = WebService::Geocodio::Location->new(
    number => 1060,
    postdirection => 'W',
    street => 'Addison',
    suffix => 'Street',
    city => 'Chicago',
    state => 'IL',
);

$geo->add_location($loc, '20050');

$geo->add_field('timezone');

map { say $_->city, ": ", $_->lat, ", ", $_->lng, ", ", $_->fields->timezone->name } $geo->geocode();

ok(1);

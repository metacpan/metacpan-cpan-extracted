use 5.014;
use WebService::Geocodio;
use WebService::Geocodio::Location;

use Test::More;

BEGIN { 
    if (! $ENV{GEOCODIO_API_KEY} ) {
        plan skip_all => "Set GEOCODIO_API_KEY to run these tests.";
    }
    else {
        plan tests => 9;
    }
};

my $geo = WebService::Geocodio->new(
    api_key => $ENV{GEOCODIO_API_KEY}
);
    
# Chicago, IL
my $loc = WebService::Geocodio::Location->new(
    lat => 41.947205791667,
    lng => -87.656316875
);

$geo->add_location($loc);
$geo->add_field('timezone', 'cd', 'school', 'stateleg', 'foobar');
    
my @r = $geo->reverse_geocode();

is($r[0]->state, 'IL', "Got right state (IL)");
is($r[0]->fields->timezone->name, 'CST', "Got right timezone (CST)");

$geo->clear_locations();

# Washington DC
$geo->add_location('38.893311,-77.014647');

my $s = $geo->reverse_geocode();
is($s->[0]->city, 'Washington', "Got right city (Washington)");
is($s->[0]->fields->timezone->name, 'EST', "Got right timezone (EST)");

$geo->clear_locations();

my $t = $geo->geocode('5300 SW 21st St, Topeka, KS, 66604');

is($t->[1]->fields->cd->district_number, 2, "Got right district number (2)");
is($t->[1]->fields->stateleg->house->district_number, 53, "Got right state house district (52)");
is($t->[1]->fields->stateleg->senate->district_number, 20, "Got right state senate district (20)");
like($t->[1]->fields->school->unified->name, qr/501/, "Got right school district (501)");
is($t->[1]->fields->timezone->name, 'CST', "Got right timezone (CST)");

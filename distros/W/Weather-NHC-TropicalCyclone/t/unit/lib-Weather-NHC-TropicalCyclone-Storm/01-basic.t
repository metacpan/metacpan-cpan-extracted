use strict;
use warnings;
use FindBin qw/$Bin/;
use JSON::XS ();

use Test::More;

use_ok q{Weather::NHC::TropicalCyclone};
use_ok q{Weather::NHC::TropicalCyclone::Storm};

open my $dh, q{<}, qq{$Bin/../../data/CurrentStorms.json} or die $!;
local $/;
my $json = <$dh>;

# simulating HTTP::Tiny->get...
{
    no warnings qw/redefine once/;
    local *HTTP::Tiny::get = sub {
        return { content => $json, status => 200 };
    };
    my $obj2 = Weather::NHC::TropicalCyclone->new;
    isa_ok $obj2, q{Weather::NHC::TropicalCyclone}, q{Can create instance of Weather::NHC::TropicalCyclone};
    ok $obj2->fetch, q{testing 'fetch' method};
    is( 2, scalar @{ $obj2->{_obj}->{activeStorms} }, q{active_storms count is as expected} );
    for my $s ( @{ $obj2->active_storms } ) {
        isa_ok $s, q{Weather::NHC::TropicalCyclone::Storm};
        can_ok $s,
          qw/id binNumber name classification intensity pressure latitude longitude latitude_numberic movementDir movementSpeed lastUpdate publicAdvisory forecastAdvisory windSpeedProbabilities forecastDiscussion forecastGraphics forecastTrack windWatchesWarnings trackCone initialWindExtent forecastWindRadiiGIS bestTrackGIS earliestArrivalTimeTSWindsGIS mostLikelyTimeTSWindsGIS windSpeedProbabilitiesGIS kmzFile34kt kmzFile50kt kmzFile64kt stormSurgeWatchWarningGIS potentialStormSurgeFloodingGIS/;
        ok $s->name, q{found 'id' field};
        ok $s->name, q{found 'name' field};
        ok $s->name, q{found 'category' field};
        ok $s->name, q{found 'pressure' field};
        ok $s->name, q{found 'intensity' field};
        ok $s->name, q{found 'latitude' field};
        ok $s->name, q{found 'longitude' field};
        ok $s->name, q{found 'movementDir' field};
        ok $s->name, q{found 'movementSpeed' field};
        ok $s->name, q{found 'lastUpdate' field};
        ok $s->name, q{found 'binNumber' field};
    }
}

done_testing;

__END__

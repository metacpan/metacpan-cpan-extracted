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
        can_ok $s, qw/id binNumber name classification intensity pressure latitude longitude latitude_numberic movementDir movementSpeed lastUpdate publicAdvisory forecastAdvisory windSpeedProbabilities forecastDiscussion forecastGraphics forecastTrack windWatchesWarnings trackCone initialWindExtent forecastWindRadiiGIS bestTrackGIS earliestArrivalTimeTSWindsGIS mostLikelyTimeTSWindsGIS windSpeedProbabilitiesGIS kmzFile34kt kmzFile50kt kmzFile64kt stormSurgeWatchWarningGIS potentialStormSurgeFloodingGIS fetch_forecastGraphics_urls fetch_forecastAdvisory_as_atcf/;
        ok $s->id,             q{found 'id' field};
        ok $s->name,           q{found 'name' field};
        ok $s->classification, q{found 'category' field};
        ok $s->kind,           q{kind of storm based on 'classification' field with 'Human meaningful' entry};
        ok $s->pressure,       q{found 'pressure' field};
        ok $s->intensity,      q{found 'intensity' field};
        ok $s->latitude,       q{found 'latitude' field};
        ok $s->longitude,      q{found 'longitude' field};
        ok $s->movementDir,    q{found 'movementDir' field};
        ok $s->movementSpeed,  q{found 'movementSpeed' field};
        ok $s->lastUpdate,     q{found 'lastUpdate' field};
        ok $s->binNumber,      q{found 'binNumber' field};
    }
}

# simulating HTTP::Tiny->mirror
{
    no warnings qw/redefine once/;

    local *HTTP::Tiny::get = sub {
        return { content => $json, status => 200 };
    };

    my $url;
    local *HTTP::Tiny::mirror = sub {
        ( my $self, $url ) = @_;
        return { success => 1 };
    };

    my $obj3 = Weather::NHC::TropicalCyclone->new;
    $obj3->fetch;
    for my $s ( @{ $obj3->active_storms } ) {
        ok my $local_file = $s->fetch_best_track, q{set up to download best track ".dat" file looks good via fetch_best_track};
        my $expected_name = sprintf( qq{b%s.dat}, $s->id );
        is $local_file, $expected_name, q{expected best track file name returned};
        like $url, qr/$expected_name/, q{URL looks valid};
        is q{foobar.dat}, $s->fetch_best_track(q{foobar.dat}), q{custom local file honored by fetch_best_track};
        my $types = $s->_fetch_data_types;
        for my $type ( keys %$types ) {
            foreach my $field ( @{ $types->{$type} } ) {
                my $method = qq{fetch_$field};
                if ( $s->{$field} ) {
                    ok $s->$method($type), qq{'$method' set up looks good for URL '$type'};
                }
                else {
                    my $name = $s->name;
                    my $id   = $s->id;
                    note qq{Skipping '$method' test because test JSON file doesn't contain an entry for $name/$id};
                }
            }
        }
    }
}

done_testing;

__END__

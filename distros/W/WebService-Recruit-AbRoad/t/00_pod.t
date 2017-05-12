use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/AbRoad.pm
    lib/WebService/Recruit/AbRoad/Base.pm
    lib/WebService/Recruit/AbRoad/Tour.pm
    lib/WebService/Recruit/AbRoad/Area.pm
    lib/WebService/Recruit/AbRoad/Country.pm
    lib/WebService/Recruit/AbRoad/City.pm
    lib/WebService/Recruit/AbRoad/Hotel.pm
    lib/WebService/Recruit/AbRoad/Airline.pm
    lib/WebService/Recruit/AbRoad/Kodawari.pm
    lib/WebService/Recruit/AbRoad/Spot.pm
    lib/WebService/Recruit/AbRoad/TourTally.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/CarSensor.pm
    lib/WebService/Recruit/CarSensor/Base.pm
    lib/WebService/Recruit/CarSensor/Usedcar.pm
    lib/WebService/Recruit/CarSensor/Catalog.pm
    lib/WebService/Recruit/CarSensor/Brand.pm
    lib/WebService/Recruit/CarSensor/Country.pm
    lib/WebService/Recruit/CarSensor/LargeArea.pm
    lib/WebService/Recruit/CarSensor/Pref.pm
    lib/WebService/Recruit/CarSensor/Body.pm
    lib/WebService/Recruit/CarSensor/Color.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

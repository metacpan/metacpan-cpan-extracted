use strict;
use Test::More;

my $FILES = [qw(
	lib/WebService/Recruit/Dokoiku.pm
	lib/WebService/Recruit/Dokoiku/GetLandmark.pm
	lib/WebService/Recruit/Dokoiku/GetStation.pm
	lib/WebService/Recruit/Dokoiku/SearchPOI.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

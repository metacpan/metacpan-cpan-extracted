use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/HotPepperBeauty.pm
    lib/WebService/Recruit/HotPepperBeauty/Base.pm
    lib/WebService/Recruit/HotPepperBeauty/Salon.pm
    lib/WebService/Recruit/HotPepperBeauty/ServiceArea.pm
    lib/WebService/Recruit/HotPepperBeauty/MiddleArea.pm
    lib/WebService/Recruit/HotPepperBeauty/SmallArea.pm
    lib/WebService/Recruit/HotPepperBeauty/HairImage.pm
    lib/WebService/Recruit/HotPepperBeauty/HairLength.pm
    lib/WebService/Recruit/HotPepperBeauty/Kodawari.pm
    lib/WebService/Recruit/HotPepperBeauty/KodawariSetsubi.pm
    lib/WebService/Recruit/HotPepperBeauty/KodawariMenu.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

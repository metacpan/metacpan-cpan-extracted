use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/Jalan.pm
    lib/WebService/Recruit/Jalan/HotelSearchLite.pm
    lib/WebService/Recruit/Jalan/HotelSearchAdvance.pm
    lib/WebService/Recruit/Jalan/AreaSearch.pm
    lib/WebService/Recruit/Jalan/OnsenSearch.pm
    lib/WebService/Recruit/Jalan/StockSearch.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

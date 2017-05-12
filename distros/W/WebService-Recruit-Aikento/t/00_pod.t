use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/Aikento.pm
    lib/WebService/Recruit/Aikento/Base.pm
    lib/WebService/Recruit/Aikento/Item.pm
    lib/WebService/Recruit/Aikento/LargeCategory.pm
    lib/WebService/Recruit/Aikento/SmallCategory.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

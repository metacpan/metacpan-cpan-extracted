use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/Akasugu.pm
    lib/WebService/Recruit/Akasugu/Base.pm
    lib/WebService/Recruit/Akasugu/Item.pm
    lib/WebService/Recruit/Akasugu/LargeCategory.pm
    lib/WebService/Recruit/Akasugu/MiddleCategory.pm
    lib/WebService/Recruit/Akasugu/SmallCategory.pm
    lib/WebService/Recruit/Akasugu/Age.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

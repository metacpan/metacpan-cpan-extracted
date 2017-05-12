use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/AkasuguUchiiwai.pm
    lib/WebService/Recruit/AkasuguUchiiwai/Base.pm
    lib/WebService/Recruit/AkasuguUchiiwai/Item.pm
    lib/WebService/Recruit/AkasuguUchiiwai/Category.pm
    lib/WebService/Recruit/AkasuguUchiiwai/Target.pm
    lib/WebService/Recruit/AkasuguUchiiwai/Feature.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

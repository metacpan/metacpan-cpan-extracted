use strict;
use Test::More;

my $FILES = [qw(
    lib/WebService/Recruit/Shingaku.pm
    lib/WebService/Recruit/Shingaku/Base.pm
    lib/WebService/Recruit/Shingaku/School.pm
    lib/WebService/Recruit/Shingaku/Subject.pm
    lib/WebService/Recruit/Shingaku/Work.pm
    lib/WebService/Recruit/Shingaku/License.pm
    lib/WebService/Recruit/Shingaku/Pref.pm
    lib/WebService/Recruit/Shingaku/Category.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;

use strict;
use Test::More;
eval qq{ use Test::Pod };
if ($@) {
    plan skip_all => "Test::Pod required for testing POD";
}
else {
    plan tests => 1;
}
pod_file_ok('lib/Unicode/RecursiveDowngrade.pm', "Valid POD file");

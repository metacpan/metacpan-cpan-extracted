
BEGIN {
    use Test::More;
    unless ($ENV{RELEASE_TESTING}) {
        plan skip_all => 'Release test. Set $ENV{RELEASE_TESTING} to a true value to run.';
    }
}

use strict;
use warnings;
use FindBin;

eval "use Test::Pod";
plan skip_all => "Test::Pod required to criticise code" if $@;

all_pod_files_ok( all_pod_files("$FindBin::RealBin/../lib") );

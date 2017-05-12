#!perl
use Test::More;
BEGIN
{
    eval "use Test::Pod";
    if ($@) {
        plan(skip_all => "Test::Pod required for testing POD");
    }
}

all_pod_files_ok(all_pod_files(qw(blib)));
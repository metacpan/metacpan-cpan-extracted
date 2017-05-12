#!perl -T

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR})
{
    plan skip_all => 'Set $ENV{TEST_AUTHOR} to a true value to run POD tests.';
}

my $min_tp = 1.22;

eval "use Test::Pod $min_tp";
if ($@)
{
    plan skip_all => "Test::Pod $min_tp required to test POD syntax";
}

all_pod_files_ok();


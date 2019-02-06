use strict;
use utf8;
use warnings;

use Test::More;
use Test::Exception;

use WebService::IPStack;

BEGIN {
    unless ($ENV{IPSTACK_ACCESS_KEY}) {
        plan skip_all => '$ENV{IPSTACK_ACCESS_KEY} not set, skipping live tests'
    }
}

my $got;
my $ipstack = WebService::IPStack->new(api_key => $ENV{IPSTACK_ACCESS_KEY});

dies_ok {
    $got = $ipstack->bulk_lookup('8.8.8.8');
} 'expect termination on missing an array of IP address';

dies_ok {
    $got = $ipstack->bulk_lookup(['8.8.8.8']);
} 'expect termination on insufficient subscription plan';

done_testing;

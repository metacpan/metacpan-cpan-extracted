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

$got = $ipstack->lookup('8.8.8.8');
is($got->{country_code}, "US", 'expect country code match');

dies_ok {
    $got = $ipstack->lookup('8.8.8.8', {security => 1});
} 'expect termination on insufficient subscription plan';

done_testing;

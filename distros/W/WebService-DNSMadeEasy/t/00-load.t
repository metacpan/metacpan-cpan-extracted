use strict;

use Test::More 0.98;

use_ok $_ for qw(
    WebService::DNSMadeEasy
    WebService::DNSMadeEasy::ManagedDomain
    WebService::DNSMadeEasy::ManagedDomain::Record
    WebService::DNSMadeEasy::Monitor
);

done_testing;


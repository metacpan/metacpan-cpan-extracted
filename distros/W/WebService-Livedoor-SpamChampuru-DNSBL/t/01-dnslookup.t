#!perl -T
# $Id: 01-dnslookup.t 740 2008-09-30 08:05:32Z k-kaneko $
use strict;
use warnings;

use Test::More qw(no_plan);

use WebService::Livedoor::SpamChampuru::DNSBL;

can_ok("WebService::Livedoor::SpamChampuru::DNSBL", "new");

my $dnsbl = WebService::Livedoor::SpamChampuru::DNSBL->new(
    timeout => 1,
#    nameservers => [qw(203.104.103.173)],
);
isa_ok($dnsbl, "WebService::Livedoor::SpamChampuru::DNSBL");

can_ok($dnsbl, "lookup");
my $res = $dnsbl->lookup("192.0.2.100");
ok ($res);

1;

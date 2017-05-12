use strict;
use warnings;
use utf8;
use t::Util;
use LWP::UserAgent;
use Test::More;

my $agent = t::Util::build_ukigumo_agent();
my $ua = LWP::UserAgent->new(timeout => 3);
my $res = $ua->get("http://127.0.0.1:@{[ $agent->port ]}");
is $res->code, 200;

done_testing;


use strict;
use warnings;

use Test::More tests => 3;

use WWW::ProximoBus;

my $proximo = WWW::ProximoBus->new;
isa_ok($proximo, 'WWW::ProximoBus', 'constructor returns the right object');
isa_ok($proximo->ua, 'LWP::UserAgent', 'useragent attr is an LWP::UserAgent');

eval 'require LWP::UserAgent';
my $ua = LWP::UserAgent->new;
$ua->timeout(15);
$proximo->ua($ua);
is($proximo->ua->timeout, 15, 'we can set a new useragent if we like');

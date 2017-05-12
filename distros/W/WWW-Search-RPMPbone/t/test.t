use Test::Simple tests=>2;

use WWW::Search::RPMPbone;
ok(1);

use WWW::Search;
my $oSearch = new WWW::Search('RPMPbone');
ok(defined $oSearch);


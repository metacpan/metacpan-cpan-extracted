use strict;
use Test::More 0.98;

use WebService::Annict::Episodes;

my $episodes = WebService::Annict::Episodes->new();
isa_ok $episodes, "WebService::Annict::Episodes";

done_testing;

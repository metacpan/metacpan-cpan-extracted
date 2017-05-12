use strict;
use Test::More 0.98;

use WebService::Annict::Records;

my $records = WebService::Annict::Records->new();
isa_ok $records, "WebService::Annict::Records";

done_testing;

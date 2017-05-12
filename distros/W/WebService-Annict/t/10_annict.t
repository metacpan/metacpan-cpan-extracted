use strict;
use Test::More 0.98;

use WebService::Annict;

my $access_token = $ENV{ANNICT_ACCESS_TOKEN};

my $annict = WebService::Annict->new(access_token => $access_token);
isa_ok $annict, "WebService::Annict";

#if($access_token) {
#}

done_testing;

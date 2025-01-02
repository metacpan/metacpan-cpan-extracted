use strict;
use warnings;
use Test::More;

use_ok "Webservice::Rosary::API";

my $Rosary = Webservice::Rosary::API->new;

isa_ok $Rosary, "Webservice::Rosary::API";

done_testing;

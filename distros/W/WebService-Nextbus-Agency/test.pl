use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 9 };
BEGIN { use_ok('WebService::Nextbus::Agency') };

my $agency = new WebService::Nextbus::Agency;
isa_ok($agency, 'WebService::Nextbus::Agency', 'new agency');

can_ok($agency, qw(nameCode routeRegExp dirRegExp routes dirs stops stopCode allStopNames allStopCodes parseRoute parseDir str2stopCodes routesAsString));

BEGIN { use_ok('WebService::Nextbus::Agency::SFMUNI') };

my $muniAgency = new WebService::Nextbus::Agency::SFMUNI;
isa_ok($muniAgency, 'WebService::Nextbus::Agency::SFMUNI', 'new muniAgency');
isa_ok($muniAgency, 'WebService::Nextbus::Agency', 'new muniAgency');

# Don't need this can_ok for now since the subclass doesn't havfe any
# additional methods.  But may need it in future.
# can_ok($muniAgency, qw());

is($muniAgency->nameCode(), 'sf-muni', 'set basic variable correctly');
is($muniAgency->stopCode('N', 'caltrain', 'Judah St and Funston Ave'), 'JUDAFUN1', 'JUDAFUN1 checks out in routes tree');
is(join('', $muniAgency->str2stopCodes('N', 'judah', 'Judah Funston')), 'JUDAFUN0', 'can find stopCode JUDAFUN0 (Judah and Funston) using str2stopCodes');
